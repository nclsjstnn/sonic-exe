--[[
	Config.lua (ModuleScript)
	=========================
	Constantes compartidas entre servidor y cliente.
	Ubicación: ReplicatedStorage.Modules.Config
]]

local Config = {}

---------------------------------------------------------------------
-- Tiempos de fase (segundos)
---------------------------------------------------------------------
Config.REST_TIME       = 40
Config.SELECT_TIME     = 30
Config.MATCH_TIME      = 300
Config.DOOR_OPEN_AT    = 60   -- puertas abren cuando quedan estos segundos
Config.POST_MATCH_WAIT = 5

---------------------------------------------------------------------
-- Formas disponibles
---------------------------------------------------------------------
Config.SHAPE_NAMES = { "Cono", "Esfera", "Cubo", "Tubo", "Rectangulo" }

Config.SHAPE_COLORS = {
	Cono       = Color3.fromRGB(255, 200, 0),
	Esfera     = Color3.fromRGB(50, 120, 255),
	Cubo       = Color3.fromRGB(255, 60, 60),
	Tubo       = Color3.fromRGB(60, 200, 60),
	Rectangulo = Color3.fromRGB(180, 60, 255),
}

---------------------------------------------------------------------
-- Combate
---------------------------------------------------------------------
Config.SHAPE_HEALTH    = 100
Config.GOLPE_DAMAGE    = 10
Config.GOLPE_COOLDOWN  = 2.1
Config.GOLPE_RANGE     = 12  -- studs

---------------------------------------------------------------------
-- Mapa
---------------------------------------------------------------------
Config.LOBBY_POS  = Vector3.new(0, 3, 0)
Config.GAME_POS   = Vector3.new(0, 3, 200)
Config.FLOOR_SIZE = Vector3.new(200, 1, 200)

Config.DOOR_POSITIONS = {
	Vector3.new(100,  5, 200),
	Vector3.new(-100, 5, 200),
	Vector3.new(0,    5, 300),
	Vector3.new(0,    5, 100),
}
Config.DOORS_TO_OPEN = 3

---------------------------------------------------------------------
-- RemoteEvents que necesita el juego
---------------------------------------------------------------------
Config.REMOTE_NAMES = {
	"RoleAssigned",
	"UpdateTimer",
	"DamagePlayer",
	"ShowBlackScreen",
	"OpenDoors",
	"PlayerEscaped",
	"ShowDefeatScreen",
	"ShowVictoryScreen",
	"ShowEscapeScreen",
	"ShapeSelected",
	"TeleportToGame",
	"StartMatch",
}

return Config
