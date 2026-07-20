-- SYSTEM HUB PRO v5.0 (Ultra Extended)

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Clean up previous execution instances
if CoreGui:FindFirstChild("SystemHubProUI") then
    CoreGui.SystemHubProUI:Destroy()
end

-- Primary Container GUI Setup
local AdminHub = Instance.new("ScreenGui")
AdminHub.Name = "SystemHubProUI"
AdminHub.Parent = CoreGui
AdminHub.ResetOnSpawn = false

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESP_Storage"
ESPFolder.Parent = AdminHub

local ToolESPFolder = Instance.new("Folder")
ToolESPFolder.Name = "ToolESP_Storage"
ToolESPFolder.Parent = AdminHub

-- Global State & Settings Configs
local toggles = {
    Fly = false,
    Noclip = false,
    InfiniteJump = false,
    ESP = false,
    Fullbright = false,
    AntiStun = false,
    ShowDistance = true,
    GodMode = false,
    AutoSafeZone = false,
    TargetSpamTP = false,
    ToolESP = false,
    LockFOV = false,
    AutoRejoin = false
}

local sliderValues = {
    Speed = 16,
    JumpPower = 50,
    GuiScale = 1.0,
    FlySpeed = 50,
    TargetTPDelay = 0.1,
    CameraFOV = 70,
    CameraDistance = 15
}

local adminState = {
    SavedLocation = nil,
    FlyingCarpetPart = nil
}

local tracerOrigin = "Bottom" -- "Bottom", "Center", "Mouse"
local EspRegistry = {}
local SafeZonePart = nil
local safeZoneHeight = 5000

local targetSpamName = nil
local lastTargetTP = 0

local originalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime
}

-- ==========================================
-- MODERN DARK THEME UI ARCHITECTURE
-- ==========================================

local MainPanel = Instance.new("Frame")
MainPanel.Name = "MainPanel"
MainPanel.Size = UDim2.new(0, 360, 0, 540)
MainPanel.Position = UDim2.new(0.5, -180, 0.4, -270)
MainPanel.BackgroundColor3 = Color3.fromRGB(13, 15, 20)
MainPanel.BorderSizePixel = 0
MainPanel.Active = true
MainPanel.Parent = AdminHub

local UIScale = Instance.new("UIScale")
UIScale.Scale = sliderValues.GuiScale
UIScale.Parent = MainPanel

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 16)
PanelCorner.Parent = MainPanel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(35, 42, 58)
PanelStroke.Thickness = 1.5
PanelStroke.Parent = MainPanel

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
Header.BorderSizePixel = 0
Header.Parent = MainPanel

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 16)
HeaderCorner.Parent = Header

local HeaderHide = Instance.new("Frame")
HeaderHide.Size = UDim2.new(1, 0, 0, 15)
HeaderHide.Position = UDim2.new(0, 0, 1, -15)
HeaderHide.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
HeaderHide.BorderSizePixel = 0
HeaderHide.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.Text = "SYSTEM HUB PRO <font color=\"rgb(255, 75, 75)\">v5.0</font>"
Title.RichText = true
Title.TextColor3 = Color3.fromRGB(240, 243, 250)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Header

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 32, 0, 32)
MinimizeBtn.Position = UDim2.new(1, -42, 0.5, -16)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 46)
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 205, 220)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinimizeBtn

local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenBtn"
OpenBtn.Size = UDim2.new(0, 55, 0, 55)
OpenBtn.Position = UDim2.new(0, 20, 0.3, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
OpenBtn.Text = "HUB"
OpenBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 13
OpenBtn.Visible = false
OpenBtn.Active = true
OpenBtn.Parent = AdminHub

local OpenScale = Instance.new("UIScale")
OpenScale.Scale = sliderValues.GuiScale
OpenScale.Parent = OpenBtn

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 28)
OpenCorner.Parent = OpenBtn

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Color3.fromRGB(255, 75, 75)
OpenStroke.Thickness = 2
OpenStroke.Parent = OpenBtn

-- Quick GUI Scale HUD
local QuickScaleFrame = Instance.new("Frame")
QuickScaleFrame.Name = "QuickScaleFrame"
QuickScaleFrame.Size = UDim2.new(0, 80, 0, 35)
QuickScaleFrame.Position = UDim2.new(0, 20, 0.3, 65)
QuickScaleFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
QuickScaleFrame.Parent = AdminHub

local QuickScaleCorner = Instance.new("UICorner")
QuickScaleCorner.CornerRadius = UDim.new(0, 10)
QuickScaleCorner.Parent = QuickScaleFrame

local QuickScaleStroke = Instance.new("UIStroke")
QuickScaleStroke.Color = Color3.fromRGB(35, 42, 58)
QuickScaleStroke.Thickness = 1
QuickScaleStroke.Parent = QuickScaleFrame

