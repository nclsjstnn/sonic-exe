--[[
	GameUI - init.client.lua (LocalScript)
	======================================
	Interfaz principal del jugador. Crea y controla:
	  • TimerLabel – temporizador de fase
	  • HealthBar – barra de vida (Formas)
	  • BlackScreen – cortinilla negra
	  • DefeatScreen – "Mejor suerte la próxima"
	  • VictoryScreen – mensaje de victoria
	  • EscapeScreen – "¡Escapaste!"
	  • RoleLabel – indicador de rol actual
	  • CooldownIndicator – cooldown del Golpe (Polígono)

	Ubicación: StarterGui.GameUI
]]

---------------------------------------------------------------------
-- Servicios
---------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- Módulos compartidos
---------------------------------------------------------------------
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config  = require(Modules:WaitForChild("Config"))
local Remotes = require(Modules:WaitForChild("RemoteManager"))

---------------------------------------------------------------------
-- RemoteEvents
---------------------------------------------------------------------
local UpdateTimer       = Remotes.Get("UpdateTimer")
local RoleAssigned      = Remotes.Get("RoleAssigned")
local ShowBlackScreen   = Remotes.Get("ShowBlackScreen")
local ShowDefeatScreen  = Remotes.Get("ShowDefeatScreen")
local ShowVictoryScreen = Remotes.Get("ShowVictoryScreen")
local ShowEscapeScreen  = Remotes.Get("ShowEscapeScreen")
local ShapeSelected     = Remotes.Get("ShapeSelected")
local OpenDoors         = Remotes.Get("OpenDoors")
local TeleportToGame    = Remotes.Get("TeleportToGame")
local StartMatch        = Remotes.Get("StartMatch")

---------------------------------------------------------------------
-- ScreenGui raíz
---------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name              = "GameUI"
screenGui.ResetOnSpawn      = false
screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset    = true
screenGui.Parent            = playerGui

---------------------------------------------------------------------
-- Helpers de creación
---------------------------------------------------------------------
local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function label(props)
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency  = props.bgTransparency or 1
	lbl.BackgroundColor3        = props.bgColor or Color3.new(0,0,0)
	lbl.Size                    = props.size or UDim2.new(1,0,1,0)
	lbl.Position                = props.position or UDim2.new(0,0,0,0)
	lbl.Text                    = props.text or ""
	lbl.TextColor3              = props.textColor or Color3.new(1,1,1)
	lbl.TextStrokeTransparency  = props.strokeTransparency or 0
	lbl.TextScaled              = true
	lbl.Font                    = props.font or Enum.Font.GothamBold
	lbl.ZIndex                  = props.zindex or 1
	lbl.Name                    = props.name or "Label"
	lbl.Parent                  = props.parent
	return lbl
end

---------------------------------------------------------------------
-- 1) TIMER LABEL
---------------------------------------------------------------------
local timerLabel = label({
	name        = "TimerLabel",
	size        = UDim2.new(0, 420, 0, 50),
	position    = UDim2.new(0.5, -210, 0, 40),
	bgTransparency = 0.4,
	bgColor     = Color3.fromRGB(10, 10, 10),
	text        = "",
	parent      = screenGui,
})
corner(timerLabel, 10)

---------------------------------------------------------------------
-- 2) HEALTH BAR
---------------------------------------------------------------------
local healthFrame = Instance.new("Frame")
healthFrame.Name              = "HealthBarFrame"
healthFrame.Size              = UDim2.new(0, 320, 0, 28)
healthFrame.Position          = UDim2.new(0.5, -160, 1, -80)
healthFrame.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
healthFrame.BorderSizePixel   = 0
healthFrame.Visible           = false
healthFrame.Parent            = screenGui
corner(healthFrame, 6)

local healthFill = Instance.new("Frame")
healthFill.Name              = "Fill"
healthFill.Size              = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3  = Color3.fromRGB(0, 210, 0)
healthFill.BorderSizePixel   = 0
healthFill.Parent            = healthFrame
corner(healthFill, 6)

local healthText = label({
	name     = "HealthText",
	text     = "100 / 100",
	zindex   = 3,
	parent   = healthFrame,
})

---------------------------------------------------------------------
-- 3) BLACK SCREEN
---------------------------------------------------------------------
local blackScreen = Instance.new("Frame")
blackScreen.Name                 = "BlackScreenFrame"
blackScreen.Size                 = UDim2.new(1, 0, 1, 0)
blackScreen.BackgroundColor3     = Color3.new(0, 0, 0)
blackScreen.BackgroundTransparency = 1
blackScreen.ZIndex               = 50
blackScreen.Visible              = false
blackScreen.Parent               = screenGui

