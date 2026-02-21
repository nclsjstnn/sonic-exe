--[[
	GolpeAbility.client.lua (LocalScript)
	=====================================
	Maneja la entrada del jugador para la habilidad "Golpe"
	del Polígono. Envía el ataque al servidor para validación.

	• Click izquierdo / toque → atacar forma más cercana
	• Cooldown visual de 2.1 s
	• Solo activo cuando el jugador tiene rol "Poligono"

	Ubicación: StarterPlayer.StarterPlayerScripts.GolpeAbility
]]

---------------------------------------------------------------------
-- Servicios
---------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse  = player:GetMouse()

---------------------------------------------------------------------
-- Módulos
---------------------------------------------------------------------
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config  = require(Modules:WaitForChild("Config"))
local Remotes = require(Modules:WaitForChild("RemoteManager"))

local DamagePlayer = Remotes.Get("DamagePlayer")

---------------------------------------------------------------------
-- Estado local
---------------------------------------------------------------------
local lastAttack = 0
local onCooldown = false

---------------------------------------------------------------------
-- Encontrar forma más cercana en rango
---------------------------------------------------------------------
local function findTarget(): Player?
	local char = player.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local best: Player? = nil
	local bestDist = Config.GOLPE_RANGE

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other:GetAttribute("Role") == "Forma" then
			local oChar = other.Character
			if oChar then
				local oRoot = oChar:FindFirstChild("HumanoidRootPart")
				if oRoot then
					local d = (root.Position - oRoot.Position).Magnitude
					if d < bestDist then
						bestDist = d
						best = other
					end
				end
			end
		end
	end

	return best
end

---------------------------------------------------------------------
-- Efecto visual de ataque (partículas rojas)
---------------------------------------------------------------------
local function attackVFX()
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local att = Instance.new("Attachment")
	att.Parent = root

	local emitter = Instance.new("ParticleEmitter")
	emitter.Color    = ColorSequence.new(Color3.fromRGB(255, 0, 0))
	emitter.Size     = NumberSequence.new(1, 0)
	emitter.Lifetime = NumberRange.new(0.2, 0.4)
	emitter.Speed    = NumberRange.new(12, 22)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate     = 0
	emitter.Parent   = att

	emitter:Emit(20)
	task.delay(0.8, function() att:Destroy() end)
end

---------------------------------------------------------------------
-- Animación de cooldown en la UI
---------------------------------------------------------------------
local function animateCooldown()
	local gui = player:FindFirstChild("PlayerGui")
	if not gui then return end
	local gameUI = gui:FindFirstChild("GameUI")
	if not gameUI then return end
	local cd = gameUI:FindFirstChild("CooldownIndicator")
	if not cd then return end
	local txt = cd:FindFirstChild("CooldownText")
	if not txt then return end

	onCooldown = true
	cd.BackgroundColor3 = Color3.fromRGB(100, 0, 0)

	task.spawn(function()
		local remaining = Config.GOLPE_COOLDOWN
		while remaining > 0 do
			if txt and txt.Parent then
				txt.Text = string.format("%.1f", remaining)
			end
			task.wait(0.1)
			remaining -= 0.1
		end
		if txt and txt.Parent then
			txt.Text = "Golpe"
		end
		if cd and cd.Parent then
			cd.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
		end
		onCooldown = false
	end)
end

---------------------------------------------------------------------
-- Ejecutar golpe
---------------------------------------------------------------------
local function performGolpe()
	if player:GetAttribute("Role") ~= "Poligono" then return end

	local now = tick()
	if (now - lastAttack) < Config.GOLPE_COOLDOWN then return end
	lastAttack = now

	local target = findTarget()
	if not target then return end

	DamagePlayer:FireServer(target)
	attackVFX()
	animateCooldown()
end

---------------------------------------------------------------------
-- Input
---------------------------------------------------------------------
mouse.Button1Down:Connect(performGolpe)

UserInputService.TouchTap:Connect(function()
	if player:GetAttribute("Role") == "Poligono" then
		performGolpe()
	end
end)

print("[GolpeAbility] Habilidad de golpe cargada.")
