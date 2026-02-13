--[[
	GameManager.server.lua
	=====================
	Script principal del servidor. Controla el ciclo completo del juego:
	  1. Descanso (40 s)  – todos en Lobby
	  2. Selección (30 s) – pantalla negra, asignar Polígono, formas eligen personaje
	  3. Partida (300 s)  – juego activo, puertas abren a los 60 s finales
	Después de cada partida se reinicia todo y se vuelve a Descanso.
]]

---------------------------------------------------------------------
-- Servicios
---------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local ServerStorage      = game:GetService("ServerStorage")

---------------------------------------------------------------------
-- RemoteEvents (se crean si no existen)
---------------------------------------------------------------------
local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "RemoteEvents"
	remoteFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name: string): RemoteEvent
	local r = remoteFolder:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remoteFolder
	end
	return r
end

local RoleAssigned      = getOrCreateRemote("RoleAssigned")
local UpdateTimer       = getOrCreateRemote("UpdateTimer")
local DamagePlayer      = getOrCreateRemote("DamagePlayer")
local ShowBlackScreen   = getOrCreateRemote("ShowBlackScreen")
local OpenDoors         = getOrCreateRemote("OpenDoors")
local PlayerEscaped     = getOrCreateRemote("PlayerEscaped")
local ShowDefeatScreen  = getOrCreateRemote("ShowDefeatScreen")
local ShapeSelected     = getOrCreateRemote("ShapeSelected")
local ShowVictoryScreen = getOrCreateRemote("ShowVictoryScreen")
local TeleportToGame    = getOrCreateRemote("TeleportToGame")
local ShowEscapeScreen  = getOrCreateRemote("ShowEscapeScreen")

---------------------------------------------------------------------
-- Configuración
---------------------------------------------------------------------
local REST_TIME      = 40   -- segundos de descanso
local SELECT_TIME    = 30   -- segundos de selección
local MATCH_TIME     = 300  -- 5 minutos de partida
local DOOR_OPEN_AT   = 60   -- puertas abren cuando quedan 60 s
local POST_MATCH     = 5    -- espera después de partida

local SHAPE_NAMES = { "Cono", "Esfera", "Cubo", "Tubo", "Rectangulo" }
local SHAPE_HEALTH = 100
local GOLPE_DAMAGE = 10
local GOLPE_COOLDOWN = 2.1

---------------------------------------------------------------------
-- Estado global del juego
---------------------------------------------------------------------
local currentPhase = "Descanso" -- "Descanso" | "Seleccion" | "Partida"
local poligonoPlayer = nil      -- Player que es Polígono
local aliveForms = {}           -- { [Player] = true }
local escapedForms = {}         -- { [Player] = true }
local playerShapes = {}         -- { [Player] = "Cubo" | etc. }
local lastGolpeTime = {}        -- { [Player] = tick() } cooldown tracker
local doorsOpen = false

---------------------------------------------------------------------
-- Workspace references (se crean si no existen)
---------------------------------------------------------------------
local workspace = game:GetService("Workspace")

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local mapFolder   = ensureFolder(workspace, "Map")
local doorsFolder = ensureFolder(workspace, "Doors")

-- Spawn points
local function ensureSpawn(parent, name, position)
	local sp = parent:FindFirstChild(name)
	if not sp then
		sp = Instance.new("SpawnLocation")
		sp.Name = name
		sp.Size = Vector3.new(12, 1, 12)
		sp.Position = position
		sp.Anchored = true
		sp.CanCollide = true
		sp.Neutral = false
		sp.Parent = parent
	end
	return sp
end

local lobbySpawn = ensureSpawn(workspace, "LobbySpawn", Vector3.new(0, 3, 0))
local gameSpawn  = ensureSpawn(workspace, "GameSpawn", Vector3.new(0, 3, 200))

-- Desactivar auto-asignación de team en spawns
lobbySpawn.Neutral = true
gameSpawn.Neutral = true

---------------------------------------------------------------------
-- Creación de mapa básico (suelo de juego)
---------------------------------------------------------------------
local function ensureMapFloor()
	if not mapFolder:FindFirstChild("Floor") then
		local floor = Instance.new("Part")
		floor.Name = "Floor"
		floor.Size = Vector3.new(200, 1, 200)
		floor.Position = Vector3.new(0, 0, 200)
		floor.Anchored = true
		floor.BrickColor = BrickColor.new("Dark stone grey")
		floor.Material = Enum.Material.Concrete
		floor.Parent = mapFolder
	end
	if not mapFolder:FindFirstChild("LobbyFloor") then
		local lf = Instance.new("Part")
		lf.Name = "LobbyFloor"
		lf.Size = Vector3.new(60, 1, 60)
		lf.Position = Vector3.new(0, 0, 0)
		lf.Anchored = true
		lf.BrickColor = BrickColor.new("Medium stone grey")
		lf.Material = Enum.Material.SmoothPlastic
		lf.Parent = mapFolder
	end
