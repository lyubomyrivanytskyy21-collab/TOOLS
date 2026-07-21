-- SYSTEM HUB PRO v6.0 (Ultra Extended Rebuild)

--// Services
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

--// Cleanup previous UI
pcall(function()
    if CoreGui:FindFirstChild("SystemHubProUI") then
        CoreGui.SystemHubProUI:Destroy()
    end
end)

--// Root GUI
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

--// Global State
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
    AutoRejoin = false,
    AutoRespawn = true,
    AutoHeal = false,
    AutoAlignToTarget = false
}

local sliderValues = {
    Speed = 16,
    JumpPower = 50,
    GuiScale = 1.0,
    FlySpeed = 50,
    TargetTPDelay = 0.1,
    CameraFOV = 70,
    CameraDistance = 15,
    SafeZoneHeight = 5000,
    AutoHealThreshold = 0.4
}

local adminState = {
    SavedLocation = nil,
    FlyingCarpetPart = nil,
    LastServerJobId = game.JobId,
    LastPlaceId = game.PlaceId
}

local tracerOrigin = "Bottom" -- "Bottom", "Center", "Mouse"
local EspRegistry = {}
local SafeZonePart = nil
local targetSpamName = nil
local lastTargetTP = 0

local originalLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd
}

--// Safe Zone Creation (Top, not bottom)
local function ensureSafeZone()
    if SafeZonePart and SafeZonePart.Parent == Workspace then return SafeZonePart end

    SafeZonePart = Instance.new("Part")
    SafeZonePart.Name = "SystemHub_SafeZone"
    SafeZonePart.Anchored = true
    SafeZonePart.CanCollide = true
    SafeZonePart.Size = Vector3.new(200, 10, 200)
    SafeZonePart.Transparency = 1
    SafeZonePart.Color = Color3.fromRGB(0, 255, 0)

    local basePos = Vector3.new(0, sliderValues.SafeZoneHeight, 0)
    pcall(function()
        if Workspace:FindFirstChild("Baseplate") then
            basePos = Workspace.Baseplate.Position + Vector3.new(0, sliderValues.SafeZoneHeight, 0)
        end
    end)

    SafeZonePart.CFrame = CFrame.new(basePos)
    SafeZonePart.Parent = Workspace

    return SafeZonePart
end

local function teleportToSafeZoneTop()
    local character = LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local zone = ensureSafeZone()
    local topCFrame = zone.CFrame * CFrame.new(0, zone.Size.Y / 2 + 5, 0)
    root.CFrame = topCFrame
end

--// MAIN PANEL UI
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
Title.Text = "SYSTEM HUB PRO <font color=\"rgb(255, 75, 75)\">v6.0</font>"
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

-- UI FACTORIES
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

-- MAIN TAB: MOVEMENT / GOD MODE
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
        if FlightVelocity then FlightVelocity:Destroy() FlightVelocity = nil end
        if FlightGyro then FlightGyro:Destroy() FlightGyro = nil end
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

            if character:FindFirstChildOfClass("Humanoid") then
                character:FindFirstChildOfClass("Humanoid").PlatformStand = true
            end
        end
    end
end)

createToggle(MainTab, "Noclip Engine", "Noclip")
createToggle(MainTab, "Infinite Jump", "InfiniteJump")
createToggle(MainTab, "Anti-Stun / Ragdoll Immunity", "AntiStun")
createToggle(MainTab, "GOD MODE (Immortal)", "GodMode")
createToggle(MainTab, "Auto Safe Zone (Top)", "AutoSafeZone", function(state)
    if state then
        ensureSafeZone()
    end
end)

createSlider(MainTab, "Fly Speed", 10, 300, "FlySpeed", 50)
createSlider(MainTab, "Walk Speed", 16, 350, "Speed", 16)
createSlider(MainTab, "Jump Power", 50, 350, "JumpPower", 50)
createSlider(MainTab, "Safe Zone Height", 1000, 10000, "SafeZoneHeight", 5000, false, function()
    if SafeZonePart then
        SafeZonePart.CFrame = SafeZonePart.CFrame + Vector3.new(0, sliderValues.SafeZoneHeight - SafeZonePart.Position.Y, 0)
    end
end)

createButton(MainTab, "Teleport to Safe Zone (Top)", function()
    teleportToSafeZoneTop()
end)

createButton(MainTab, "Save Current Location", function()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        adminState.SavedLocation = root.CFrame
    end
end)

createButton(MainTab, "Return to Saved Location", function()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and adminState.SavedLocation then
        root.CFrame = adminState.SavedLocation
    end
end)

