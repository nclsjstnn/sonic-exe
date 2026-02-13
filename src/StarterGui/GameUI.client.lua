--[[
	GameUI.client.lua
	=================
	LocalScript que maneja toda la interfaz del jugador:
	  - TimerLabel: muestra el temporizador de fase
	  - HealthBar: barra de vida de las Formas
	  - BlackScreenFrame: pantalla negra durante selección
	  - DefeatScreen: "Mejor suerte la próxima"
	  - VictoryScreen: mensaje de victoria
	  - EscapeScreen: "¡Escapaste!"
	  - SelectionUI: botones para elegir forma
]]

---------------------------------------------------------------------
-- Servicios
---------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- RemoteEvents
---------------------------------------------------------------------
local remoteFolder     = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateTimer      = remoteFolder:WaitForChild("UpdateTimer")
local RoleAssigned     = remoteFolder:WaitForChild("RoleAssigned")
local ShowBlackScreen  = remoteFolder:WaitForChild("ShowBlackScreen")
local ShowDefeatScreen = remoteFolder:WaitForChild("ShowDefeatScreen")
local ShowVictoryScreen= remoteFolder:WaitForChild("ShowVictoryScreen")
local ShowEscapeScreen = remoteFolder:WaitForChild("ShowEscapeScreen")
local ShapeSelected    = remoteFolder:WaitForChild("ShapeSelected")
local OpenDoors        = remoteFolder:WaitForChild("OpenDoors")
local TeleportToGame   = remoteFolder:WaitForChild("TeleportToGame")

---------------------------------------------------------------------
-- Crear ScreenGui principal
---------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

---------------------------------------------------------------------
-- TimerLabel
---------------------------------------------------------------------
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(0, 400, 0, 50)
timerLabel.Position = UDim2.new(0.5, -200, 0, 10)
timerLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
timerLabel.BackgroundTransparency = 0.5
timerLabel.BorderSizePixel = 0
timerLabel.Text = ""
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Parent = screenGui

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 8)
timerCorner.Parent = timerLabel

---------------------------------------------------------------------
-- HealthBar
---------------------------------------------------------------------
local healthBarFrame = Instance.new("Frame")
healthBarFrame.Name = "HealthBarFrame"
healthBarFrame.Size = UDim2.new(0, 300, 0, 30)
healthBarFrame.Position = UDim2.new(0.5, -150, 1, -60)
healthBarFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
healthBarFrame.BorderSizePixel = 0
healthBarFrame.Visible = false
healthBarFrame.Parent = screenGui

local healthBarCorner = Instance.new("UICorner")
healthBarCorner.CornerRadius = UDim.new(0, 6)
healthBarCorner.Parent = healthBarFrame

local healthBarFill = Instance.new("Frame")
healthBarFill.Name = "Fill"
healthBarFill.Size = UDim2.new(1, 0, 1, 0)
healthBarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
healthBarFill.BorderSizePixel = 0
healthBarFill.Parent = healthBarFrame

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 6)
fillCorner.Parent = healthBarFill

local healthLabel = Instance.new("TextLabel")
healthLabel.Name = "HealthText"
healthLabel.Size = UDim2.new(1, 0, 1, 0)
healthLabel.BackgroundTransparency = 1
healthLabel.Text = "100 / 100"
healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
healthLabel.TextStrokeTransparency = 0
healthLabel.TextScaled = true
healthLabel.Font = Enum.Font.GothamBold
healthLabel.ZIndex = 2
healthLabel.Parent = healthBarFrame

---------------------------------------------------------------------
-- BlackScreenFrame
---------------------------------------------------------------------
local blackScreen = Instance.new("Frame")
blackScreen.Name = "BlackScreenFrame"
blackScreen.Size = UDim2.new(1, 0, 1, 0)
blackScreen.Position = UDim2.new(0, 0, 0, 0)
blackScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
blackScreen.BackgroundTransparency = 1
blackScreen.BorderSizePixel = 0
blackScreen.ZIndex = 10
blackScreen.Visible = false
blackScreen.Parent = screenGui