end
ensureMapFloor()

---------------------------------------------------------------------
-- Sistema de puertas
---------------------------------------------------------------------
local DOOR_POSITIONS = {
	Vector3.new(100, 5, 200),
	Vector3.new(-100, 5, 200),
	Vector3.new(0, 5, 300),
	Vector3.new(0, 5, 100),
}

local activeDoors = {}

local function createDoor(position: Vector3): Part
	local door = Instance.new("Part")
	door.Name = "EscapeDoor"
	door.Size = Vector3.new(8, 12, 2)
	door.Position = position
	door.Anchored = true
	door.CanCollide = false -- las formas pueden pasar
	door.BrickColor = BrickColor.new("Bright green")
	door.Material = Enum.Material.Neon
	door.Transparency = 0.3
	door.Parent = doorsFolder

	-- Zona de detección
	local touchConn
	touchConn = door.Touched:Connect(function(hit)
		if currentPhase ~= "Partida" or not doorsOpen then return end

		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end
		if player == poligonoPlayer then return end
		if escapedForms[player] then return end
		if not aliveForms[player] then return end

		-- Jugador escapa
		escapedForms[player] = true
		aliveForms[player] = nil
		player:SetAttribute("Escaped", true)
		ShowEscapeScreen:FireClient(player)
		teleportToLobby(player)
		checkVictoryConditions()
	end)

	return door
end