-- VISUALS TAB: ESP / FULLBRIGHT / TOOL ESP / FOV
createToggle(VisualsTab, "Global Master ESP", "ESP")
createToggle(VisualsTab, "Display Player Distance", "ShowDistance")
createToggle(VisualsTab, "Tool ESP (Tools in Workspace)", "ToolESP")
createToggle(VisualsTab, "Fullbright Lighting", "Fullbright", function(state)
    if state then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 14
        Lighting.Brightness = 3
        Lighting.FogEnd = 100000
    else
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.Brightness = originalLighting.Brightness
        Lighting.FogEnd = originalLighting.FogEnd
    end
end)

createSlider(VisualsTab, "Camera FOV", 40, 120, "CameraFOV", 70, false, function(value)
    Camera.FieldOfView = value
end)

createToggle(VisualsTab, "Lock FOV", "LockFOV")

createSlider(VisualsTab, "Camera Distance", 5, 50, "CameraDistance", 15, false)

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

-- TELEPORT TAB: ADVANCED TELEPORT FEATURES
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
        if myRoot then
            myRoot.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        end
    end
end)

createButton(TeleportTab, "Teleport All Players To Me", function()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            p.Character.HumanoidRootPart.CFrame = myRoot.CFrame * CFrame.new(0, 0, 5)
        end
    end
end)

createButton(TeleportTab, "Teleport Me To Safe Zone (Top)", function()
    teleportToSafeZoneTop()
end)

-- SETTINGS TAB: AUTO REJOIN / AUTO RESPAWN / AUTO HEAL
createToggle(SettingsTab, "Auto Rejoin on Kick/Disconnect", "AutoRejoin")
createToggle(SettingsTab, "Auto Respawn on Death", "AutoRespawn")
createToggle(SettingsTab, "Auto Heal (if health below threshold)", "AutoHeal")

createSlider(SettingsTab, "Auto Heal Threshold (0.1 - 0.9)", 0.1, 0.9, "AutoHealThreshold", 0.4, true)

createButton(SettingsTab, "Rejoin Current Server", function()
    TeleportService:Teleport(adminState.LastPlaceId, LocalPlayer)
end)

createButton(SettingsTab, "Rejoin Different Server", function()
    TeleportService:Teleport(adminState.LastPlaceId)
end)

createButton(SettingsTab, "Copy JobId to Clipboard", function()
    if setclipboard then
        setclipboard(adminState.LastServerJobId)
    end
end)

-- ADMIN TAB: EXTRA FUN / CARPET / ALIGN
createButton(AdminTab, "Spawn Flying Carpet", function()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if adminState.FlyingCarpetPart and adminState.FlyingCarpetPart.Parent then
        adminState.FlyingCarpetPart:Destroy()
        adminState.FlyingCarpetPart = nil
    end

    local carpet = Instance.new("Part")
    carpet.Name = "SystemHub_FlyingCarpet"
    carpet.Size = Vector3.new(8, 1, 8)
    carpet.Anchored = false
    carpet.CanCollide = true
    carpet.Color = Color3.fromRGB(255, 75, 75)
    carpet.Material = Enum.Material.Neon
    carpet.CFrame = root.CFrame * CFrame.new(0, -4, 0)
    carpet.Parent = Workspace

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = carpet
    weld.Part1 = root
    weld.Parent = carpet

    adminState.FlyingCarpetPart = carpet
end)

createButton(AdminTab, "Destroy Flying Carpet", function()
    if adminState.FlyingCarpetPart and adminState.FlyingCarpetPart.Parent then
        adminState.FlyingCarpetPart:Destroy()
        adminState.FlyingCarpetPart = nil
    end
end)

createToggle(AdminTab, "Auto Align To Target (Spam TP target)", "AutoAlignToTarget")

createButton(AdminTab, "Reset Character (Soft)", function()
    local character = LocalPlayer.Character
    if character then
        for _, v in ipairs(character:GetChildren()) do
            if v:IsA("BasePart") then
                v.Velocity = Vector3.new(0, 0, 0)
                v.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end)

createButton(AdminTab, "Hard Reset (Respawn)", function()
    LocalPlayer:LoadCharacter()
end)

-- CORE LOGIC LOOPS