local ScaleDownBtn = Instance.new("TextButton")
ScaleDownBtn.Size = UDim2.new(0.5, 0, 1, 0)
ScaleDownBtn.Position = UDim2.new(0, 0, 0, 0)
ScaleDownBtn.BackgroundTransparency = 1
ScaleDownBtn.Text = "−"
ScaleDownBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
ScaleDownBtn.Font = Enum.Font.GothamBold
ScaleDownBtn.TextSize = 16
ScaleDownBtn.Parent = QuickScaleFrame

local ScaleUpBtn = Instance.new("TextButton")
ScaleUpBtn.Size = UDim2.new(0.5, 0, 1, 0)
ScaleUpBtn.Position = UDim2.new(0.5, 0, 0, 0)
ScaleUpBtn.BackgroundTransparency = 1
ScaleUpBtn.Text = "+"
ScaleUpBtn.TextColor3 = Color3.fromRGB(75, 255, 120)
ScaleUpBtn.Font = Enum.Font.GothamBold
ScaleUpBtn.TextSize = 16
ScaleUpBtn.Parent = QuickScaleFrame

local function updateScale(delta)
    sliderValues.GuiScale = math.clamp(sliderValues.GuiScale + delta, 0.4, 1.6)
    UIScale.Scale = sliderValues.GuiScale
    OpenScale.Scale = sliderValues.GuiScale
end

ScaleDownBtn.MouseButton1Click:Connect(function() updateScale(-0.1) end)
ScaleUpBtn.MouseButton1Click:Connect(function() updateScale(0.1) end)

-- Navigation System
local TabNav = Instance.new("Frame")
TabNav.Name = "TabNav"
TabNav.Size = UDim2.new(1, -24, 0, 34)
TabNav.Position = UDim2.new(0, 12, 0, 58)
TabNav.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
TabNav.Parent = MainPanel

local TabNavCorner = Instance.new("UICorner")
TabNavCorner.CornerRadius = UDim.new(0, 8)
TabNavCorner.Parent = TabNav

local TabNavLayout = Instance.new("UIListLayout")
TabNavLayout.FillDirection = Enum.FillDirection.Horizontal
TabNavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabNavLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabNavLayout.Padding = UDim.new(0, 4)
TabNavLayout.Parent = TabNav

local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -24, 1, -108)
ContentArea.Position = UDim2.new(0, 12, 0, 98)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainPanel

local Tabs = {}
local TabButtons = {}

local function createTab(tabName)
    local TabFrame = Instance.new("ScrollingFrame")
    TabFrame.Name = tabName .. "Tab"
    TabFrame.Size = UDim2.new(1, 0, 1, 0)
    TabFrame.BackgroundTransparency = 1
    TabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabFrame.ScrollBarThickness = 3
    TabFrame.ScrollBarImageColor3 = Color3.fromRGB(50, 60, 85)
    TabFrame.Visible = false
    TabFrame.Parent = ContentArea

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 8)
    TabLayout.Parent = TabFrame

    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, 72, 1, -6)
    TabBtn.BackgroundColor3 = Color3.fromRGB(28, 33, 46)
    TabBtn.Text = tabName
    TabBtn.TextColor3 = Color3.fromRGB(160, 170, 190)
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.TextSize = 10
    TabBtn.Parent = TabNav

    local TabBtnCorner = Instance.new("UICorner")
    TabBtnCorner.CornerRadius = UDim.new(0, 6)
    TabBtnCorner.Parent = TabBtn

    TabBtn.MouseButton1Click:Connect(function()
        for name, frame in pairs(Tabs) do
            frame.Visible = (name == tabName)
        end
        for name, btn in pairs(TabButtons) do
            if name == tabName then
                btn.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.BackgroundColor3 = Color3.fromRGB(28, 33, 46)
                btn.TextColor3 = Color3.fromRGB(160, 170, 190)
            end
        end
    end)

    Tabs[tabName] = TabFrame
    TabButtons[tabName] = TabBtn
    return TabFrame
end

local MainTab = createTab("Main")
local VisualsTab = createTab("Visuals")
local TeleportTab = createTab("Teleport")
local SettingsTab = createTab("Settings")
local AdminTab = createTab("Admin")

Tabs["Main"].Visible = true
TabButtons["Main"].BackgroundColor3 = Color3.fromRGB(255, 75, 75)
TabButtons["Main"].TextColor3 = Color3.fromRGB(255, 255, 255)

-- Dragging
local function enableDragging(frame, dragHandle)
    local dragging, dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + (delta.X / UIScale.Scale),
                startPos.Y.Scale,
                startPos.Y.Offset + (delta.Y / UIScale.Scale)
            )
        end
    end)
end

