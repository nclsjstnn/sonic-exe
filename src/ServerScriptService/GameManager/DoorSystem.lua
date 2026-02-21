--[[
	DoorSystem.lua (ModuleScript)
	=============================
	Crea, abre y cierra puertas de escape en la arena.
	Las puertas son Parts Neon semitransparentes que detectan
	colisión con jugadores para permitir el escape.
	Ubicación: ServerScriptService.GameManager.DoorSystem
]]

local Players = game:GetService("Players")
local Config  = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Config"))

local DoorSystem = {}

---------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------
local activeDoors: { Part } = {}
local isOpen = false

-- Callbacks inyectadas desde init
DoorSystem.OnPlayerEscape = nil  -- function(player: Player)
DoorSystem.DoorsFolder    = nil  -- Folder en Workspace

---------------------------------------------------------------------
-- Utilidad: shuffle
---------------------------------------------------------------------
local function shuffle(t)
	local copy = table.clone(t)
	for i = #copy, 2, -1 do
		local j = math.random(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

---------------------------------------------------------------------
-- Crear una puerta individual
---------------------------------------------------------------------
local function createDoor(position: Vector3): Part
	local door = Instance.new("Part")
	door.Name         = "EscapeDoor"
	door.Size         = Vector3.new(8, 14, 2)
	door.Position     = position
	door.Anchored     = true
	door.CanCollide   = false
	door.BrickColor   = BrickColor.new("Lime green")
	door.Material     = Enum.Material.Neon
	door.Transparency = 0.25
	door.Parent       = DoorSystem.DoorsFolder

	-- Billboard "SALIDA"
	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 120, 0, 40)
	bb.StudsOffset = Vector3.new(0, 9, 0)
	bb.Adornee     = door
	bb.AlwaysOnTop = true
	bb.Parent      = door

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = "SALIDA"
	lbl.TextColor3             = Color3.fromRGB(0, 255, 0)
	lbl.TextStrokeTransparency = 0
	lbl.TextScaled             = true
	lbl.Font                   = Enum.Font.GothamBold
	lbl.Parent                 = bb

	-- Luz verde
	local light = Instance.new("PointLight")
	light.Color      = Color3.fromRGB(0, 255, 0)
	light.Brightness = 4
	light.Range      = 25
	light.Parent     = door

	-- Detección de toque
	door.Touched:Connect(function(hit)
		if not isOpen then return end

		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		if DoorSystem.OnPlayerEscape then
			DoorSystem.OnPlayerEscape(player)
		end
	end)

	return door
end

---------------------------------------------------------------------
-- Abrir puertas en posiciones aleatorias
---------------------------------------------------------------------
function DoorSystem.Open()
	if isOpen then return end
	isOpen = true

	local positions = shuffle(Config.DOOR_POSITIONS)
	local count = math.min(Config.DOORS_TO_OPEN, #positions)

	for i = 1, count do
		local door = createDoor(positions[i])
		table.insert(activeDoors, door)
	end
end

---------------------------------------------------------------------
-- Cerrar y destruir todas las puertas
---------------------------------------------------------------------
function DoorSystem.Close()
	isOpen = false
	for _, door in ipairs(activeDoors) do
		if door and door.Parent then
			door:Destroy()
		end
	end
	activeDoors = {}
end

---------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------
function DoorSystem.IsOpen(): boolean
	return isOpen
end

return DoorSystem
