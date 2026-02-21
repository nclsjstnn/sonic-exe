--[[
	PlayerManager.lua (ModuleScript)
	================================
	Gestiona atributos, teletransporte, apariencia y roles de jugadores.
	Ubicación: ServerScriptService.GameManager.PlayerManager
]]

local Players = game:GetService("Players")
local Config  = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Config"))

local PlayerManager = {}

-- Se inyectan después del Build en init
PlayerManager.LobbySpawn = nil
PlayerManager.GameSpawn  = nil

---------------------------------------------------------------------
-- Atributos
---------------------------------------------------------------------
function PlayerManager.ResetAttributes(player: Player)
	player:SetAttribute("Role", "None")
	player:SetAttribute("Health", 0)
	player:SetAttribute("Escaped", false)
	player:SetAttribute("Shape", "None")
end

function PlayerManager.InitForMatch(player: Player, role: string)
	player:SetAttribute("Role", role)
	player:SetAttribute("Escaped", false)
	if role == "Forma" then
		player:SetAttribute("Health", Config.SHAPE_HEALTH)
	else
		player:SetAttribute("Health", 999)
	end
end

---------------------------------------------------------------------
-- Teletransporte
---------------------------------------------------------------------
function PlayerManager.TeleportToLobby(player: Player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if not PlayerManager.LobbySpawn then return end
	root.CFrame = PlayerManager.LobbySpawn.CFrame + Vector3.new(
		math.random(-5, 5), 5, math.random(-5, 5)
	)
end

function PlayerManager.TeleportToGame(player: Player)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if not PlayerManager.GameSpawn then return end
	root.CFrame = PlayerManager.GameSpawn.CFrame + Vector3.new(
		math.random(-10, 10), 5, math.random(-10, 10)
	)
end

---------------------------------------------------------------------
-- Apariencia: Forma
---------------------------------------------------------------------
function PlayerManager.ApplyShapeAppearance(player: Player, shapeName: string)
	local char = player.Character
	if not char then return end

	local color = Config.SHAPE_COLORS[shapeName] or Color3.fromRGB(128, 128, 128)

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Color = color
		end
	end

	-- Indicador sobre la cabeza
	local head = char:FindFirstChild("Head")
	if head then
		local old = head:FindFirstChild("ShapeIndicator")
		if old then old:Destroy() end

		local bb = Instance.new("BillboardGui")
		bb.Name            = "ShapeIndicator"
		bb.Size            = UDim2.new(0, 100, 0, 40)
		bb.StudsOffset     = Vector3.new(0, 3, 0)
		bb.Adornee         = head
		bb.AlwaysOnTop     = true
		bb.Parent          = head

		local lbl = Instance.new("TextLabel")
		lbl.Size                = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text                = shapeName
		lbl.TextColor3          = Color3.new(1, 1, 1)
		lbl.TextStrokeTransparency = 0
		lbl.TextScaled          = true
		lbl.Font                = Enum.Font.GothamBold
		lbl.Parent              = bb
	end
end

---------------------------------------------------------------------
-- Apariencia: Polígono
---------------------------------------------------------------------
function PlayerManager.ApplyPoligonoAppearance(player: Player)
	local char = player.Character
	if not char then return end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.BrickColor = BrickColor.new("Really black")
			part.Material   = Enum.Material.Neon
		end
	end

	-- Hacer al polígono ligeramente más grande (intimidante)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.BodyHeightScale.Value  = 1.15
		humanoid.BodyWidthScale.Value   = 1.15
		humanoid.HeadScale.Value        = 1.2
	end

	local head = char:FindFirstChild("Head")
	if head then
		local old = head:FindFirstChild("ShapeIndicator")
		if old then old:Destroy() end

		local bb = Instance.new("BillboardGui")
		bb.Name            = "ShapeIndicator"
		bb.Size            = UDim2.new(0, 140, 0, 40)
		bb.StudsOffset     = Vector3.new(0, 3.5, 0)
		bb.Adornee         = head
		bb.AlwaysOnTop     = true
		bb.Parent          = head

		local lbl = Instance.new("TextLabel")
		lbl.Size                = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text                = "POLIGONO"
		lbl.TextColor3          = Color3.fromRGB(255, 0, 0)
		lbl.TextStrokeTransparency = 0
		lbl.TextStrokeColor3    = Color3.fromRGB(100, 0, 0)
		lbl.TextScaled          = true
		lbl.Font                = Enum.Font.GothamBold
		lbl.Parent              = bb
	end

	-- Ojos rojos (PointLight en la cabeza)
	if head and not head:FindFirstChild("EyeGlow") then
		local light = Instance.new("PointLight")
		light.Name       = "EyeGlow"
		light.Color      = Color3.fromRGB(255, 0, 0)
		light.Brightness = 3
		light.Range      = 15
		light.Parent     = head
	end
end

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
function PlayerManager.GetActivePlayers(): { Player }
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Parent then
			table.insert(list, p)
		end
	end
	return list
end

function PlayerManager.RespawnAndTeleportLobby(player: Player)
	player:LoadCharacter()
	task.wait(0.3)
	PlayerManager.TeleportToLobby(player)
end

return PlayerManager