-- Noclip
RunService.Stepped:Connect(function()
    if toggles.Noclip then
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if toggles.InfiniteJump then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Movement (Speed / Jump / Fly)
RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if humanoid then
        humanoid.WalkSpeed = sliderValues.Speed
        humanoid.JumpPower = sliderValues.JumpPower
    end

    if toggles.Fly and FlightVelocity and FlightGyro and root then
        local moveDirection = Vector3.new(0, 0, 0)
        local camCF = Camera.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camCF.RightVector
        end

        if upPressed or UserInputService:IsKeyDown(Enum.KeyCode.E) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if downPressed or UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end

        FlightVelocity.Velocity = moveDirection * sliderValues.FlySpeed
        FlightGyro.CFrame = camCF
    end
end)

-- Anti-Stun / GodMode / AutoHeal
RunService.Heartbeat:Connect(function()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if toggles.AntiStun then
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end

    if toggles.GodMode then
        humanoid.Health = humanoid.MaxHealth
        humanoid.BreakJointsOnDeath = false
    end

    if toggles.AutoHeal then
        if humanoid.Health / humanoid.MaxHealth <= sliderValues.AutoHealThreshold then
            humanoid.Health = humanoid.MaxHealth
        end
    end
end)

-- Auto Safe Zone
RunService.Heartbeat:Connect(function()
    if toggles.AutoSafeZone then
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            if root.Position.Y < 0 then
                teleportToSafeZoneTop()
            end
        end
    end
end)

-- Auto Respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    if toggles.AutoRespawn then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                if toggles.AutoRespawn then
                    LocalPlayer:LoadCharacter()
                end
            end)
        end
    end
end)

-- Auto Rejoin (basic)
game:GetService("GuiService").ErrorMessageChanged:Connect(function(message)
    if toggles.AutoRejoin and message ~= "" then
        TeleportService:Teleport(adminState.LastPlaceId, LocalPlayer)
    end
end)

-- ESP (Players)
local function clearESP()
    for _, v in ipairs(ESPFolder:GetChildren()) do
        v:Destroy()
    end
end

local function createESPForPlayer(player)
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.Adornee = root
    billboard.Parent = ESPFolder

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
    distLabel.Font = Enum.Font.GothamMedium
    distLabel.TextSize = 11
    distLabel.Text = ""
    distLabel.Parent = billboard

    RunService.RenderStepped:Connect(function()
        if not billboard.Parent then return end
        if toggles.ShowDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            local dist = (myRoot.Position - root.Position).Magnitude
            distLabel.Text = string.format("Distance: %.0f", dist)
        else
            distLabel.Text = ""
        end
    end)
end

local function refreshESP()
    clearESP()
    if not toggles.ESP then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if next(EspRegistry) == nil or EspRegistry[player.Name] then
                createESPForPlayer(player)
            end
        end
    end
end

Players.PlayerAdded:Connect(function()
    refreshESP()
end)
Players.PlayerRemoving:Connect(function()
    refreshESP()
end)

RunService.Heartbeat:Connect(function()
    refreshESP()
end)

-- Tool ESP
local function clearToolESP()
    for _, v in ipairs(ToolESPFolder:GetChildren()) do
        v:Destroy()
    end
end

local function createToolESP(tool)
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ToolESP_" .. tool.Name
    billboard.Size = UDim2.new(0, 150, 0, 40)
    billboard.AlwaysOnTop = true
    billboard.Adornee = handle
    billboard.Parent = ToolESPFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(75, 255, 120)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Text = "Tool: " .. tool.Name
    label.Parent = billboard
end

local function refreshToolESP()
    clearToolESP()
    if not toggles.ToolESP then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            createToolESP(obj)
        end
    end
end

RunService.Heartbeat:Connect(function()
    refreshToolESP()
end)

-- Target Spam TP
RunService.Heartbeat:Connect(function(dt)
    if toggles.TargetSpamTP and targetSpamName then
        if tick() - lastTargetTP >= sliderValues.TargetTPDelay then
            lastTargetTP = tick()
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end

            local foundPlayer = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():sub(1, #targetSpamName) == targetSpamName:lower() or p.DisplayName:lower():sub(1, #targetSpamName) == targetSpamName:lower() then
                    foundPlayer = p
                    break
                end
            end

            if foundPlayer and foundPlayer.Character and foundPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = foundPlayer.Character.HumanoidRootPart
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)

                if toggles.AutoAlignToTarget then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetRoot.Position)
                end
            end
        end
    end
end)

-- FOV Lock
RunService.RenderStepped:Connect(function()
    if toggles.LockFOV then
        Camera.FieldOfView = sliderValues.CameraFOV
    end
end)

-- Camera Distance (Third person)
RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        local camPos = root.Position - Camera.CFrame.LookVector * sliderValues.CameraDistance
        Camera.CFrame = CFrame.new(camPos, root.Position)
    end
end)