---------------------------------------------------------------------
-- DefeatScreen: "Mejor suerte la próxima"
---------------------------------------------------------------------
local defeatScreen = Instance.new("Frame")
defeatScreen.Name = "DefeatScreen"
defeatScreen.Size = UDim2.new(1, 0, 1, 0)
defeatScreen.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
defeatScreen.BackgroundTransparency = 0.3
defeatScreen.BorderSizePixel = 0
defeatScreen.ZIndex = 8
defeatScreen.Visible = false
defeatScreen.Parent = screenGui

local defeatLabel = Instance.new("TextLabel")
defeatLabel.Name = "DefeatText"
defeatLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
defeatLabel.Position = UDim2.new(0.1, 0, 0.35, 0)
defeatLabel.BackgroundTransparency = 1
defeatLabel.Text = "Mejor suerte la próxima"
defeatLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
defeatLabel.TextStrokeTransparency = 0
defeatLabel.TextScaled = true
defeatLabel.Font = Enum.Font.GothamBold
defeatLabel.ZIndex = 9
defeatLabel.Parent = defeatScreen

---------------------------------------------------------------------
-- VictoryScreen
---------------------------------------------------------------------
local victoryScreen = Instance.new("Frame")
victoryScreen.Name = "VictoryScreen"
victoryScreen.Size = UDim2.new(1, 0, 1, 0)
victoryScreen.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
victoryScreen.BackgroundTransparency = 0.3
victoryScreen.BorderSizePixel = 0
victoryScreen.ZIndex = 8
victoryScreen.Visible = false
victoryScreen.Parent = screenGui

local victoryLabel = Instance.new("TextLabel")
victoryLabel.Name = "VictoryText"
victoryLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
victoryLabel.Position = UDim2.new(0.1, 0, 0.35, 0)
victoryLabel.BackgroundTransparency = 1
victoryLabel.Text = "¡Victoria!"
victoryLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
victoryLabel.TextStrokeTransparency = 0
victoryLabel.TextScaled = true
victoryLabel.Font = Enum.Font.GothamBold
victoryLabel.ZIndex = 9
victoryLabel.Parent = victoryScreen

---------------------------------------------------------------------
-- EscapeScreen
---------------------------------------------------------------------
local escapeScreen = Instance.new("Frame")
escapeScreen.Name = "EscapeScreen"
escapeScreen.Size = UDim2.new(1, 0, 1, 0)
escapeScreen.BackgroundColor3 = Color3.fromRGB(0, 50, 80)
escapeScreen.BackgroundTransparency = 0.3
escapeScreen.BorderSizePixel = 0
escapeScreen.ZIndex = 8
escapeScreen.Visible = false
escapeScreen.Parent = screenGui

local escapeLabel = Instance.new("TextLabel")
escapeLabel.Name = "EscapeText"
escapeLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
escapeLabel.Position = UDim2.new(0.1, 0, 0.35, 0)
escapeLabel.BackgroundTransparency = 1
escapeLabel.Text = "¡Escapaste!"
escapeLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
escapeLabel.TextStrokeTransparency = 0
escapeLabel.TextScaled = true
escapeLabel.Font = Enum.Font.GothamBold
escapeLabel.ZIndex = 9
escapeLabel.Parent = escapeScreen

---------------------------------------------------------------------
-- SelectionUI: botones para elegir forma
---------------------------------------------------------------------
local selectionFrame = Instance.new("Frame")
selectionFrame.Name = "SelectionUI"
selectionFrame.Size = UDim2.new(0, 500, 0, 350)
selectionFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
selectionFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
selectionFrame.BackgroundTransparency = 0.1
selectionFrame.BorderSizePixel = 0
selectionFrame.ZIndex = 6
selectionFrame.Visible = false
selectionFrame.Parent = screenGui

local selCorner = Instance.new("UICorner")
selCorner.CornerRadius = UDim.new(0, 12)
selCorner.Parent = selectionFrame

