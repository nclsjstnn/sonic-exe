--[[
	init.server.lua (Script)
	========================
	Script raíz de GameManager. Orquesta todas las fases del juego
	conectando los módulos: MapBuilder, PlayerManager, DoorSystem,
	DamageSystem. Implementa el bucle de rondas automático.

	Ubicación: ServerScriptService.GameManager
]]

---------------------------------------------------------------------
-- Servicios
---------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------------------------------------------------------------------
-- Módulos compartidos
---------------------------------------------------------------------
local Modules  = ReplicatedStorage:WaitForChild("Modules")
local Config   = require(Modules:WaitForChild("Config"))
local Remotes  = require(Modules:WaitForChild("RemoteManager"))

---------------------------------------------------------------------
-- Crear RemoteEvents antes de que los clientes los necesiten
---------------------------------------------------------------------
Remotes.Init()

---------------------------------------------------------------------
-- Módulos del servidor
---------------------------------------------------------------------
local MapBuilder    = require(script:WaitForChild("MapBuilder"))
local PlayerManager = require(script:WaitForChild("PlayerManager"))
local DoorSystem    = require(script:WaitForChild("DoorSystem"))
local DamageSystem  = require(script:WaitForChild("DamageSystem"))

---------------------------------------------------------------------
-- Construir mapa
---------------------------------------------------------------------
MapBuilder.Build()

-- Inyectar spawns en PlayerManager
PlayerManager.LobbySpawn = MapBuilder.LobbySpawn
PlayerManager.GameSpawn  = MapBuilder.GameSpawn

-- Inyectar carpeta de puertas
DoorSystem.DoorsFolder = MapBuilder.DoorsFolder

---------------------------------------------------------------------
-- Estado global de la ronda
---------------------------------------------------------------------
local currentPhase   = "Descanso"  -- "Descanso" | "Seleccion" | "Partida" | "Fin"
local poligonoPlayer = nil         -- Player que es el Polígono
local aliveForms     = {}          -- { [Player] = true }
local escapedForms   = {}          -- { [Player] = true }
local playerShapes   = {}          -- { [Player] = "Cubo" | ... }

---------------------------------------------------------------------
-- Remotes
---------------------------------------------------------------------
local RoleAssigned      = Remotes.Get("RoleAssigned")
local UpdateTimer       = Remotes.Get("UpdateTimer")
local ShowBlackScreen   = Remotes.Get("ShowBlackScreen")
local ShowDefeatScreen  = Remotes.Get("ShowDefeatScreen")
local ShowVictoryScreen = Remotes.Get("ShowVictoryScreen")
local ShowEscapeScreen  = Remotes.Get("ShowEscapeScreen")
local ShapeSelected     = Remotes.Get("ShapeSelected")
local OpenDoors         = Remotes.Get("OpenDoors")
local TeleportToGame    = Remotes.Get("TeleportToGame")
local StartMatch        = Remotes.Get("StartMatch")

---------------------------------------------------------------------
-- Condiciones de victoria
---------------------------------------------------------------------
local function checkVictory()
	if currentPhase ~= "Partida" then return end

	local aliveCount = 0
	for _ in pairs(aliveForms) do aliveCount += 1 end

	local escapedCount = 0
	for _ in pairs(escapedForms) do escapedCount += 1 end

	-- Si ya no hay formas vivas, determinar resultado
	if aliveCount == 0 then
		if escapedCount > 0 then
			-- Formas ganan
			for p in pairs(escapedForms) do
				if p and p.Parent then
					ShowVictoryScreen:FireClient(p, "Formas")
				end
			end
			if poligonoPlayer and poligonoPlayer.Parent then
				ShowDefeatScreen:FireClient(poligonoPlayer)
			end
		else
			-- Polígono gana
			if poligonoPlayer and poligonoPlayer.Parent then
				ShowVictoryScreen:FireClient(poligonoPlayer, "Poligono")
			end
		end
		currentPhase = "Fin"
	end
end

---------------------------------------------------------------------
-- Inyectar callbacks en DamageSystem
---------------------------------------------------------------------
DamageSystem.GetPhase    = function() return currentPhase end
DamageSystem.GetPoligono = function() return poligonoPlayer end
DamageSystem.IsAlive     = function(p) return aliveForms[p] == true end
DamageSystem.IsEscaped   = function(p) return escapedForms[p] == true end

DamageSystem.OnPlayerKilled = function(player: Player)
	aliveForms[player] = nil
	ShowDefeatScreen:FireClient(player)
	task.delay(0.5, function()
		if player and player.Parent then
			PlayerManager.TeleportToLobby(player)
		end
	end)
	checkVictory()
end