enableDragging(MainPanel, Header)
enableDragging(OpenBtn, OpenBtn)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainPanel.Visible = false
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    MainPanel.Visible = true
    OpenBtn.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and (input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert) then
        MainPanel.Visible = not MainPanel.Visible
        OpenBtn.Visible = not MainPanel.Visible
    end
end)

-- ==========================================
-- UI FACTORIES
-- ==========================================

local function createToggle(parent, name, stateKey, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 42)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    Frame.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(220, 225, 235)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = Frame
    
    local ActionBtn = Instance.new("TextButton")
    ActionBtn.Size = UDim2.new(0, 52, 0, 24)
    ActionBtn.Position = UDim2.new(1, -62, 0.5, -12)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
    ActionBtn.Text = "OFF"
    ActionBtn.TextColor3 = Color3.fromRGB(140, 150, 170)
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.TextSize = 10
    ActionBtn.Parent = Frame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = ActionBtn
    
    ActionBtn.MouseButton1Click:Connect(function()
        toggles[stateKey] = not toggles[stateKey]
        if toggles[stateKey] then
            ActionBtn.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
            ActionBtn.Text = "ON"
            ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            ActionBtn.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
            ActionBtn.Text = "OFF"
            ActionBtn.TextColor3 = Color3.fromRGB(140, 150, 170)
        end
        if callback then callback(toggles[stateKey]) end
    end)
end

local function createSlider(parent, name, min, max, stateKey, default, isFloat, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 52)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    Frame.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 22)
    Label.Position = UDim2.new(0, 12, 0, 4)
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(220, 225, 235)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = Frame
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0.3, 0, 0, 22)
    ValueLabel.Position = UDim2.new(1, -92, 0, 4)
    ValueLabel.Text = isFloat and string.format("%.2f", default) or tostring(default)
    ValueLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextSize = 12
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Parent = Frame
    
    local SliderTrack = Instance.new("Frame")
    SliderTrack.Size = UDim2.new(1, -24, 0, 6)
    SliderTrack.Position = UDim2.new(0, 12, 0, 34)
    SliderTrack.BackgroundColor3 = Color3.fromRGB(35, 42, 58)
    SliderTrack.BorderSizePixel = 0
    SliderTrack.Parent = Frame
    
    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(0, 3)
    TrackCorner.Parent = SliderTrack
    
    local SliderFill = Instance.new("Frame")
    local initScale = math.clamp((default - min) / (max - min), 0, 1)
    SliderFill.Size = UDim2.new(initScale, 0, 1, 0)
    SliderFill.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
    SliderFill.BorderSizePixel = 0
    SliderFill.Parent = SliderTrack
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 3)
    FillCorner.Parent = SliderFill
    
    local function snapToValue(input)
        local totalWidth = SliderTrack.AbsoluteSize.X
        local relativeX = input.Position.X - SliderTrack.AbsolutePosition.X
        local percentage = math.clamp(relativeX / totalWidth, 0, 1)
        
        SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        local rawValue = min + (percentage * (max - min))
        local finalValue = isFloat and (math.floor(rawValue * 100) / 100) or math.floor(rawValue + 0.5)
        
        ValueLabel.Text = isFloat and string.format("%.2f", finalValue) or tostring(finalValue)
        sliderValues[stateKey] = finalValue
        if callback then callback(finalValue) end
    end
    
    local isSliding = false
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
            snapToValue(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            snapToValue(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = false
        end
    end)
end

local function createButton(parent, name, callback)
    local ActionBtn = Instance.new("TextButton")
    ActionBtn.Size = UDim2.new(1, 0, 0, 38)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(26, 32, 44)
    ActionBtn.Text = name
    ActionBtn.TextColor3 = Color3.fromRGB(230, 235, 245)
    ActionBtn.Font = Enum.Font.GothamMedium
    ActionBtn.TextSize = 12
    ActionBtn.Parent = parent
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = ActionBtn
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(42, 50, 68)
    Stroke.Thickness = 1
    Stroke.Parent = ActionBtn
    
    ActionBtn.MouseButton1Click:Connect(callback)
end

local function createTeleportBox(parent, placeholder, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 42)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    Frame.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame
    
    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(1, -75, 1, 0)
    TextBox.Position = UDim2.new(0, 12, 0, 0)
    TextBox.BackgroundTransparency = 1
    TextBox.Text = ""
    TextBox.PlaceholderText = placeholder
    TextBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.Font = Enum.Font.GothamMedium
    TextBox.TextSize = 12
    TextBox.TextXAlignment = Enum.TextXAlignment.Left
    TextBox.ClearTextOnFocus = true
    TextBox.Parent = Frame
    
    local GoBtn = Instance.new("TextButton")
    GoBtn.Size = UDim2.new(0, 52, 0, 26)
    GoBtn.Position = UDim2.new(1, -62, 0.5, -13)
    GoBtn.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
    GoBtn.Text = "TP"
    GoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GoBtn.Font = Enum.Font.GothamBold
    GoBtn.TextSize = 11
    GoBtn.Parent = Frame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = GoBtn
    
    GoBtn.MouseButton1Click:Connect(function()
        if TextBox.Text ~= "" then
            callback(TextBox.Text)
        end
    end)
end

-- ==========================================
-- MAIN TAB: MOVEMENT / GOD MODE
-- ==========================================

local FlightVelocity, FlightGyro
local upPressed, downPressed = false, false

local MobileFlyFrame = Instance.new("Frame")
MobileFlyFrame.Name = "MobileFlyFrame"
MobileFlyFrame.Size = UDim2.new(0, 60, 0, 130)
MobileFlyFrame.Position = UDim2.new(1, -80, 0.5, -65)
MobileFlyFrame.BackgroundTransparency = 1
MobileFlyFrame.Visible = false
MobileFlyFrame.Parent = AdminHub

local FlyUpBtn = Instance.new("TextButton")
FlyUpBtn.Size = UDim2.new(0, 55, 0, 55)
FlyUpBtn.Position = UDim2.new(0, 0, 0, 0)
FlyUpBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
FlyUpBtn.Text = "▲"
FlyUpBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
FlyUpBtn.Font = Enum.Font.GothamBold
FlyUpBtn.TextSize = 18
FlyUpBtn.Parent = MobileFlyFrame
Instance.new("UICorner", FlyUpBtn).CornerRadius = UDim.new(0, 12)

local FlyDownBtn = Instance.new("TextButton")
FlyDownBtn.Size = UDim2.new(0, 55, 0, 55)
FlyDownBtn.Position = UDim2.new(0, 0, 0, 65)
FlyDownBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
FlyDownBtn.Text = "▼"
FlyDownBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
FlyDownBtn.Font = Enum.Font.GothamBold
FlyDownBtn.TextSize = 18
FlyDownBtn.Parent = MobileFlyFrame
Instance.new("UICorner", FlyDownBtn).CornerRadius = UDim.new(0, 12)

FlyUpBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        upPressed = true
    end
end)
FlyUpBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        upPressed = false
    end
