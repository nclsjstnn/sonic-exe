--[[
	GolpeAbility.client.lua
	=======================
	LocalScript que maneja la entrada del jugador para la habilidad "Golpe"
	del Polígono. Envía el evento al servidor para validación.

	- Click izquierdo o toque para atacar
	- Cooldown visual de 2.1 segundos
	- Solo funciona si el jugador tiene rol "Poligono"
	- El daño real se valida en el servidor
]]

---------------------------------------------------------------------
-- Servicios
---------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

---------------------------------------------------------------------
-- RemoteEvents
---------------------------------------------------------------------
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local DamagePlayer = remoteFolder:WaitForChild("DamagePlayer")

---------------------------------------------------------------------
-- Configuración
---------------------------------------------------------------------
local GOLPE_COOLDOWN = 2.1
local GOLPE_RANGE = 12  -- studs de alcance máximo
local lastAttackTime = 0

---------------------------------------------------------------------
-- Función: encontrar el jugador más cercano en rango
---------------------------------------------------------------------
local function findNearestTarget(): Player?
	local character = player.Character
	if not character then return nil end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local nearestPlayer = nil
	local nearestDistance = GOLPE_RANGE

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local otherChar = otherPlayer.Character
			if otherChar then
				local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
				if otherRoot then
					local distance = (root.Position - otherRoot.Position).Magnitude
					if distance < nearestDistance then
						nearestDistance = distance
						nearestPlayer = otherPlayer
					end
				end
			end
		end
	end

	return nearestPlayer
end

---------------------------------------------------------------------
-- Función: ejecutar golpe
---------------------------------------------------------------------
local function performGolpe()
	-- Verificar que somos Polígono
	local role = player:GetAttribute("Role")
	if role ~= "Poligono" then return end

	-- Verificar cooldown local (el servidor también verifica)
	local now = tick()
	if (now - lastAttackTime) < GOLPE_COOLDOWN then return end
	lastAttackTime = now

	-- Buscar target
	local target = findNearestTarget()
	if not target then return end

	-- Verificar que el target es una Forma viva
	local targetRole = target:GetAttribute("Role")
	if targetRole ~= "Forma" then return end

	-- Enviar al servidor para validación
	DamagePlayer:FireServer(target)

	-- Efecto visual local del golpe
	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			-- Efecto de partículas rojo breve
			local attachment = Instance.new("Attachment")
			attachment.Parent = root

			local particles = Instance.new("ParticleEmitter")
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
			particles.Size = NumberSequence.new(1, 0)
			particles.Lifetime = NumberRange.new(0.3, 0.5)
			particles.Speed = NumberRange.new(10, 20)
			particles.SpreadAngle = Vector2.new(180, 180)
			particles.Rate = 0
			particles.Parent = attachment

			particles:Emit(15)

			-- Limpiar después de 1 segundo
			task.delay(1, function()
				attachment:Destroy()
			end)
		end
	end

	-- Actualizar UI de cooldown
	local playerGui = player:WaitForChild("PlayerGui")
	local gameUI = playerGui:FindFirstChild("GameUI")
	if gameUI then
		local cdIndicator = gameUI:FindFirstChild("CooldownIndicator")
		if cdIndicator then
			local cdText = cdIndicator:FindFirstChild("CooldownText")
			if cdText then
				-- Mostrar cooldown activo
				cdIndicator.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
				cdText.Text = "..."

				-- Animación de cooldown
				task.spawn(function()
					local remaining = GOLPE_COOLDOWN
					while remaining > 0 do
						if cdText and cdText.Parent then
							cdText.Text = string.format("%.1f", remaining)
						end
						task.wait(0.1)
						remaining -= 0.1
					end
					if cdText and cdText.Parent then
						cdText.Text = "Golpe"
						cdIndicator.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
					end
				end)
			end
		end
	end
end

---------------------------------------------------------------------
-- Input: click izquierdo del mouse
---------------------------------------------------------------------
mouse.Button1Down:Connect(function()
	performGolpe()
end)

-- También soportar input táctil
UserInputService.TouchTap:Connect(function()
	local role = player:GetAttribute("Role")
	if role == "Poligono" then
		performGolpe()
	end
end)

print("[GolpeAbility] Sistema de golpe del Polígono cargado.")