local selTitle = Instance.new("TextLabel")
selTitle.Name = "Title"
selTitle.Size = UDim2.new(1, 0, 0, 50)
selTitle.BackgroundTransparency = 1
selTitle.Text = "ELIGE TU FORMA"
selTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
selTitle.TextScaled = true
selTitle.Font = Enum.Font.GothamBold
selTitle.ZIndex = 7
selTitle.Parent = selectionFrame

-- Contenedor de botones
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "Buttons"
buttonContainer.Size = UDim2.new(1, -20, 1, -60)
buttonContainer.Position = UDim2.new(0, 10, 0, 55)
buttonContainer.BackgroundTransparency = 1
buttonContainer.ZIndex = 7
buttonContainer.Parent = selectionFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 140, 0, 100)
gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = buttonContainer

local SHAPE_BUTTON_COLORS = {
	Cono       = Color3.fromRGB(255, 200, 0),
	Esfera     = Color3.fromRGB(50, 120, 255),
	Cubo       = Color3.fromRGB(255, 60, 60),
	Tubo       = Color3.fromRGB(60, 200, 60),
	Rectangulo = Color3.fromRGB(180, 60, 255),
}

local SHAPE_NAMES = { "Cono", "Esfera", "Cubo", "Tubo", "Rectangulo" }

local selectedShape = nil

for i, shapeName in ipairs(SHAPE_NAMES) do
	local btn = Instance.new("TextButton")
	btn.Name = shapeName
	btn.Size = UDim2.new(0, 140, 0, 100)
	btn.BackgroundColor3 = SHAPE_BUTTON_COLORS[shapeName] or Color3.fromRGB(100, 100, 100)
	btn.Text = shapeName
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextStrokeTransparency = 0
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.LayoutOrder = i
	btn.ZIndex = 8
	btn.Parent = buttonContainer

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		selectedShape = shapeName
		ShapeSelected:FireServer(shapeName)

		-- Feedback visual: resaltar botón seleccionado
		for _, child in ipairs(buttonContainer:GetChildren()) do
			if child:IsA("TextButton") then
				child.BorderSizePixel = 0
				child.BackgroundTransparency = 0
			end
		end
		btn.BorderSizePixel = 3
		btn.BorderColor3 = Color3.fromRGB(255, 255, 255)

		-- Cambiar título
		selTitle.Text = "ELEGIDO: " .. shapeName
	end)
end

---------------------------------------------------------------------
-- Pantalla del Polígono (cuando es seleccionado como Polígono)
---------------------------------------------------------------------
local poligonoFrame = Instance.new("Frame")
poligonoFrame.Name = "PoligonoScreen"
poligonoFrame.Size = UDim2.new(0, 500, 0, 200)
poligonoFrame.Position = UDim2.new(0.5, -250, 0.5, -100)
poligonoFrame.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
poligonoFrame.BackgroundTransparency = 0.1
poligonoFrame.BorderSizePixel = 0
poligonoFrame.ZIndex = 6
poligonoFrame.Visible = false
poligonoFrame.Parent = screenGui

local poliCorner = Instance.new("UICorner")
poliCorner.CornerRadius = UDim.new(0, 12)
poliCorner.Parent = poligonoFrame

local poliTitle = Instance.new("TextLabel")
poliTitle.Size = UDim2.new(1, 0, 0.5, 0)
poliTitle.BackgroundTransparency = 1
poliTitle.Text = "ERES EL POLÍGONO"
poliTitle.TextColor3 = Color3.fromRGB(255, 0, 0)
poliTitle.TextStrokeTransparency = 0
poliTitle.TextScaled = true
poliTitle.Font = Enum.Font.GothamBold
poliTitle.ZIndex = 7
poliTitle.Parent = poligonoFrame

local poliDesc = Instance.new("TextLabel")
poliDesc.Size = UDim2.new(1, -20, 0.4, 0)
poliDesc.Position = UDim2.new(0, 10, 0.5, 0)
poliDesc.BackgroundTransparency = 1
poliDesc.Text = "Elimina a todas las Formas antes de que escapen.\nHabilidad: Golpe (Click izquierdo)"
poliDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
poliDesc.TextWrapped = true
poliDesc.TextScaled = true
poliDesc.Font = Enum.Font.Gotham
poliDesc.ZIndex = 7
poliDesc.Parent = poligonoFrame