end)

FlyDownBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        downPressed = true
    end
end)
FlyDownBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        downPressed = false
    end
end)

createToggle(MainTab, "Flight Engine", "Fly", function(state)
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    MobileFlyFrame.Visible = state
    
    if not state then
        if FlightVelocity then FlightVelocity:Destroy() end
        if FlightGyro then FlightGyro:Destroy() end
        if character and character:FindFirstChildOfClass("Humanoid") then
            character:FindFirstChildOfClass("Humanoid").PlatformStand = false
        end
    else
        if rootPart then
            FlightVelocity = Instance.new("BodyVelocity")
            FlightVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            FlightVelocity.Velocity = Vector3.new(0, 0, 0)
            FlightVelocity.Parent = rootPart
            
            FlightGyro = Instance.new("BodyGyro")
            FlightGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            FlightGyro.CFrame = rootPart.CFrame
            FlightGyro.Parent = rootPart
        end
    end
end)

createToggle(MainTab, "Noclip Engine", "Noclip")
createToggle(MainTab, "Infinite Jump", "InfiniteJump")
createToggle(MainTab, "Anti-Stun / Ragdoll Immunity", "AntiStun")
createToggle(MainTab, "GOD MODE (Immortal)", "GodMode")
createSlider(MainTab, "Fly Speed", 10, 300, "FlySpeed", 50)
createSlider(MainTab, "Walk Speed", 16, 350, "Speed", 16)
createSlider(MainTab, "Jump Power", 50, 350, "JumpPower", 50)

-- ==========================================
-- VISUALS TAB: ESP / FULLBRIGHT / TOOL ESP
-- ==========================================

createToggle(VisualsTab, "Global Master ESP", "ESP")
createToggle(VisualsTab, "Display Player Distance", "ShowDistance")
createToggle(VisualsTab, "Tool ESP (Tools in Workspace)", "ToolESP")
createToggle(VisualsTab, "Fullbright Lighting", "Fullbright", function(state)
    if state then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 14
    else
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.ClockTime = originalLighting.ClockTime
    end
end)

createButton(VisualsTab, "Cycle Tracer Origin: Bottom", function()
    if tracerOrigin == "Bottom" then
        tracerOrigin = "Center"
    elseif tracerOrigin == "Center" then
        tracerOrigin = "Mouse"
    else
        tracerOrigin = "Bottom"
    end
    for _, btn in pairs(VisualsTab:GetChildren()) do
        if btn:IsA("TextButton") and btn.Text:sub(1, 19) == "Cycle Tracer Origin" then
            btn.Text = "Cycle Tracer Origin: " .. tracerOrigin
        end
    end
end)

