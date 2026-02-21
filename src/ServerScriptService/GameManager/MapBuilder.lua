--[[
	MapBuilder.lua (ModuleScript)
	=============================
	Construye el mapa del juego: suelo del lobby, suelo de la arena,
	spawns y paredes perimetrales. Todo se crea en Workspace.
	Ubicación: ServerScriptService.GameManager.MapBuilder
]]

local Workspace = game:GetService("Workspace")
local Config    = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Config"))

local MapBuilder = {}

---------------------------------------------------------------------
-- Referencias a las carpetas
---------------------------------------------------------------------
local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

MapBuilder.MapFolder   = nil
MapBuilder.DoorsFolder = nil
MapBuilder.LobbySpawn  = nil
MapBuilder.GameSpawn   = nil

---------------------------------------------------------------------
-- Crear un SpawnLocation
---------------------------------------------------------------------
local function makeSpawn(name: string, position: Vector3, parent: Instance): SpawnLocation
	local existing = parent:FindFirstChild(name)
	if existing then return existing end

	local sp = Instance.new("SpawnLocation")
	sp.Name      = name
	sp.Size      = Vector3.new(12, 1, 12)
	sp.Position  = position
	sp.Anchored  = true
	sp.CanCollide = true
	sp.Neutral   = true
	sp.TeamColor = BrickColor.new("Medium stone grey")
	sp.Material  = Enum.Material.SmoothPlastic
	sp.Parent    = parent
	-- Ocultar el decal del spawn
	sp.Duration  = 0
	return sp
end

---------------------------------------------------------------------
-- Construir suelo
---------------------------------------------------------------------
local function makeFloor(name, size, pos, color, material, parent)
	local existing = parent:FindFirstChild(name)
	if existing then return existing end

	local part = Instance.new("Part")
	part.Name      = name
	part.Size      = size
	part.Position  = pos
	part.Anchored  = true
	part.BrickColor = BrickColor.new(color)
	part.Material  = material
	part.Parent    = parent
	return part
end

---------------------------------------------------------------------
-- Paredes de la arena
---------------------------------------------------------------------
local function makeWalls(parent)
	if parent:FindFirstChild("WallN") then return end

	local cx, cy, cz = 0, 0, 200  -- centro arena
	local halfW, halfD = 100, 100
	local wallH = 20

	local specs = {
		{ name = "WallN", size = Vector3.new(halfW*2, wallH, 2), pos = Vector3.new(cx, wallH/2+cy, cz + halfD) },
		{ name = "WallS", size = Vector3.new(halfW*2, wallH, 2), pos = Vector3.new(cx, wallH/2+cy, cz - halfD) },
		{ name = "WallE", size = Vector3.new(2, wallH, halfD*2), pos = Vector3.new(cx + halfW, wallH/2+cy, cz) },
		{ name = "WallW", size = Vector3.new(2, wallH, halfD*2), pos = Vector3.new(cx - halfW, wallH/2+cy, cz) },
	}

	for _, s in ipairs(specs) do
		local wall = Instance.new("Part")
		wall.Name        = s.name
		wall.Size        = s.size
		wall.Position    = s.pos
		wall.Anchored    = true
		wall.BrickColor  = BrickColor.new("Really black")
		wall.Material    = Enum.Material.SmoothPlastic
		wall.Transparency = 0.6
		wall.Parent      = parent
	end
end

---------------------------------------------------------------------
-- Obstáculos dentro de la arena para que las Formas se escondan
---------------------------------------------------------------------
local function makeObstacles(parent)
	if parent:FindFirstChild("Obstacle1") then return end

	local obstacles = {
		{ pos = Vector3.new(30, 5, 220),  size = Vector3.new(10, 10, 10) },
		{ pos = Vector3.new(-40, 5, 180), size = Vector3.new(12, 10, 6)  },
		{ pos = Vector3.new(60, 5, 250),  size = Vector3.new(8, 10, 14)  },
		{ pos = Vector3.new(-20, 5, 240), size = Vector3.new(15, 10, 8)  },
		{ pos = Vector3.new(10, 5, 160),  size = Vector3.new(6, 10, 20)  },
		{ pos = Vector3.new(-60, 5, 210), size = Vector3.new(10, 10, 10) },
		{ pos = Vector3.new(50, 5, 170),  size = Vector3.new(14, 10, 6)  },
		{ pos = Vector3.new(-70, 5, 250), size = Vector3.new(8, 10, 12)  },
	}

	for i, data in ipairs(obstacles) do
		local part = Instance.new("Part")
		part.Name      = "Obstacle" .. i
		part.Size      = data.size
		part.Position  = data.pos
		part.Anchored  = true
		part.BrickColor = BrickColor.new("Dark stone grey")
		part.Material  = Enum.Material.Concrete
		part.Parent    = parent
	end
end

---------------------------------------------------------------------
-- Iluminación tenebrosa
---------------------------------------------------------------------
local function setupLighting()
	local Lighting = game:GetService("Lighting")
	Lighting.Ambient        = Color3.fromRGB(30, 20, 30)
	Lighting.OutdoorAmbient = Color3.fromRGB(40, 30, 40)
	Lighting.Brightness     = 0.5
	Lighting.ClockTime      = 0    -- medianoche
	Lighting.FogEnd         = 350
	Lighting.FogStart       = 50
	Lighting.FogColor       = Color3.fromRGB(10, 5, 15)

	-- Atmósfera si no existe
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atm = Instance.new("Atmosphere")
		atm.Density = 0.4
		atm.Offset  = 0.25
		atm.Color   = Color3.fromRGB(20, 10, 25)
		atm.Decay   = Color3.fromRGB(15, 10, 20)
		atm.Glare   = 0
		atm.Haze    = 2
		atm.Parent  = Lighting
	end
end

---------------------------------------------------------------------
-- Build: llamar para construir todo
---------------------------------------------------------------------
function MapBuilder.Build()
	MapBuilder.MapFolder   = ensureFolder(Workspace, "Map")
	MapBuilder.DoorsFolder = ensureFolder(Workspace, "Doors")

	-- Suelo del lobby
	makeFloor(
		"LobbyFloor",
		Vector3.new(60, 1, 60),
		Vector3.new(0, 0, 0),
		"Medium stone grey",
		Enum.Material.SmoothPlastic,
		MapBuilder.MapFolder
	)

	-- Suelo de la arena
	makeFloor(
		"ArenaFloor",
		Config.FLOOR_SIZE,
		Vector3.new(0, 0, 200),
		"Black",
		Enum.Material.Concrete,
		MapBuilder.MapFolder
	)

	-- Spawns
	MapBuilder.LobbySpawn = makeSpawn("LobbySpawn", Config.LOBBY_POS, Workspace)
	MapBuilder.GameSpawn  = makeSpawn("GameSpawn",  Config.GAME_POS,  Workspace)

	-- Paredes de la arena
	makeWalls(MapBuilder.MapFolder)

	-- Obstáculos
	makeObstacles(MapBuilder.MapFolder)

	-- Iluminación
	setupLighting()

	print("[MapBuilder] Mapa construido.")
end

return MapBuilder
