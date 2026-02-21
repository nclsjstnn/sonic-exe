--[[
	DamageSystem.lua (ModuleScript)
	===============================
	Sistema de daño validado completamente en el servidor.
	Verifica: rol del atacante, cooldown, fase de juego, rango, etc.
	Ubicación: ServerScriptService.GameManager.DamageSystem
]]

local Players = game:GetService("Players")
local Config  = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Config"))
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("RemoteManager"))

local DamageSystem = {}

---------------------------------------------------------------------
-- Estado
---------------------------------------------------------------------
local lastGolpeTime: { [Player]: number } = {}

-- Callbacks inyectadas desde init
DamageSystem.GetPhase        = nil  -- function(): string
DamageSystem.GetPoligono     = nil  -- function(): Player?
DamageSystem.IsAlive         = nil  -- function(player): boolean
DamageSystem.IsEscaped       = nil  -- function(player): boolean
DamageSystem.OnPlayerKilled  = nil  -- function(player): ()

---------------------------------------------------------------------
-- Conectar RemoteEvent
---------------------------------------------------------------------
function DamageSystem.Init()
	local DamagePlayer = Remotes.Get("DamagePlayer")

	DamagePlayer.OnServerEvent:Connect(function(attacker: Player, targetPlayer: Player)
		-- Solo durante partida
		if DamageSystem.GetPhase() ~= "Partida" then return end

		-- Solo el Polígono puede atacar
		if attacker ~= DamageSystem.GetPoligono() then return end

		-- Validar que target es un Player real
		if not targetPlayer or not targetPlayer:IsA("Player") then return end

		-- No autodaño
		if targetPlayer == attacker then return end

		-- Target debe estar vivo y no haber escapado
		if not DamageSystem.IsAlive(targetPlayer) then return end
		if DamageSystem.IsEscaped(targetPlayer) then return end

		-- Validar rango (anti-cheat)
		local attackerChar = attacker.Character
		local targetChar   = targetPlayer.Character
		if not attackerChar or not targetChar then return end

		local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
		local targetRoot   = targetChar:FindFirstChild("HumanoidRootPart")
		if not attackerRoot or not targetRoot then return end

		local distance = (attackerRoot.Position - targetRoot.Position).Magnitude
		-- Margen generoso para compensar latencia de red
		if distance > Config.GOLPE_RANGE * 2 then return end

		-- Cooldown del golpe (servidor autoritativo)
		local now = tick()
		if lastGolpeTime[attacker] and (now - lastGolpeTime[attacker]) < Config.GOLPE_COOLDOWN then
			return
		end
		lastGolpeTime[attacker] = now

		-- Aplicar daño
		local currentHealth = targetPlayer:GetAttribute("Health") or 0
		currentHealth = math.max(0, currentHealth - Config.GOLPE_DAMAGE)
		targetPlayer:SetAttribute("Health", currentHealth)

		-- Efecto de daño en el target (sacudida de la cámara se haría en cliente)
		-- Aquí hacemos un efecto visual con color rojo momentáneo
		if targetChar then
			task.spawn(function()
				for _, part in ipairs(targetChar:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.Material = Enum.Material.Neon
					end
				end
				task.wait(0.15)
				for _, part in ipairs(targetChar:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.Material = Enum.Material.SmoothPlastic
					end
				end
			end)
		end

		-- Si la vida llega a 0 → muerte
		if currentHealth <= 0 then
			targetPlayer:SetAttribute("Role", "Dead")

			if DamageSystem.OnPlayerKilled then
				DamageSystem.OnPlayerKilled(targetPlayer)
			end
		end
	end)
end

---------------------------------------------------------------------
-- Limpiar cooldown de un jugador (al desconectarse)
---------------------------------------------------------------------
function DamageSystem.ClearCooldown(player: Player)
	lastGolpeTime[player] = nil
end

---------------------------------------------------------------------
-- Resetear todos los cooldowns (al reiniciar ronda)
---------------------------------------------------------------------
function DamageSystem.ResetAll()
	table.clear(lastGolpeTime)
end

return DamageSystem