local function openAllDoors()
	doorsOpen = true
	-- Elegir 2 posiciones aleatorias de las disponibles
	local shuffled = table.clone(DOOR_POSITIONS)
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	local count = math.min(3, #shuffled)
	for i = 1, count do
		local door = createDoor(shuffled[i])
		table.insert(activeDoors, door)
	end

	OpenDoors:FireAllClients()
end

local function closeAllDoors()
	doorsOpen = false
	for _, door in ipairs(activeDoors) do
		if door and door.Parent then
			door:Destroy()
		end
	end
	activeDoors = {}
end

---------------------------------------------------------------------
-- Utilidades de teletransporte
---------------------------------------------------------------------
function teleportToLobby(player: Player)
	local char = player.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = lobbySpawn.CFrame + Vector3.new(
				math.random(-5, 5), 5, math.random(-5, 5)
			)
		end
	end
end

local function teleportToGame(player: Player)
	local char = player.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = gameSpawn.CFrame + Vector3.new(
				math.random(-10, 10), 5, math.random(-10, 10)
			)
		end
	end
end

---------------------------------------------------------------------
-- Utilidades de atributos
---------------------------------------------------------------------
local function resetPlayerAttributes(player: Player)
	player:SetAttribute("Role", "None")
	player:SetAttribute("Health", 0)
	player:SetAttribute("Escaped", false)
	player:SetAttribute("Shape", "None")
end

local function initPlayerForMatch(player: Player, role: string)
	player:SetAttribute("Role", role)
	player:SetAttribute("Escaped", false)

	if role == "Forma" then
		player:SetAttribute("Health", SHAPE_HEALTH)
	else
		player:SetAttribute("Health", 999) -- Polígono no tiene vida limitada
	end
end

---------------------------------------------------------------------
-- Condiciones de victoria
---------------------------------------------------------------------
function checkVictoryConditions()
	if currentPhase ~= "Partida" then return end

	local aliveCount = 0
	for _ in pairs(aliveForms) do
		aliveCount += 1
	end

	local escapedCount = 0
	for _ in pairs(escapedForms) do
		escapedCount += 1
	end

	-- Polígono gana: todas las formas murieron (ninguna escapó y ninguna viva)
	if aliveCount == 0 and escapedCount == 0 then
		-- Polígono gana
		if poligonoPlayer then
			ShowVictoryScreen:FireClient(poligonoPlayer, "Polígono")
		end
		currentPhase = "Fin"
		return
	end

	-- Formas ganan: al menos una escapó
	if escapedCount > 0 and aliveCount == 0 then
		-- Todas las formas restantes murieron o escaparon; al menos una escapó
		for player in pairs(escapedForms) do
			ShowVictoryScreen:FireClient(player, "Formas")
		end
		if poligonoPlayer then
			ShowDefeatScreen:FireClient(poligonoPlayer)
		end
		currentPhase = "Fin"
		return
	end
end

---------------------------------------------------------------------
-- Sistema de daño (servidor)
---------------------------------------------------------------------
DamagePlayer.OnServerEvent:Connect(function(attacker: Player, targetPlayer: Player)
	-- Validaciones
	if currentPhase ~= "Partida" then return end
	if attacker ~= poligonoPlayer then return end -- solo Polígono puede atacar
	if targetPlayer == poligonoPlayer then return end -- no autodaño
	if not aliveForms[targetPlayer] then return end
	if escapedForms[targetPlayer] then return end

	-- Cooldown del golpe
	local now = tick()
	if lastGolpeTime[attacker] and (now - lastGolpeTime[attacker]) < GOLPE_COOLDOWN then
		return -- aún en cooldown
	end
	lastGolpeTime[attacker] = now

	-- Aplicar daño
	local currentHealth = targetPlayer:GetAttribute("Health") or 0
	currentHealth = math.max(0, currentHealth - GOLPE_DAMAGE)
	targetPlayer:SetAttribute("Health", currentHealth)

	if currentHealth <= 0 then
		-- Forma muere
		aliveForms[targetPlayer] = nil
		ShowDefeatScreen:FireClient(targetPlayer)
		teleportToLobby(targetPlayer)
		targetPlayer:SetAttribute("Role", "Dead")

		-- Respawnear al jugador en lobby
		task.delay(1, function()
			if targetPlayer and targetPlayer.Parent then
				local char = targetPlayer.Character
				if char then
					local humanoid = char:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.Health = humanoid.MaxHealth
					end
				end
			end
		end)

		checkVictoryConditions()
	end
end)

---------------------------------------------------------------------
-- Selección de forma (servidor)
---------------------------------------------------------------------
ShapeSelected.OnServerEvent:Connect(function(player: Player, shapeName: string)
	if currentPhase ~= "Seleccion" then return end
	if player == poligonoPlayer then return end

	-- Validar que sea una forma válida
	local valid = false
	for _, name in ipairs(SHAPE_NAMES) do
		if name == shapeName then
			valid = true
			break
		end
	end
	if not valid then return end

	playerShapes[player] = shapeName
	player:SetAttribute("Shape", shapeName)
end)

---------------------------------------------------------------------
-- Obtener jugadores activos
---------------------------------------------------------------------
local function getActivePlayers(): { Player }
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Parent then
			table.insert(list, player)
		end
	end
	return list
end

---------------------------------------------------------------------
-- FASE: DESCANSO
---------------------------------------------------------------------
local function phaseRest()
	currentPhase = "Descanso"

	-- Asegurar todos en lobby
	for _, player in ipairs(Players:GetPlayers()) do
		resetPlayerAttributes(player)
		teleportToLobby(player)
	end

	-- Timer de descanso
	for i = REST_TIME, 1, -1 do
		if currentPhase ~= "Descanso" then return end

		local label = "Descanso: " .. tostring(i)
		UpdateTimer:FireAllClients(label)
		task.wait(1)
	end

	-- Verificar mínimo de jugadores
	local players = getActivePlayers()
	if #players < 2 then
		UpdateTimer:FireAllClients("Esperando jugadores... (mínimo 2)")
		-- Esperar hasta tener al menos 2 jugadores
		while #getActivePlayers() < 2 do
			task.wait(1)
		end
	end
end

---------------------------------------------------------------------
-- FASE: SELECCIÓN
---------------------------------------------------------------------
local function phaseSelection()
	currentPhase = "Seleccion"
	playerShapes = {}
	aliveForms = {}
	escapedForms = {}
	lastGolpeTime = {}
	poligonoPlayer = nil

	-- Pantalla negra para todos
	ShowBlackScreen:FireAllClients(true)
	task.wait(1)

	-- Elegir Polígono al azar
	local players = getActivePlayers()
	if #players < 2 then
		ShowBlackScreen:FireAllClients(false)
		return
	end

	local randomIndex = math.random(1, #players)
	poligonoPlayer = players[randomIndex]
	poligonoPlayer:SetAttribute("Role", "Poligono")
	RoleAssigned:FireClient(poligonoPlayer, "Poligono")

	-- Asignar rol "Forma" a los demás y mostrar UI de selección
	for _, player in ipairs(players) do
		if player ~= poligonoPlayer then
			player:SetAttribute("Role", "Forma")
			RoleAssigned:FireClient(player, "Forma")
		end
	end

	-- Quitar pantalla negra después de 2 segundos
	task.wait(1)
	ShowBlackScreen:FireAllClients(false)

	-- Timer de selección
	for i = SELECT_TIME, 1, -1 do
		if currentPhase ~= "Seleccion" then return end

		local label = "Selección: " .. tostring(i)
		UpdateTimer:FireAllClients(label)
		task.wait(1)
	end

	-- Asignar forma aleatoria a quienes no eligieron
	for _, player in ipairs(getActivePlayers()) do
		if player ~= poligonoPlayer then
			if not playerShapes[player] then
				local randomShape = SHAPE_NAMES[math.random(1, #SHAPE_NAMES)]
				playerShapes[player] = randomShape
				player:SetAttribute("Shape", randomShape)
			end
		end
	end
end

---------------------------------------------------------------------
-- Aplicar apariencia de forma al personaje
---------------------------------------------------------------------
local SHAPE_COLORS = {
	Cono       = BrickColor.new("Bright yellow"),
	Esfera     = BrickColor.new("Bright blue"),
	Cubo       = BrickColor.new("Bright red"),
	Tubo       = BrickColor.new("Bright green"),
	Rectangulo = BrickColor.new("Bright violet"),
}

local function applyShapeAppearance(player: Player, shapeName: string)
	local char = player.Character
	if not char then return end

	local color = SHAPE_COLORS[shapeName] or BrickColor.new("Medium stone grey")

	-- Cambiar color de todas las partes del cuerpo
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.BrickColor = color
		end
	end

	-- Poner un accesorio identificador sobre la cabeza
	local head = char:FindFirstChild("Head")
	if head then
		local existing = head:FindFirstChild("ShapeIndicator")
		if existing then existing:Destroy() end

		local indicator = Instance.new("BillboardGui")
		indicator.Name = "ShapeIndicator"
		indicator.Size = UDim2.new(0, 100, 0, 40)
		indicator.StudsOffset = Vector3.new(0, 3, 0)
		indicator.Adornee = head
		indicator.AlwaysOnTop = true
		indicator.Parent = head

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = shapeName
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = indicator
	end
end

local function applyPoligonoAppearance(player: Player)
	local char = player.Character
	if not char then return end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.BrickColor = BrickColor.new("Really black")
			part.Material = Enum.Material.Neon
		end
	end

	local head = char:FindFirstChild("Head")
	if head then
		local existing = head:FindFirstChild("ShapeIndicator")
		if existing then existing:Destroy() end

		local indicator = Instance.new("BillboardGui")
		indicator.Name = "ShapeIndicator"
		indicator.Size = UDim2.new(0, 120, 0, 40)
		indicator.StudsOffset = Vector3.new(0, 3, 0)
		indicator.Adornee = head
		indicator.AlwaysOnTop = true
		indicator.Parent = head

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "POLÍGONO"
		label.TextColor3 = Color3.new(1, 0, 0)
		label.TextStrokeTransparency = 0
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = indicator
	end
end

---------------------------------------------------------------------
-- FASE: PARTIDA
---------------------------------------------------------------------
local function phaseMatch()
	currentPhase = "Partida"
	doorsOpen = false

	local players = getActivePlayers()

	-- Inicializar jugadores
	for _, player in ipairs(players) do
		if player == poligonoPlayer then
			initPlayerForMatch(player, "Poligono")
			-- Respawnear personaje
			player:LoadCharacter()
			task.wait(0.5)
			teleportToGame(player)
			applyPoligonoAppearance(player)
		else
			initPlayerForMatch(player, "Forma")
			aliveForms[player] = true
			player:LoadCharacter()
			task.wait(0.2)
			teleportToGame(player)
			local shape = playerShapes[player] or "Cubo"
			applyShapeAppearance(player, shape)
		end
	end

	-- Enviar señal a clientes de que empieza la partida
	TeleportToGame:FireAllClients()

	-- Timer de partida
	for i = MATCH_TIME, 1, -1 do
		if currentPhase ~= "Partida" then break end

		-- Formato mm:ss
		local minutes = math.floor(i / 60)
		local seconds = i % 60
		local label = string.format("Partida: %d:%02d", minutes, seconds)
		UpdateTimer:FireAllClients(label)

		-- Abrir puertas cuando quedan 60 segundos
		if i == DOOR_OPEN_AT and not doorsOpen then
			openAllDoors()
			UpdateTimer:FireAllClients(label .. " | ¡PUERTAS ABIERTAS!")
		end

		-- Añadir indicador de puertas abiertas
		if i < DOOR_OPEN_AT and doorsOpen then
			UpdateTimer:FireAllClients(label .. " | ¡ESCAPA!")
		end

		task.wait(1)

		-- Verificar si la partida ya terminó
		if currentPhase == "Fin" then break end
	end

	-- Tiempo agotado - cerrar puertas
	closeAllDoors()

	if currentPhase == "Partida" then
		-- Matar formas que no escaparon
		for player in pairs(aliveForms) do
			if player and player.Parent then
				ShowDefeatScreen:FireClient(player)
				teleportToLobby(player)
				player:SetAttribute("Role", "Dead")
				player:SetAttribute("Health", 0)
			end
		end

		-- Determinar resultado final
		local escapedCount = 0
		for _ in pairs(escapedForms) do
			escapedCount += 1
		end

		if escapedCount > 0 then
			-- Formas ganan
			for player in pairs(escapedForms) do
				if player and player.Parent then
					ShowVictoryScreen:FireClient(player, "Formas")
				end
			end
			if poligonoPlayer and poligonoPlayer.Parent then
				ShowDefeatScreen:FireClient(poligonoPlayer)
			end
		else
			-- Polígono gana
			if poligonoPlayer and poligonoPlayer.Parent then
				ShowVictoryScreen:FireClient(poligonoPlayer, "Polígono")
			end
		end

		aliveForms = {}
	end

	currentPhase = "Fin"
end

---------------------------------------------------------------------
-- FASE: REINICIO
---------------------------------------------------------------------
local function phasePostMatch()
	UpdateTimer:FireAllClients("Reiniciando...")
	task.wait(POST_MATCH)

	-- Resetear todo
	closeAllDoors()
	poligonoPlayer = nil
	aliveForms = {}
	escapedForms = {}
	playerShapes = {}
	lastGolpeTime = {}
	doorsOpen = false

	for _, player in ipairs(Players:GetPlayers()) do
		resetPlayerAttributes(player)
		player:LoadCharacter()
		task.wait(0.2)
		teleportToLobby(player)
	end
end

---------------------------------------------------------------------
-- Manejo de desconexiones
---------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player: Player)
	-- Limpiar al jugador de todas las tablas
	aliveForms[player] = nil
	escapedForms[player] = nil
	playerShapes[player] = nil
	lastGolpeTime[player] = nil

	if player == poligonoPlayer then
		-- Si el Polígono se desconecta, las formas ganan
		if currentPhase == "Partida" then
			poligonoPlayer = nil
			for p in pairs(aliveForms) do
				if p and p.Parent then
					ShowVictoryScreen:FireClient(p, "Formas")
					teleportToLobby(p)
				end
			end
			for p in pairs(escapedForms) do
				if p and p.Parent then
					ShowVictoryScreen:FireClient(p, "Formas")
				end
			end
			aliveForms = {}
			currentPhase = "Fin"
		end
	else
		-- Si una forma se desconecta, verificar condiciones de victoria
		if currentPhase == "Partida" then
			checkVictoryConditions()
		end
	end
end)

---------------------------------------------------------------------
-- Manejo de nuevos jugadores
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player: Player)
	resetPlayerAttributes(player)

	player.CharacterAdded:Connect(function(character)
		-- Si el jugador muere durante partida, manejarlo
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			if currentPhase == "Partida" then
				if aliveForms[player] then
					aliveForms[player] = nil
					ShowDefeatScreen:FireClient(player)
					task.wait(2)
					if player and player.Parent then
						teleportToLobby(player)
						checkVictoryConditions()
					end
				end
			end
		end)
	end)

	-- Si el juego está en descanso, teletransportar al lobby
	if currentPhase == "Descanso" then
		player.CharacterAdded:Wait()
		teleportToLobby(player)
	end
end)

---------------------------------------------------------------------
-- Inicializar jugadores existentes
---------------------------------------------------------------------
for _, player in ipairs(Players:GetPlayers()) do
	resetPlayerAttributes(player)
end

---------------------------------------------------------------------
-- BUCLE PRINCIPAL DEL JUEGO
---------------------------------------------------------------------
task.spawn(function()
	while true do
		phaseRest()
		phaseSelection()
		phaseMatch()
		phasePostMatch()
	end
end)

print("[GameManager] Sistema de juego iniciado correctamente.")