---------------------------------------------------------------------
-- Indicador de cooldown del Golpe
---------------------------------------------------------------------
local cooldownFrame = Instance.new("Frame")
cooldownFrame.Name = "CooldownIndicator"
cooldownFrame.Size = UDim2.new(0, 60, 0, 60)
cooldownFrame.Position = UDim2.new(0.5, -30, 1, -130)
cooldownFrame.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
cooldownFrame.BorderSizePixel = 0
cooldownFrame.ZIndex = 5
cooldownFrame.Visible = false
cooldownFrame.Parent = screenGui

local cdCorner = Instance.new("UICorner")
cdCorner.CornerRadius = UDim.new(0, 30)
cdCorner.Parent = cooldownFrame

local cdLabel = Instance.new("TextLabel")
cdLabel.Name = "CooldownText"
cdLabel.Size = UDim2.new(1, 0, 1, 0)
cdLabel.BackgroundTransparency = 1
cdLabel.Text = "Golpe"
cdLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
cdLabel.TextScaled = true
cdLabel.Font = Enum.Font.GothamBold
cdLabel.ZIndex = 6
cdLabel.Parent = cooldownFrame

---------------------------------------------------------------------
-- Indicador de rol actual
---------------------------------------------------------------------
local roleLabel = Instance.new("TextLabel")
roleLabel.Name = "RoleLabel"
roleLabel.Size = UDim2.new(0, 250, 0, 35)
roleLabel.Position = UDim2.new(0.5, -125, 0, 65)
roleLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
roleLabel.BackgroundTransparency = 0.5
roleLabel.BorderSizePixel = 0
roleLabel.Text = ""
roleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roleLabel.TextScaled = true
roleLabel.Font = Enum.Font.GothamBold
roleLabel.Visible = false
roleLabel.Parent = screenGui

local roleCorner = Instance.new("UICorner")
roleCorner.CornerRadius = UDim.new(0, 6)
roleCorner.Parent = roleLabel

---------------------------------------------------------------------
-- Funciones de utilidad para mostrar/ocultar pantallas
---------------------------------------------------------------------
local function hideAllScreens()
	defeatScreen.Visible = false
	victoryScreen.Visible = false
	escapeScreen.Visible = false
	selectionFrame.Visible = false
	poligonoFrame.Visible = false
	healthBarFrame.Visible = false
	cooldownFrame.Visible = false
	roleLabel.Visible = false
end

local function showScreenTemporarily(screen: Frame, duration: number)
	screen.Visible = true
	task.delay(duration or 4, function()
		screen.Visible = false
	end)
end

---------------------------------------------------------------------
-- Event Handlers
---------------------------------------------------------------------

-- Actualizar timer
UpdateTimer.OnClientEvent:Connect(function(text: string)
	timerLabel.Text = text

	-- Si estamos en descanso, ocultar pantallas de juego
	if string.find(text, "Descanso") or string.find(text, "Esperando") then
		hideAllScreens()
	end
end)

-- Asignación de rol
RoleAssigned.OnClientEvent:Connect(function(role: string)
	if role == "Poligono" then
		selectionFrame.Visible = false
		poligonoFrame.Visible = true
		healthBarFrame.Visible = false
		roleLabel.Text = "ROL: POLÍGONO"
		roleLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		roleLabel.Visible = true
	elseif role == "Forma" then
		poligonoFrame.Visible = false
		selectionFrame.Visible = true
		selTitle.Text = "ELIGE TU FORMA"
		selectedShape = nil
		roleLabel.Text = "ROL: FORMA"
		roleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		roleLabel.Visible = true

		-- Resetear botones
		for _, child in ipairs(buttonContainer:GetChildren()) do
			if child:IsA("TextButton") then
				child.BorderSizePixel = 0
				child.BackgroundTransparency = 0
			end
		end
	end
end)