---------------------------------------------------------------------
-- 4) DEFEAT SCREEN
---------------------------------------------------------------------
local defeatScreen = Instance.new("Frame")
defeatScreen.Name                = "DefeatScreen"
defeatScreen.Size                = UDim2.new(1, 0, 1, 0)
defeatScreen.BackgroundColor3    = Color3.fromRGB(60, 0, 0)
defeatScreen.BackgroundTransparency = 0.25
defeatScreen.ZIndex              = 40
defeatScreen.Visible             = false
defeatScreen.Parent              = screenGui

label({
	name       = "DefeatText",
	size       = UDim2.new(0.8, 0, 0.15, 0),
	position   = UDim2.new(0.1, 0, 0.4, 0),
	text       = "Mejor suerte la proxima",
	textColor  = Color3.fromRGB(255, 70, 70),
	zindex     = 41,
	parent     = defeatScreen,
})

---------------------------------------------------------------------
-- 5) VICTORY SCREEN
---------------------------------------------------------------------
local victoryScreen = Instance.new("Frame")
victoryScreen.Name                = "VictoryScreen"
victoryScreen.Size                = UDim2.new(1, 0, 1, 0)
victoryScreen.BackgroundColor3    = Color3.fromRGB(0, 60, 0)
victoryScreen.BackgroundTransparency = 0.25
victoryScreen.ZIndex              = 40
victoryScreen.Visible             = false
victoryScreen.Parent              = screenGui

local victoryLabel = label({
	name       = "VictoryText",
	size       = UDim2.new(0.8, 0, 0.15, 0),
	position   = UDim2.new(0.1, 0, 0.4, 0),
	text       = "Victoria!",
	textColor  = Color3.fromRGB(70, 255, 70),
	zindex     = 41,
	parent     = victoryScreen,
})

---------------------------------------------------------------------
-- 6) ESCAPE SCREEN
---------------------------------------------------------------------
local escapeScreen = Instance.new("Frame")
escapeScreen.Name                = "EscapeScreen"
escapeScreen.Size                = UDim2.new(1, 0, 1, 0)
escapeScreen.BackgroundColor3    = Color3.fromRGB(0, 40, 80)
escapeScreen.BackgroundTransparency = 0.25
escapeScreen.ZIndex              = 40
escapeScreen.Visible             = false
escapeScreen.Parent              = screenGui

label({
	name       = "EscapeText",
	size       = UDim2.new(0.8, 0, 0.15, 0),
	position   = UDim2.new(0.1, 0, 0.4, 0),
	text       = "Escapaste!",
	textColor  = Color3.fromRGB(100, 200, 255),
	zindex     = 41,
	parent     = escapeScreen,
})

---------------------------------------------------------------------
-- 7) SELECTION UI (elegir forma)
---------------------------------------------------------------------
local selectionFrame = Instance.new("Frame")
selectionFrame.Name                = "SelectionUI"
selectionFrame.Size                = UDim2.new(0, 520, 0, 360)
selectionFrame.Position            = UDim2.new(0.5, -260, 0.5, -180)
selectionFrame.BackgroundColor3    = Color3.fromRGB(15, 15, 25)
selectionFrame.BackgroundTransparency = 0.05
selectionFrame.ZIndex              = 30
selectionFrame.Visible             = false
selectionFrame.Parent              = screenGui
corner(selectionFrame, 14)

local selTitle = label({
	name     = "Title",
	size     = UDim2.new(1, 0, 0, 50),
	text     = "ELIGE TU FORMA",
	zindex   = 31,
	parent   = selectionFrame,
})

local btnContainer = Instance.new("Frame")
btnContainer.Name                = "Buttons"
btnContainer.Size                = UDim2.new(1, -20, 1, -65)
btnContainer.Position            = UDim2.new(0, 10, 0, 58)
btnContainer.BackgroundTransparency = 1
btnContainer.ZIndex              = 31
btnContainer.Parent              = selectionFrame

local grid = Instance.new("UIGridLayout")
grid.CellSize             = UDim2.new(0, 145, 0, 105)
grid.CellPadding          = UDim2.new(0, 12, 0, 12)
grid.HorizontalAlignment  = Enum.HorizontalAlignment.Center
grid.SortOrder            = Enum.SortOrder.LayoutOrder
grid.Parent               = btnContainer

local selectedShape = nil