local EspHeaderLabel = Instance.new("TextLabel")
EspHeaderLabel.Size = UDim2.new(1, 0, 0, 20)
EspHeaderLabel.BackgroundTransparency = 1
EspHeaderLabel.Text = "TARGET SELECTIVE ESP"
EspHeaderLabel.TextColor3 = Color3.fromRGB(140, 150, 170)
EspHeaderLabel.Font = Enum.Font.GothamBold
EspHeaderLabel.TextSize = 10
EspHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
EspHeaderLabel.Parent = VisualsTab

local EspScroller = Instance.new("ScrollingFrame")
EspScroller.Size = UDim2.new(1, 0, 0, 110)
EspScroller.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
EspScroller.BorderSizePixel = 0
EspScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
EspScroller.ScrollBarThickness = 3
EspScroller.Parent = VisualsTab

local EspListLayout = Instance.new("UIListLayout")
EspListLayout.Padding = UDim.new(0, 4)
EspListLayout.Parent = EspScroller

Instance.new("UICorner", EspScroller).CornerRadius = UDim.new(0, 8)

local function UpdateEspSelectionList()
    for _, child in pairs(EspScroller:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local rowCount = 0
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            rowCount = rowCount + 1
            local RowButton = Instance.new("TextButton")
            RowButton.Size = UDim2.new(1, -6, 0, 28)
            RowButton.BackgroundColor3 = EspRegistry[player.Name] and Color3.fromRGB(255, 75, 75) or Color3.fromRGB(28, 33, 46)
            RowButton.Text = "  " .. player.DisplayName .. " (@" .. player.Name .. ")"
            RowButton.Font = Enum.Font.GothamMedium
            RowButton.TextSize = 11
            RowButton.TextColor3 = EspRegistry[player.Name] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 205, 220)
            RowButton.TextXAlignment = Enum.TextXAlignment.Left
            RowButton.Parent = EspScroller
            
            Instance.new("UICorner", RowButton).CornerRadius = UDim.new(0, 6)
            
            RowButton.MouseButton1Click:Connect(function()
                EspRegistry[player.Name] = not EspRegistry[player.Name]
                RowButton.BackgroundColor3 = EspRegistry[player.Name] and Color3.fromRGB(255, 75, 75) or Color3.fromRGB(28, 33, 46)
                RowButton.TextColor3 = EspRegistry[player.Name] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 205, 220)
            end)
        end
    end
    EspScroller.CanvasSize = UDim2.new(0, 0, 0, rowCount * 32)
end

Players.PlayerAdded:Connect(UpdateEspSelectionList)
Players.PlayerRemoving:Connect(UpdateEspSelectionList)
UpdateEspSelectionList()

-- ==========================================
-- TELEPORT TAB: ADVANCED TELEPORT FEATURES
-- ==========================================

createTeleportBox(TeleportTab, "Teleport to Player...", function(targetName)
    local foundPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #targetName) == targetName:lower() or p.DisplayName:lower():sub(1, #targetName) == targetName:lower() then
            foundPlayer = p
            break
        end
    end
    
    if foundPlayer and foundPlayer.Character and foundPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then
            myRoot.CFrame = foundPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        end
    end
end)

createTeleportBox(TeleportTab, "Bring Player To Me...", function(targetName)
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local foundPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #targetName) == targetName:lower() or p.DisplayName:lower():sub(1, #targetName) == targetName:lower() then
            foundPlayer = p
            break
        end
    end
    
    if foundPlayer and foundPlayer.Character and foundPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetRoot = foundPlayer.Character.HumanoidRootPart
        targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, 3)
    end
end)

createTeleportBox(TeleportTab, "Set Target Player for Spam TP...", function(targetName)
    targetSpamName = targetName
end)

createToggle(TeleportTab, "Enable Target Spam Teleport", "TargetSpamTP")
createSlider(TeleportTab, "Spam TP Delay (sec)", 0.05, 1.0, "TargetTPDelay", 0.10, true)

