--[[
	RemoteManager.lua (ModuleScript)
	================================
	Crea y devuelve todos los RemoteEvents del juego.
	Puede usarse tanto en servidor como en cliente.
	Ubicación: ReplicatedStorage.Modules.RemoteManager
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local Config = require(script.Parent:WaitForChild("Config"))

local RemoteManager = {}

---------------------------------------------------------------------
-- Carpeta contenedora
---------------------------------------------------------------------
local function getFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "RemoteEvents"
			folder.Parent = ReplicatedStorage
		end
		return folder
	else
		return ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	end
end

---------------------------------------------------------------------
-- Inicializar (llamar desde servidor para crear los remotes)
---------------------------------------------------------------------
function RemoteManager.Init()
	local folder = getFolder()
	for _, name in ipairs(Config.REMOTE_NAMES) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
end

---------------------------------------------------------------------
-- Obtener un RemoteEvent por nombre
---------------------------------------------------------------------
function RemoteManager.Get(name: string): RemoteEvent
	local folder = getFolder()
	if RunService:IsServer() then
		return folder:FindFirstChild(name)
	else
		return folder:WaitForChild(name, 10)
	end
end

return RemoteManager