for i, shapeName in ipairs(Config.SHAPE_NAMES) do
	local btn = Instance.new("TextButton")
	btn.Name              = shapeName
	btn.BackgroundColor3  = Config.SHAPE_COLORS[shapeName] or Color3.fromRGB(100,100,100)
	btn.Text              = shapeName
	btn.TextColor3        = Color3.new(1, 1, 1)
	btn.TextStrokeTransparency = 0
	btn.TextScaled        = true
	btn.Font              = Enum.Font.GothamBold
	btn.LayoutOrder       = i
	btn.ZIndex            = 32
	btn.Parent            = btnContainer
	corner(btn, 10)

	btn.MouseButton1Click:Connect(function()
		selectedShape = shapeName
		ShapeSelected:FireServer(shapeName)

		-- Feedback visual
		for _, child in ipairs(btnContainer:GetChildren()) do
			if child:IsA("TextButton") then
				child.BorderSizePixel = 0
			end
		end
		btn.BorderSizePixel  = 3
		btn.BorderColor3     = Color3.new(1, 1, 1)
		selTitle.Text        = "ELEGIDO: " .. shapeName
	end)
end

---------------------------------------------------------------------
-- 8) POLIGONO SCREEN (al ser elegido Polígono)
---------------------------------------------------------------------
local poligonoFrame = Instance.new("Frame")
poligonoFrame.Name                = "PoligonoScreen"
poligonoFrame.Size                = UDim2.new(0, 520, 0, 220)
poligonoFrame.Position            = UDim2.new(0.5, -260, 0.5, -110)
poligonoFrame.BackgroundColor3    = Color3.fromRGB(25, 0, 0)
poligonoFrame.BackgroundTransparency = 0.05
poligonoFrame.ZIndex              = 30
poligonoFrame.Visible             = false
poligonoFrame.Parent              = screenGui
corner(poligonoFrame, 14)

label({
	name       = "Title",
	size       = UDim2.new(1, 0, 0.45, 0),
	text       = "ERES EL POLIGONO",
	textColor  = Color3.fromRGB(255, 0, 0),
	zindex     = 31,
	parent     = poligonoFrame,
})

label({
	name       = "Desc",
	size       = UDim2.new(1, -30, 0.45, 0),
	position   = UDim2.new(0, 15, 0.5, 0),
	text       = "Elimina a todas las Formas antes de que escapen.\nHabilidad: Golpe (Click izquierdo)",
	textColor  = Color3.fromRGB(200, 200, 200),
	font       = Enum.Font.Gotham,
	zindex     = 31,
	parent     = poligonoFrame,
})

---------------------------------------------------------------------
-- 9) COOLDOWN INDICATOR (Polígono)
---------------------------------------------------------------------
local cooldownFrame = Instance.new("Frame")
cooldownFrame.Name              = "CooldownIndicator"
cooldownFrame.Size              = UDim2.new(0, 64, 0, 64)
cooldownFrame.Position          = UDim2.new(0.5, -32, 1, -155)
cooldownFrame.BackgroundColor3  = Color3.fromRGB(50, 0, 0)
cooldownFrame.BorderSizePixel   = 0
cooldownFrame.ZIndex            = 20
cooldownFrame.Visible           = false
cooldownFrame.Parent            = screenGui
corner(cooldownFrame, 32)

local cooldownText = label({
	name     = "CooldownText",
	text     = "Golpe",
	zindex   = 21,
	parent   = cooldownFrame,
})

---------------------------------------------------------------------
-- 10) ROLE LABEL
---------------------------------------------------------------------
local roleLabel = label({
	name           = "RoleLabel",
	size           = UDim2.new(0, 260, 0, 36),
	position       = UDim2.new(0.5, -130, 0, 95),
	bgTransparency = 0.4,
	bgColor        = Color3.fromRGB(10, 10, 10),
	text           = "",
	parent         = screenGui,
})
roleLabel.Visible = false
corner(roleLabel, 6)

---------------------------------------------------------------------
-- Funciones de UI
---------------------------------------------------------------------
local function hideAllScreens()
	defeatScreen.Visible    = false
	victoryScreen.Visible   = false
	escapeScreen.Visible    = false
	selectionFrame.Visible  = false
	poligonoFrame.Visible   = false
	healthFrame.Visible     = false
	cooldownFrame.Visible   = false
	roleLabel.Visible       = false
end

local function showTemp(screen, duration)
	screen.Visible = true
	task.delay(duration or 5, function()
		screen.Visible = false
	end)
end

---------------------------------------------------------------------
-- Eventos
---------------------------------------------------------------------