-- Pantalla negra
ShowBlackScreen.OnClientEvent:Connect(function(show: boolean)
	if show then
		blackScreen.BackgroundTransparency = 0
		blackScreen.Visible = true
	else
		-- Fade out
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

-- Pantalla de derrota
ShowDefeatScreen.OnClientEvent:Connect(function()
	hideAllScreens()
	showScreenTemporarily(defeatScreen, 5)
end)

-- Pantalla de victoria
ShowVictoryScreen.OnClientEvent:Connect(function(winnerSide: string)
	hideAllScreens()
	if winnerSide == "Polígono" then
		victoryLabel.Text = "¡VICTORIA! El Polígono ha ganado"
	else
		victoryLabel.Text = "¡VICTORIA! Las Formas han ganado"
	end
	showScreenTemporarily(victoryScreen, 5)
end)

-- Pantalla de escape
ShowEscapeScreen.OnClientEvent:Connect(function()
	hideAllScreens()
	showScreenTemporarily(escapeScreen, 5)
end)

-- Inicio de partida: ocultar selección y mostrar UI de juego
TeleportToGame.OnClientEvent:Connect(function()
	selectionFrame.Visible = false
	poligonoFrame.Visible = false

	local role = player:GetAttribute("Role")
	if role == "Forma" then
		healthBarFrame.Visible = true
	elseif role == "Poligono" then
		cooldownFrame.Visible = true
	end
end)

-- Apertura de puertas
OpenDoors.OnClientEvent:Connect(function()
	-- Notificación visual
	local doorNotif = Instance.new("TextLabel")
	doorNotif.Name = "DoorNotification"
	doorNotif.Size = UDim2.new(0, 400, 0, 60)
	doorNotif.Position = UDim2.new(0.5, -200, 0.3, 0)
	doorNotif.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	doorNotif.BackgroundTransparency = 0.2
	doorNotif.BorderSizePixel = 0
	doorNotif.Text = "¡LAS PUERTAS SE HAN ABIERTO!\n¡CORRE!"
	doorNotif.TextColor3 = Color3.fromRGB(255, 255, 255)
	doorNotif.TextStrokeTransparency = 0
	doorNotif.TextScaled = true
	doorNotif.Font = Enum.Font.GothamBold
	doorNotif.ZIndex = 9
	doorNotif.Parent = screenGui

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 10)
	notifCorner.Parent = doorNotif

	-- Desaparecer después de 3 segundos
	task.delay(3, function()
		local tween = TweenService:Create(
			doorNotif,
			TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1, TextTransparency = 1 }
		)
		tween:Play()
		tween.Completed:Connect(function()
			doorNotif:Destroy()
		end)
	end)
end)

---------------------------------------------------------------------
-- Actualizar barra de vida basada en atributo Health
---------------------------------------------------------------------
local function updateHealthBar()
	local health = player:GetAttribute("Health") or 0
	local maxHealth = 100
	local fraction = math.clamp(health / maxHealth, 0, 1)

	-- Animar barra
	TweenService:Create(
		healthBarFill,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(fraction, 0, 1, 0) }
	):Play()

	-- Color de la barra según vida
	if fraction > 0.6 then
		healthBarFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
	elseif fraction > 0.3 then
		healthBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	else
		healthBarFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	end

	healthLabel.Text = tostring(health) .. " / " .. tostring(maxHealth)
end

player:GetAttributeChangedSignal("Health"):Connect(updateHealthBar)

-- También escuchar cambios de rol para mostrar/ocultar barra
player:GetAttributeChangedSignal("Role"):Connect(function()
	local role = player:GetAttribute("Role")
	if role == "Forma" then
		healthBarFrame.Visible = true
		updateHealthBar()
	elseif role == "Poligono" then
		healthBarFrame.Visible = false
		cooldownFrame.Visible = true
	else
		healthBarFrame.Visible = false
		cooldownFrame.Visible = false
		roleLabel.Visible = false
	end
end)

print("[GameUI] UI del juego cargada correctamente.")