createButton(TeleportTab, "Teleport to Random Player", function()
    local availablePlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(availablePlayers, p)
        end
    end
    
    if #availablePlayers > 0 then
        local target = availablePlayers[math.random(1, #availablePlayers)]
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and targetRoot then
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        end
    end
end)

createButton(TeleportTab, "Save Current Location", function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        adminState.SavedLocation = root.Position
    end
end)

createButton(TeleportTab, "Teleport to Saved Location", function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and adminState.SavedLocation then
        root.CFrame = CFrame.new(adminState.SavedLocation + Vector3.new(0, 3, 0))
    end
end)

createButton(TeleportTab, "Teleport Above Map (High Sky)", function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(root.Position.X, safeZoneHeight + 200, root.Position.Z)
    end
end)

createButton(TeleportTab, "Teleport Below Map (Void)", function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(root.Position.X, -500, root.Position.Z)
    end
end)

createButton(TeleportTab, "Get Click-Teleport Tool", function()
    local tool = Instance.new("Tool")
    tool.Name = "Click Teleport"
    tool.RequiresHandle = false
    
    tool.Activated:Connect(function()
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            local mouseLocation = UserInputService:GetMouseLocation()
            local unitRay = Camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {character}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
            if result then
                root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
            end
        end
    end)
    tool.Parent = LocalPlayer:WaitForChild("Backpack")
end)

local function GenerateSafeZone()
    if SafeZonePart and SafeZonePart.Parent then return SafeZonePart end
    
    SafeZonePart = Instance.new("Part")
    SafeZonePart.Name = "OmnipresentSafeZonePlank"
    SafeZonePart.Size = Vector3.new(150, 2, 150)
    SafeZonePart.Position = Vector3.new(0, safeZoneHeight, 0)
    SafeZonePart.Anchored = true
    SafeZonePart.Material = Enum.Material.SmoothPlastic
    SafeZonePart.Color = Color3.fromRGB(255, 255, 255)
    SafeZonePart.TopSurface = Enum.SurfaceType.Smooth
    SafeZonePart.Parent = Workspace
    
    local Barrier = Instance.new("Part")
    Barrier.Size = Vector3.new(152, 20, 152)
    Barrier.Position = SafeZonePart.Position + Vector3.new(0, 10, 0)
    Barrier.Transparency = 1
    Barrier.Anchored = true
    Barrier.CanCollide = true
    Barrier.Parent = SafeZonePart
    
    local SelectionOutline = Instance.new("SelectionBox")
    SelectionOutline.Adornee = SafeZonePart
    SelectionOutline.Color3 = Color3.fromRGB(255, 75, 75)
    SelectionOutline.Parent = SafeZonePart
    
    return SafeZonePart
end

createButton(TeleportTab, "Deploy & TP to Safe Zone Platform", function()
    local platform = GenerateSafeZone()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        -- Teleport ABOVE the platform by 10 studs so you drop onto it
        root.CFrame = CFrame.new(platform.Position + Vector3.new(0, 10, 0))
    end
end)

createToggle(TeleportTab, "Auto Safe Zone (Keep You On Platform)", "AutoSafeZone")

createButton(TeleportTab, "Rejoin Current Server", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

createButton(TeleportTab, "Server Hop (Find New Lobby)", function()
    local success, servers = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    end)
    if success and servers then
        local decoded = HttpService:JSONDecode(servers)
        for _, server in ipairs(decoded.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                break
            end
        end
    end
end)

-- ==========================================
-- SETTINGS TAB: CAMERA / UI / AUTO REJOIN
-- ==========================================

createSlider(SettingsTab, "GUI Scale (Mobile Friendly)", 0.5, 1.5, "GuiScale", 1.0, true, function(scaleValue)
    UIScale.Scale = scaleValue
    OpenScale.Scale = scaleValue
end)

createSlider(SettingsTab, "Camera FOV", 40, 100, "CameraFOV", 70, false, function(value)
    sliderValues.CameraFOV = value
    Camera.FieldOfView = value
end)

createSlider(SettingsTab, "Camera Distance", 5, 50, "CameraDistance", 15, false, function(value)
    sliderValues.CameraDistance = value
    LocalPlayer.CameraMaxZoomDistance = value
    LocalPlayer.CameraMinZoomDistance = 5
end)

createToggle(SettingsTab, "Lock Camera FOV", "LockFOV", function(state)
    if state then
        Camera.FieldOfView = sliderValues.CameraFOV
    end
end)

createToggle(SettingsTab, "Auto Rejoin On Death", "AutoRejoin")

createButton(SettingsTab, "Reset UI Center Position", function()
    MainPanel.Position = UDim2.new(0.5, -180, 0.4, -270)
    OpenBtn.Position = UDim2.new(0, 20, 0.3, 0)
end)

-- ==========================================
-- ADMIN TAB: FAKE ADMIN TOOLS (Flying Carpet, Blink, Dash)
-- ==========================================

local function giveFlyingCarpetTool()
    local tool = Instance.new("Tool")
    tool.Name = "Fake Flying Carpet"
    tool.RequiresHandle = false
    
    tool.Equipped:Connect(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            if adminState.FlyingCarpetPart and adminState.FlyingCarpetPart.Parent then
                adminState.FlyingCarpetPart:Destroy()
            end
            local carpet = Instance.new("Part")
            carpet.Name = "FlyingCarpetPlatform"
            carpet.Size = Vector3.new(8, 1, 12)
            carpet.Anchored = true
            carpet.Material = Enum.Material.SmoothPlastic
            carpet.Color = Color3.fromRGB(255, 255, 0)
            carpet.Position = root.Position - Vector3.new(0, 3, 0)
            carpet.Parent = Workspace
            adminState.FlyingCarpetPart = carpet
        end
    end)
    
    tool.Unequipped:Connect(function()
        if adminState.FlyingCarpetPart then
            adminState.FlyingCarpetPart:Destroy()
            adminState.FlyingCarpetPart = nil
        end
    end)
    
    tool.Activated:Connect(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and adminState.FlyingCarpetPart then
            adminState.FlyingCarpetPart.CFrame = root.CFrame * CFrame.new(0, -3, 0)
        end
    end)
    
    tool.Parent = LocalPlayer:WaitForChild("Backpack")
end

local function giveBlinkTeleportTool()
    local tool = Instance.new("Tool")
    tool.Name = "Blink Teleport"
    tool.RequiresHandle = false
    
    tool.Activated:Connect(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local forward = Camera.CFrame.LookVector
            root.CFrame = root.CFrame + (forward * 15)
        end
    end)
    
    tool.Parent = LocalPlayer:WaitForChild("Backpack")
end

local function giveDashTool()
    local tool = Instance.new("Tool")
    tool.Name = "Phase Dash"
    tool.RequiresHandle = false
    
    tool.Activated:Connect(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local forward = Camera.CFrame.LookVector
            root.CFrame = root.CFrame + (forward * 40)
        end
    end)
    
    tool.Parent = LocalPlayer:WaitForChild("Backpack")
end

createButton(AdminTab, "Give Fake Flying Carpet Tool", function()
    giveFlyingCarpetTool()
end)

createButton(AdminTab, "Give Blink Teleport Tool", function()
    giveBlinkTeleportTool()
end)

createButton(AdminTab, "Give Phase Dash Tool", function()
    giveDashTool()
end)

createButton(AdminTab, "Clean ESP / Tool ESP Storage", function()
    for _, v in ipairs(ESPFolder:GetChildren()) do v:Destroy() end
    for _, v in ipairs(ToolESPFolder:GetChildren()) do v:Destroy() end
end)

-- ==========================================
-- ESP SYSTEM
-- ==========================================

local function createESPAssets(player)
    if player == LocalPlayer then return end
    
    local function applyESP(character)
        if not character then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then
            root = character:WaitForChild("HumanoidRootPart", 5)
            if not root then return end
        end
        
        if not character:FindFirstChild("ESPHighlight") then
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESPHighlight"
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineTransparency = 0
            highlight.Adornee = character
            highlight.Enabled = toggles.ESP
            highlight.Parent = character
        end
        
        local billboardName = player.Name .. "_ESP_Bill"
        local tracerName = player.Name .. "_ESP_Trace"
        
        if not ESPFolder:FindFirstChild(billboardName) then
            local bill = Instance.new("BillboardGui")
            bill.Name = billboardName
            bill.AlwaysOnTop = true
            bill.Size = UDim2.new(0, 200, 0, 50)
            bill.StudsOffset = Vector3.new(0, 3, 0)
            bill.Adornee = root
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "Tag"
            nameLabel.Size = UDim2.new(1, 0, 1, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 13
            nameLabel.TextStrokeTransparency = 0.2
            nameLabel.Parent = bill
            
            bill.Parent = ESPFolder
        end
        
        if not ESPFolder:FindFirstChild(tracerName) then
            local line = Instance.new("Frame")
            line.Name = tracerName
            line.AnchorPoint = Vector2.new(0.5, 0.5)
            line.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
            line.BorderSizePixel = 0
            line.Visible = false
            line.Parent = ESPFolder
        end
    end
    
    player.CharacterAdded:Connect(applyESP)
    if player.Character then applyESP(player.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do createESPAssets(p) end
Players.PlayerAdded:Connect(createESPAssets)

Players.PlayerRemoving:Connect(function(player)
    local bill = ESPFolder:FindFirstChild(player.Name .. "_ESP_Bill")
    local trace = ESPFolder:FindFirstChild(player.Name .. "_ESP_Trace")
    if bill then bill:Destroy() end
    if trace then trace:Destroy() end
end)

-- TOOL ESP
local function refreshToolESP()
    for _, child in ipairs(ToolESPFolder:GetChildren()) do
        child:Destroy()
    end

    if not toggles.ToolESP then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
            local handle = obj.Handle
            local bill = Instance.new("BillboardGui")
            bill.Name = "ToolESP_" .. obj.Name
            bill.AlwaysOnTop = true
            bill.Size = UDim2.new(0, 120, 0, 30)
            bill.StudsOffset = Vector3.new(0, 2, 0)
            bill.Adornee = handle

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(75, 255, 120)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 12
            label.Text = "[TOOL] " .. obj.Name
            label.Parent = bill

            bill.Parent = ToolESPFolder
        end
    end
end

-- ==========================================
-- MAIN ENGINE LOOP
-- ==========================================

RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    -- GOD MODE
    if hum and toggles.GodMode then
        hum.Health = hum.MaxHealth
        hum.BreakJointsOnDeath = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
    
    -- Auto Rejoin
    if hum and toggles.AutoRejoin and hum.Health <= 0 then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
    
    -- Speed / Jump
    if hum then
        hum.WalkSpeed = sliderValues.Speed
        if hum.UseJumpPower then
            hum.JumpPower = sliderValues.JumpPower
        else
            hum.JumpHeight = sliderValues.JumpPower / 3.5
        end
        
        if toggles.AntiStun then
            hum.PlatformStand = false
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end
    end
    
    -- Auto Safe Zone
    if toggles.AutoSafeZone then
        local platform = GenerateSafeZone()
        if root and platform then
            local pos = root.Position
            if pos.Y < (safeZoneHeight - 50) then
                root.CFrame = CFrame.new(platform.Position + Vector3.new(0, 10, 0))
            end
        end
    end
    
    -- Noclip
    if toggles.Noclip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- Flight
    if toggles.Fly and root and FlightVelocity and FlightGyro then
        local camCF = Camera.CFrame
        local moveDir = Vector3.zero
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
        
        if upPressed or UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDir = moveDir + Vector3.new(0, 1, 0)
        end
        if downPressed or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            moveDir = moveDir - Vector3.new(0, 1, 0)
        end
        
        FlightGyro.CFrame = camCF
        FlightVelocity.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * sliderValues.FlySpeed) or Vector3.zero
    end
    
    -- Flying Carpet follow
    if adminState.FlyingCarpetPart and root then
        adminState.FlyingCarpetPart.CFrame = root.CFrame * CFrame.new(0, -3, 0)
    end
    
    -- Target Spam TP
    if toggles.TargetSpamTP and targetSpamName and root then
        lastTargetTP = lastTargetTP + dt
        if lastTargetTP >= sliderValues.TargetTPDelay then
            lastTargetTP = 0
            local foundPlayer = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():sub(1, #targetSpamName) == targetSpamName:lower() or p.DisplayName:lower():sub(1, #targetSpamName) == targetSpamName:lower() then
                    foundPlayer = p
                    break
                end
            end
            if foundPlayer and foundPlayer.Character and foundPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = foundPlayer.Character.HumanoidRootPart
                root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            end
        end
    end
    
    -- Lock FOV
    if toggles.LockFOV then
        Camera.FieldOfView = sliderValues.CameraFOV
    end
    
    -- ESP updates
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local pChar = player.Character
            local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
            local bill = ESPFolder:FindFirstChild(player.Name .. "_ESP_Bill")
            local trace = ESPFolder:FindFirstChild(player.Name .. "_ESP_Trace")
            
            local isTargeted = (EspRegistry[player.Name] == true)
            local showPlayer = toggles.ESP or isTargeted
            
            if pChar and pChar:FindFirstChild("ESPHighlight") then
                pChar.ESPHighlight.Enabled = showPlayer
            end
            
            if pRoot and bill and trace then
                local screenPos, onScreen = Camera:WorldToViewportPoint(pRoot.Position)
                
                if showPlayer and onScreen then
                    bill.Enabled = true
                    local distance = math.floor((root and (root.Position - pRoot.Position).Magnitude) or 0)
                    local label = bill:FindFirstChild("Tag")
                    if label then
                        local healthText = ""
                        local phum = pChar:FindFirstChildOfClass("Humanoid")
                        if phum then
                            healthText = string.format(" | HP: %d", math.floor(phum.Health))
                        end
                        if toggles.ShowDistance then
                            label.Text = string.format("%s\n[%d m]%s", player.DisplayName, distance, healthText)
                        else
                            label.Text = string.format("%s%s", player.DisplayName, healthText)
                        end
                    end
                    
                    local startPos
                    if tracerOrigin == "Bottom" then
                        startPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    elseif tracerOrigin == "Center" then
                        startPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    else
                        startPos = UserInputService:GetMouseLocation()
                    end
                    
                    local targetPos = Vector2.new(screenPos.X, screenPos.Y)
                    local distanceVec = targetPos - startPos
                    
                    trace.Size = UDim2.new(0, distanceVec.Magnitude, 0, 1.5)
                    trace.Position = UDim2.new(0, startPos.X + (distanceVec.X / 2), 0, startPos.Y + (distanceVec.Y / 2))
                    trace.Rotation = math.deg(math.atan2(distanceVec.Y, distanceVec.X))
                    trace.Visible = true
                else
                    bill.Enabled = false
                    trace.Visible = false
                end
            else
                if bill then bill.Enabled = false end
                if trace then trace.Visible = false end
            end
        end
    end
    
    -- Tool ESP refresh
    refreshToolESP()
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if toggles.InfiniteJump and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)