DamageSystem.Init()

---------------------------------------------------------------------
-- Inyectar callback de escape en DoorSystem
---------------------------------------------------------------------
DoorSystem.OnPlayerEscape = function(player: Player)
	if currentPhase ~= "Partida" then return end
	if player == poligonoPlayer then return end
	if escapedForms[player] then return end
	if not aliveForms[player] then return end

	aliveForms[player] = nil
	escapedForms[player] = true
	player:SetAttribute("Escaped", true)
	ShowEscapeScreen:FireClient(player)
	PlayerManager.TeleportToLobby(player)
	checkVictory()
end

---------------------------------------------------------------------
-- Selección de forma (servidor)
---------------------------------------------------------------------
ShapeSelected.OnServerEvent:Connect(function(player: Player, shapeName: string)
	if currentPhase ~= "Seleccion" then return end
	if player == poligonoPlayer then return end

	-- Validar nombre
	local valid = false
	for _, name in ipairs(Config.SHAPE_NAMES) do
		if name == shapeName then valid = true; break end
	end
	if not valid then return end

	playerShapes[player] = shapeName
	player:SetAttribute("Shape", shapeName)
end)

---------------------------------------------------------------------
-- FASE 1: DESCANSO (40 s)
---------------------------------------------------------------------
local function phaseRest()
	currentPhase = "Descanso"

	for _, player in ipairs(Players:GetPlayers()) do
		PlayerManager.ResetAttributes(player)
		PlayerManager.TeleportToLobby(player)
	end

	for i = Config.REST_TIME, 1, -1 do
		if currentPhase ~= "Descanso" then return end
		UpdateTimer:FireAllClients("Descanso: " .. i)
		task.wait(1)
	end

	-- Verificar mínimo de jugadores
	while #PlayerManager.GetActivePlayers() < 2 do
		UpdateTimer:FireAllClients("Esperando jugadores... (minimo 2)")
		task.wait(1)
	end
end