-- Timer
UpdateTimer.OnClientEvent:Connect(function(text: string)
	timerLabel.Text = text
	if string.find(text, "Descanso") or string.find(text, "Esperando") or string.find(text, "Reiniciando") then
		hideAllScreens()
	end
end)

-- Rol asignado
RoleAssigned.OnClientEvent:Connect(function(role: string)
	if role == "Poligono" then
		selectionFrame.Visible = false
		poligonoFrame.Visible  = true
		healthFrame.Visible    = false
		roleLabel.Text         = "ROL: POLIGONO"
		roleLabel.TextColor3   = Color3.fromRGB(255, 0, 0)
		roleLabel.Visible      = true
	elseif role == "Forma" then
		poligonoFrame.Visible  = false
		selectionFrame.Visible = true
		selTitle.Text          = "ELIGE TU FORMA"
		selectedShape          = nil
		roleLabel.Text         = "ROL: FORMA"
		roleLabel.TextColor3   = Color3.fromRGB(100, 200, 255)
		roleLabel.Visible      = true
		-- Resetear botones
		for _, child in ipairs(btnContainer:GetChildren()) do
			if child:IsA("TextButton") then child.BorderSizePixel = 0 end
		end
	end
end)

-- Pantalla negra
ShowBlackScreen.OnClientEvent:Connect(function(show: boolean)
	if show then
		blackScreen.BackgroundTransparency = 0
		blackScreen.Visible = true
	else
		local tween = TweenService:Create(
			blackScreen,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		)
		tween:Play()
		tween.Completed:Connect(function()
			blackScreen.Visible = false
		end)
	end
end)

-- Derrota
ShowDefeatScreen.OnClientEvent:Connect(function()
	hideAllScreens()
	showTemp(defeatScreen, 5)
end)

-- Victoria
ShowVictoryScreen.OnClientEvent:Connect(function(side: string)
	hideAllScreens()
	if side == "Poligono" then
		victoryLabel.Text = "VICTORIA! El Poligono ha ganado"
	else
		victoryLabel.Text = "VICTORIA! Las Formas han ganado"
	end
	showTemp(victoryScreen, 5)
end)

-- Escape
ShowEscapeScreen.OnClientEvent:Connect(function()
	hideAllScreens()
	showTemp(escapeScreen, 5)
end)

-- Inicio de partida
TeleportToGame.OnClientEvent:Connect(function()
	selectionFrame.Visible = false
	poligonoFrame.Visible  = false
	local role = player:GetAttribute("Role")
	if role == "Forma" then
		healthFrame.Visible   = true
	elseif role == "Poligono" then
		cooldownFrame.Visible = true
	end
end)

-- Puertas abiertas
OpenDoors.OnClientEvent:Connect(function()
	local notif = label({
		name       = "DoorNotif",
		size       = UDim2.new(0, 420, 0, 65),
		position   = UDim2.new(0.5, -210, 0.25, 0),
		bgTransparency = 0.15,
		bgColor    = Color3.fromRGB(0, 120, 0),
		text       = "LAS PUERTAS SE HAN ABIERTO!\nCORRE!",
		zindex     = 45,
		parent     = screenGui,
	})
	corner(notif, 12)

	task.delay(3.5, function()
		local tw = TweenService:Create(notif, TweenInfo.new(0.8), { BackgroundTransparency = 1, TextTransparency = 1 })
		tw:Play()
		tw.Completed:Connect(function() notif:Destroy() end)
	end)
end)

---------------------------------------------------------------------
-- Actualizar barra de vida
---------------------------------------------------------------------
local function updateHealthBar()
	local hp  = player:GetAttribute("Health") or 0
	local max = Config.SHAPE_HEALTH
	local f   = math.clamp(hp / max, 0, 1)

	TweenService:Create(healthFill, TweenInfo.new(0.25), {
		Size = UDim2.new(f, 0, 1, 0)
	}):Play()

	if f > 0.6 then
		healthFill.BackgroundColor3 = Color3.fromRGB(0, 210, 0)
	elseif f > 0.3 then
		healthFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	else
		healthFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	end

	healthText.Text = hp .. " / " .. max
end

player:GetAttributeChangedSignal("Health"):Connect(updateHealthBar)

player:GetAttributeChangedSignal("Role"):Connect(function()
	local role = player:GetAttribute("Role")
	if role == "Forma" then
		healthFrame.Visible = true
		updateHealthBar()
	elseif role == "Poligono" then
		healthFrame.Visible   = false
		cooldownFrame.Visible = true
	else
		healthFrame.Visible   = false
		cooldownFrame.Visible = false
		roleLabel.Visible     = false
	end
end)

print("[GameUI] Interfaz cargada.")