---------------------------------------------------------------------
-- FASE 2: SELECCION (30 s)
---------------------------------------------------------------------
local function phaseSelection()
	currentPhase = "Seleccion"

	-- Limpiar estado anterior
	playerShapes  = {}
	aliveForms    = {}
	escapedForms  = {}
	poligonoPlayer = nil
	DamageSystem.ResetAll()

	-- Pantalla negra
	ShowBlackScreen:FireAllClients(true)
	task.wait(1)

	-- Elegir Polígono al azar
	local players = PlayerManager.GetActivePlayers()
	if #players < 2 then
		ShowBlackScreen:FireAllClients(false)
		return
	end

	poligonoPlayer = players[math.random(1, #players)]
	poligonoPlayer:SetAttribute("Role", "Poligono")
	RoleAssigned:FireClient(poligonoPlayer, "Poligono")

	-- Los demás son Formas
	for _, player in ipairs(players) do
		if player ~= poligonoPlayer then
			player:SetAttribute("Role", "Forma")
			RoleAssigned:FireClient(player, "Forma")
		end
	end

	-- Quitar pantalla negra
	task.wait(1)
	ShowBlackScreen:FireAllClients(false)

	-- Timer de selección
	for i = Config.SELECT_TIME, 1, -1 do
		if currentPhase ~= "Seleccion" then return end
		UpdateTimer:FireAllClients("Seleccion: " .. i)
		task.wait(1)
	end

	-- Asignar forma aleatoria a quienes no eligieron
	for _, player in ipairs(PlayerManager.GetActivePlayers()) do
		if player ~= poligonoPlayer and not playerShapes[player] then
			local shape = Config.SHAPE_NAMES[math.random(1, #Config.SHAPE_NAMES)]
			playerShapes[player] = shape
			player:SetAttribute("Shape", shape)
		end
	end
end

---------------------------------------------------------------------
-- FASE 3: PARTIDA (300 s)
---------------------------------------------------------------------
local function phaseMatch()
	currentPhase = "Partida"

	local players = PlayerManager.GetActivePlayers()

	-- Teletransportar a todos a la arena con su apariencia
	for _, player in ipairs(players) do
		if player == poligonoPlayer then
			PlayerManager.InitForMatch(player, "Poligono")
			player:LoadCharacter()
			task.wait(0.5)
			PlayerManager.TeleportToGame(player)
			task.wait(0.2)
			PlayerManager.ApplyPoligonoAppearance(player)
		else
			PlayerManager.InitForMatch(player, "Forma")
			aliveForms[player] = true
			player:LoadCharacter()
			task.wait(0.3)
			PlayerManager.TeleportToGame(player)
			task.wait(0.1)
			local shape = playerShapes[player] or "Cubo"
			PlayerManager.ApplyShapeAppearance(player, shape)
		end
	end

	-- Señal de inicio de partida
	TeleportToGame:FireAllClients()
	StartMatch:FireAllClients()

	-- Timer principal
	for i = Config.MATCH_TIME, 1, -1 do
		if currentPhase ~= "Partida" then break end

		local mm = math.floor(i / 60)
		local ss = i % 60
		local text = string.format("Partida: %d:%02d", mm, ss)

		-- Abrir puertas cuando quedan 60 s
		if i == Config.DOOR_OPEN_AT and not DoorSystem.IsOpen() then
			DoorSystem.Open()
			OpenDoors:FireAllClients()
		end

		-- Indicar que las puertas están abiertas
		if DoorSystem.IsOpen() then
			text = text .. "  |  ESCAPA!"
		end

		UpdateTimer:FireAllClients(text)
		task.wait(1)

		if currentPhase == "Fin" then break end
	end

	-- Cerrar puertas
	DoorSystem.Close()

	-- Si la partida no terminó por victoria anticipada
	if currentPhase == "Partida" then
		-- Matar formas que no escaparon
		for player in pairs(aliveForms) do
			if player and player.Parent then
				ShowDefeatScreen:FireClient(player)
				PlayerManager.TeleportToLobby(player)
				player:SetAttribute("Role", "Dead")
				player:SetAttribute("Health", 0)
			end
		end

		-- Determinar resultado
		local escapedCount = 0
		for _ in pairs(escapedForms) do escapedCount += 1 end

		if escapedCount > 0 then
			for p in pairs(escapedForms) do
				if p and p.Parent then
					ShowVictoryScreen:FireClient(p, "Formas")
				end
			end
			if poligonoPlayer and poligonoPlayer.Parent then
				ShowDefeatScreen:FireClient(poligonoPlayer)
			end
		else
			if poligonoPlayer and poligonoPlayer.Parent then
				ShowVictoryScreen:FireClient(poligonoPlayer, "Poligono")
			end
		end

		aliveForms = {}
		currentPhase = "Fin"
	end
end

---------------------------------------------------------------------
-- FASE 4: POST-PARTIDA (reinicio)
---------------------------------------------------------------------
local function phasePostMatch()
	UpdateTimer:FireAllClients("Reiniciando...")
	task.wait(Config.POST_MATCH_WAIT)

	DoorSystem.Close()
	poligonoPlayer = nil
	aliveForms     = {}
	escapedForms   = {}
	playerShapes   = {}
	DamageSystem.ResetAll()

	for _, player in ipairs(Players:GetPlayers()) do
		PlayerManager.ResetAttributes(player)
		player:LoadCharacter()
		task.wait(0.2)
		PlayerManager.TeleportToLobby(player)
	end
end

---------------------------------------------------------------------
-- Manejo de desconexiones
---------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player: Player)
	aliveForms[player]   = nil
	escapedForms[player] = nil
	playerShapes[player] = nil
	DamageSystem.ClearCooldown(player)

	if player == poligonoPlayer and currentPhase == "Partida" then
		-- Polígono se fue → Formas ganan
		poligonoPlayer = nil
		for p in pairs(aliveForms) do
			if p and p.Parent then
				ShowVictoryScreen:FireClient(p, "Formas")
				PlayerManager.TeleportToLobby(p)
			end
		end
		for p in pairs(escapedForms) do
			if p and p.Parent then
				ShowVictoryScreen:FireClient(p, "Formas")
			end
		end
		aliveForms = {}
		currentPhase = "Fin"
	elseif currentPhase == "Partida" then
		checkVictory()
	end
end)

---------------------------------------------------------------------
-- Manejo de nuevos jugadores
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player: Player)
	PlayerManager.ResetAttributes(player)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			if currentPhase == "Partida" and aliveForms[player] then
				aliveForms[player] = nil
				ShowDefeatScreen:FireClient(player)
				task.wait(2)
				if player and player.Parent then
					PlayerManager.TeleportToLobby(player)
					checkVictory()
				end
			end
		end)
	end)

	if currentPhase == "Descanso" then
		player.CharacterAdded:Wait()
		PlayerManager.TeleportToLobby(player)
	end
end)

-- Inicializar jugadores existentes
for _, player in ipairs(Players:GetPlayers()) do
	PlayerManager.ResetAttributes(player)
end

---------------------------------------------------------------------
-- BUCLE PRINCIPAL
---------------------------------------------------------------------
task.spawn(function()
	while true do
		phaseRest()
		phaseSelection()
		phaseMatch()
		phasePostMatch()
	end
end)

print("[GameManager] Juego de terror asimetrico iniciado.")
