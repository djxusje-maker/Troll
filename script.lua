--[[
ULTIMATE UNIVERSAL SCRIPT - COMPLETE WITH ALL FEATURES
Part 1: Movement + Target + Teleport
- KILASIK Fling System
- Multi-target selection
- Sit On Head (button + click tool)
- Free Camera FIXED (player movable + joystick + up/down buttons)
- Jump Power
- Rename/Delete Positions
- Notification Queue
- Respawn-Safe Cleanup
- Floating Reopen Button
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- State
local flying = false
local noclip = false
local invisible = false
local clickTeleport = false
local freeCamera = false
local jumpPower = 50

local flySpeed = 50
local walkSpeed = 16

local flyConnection
local noclipConnection
local walkSpeedConnection
local freeCameraConnection
local jumpConnection

local flyAttachment
local flyVelocity
local flyOrientation
local freeCameraPosition
local freeCameraYaw = 0
local freeCameraPitch = 0

local teleportTool
local sitHeadTool
local sitHeadConnection
local sitHeadEnabled = false
local currentSitTarget = nil

local savedPositions = {}
local positionNames = {}
local originalCanCollide = {}
local originalTransparency = {}
local originalJumpPower = 50

-- Fling
local flingActive = false
local flingConnection = nil
local SelectedTargets = {}
local PlayerCheckboxes = {}
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- Anti-Fling
local antiFlingEnabled = false
local antiFlingConnection = nil

-- Spectate
local spectating = false

-- Highlight ESP
local highlightESP = false
local highlightColor = Color3.fromRGB(255, 0, 0)
local highlightObjects = {}
local colorIndex = 1
local espColors = {
    {name = "Red", color = Color3.fromRGB(255, 0, 0)},
    {name = "Green", color = Color3.fromRGB(0, 255, 0)},
    {name = "Blue", color = Color3.fromRGB(0, 150, 255)},
    {name = "Yellow", color = Color3.fromRGB(255, 255, 0)},
    {name = "Purple", color = Color3.fromRGB(150, 0, 255)}
}

-- Aim Assist
local aimAssistEnabled = false
local aimAssistConnection = nil
local aimTarget = nil
local aimSmoothness = 0.3
local showFOVCircle = false
local fovCircleSize = 200
local fovCircle = nil
local aimPart = "Head"
local aimMode = "Camera"

-- Kill Aura
local killAuraEnabled = false
local killAuraConnection = nil
local killAuraRange = 20

-- Fullbright
local fullbrightEnabled = false
local originalLighting = {}

-- Anti-Lag
local antiLagEnabled = false
local originalGraphics = {}
local originalEffects = {}

-- Animation
local currentAnimation = "Default"
local AnimationBundles = {
    "Default", "Ninja", "Robot", "Rthro", "Levitate", "Mage",
    "Stylish", "Hero", "Toy", "Astronaut", "Bubbly", "Cartoony",
    "Elder", "Ghost", "Knight", "Vampire", "Werewolf", "Zombie",
    "Bold", "Adidas", "Catwalk", "Walmart", "Wicked", "NFL",
    "Pirate", "Adidas2", "Oldschool", "Unboxed", "Aura",
    "Wicked2", "Ud", "Toilet", "Glow Motion"
}

local isMobile = UserInputService.TouchEnabled
local guiVisible = true
local toggleKey = Enum.KeyCode.RightControl

local Colors = {
    MainBackground = Color3.fromRGB(8, 8, 8),
    Sidebar = Color3.fromRGB(12, 12, 12),
    Panel = Color3.fromRGB(17, 17, 17),
    Button = Color3.fromRGB(22, 22, 22),
    ButtonHover = Color3.fromRGB(32, 32, 32),
    Selected = Color3.fromRGB(38, 38, 38),
    Border = Color3.fromRGB(65, 65, 65),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(175, 175, 175),
    ToggleOn = Color3.fromRGB(75, 75, 75),
    ToggleOff = Color3.fromRGB(28, 28, 28)
}

pcall(function()
    local old = CoreGui:FindFirstChild("UltimateUtilityGUI")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltimateUtilityGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Helpers
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function disconnect(conn)
    if conn then pcall(function() conn:Disconnect() end) end
    return nil
end

local function style(obj, radius, thickness)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = obj
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = Colors.Border
    stroke.Parent = obj
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart
    local startPos
    local dragInput

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
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

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Floating Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.fromOffset(50, 50)
ToggleBtn.Position = UDim2.fromOffset(10, 10)
ToggleBtn.BackgroundColor3 = Colors.Button
ToggleBtn.Text = "⚡"
ToggleBtn.TextColor3 = Colors.Text
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 20
ToggleBtn.Visible = false
ToggleBtn.Parent = ScreenGui
style(ToggleBtn, 25, 1)

-- Floating reopen button drag
local toggleDragging = false
local toggleStart = nil
local togglePos = nil

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleDragging = true
        toggleStart = input.Position
        togglePos = ToggleBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if toggleDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - toggleStart
        ToggleBtn.Position = UDim2.new(togglePos.X.Scale, togglePos.X.Offset + delta.X, togglePos.Y.Scale, togglePos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleDragging = false
    end
end)

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.fromOffset(isMobile and 350 or 400, isMobile and 560 or 600)
MainFrame.Position = UDim2.fromOffset(70, 10)
MainFrame.BackgroundColor3 = Colors.MainBackground
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
style(MainFrame, 12, 2)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Colors.Panel
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -50, 1, 0)
TitleText.Position = UDim2.fromOffset(10, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "⚡ ULTIMATE UTILITY"
TitleText.TextColor3 = Colors.Text
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = isMobile and 16 or 18
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(30, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Colors.Button
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Colors.Text
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TitleBar
style(CloseBtn, 15, 1)

makeDraggable(MainFrame, TitleBar)

-- Sidebar
local SidebarWidth = isMobile and 90 or 105

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, SidebarWidth, 1, -40)
Sidebar.Position = UDim2.fromOffset(0, 40)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -SidebarWidth, 1, -40)
ContentFrame.Position = UDim2.new(0, SidebarWidth, 0, 40)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local TabNames = {"Movement", "Target", "Teleport", "Server", "Animation", "Visuals"}
local TabIcons = {"🏃", "🎯", "📍", "🌐", "🎭", "👁️"}
local Tabs = {}
local Pages = {}

for i, tabName in ipairs(TabNames) do
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, -10, 0, 43)
    TabBtn.Position = UDim2.fromOffset(5, 8 + (i - 1) * 48)
    TabBtn.BackgroundColor3 = i == 1 and Colors.Selected or Colors.Button
    TabBtn.Text = TabIcons[i] .. " " .. tabName
    TabBtn.TextColor3 = Colors.Text
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextSize = isMobile and 8 or 10
    TabBtn.AutoButtonColor = false
    TabBtn.Parent = Sidebar
    style(TabBtn, 7, 1)
    Tabs[i] = TabBtn

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.fromScale(1, 1)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = isMobile and 4 or 6
    Page.ScrollBarImageColor3 = Colors.TextSecondary
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.fromOffset(0, 0)
    Page.Visible = i == 1
    Page.Parent = ContentFrame
    Pages[i] = Page

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = Page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = Page
end

local function switchTab(index)
    for i, page in ipairs(Pages) do
        page.Visible = i == index
        Tabs[i].BackgroundColor3 = i == index and Colors.Selected or Colors.Button
    end
end

for i, tab in ipairs(Tabs) do
    tab.Activated:Connect(function() switchTab(i) end)
end

-- Component builders
local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, isMobile and 42 or 36)
    btn.BackgroundColor3 = Colors.Button
    btn.Text = text
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = isMobile and 12 or 13
    btn.AutoButtonColor = false
    btn.Parent = parent
    style(btn, 8, 1)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Colors.ButtonHover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Colors.Button end)
    btn.Activated:Connect(callback)
    return btn
end

local function CreateToggle(parent, text, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, isMobile and 45 or 40)
    frame.BackgroundColor3 = Colors.Panel
    frame.Parent = parent
    style(frame, 8, 1)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = isMobile and 11 or 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.fromOffset(42, 23)
    toggle.Position = UDim2.new(1, -52, 0.5, -11)
    toggle.BackgroundColor3 = Colors.ToggleOff
    toggle.Text = "OFF"
    toggle.TextColor3 = Colors.Text
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 9
    toggle.AutoButtonColor = false
    toggle.Parent = frame
    style(toggle, 11, 1)
    local state = false
    toggle.Activated:Connect(function()
        state = not state
        toggle.Text = state and "ON" or "OFF"
        toggle.BackgroundColor3 = state and Colors.ToggleOn or Colors.ToggleOff
        callback(state)
    end)
    return frame
end

-- Notification Queue (multiple notifications)
local NotificationHolder = Instance.new("Frame")
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Size = UDim2.fromOffset(280, 200)
NotificationHolder.AnchorPoint = Vector2.new(0.5, 0)
NotificationHolder.Position = UDim2.new(0.5, 0, 0, 10)
NotificationHolder.Parent = ScreenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0, 4)
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notifLayout.Parent = NotificationHolder

local function notify(text)
    local notification = Instance.new("TextLabel")
    notification.Size = UDim2.fromOffset(260, 36)
    notification.BackgroundColor3 = Colors.Panel
    notification.Text = text
    notification.TextColor3 = Colors.Text
    notification.Font = Enum.Font.GothamBold
    notification.TextSize = 12
    notification.Parent = NotificationHolder
    style(notification, 8, 1)
    task.delay(2.5, function()
        if notification.Parent then notification:Destroy() end
    end)
end

-- ============================================================
-- WALK SPEED
-- ============================================================

local function ApplyWalkSpeed()
    local hum = getHumanoid(LocalPlayer.Character)
    if hum and hum.Health > 0 then hum.WalkSpeed = walkSpeed end
end

local function SetWalkSpeed(value)
    value = tonumber(value)
    if not value then return false end
    walkSpeed = math.clamp(math.floor(value + 0.5), 1, 500)
    ApplyWalkSpeed()
    return true
end

walkSpeedConnection = RunService.Heartbeat:Connect(function()
    if not flying then ApplyWalkSpeed() end
end)

-- ============================================================
-- JUMP POWER
-- ============================================================

local function ApplyJumpPower()
    local hum = getHumanoid(LocalPlayer.Character)
    if hum and hum.Health > 0 then
        hum.JumpPower = jumpPower
        hum.UseJumpPower = true
    end
end

local function SetJumpPower(value)
    value = tonumber(value)
    if not value then return false end
    jumpPower = math.clamp(math.floor(value + 0.5), 1, 500)
    ApplyJumpPower()
    return true
end

jumpConnection = RunService.Heartbeat:Connect(function()
    if not flying then ApplyJumpPower() end
end)

-- ============================================================
-- NOCLIP
-- ============================================================

local function EnableNoclip()
    noclip = true
    noclipConnection = disconnect(noclipConnection)
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclip then return end
        local character = LocalPlayer.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if originalCanCollide[part] == nil then originalCanCollide[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
    end)
end

local function DisableNoclip()
    noclip = false
    noclipConnection = disconnect(noclipConnection)
    for part, value in pairs(originalCanCollide) do
        if part and part.Parent then part.CanCollide = value end
    end
    table.clear(originalCanCollide)
end

-- ============================================================
-- FLY SYSTEM
-- ============================================================

local function destroyFlyObjects()
    if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
    if flyOrientation then flyOrientation:Destroy(); flyOrientation = nil end
    if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end
end

local function DisableFly()
    flying = false
    flyConnection = disconnect(flyConnection)
    destroyFlyObjects()
    local character = LocalPlayer.Character
    local humanoid = getHumanoid(character)
    if humanoid and humanoid.Health > 0 then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        humanoid.WalkSpeed = walkSpeed
    end
end

local function EnableFly()
    DisableFly()
    local character = LocalPlayer.Character
    local humanoid = getHumanoid(character)
    local root = getRoot(character)
    if not character or not humanoid or not root or humanoid.Health <= 0 then notify("Character not ready") return end
    flying = true
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    flyAttachment = Instance.new("Attachment")
    flyAttachment.Name = "UtilityFlyAttachment"
    flyAttachment.Parent = root
    flyVelocity = Instance.new("LinearVelocity")
    flyVelocity.Name = "UtilityFlyVelocity"
    flyVelocity.Attachment0 = flyAttachment
    flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    flyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    flyVelocity.ForceLimitsEnabled = false
    flyVelocity.VectorVelocity = Vector3.zero
    flyVelocity.Parent = root
    flyOrientation = Instance.new("AlignOrientation")
    flyOrientation.Name = "UtilityFlyOrientation"
    flyOrientation.Attachment0 = flyAttachment
    flyOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    flyOrientation.RigidityEnabled = false
    flyOrientation.Responsiveness = 35
    flyOrientation.MaxTorque = math.huge
    flyOrientation.Parent = root
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flying then return end
        if LocalPlayer.Character ~= character or not root.Parent or humanoid.Health <= 0 then DisableFly() return end
        local move = humanoid.MoveDirection
        local horizontal = Vector3.new(move.X, 0, move.Z)
        local cameraLook = Camera.CFrame.LookVector
        local cameraRight = Camera.CFrame.RightVector
        local flatLook = Vector3.new(cameraLook.X, 0, cameraLook.Z)
        local flatRight = Vector3.new(cameraRight.X, 0, cameraRight.Z)
        if flatLook.Magnitude < 0.001 then flatLook = Vector3.new(0, 0, -1) else flatLook = flatLook.Unit end
        if flatRight.Magnitude < 0.001 then flatRight = Vector3.new(1, 0, 0) else flatRight = flatRight.Unit end
        local desired = Vector3.zero
        if horizontal.Magnitude > 0.03 then
            local worldMove = horizontal.Unit
            local forwardAmount = worldMove:Dot(flatLook)
            local rightAmount = worldMove:Dot(flatRight)
            desired = cameraLook * forwardAmount + flatRight * rightAmount
            if desired.Magnitude > 0.001 then desired = desired.Unit * math.min(horizontal.Magnitude, 1) * flySpeed else desired = Vector3.zero end
        end
        flyVelocity.VectorVelocity = desired
        if desired.Magnitude > 0.05 then flyOrientation.CFrame = CFrame.lookAt(root.Position, root.Position + desired.Unit) end
    end)
    notify("3D Fly ON")
end

CreateToggle(Pages[1], "Fly Mode", function(on) if on then EnableFly() else DisableFly() end end)
CreateToggle(Pages[1], "Noclip", function(on) if on then EnableNoclip() else DisableNoclip() end end)

-- Walk Speed Input
local WalkLabel = Instance.new("TextLabel")
WalkLabel.Size = UDim2.new(1, 0, 0, 20)
WalkLabel.BackgroundTransparency = 1
WalkLabel.Text = "Walk Speed: 16"
WalkLabel.TextColor3 = Colors.TextSecondary
WalkLabel.Font = Enum.Font.Gotham
WalkLabel.TextSize = 11
WalkLabel.TextXAlignment = Enum.TextXAlignment.Left
WalkLabel.Parent = Pages[1]

local WalkInput = Instance.new("TextBox")
WalkInput.Size = UDim2.new(1, 0, 0, 32)
WalkInput.BackgroundColor3 = Colors.Panel
WalkInput.Text = "16"
WalkInput.TextColor3 = Colors.Text
WalkInput.PlaceholderText = "1 - 500"
WalkInput.Font = Enum.Font.Gotham
WalkInput.TextSize = 12
WalkInput.ClearTextOnFocus = false
WalkInput.Parent = Pages[1]
style(WalkInput, 7, 1)

WalkInput.FocusLost:Connect(function()
    local value = tonumber(WalkInput.Text)
    if SetWalkSpeed(value) then WalkInput.Text = tostring(walkSpeed); WalkLabel.Text = "Walk Speed: " .. walkSpeed else WalkInput.Text = tostring(walkSpeed) end
end)

-- Jump Power Input
local JumpLabel = Instance.new("TextLabel")
JumpLabel.Size = UDim2.new(1, 0, 0, 20)
JumpLabel.BackgroundTransparency = 1
JumpLabel.Text = "Jump Power: 50"
JumpLabel.TextColor3 = Colors.TextSecondary
JumpLabel.Font = Enum.Font.Gotham
JumpLabel.TextSize = 11
JumpLabel.TextXAlignment = Enum.TextXAlignment.Left
JumpLabel.Parent = Pages[1]

local JumpInput = Instance.new("TextBox")
JumpInput.Size = UDim2.new(1, 0, 0, 32)
JumpInput.BackgroundColor3 = Colors.Panel
JumpInput.Text = "50"
JumpInput.TextColor3 = Colors.Text
JumpInput.PlaceholderText = "1 - 500"
JumpInput.Font = Enum.Font.Gotham
JumpInput.TextSize = 12
JumpInput.ClearTextOnFocus = false
JumpInput.Parent = Pages[1]
style(JumpInput, 7, 1)

JumpInput.FocusLost:Connect(function()
    local value = tonumber(JumpInput.Text)
    if SetJumpPower(value) then JumpInput.Text = tostring(jumpPower); JumpLabel.Text = "Jump Power: " .. jumpPower else JumpInput.Text = tostring(jumpPower) end
end)

-- Fly Speed Input
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, 0, 0, 20)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Fly Speed: 50"
SpeedLabel.TextColor3 = Colors.TextSecondary
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextSize = 11
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = Pages[1]

local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(1, 0, 0, 32)
SpeedInput.BackgroundColor3 = Colors.Panel
SpeedInput.Text = "50"
SpeedInput.TextColor3 = Colors.Text
SpeedInput.PlaceholderText = "10 - 500"
SpeedInput.Font = Enum.Font.Gotham
SpeedInput.TextSize = 12
SpeedInput.ClearTextOnFocus = false
SpeedInput.Parent = Pages[1]
style(SpeedInput, 7, 1)

SpeedInput.FocusLost:Connect(function()
    local value = tonumber(SpeedInput.Text)
    if value then flySpeed = math.clamp(math.floor(value + 0.5), 10, 500); SpeedInput.Text = tostring(flySpeed); SpeedLabel.Text = "Fly Speed: " .. flySpeed else SpeedInput.Text = tostring(flySpeed) end
end)

-- ============================================================
-- FREE CAMERA (FIXED - Player movable by physics + joystick + up/down buttons)
-- ============================================================

local freecamUpBtn, freecamDownBtn
local freecamMoveDir = Vector3.zero

local function StopFreeCamera()
    freeCamera = false
    freeCameraConnection = disconnect(freeCameraConnection)
    Camera.CameraType = Enum.CameraType.Custom
    local humanoid = getHumanoid(LocalPlayer.Character)
    if humanoid then Camera.CameraSubject = humanoid end
    if freecamUpBtn then freecamUpBtn.Visible = false end
    if freecamDownBtn then freecamDownBtn.Visible = false end
end

local function StartFreeCamera()
    if freeCamera then return end
    freeCamera = true
    Camera.CameraType = Enum.CameraType.Scriptable
    local cf = Camera.CFrame
    freeCameraPosition = cf.Position
    local look = cf.LookVector
    freeCameraYaw = math.atan2(-look.X, -look.Z)
    freeCameraPitch = math.asin(math.clamp(look.Y, -1, 1))
    
    -- Show up/down buttons
    if not freecamUpBtn then
        freecamUpBtn = Instance.new("TextButton")
        freecamUpBtn.Size = UDim2.fromOffset(50, 50)
        freecamUpBtn.Position = UDim2.new(0, 20, 0.5, -60)
        freecamUpBtn.BackgroundColor3 = Colors.Button
        freecamUpBtn.Text = "⬆"
        freecamUpBtn.TextColor3 = Colors.Text
        freecamUpBtn.Font = Enum.Font.GothamBold
        freecamUpBtn.TextSize = 24
        freecamUpBtn.Parent = ScreenGui
        style(freecamUpBtn, 25, 1)
        
        freecamDownBtn = Instance.new("TextButton")
        freecamDownBtn.Size = UDim2.fromOffset(50, 50)
        freecamDownBtn.Position = UDim2.new(0, 20, 0.5, 20)
        freecamDownBtn.BackgroundColor3 = Colors.Button
        freecamDownBtn.Text = "⬇"
        freecamDownBtn.TextColor3 = Colors.Text
        freecamDownBtn.Font = Enum.Font.GothamBold
        freecamDownBtn.TextSize = 24
        freecamDownBtn.Parent = ScreenGui
        style(freecamDownBtn, 25, 1)
    end
    freecamUpBtn.Visible = true
    freecamDownBtn.Visible = true
    
    freeCameraConnection = RunService.RenderStepped:Connect(function(dt)
        if not freeCamera then return end
        local rotation = CFrame.Angles(0, freeCameraYaw, 0) * CFrame.Angles(freeCameraPitch, 0, 0)
        local lookVector = rotation.LookVector
        local rightVector = rotation.RightVector
        
        -- Movement from humanoid (WASD/joystick) - player still moves!
        local humanoid = getHumanoid(LocalPlayer.Character)
        local move = humanoid and humanoid.MoveDirection or Vector3.zero
        local forward = Vector3.new(lookVector.X, 0, lookVector.Z)
        local right = Vector3.new(rightVector.X, 0, rightVector.Z)
        
        if forward.Magnitude > 0.001 then forward = forward.Unit end
        if right.Magnitude > 0.001 then right = right.Unit end
        
        local movement = (forward * move.Z + right * move.X) * 50 * dt
        
        -- Up/Down from buttons
        if freecamUpBtn and freecamUpBtn.Pressed then
            movement = movement + Vector3.new(0, 50 * dt, 0)
        end
        if freecamDownBtn and freecamDownBtn.Pressed then
            movement = movement - Vector3.new(0, 50 * dt, 0)
        end
        
        freeCameraPosition = freeCameraPosition + movement
        Camera.CFrame = CFrame.lookAt(freeCameraPosition, freeCameraPosition + lookVector, Vector3.yAxis)
    end)
end

-- Mouse look for freecam
UserInputService.InputChanged:Connect(function(input)
    if not freeCamera then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
        local delta = UserInputService:GetMouseDelta()
        freeCameraYaw = freeCameraYaw - delta.X * 0.003
        freeCameraPitch = math.clamp(freeCameraPitch - delta.Y * 0.003, -1.45, 1.45)
    end
    -- Touch look
    if input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Delta
        freeCameraYaw = freeCameraYaw - delta.X * 0.005
        freeCameraPitch = math.clamp(freeCameraPitch - delta.Y * 0.005, -1.45, 1.45)
    end
end)

CreateToggle(Pages[1], "Free Camera", function(on) if on then StartFreeCamera() else StopFreeCamera() end end)

-- ============================================================
-- INVISIBLE (with name tag hiding)
-- ============================================================

local function SetInvisible(on)
    invisible = on
    local character = LocalPlayer.Character
    if not character then return end
    if on then
        for _, obj in ipairs(character:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Decal") or obj:IsA("Texture") then
                if originalTransparency[obj] == nil then originalTransparency[obj] = obj.Transparency end
                obj.Transparency = 1
            elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
                if originalTransparency[obj] == nil then originalTransparency[obj] = {Enabled = obj.Enabled} end
                obj.Enabled = false
            end
        end
        local hum = getHumanoid(character)
        if hum then
            originalTransparency[hum] = {
                NameDisplayDistance = hum.NameDisplayDistance,
                HealthDisplayDistance = hum.HealthDisplayDistance,
                DisplayDistanceType = hum.DisplayDistanceType
            }
            hum.NameDisplayDistance = 0
            hum.HealthDisplayDistance = 0
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
        notify("👻 Invisible ON")
    else
        for obj, value in pairs(originalTransparency) do
            if obj and obj.Parent then
                if type(value) == "table" then
                    for k, v in pairs(value) do
                        pcall(function() obj[k] = v end)
                    end
                else
                    pcall(function() obj.Transparency = value end)
                end
            end
        end
        table.clear(originalTransparency)
        notify("Invisible OFF")
    end
end

CreateToggle(Pages[1], "Invisible", SetInvisible)

-- ============================================================
-- CLICK TP TOOL
-- ============================================================

local function RemoveTeleportTool()
    if teleportTool then teleportTool:Destroy(); teleportTool = nil end
end

local function GiveTeleportTool()
    RemoveTeleportTool()
    teleportTool = Instance.new("Tool")
    teleportTool.Name = "ClickTPTool"
    teleportTool.RequiresHandle = false
    teleportTool.CanBeDropped = false
    teleportTool.Parent = LocalPlayer.Backpack
    teleportTool.Activated:Connect(function()
        if not clickTeleport then return end
        local mouse = LocalPlayer:GetMouse()
        local ray = Camera:ScreenPointToRay(mouse.X, mouse.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        local root = getRoot(LocalPlayer.Character)
        if result and root then root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
    end)
end

CreateToggle(Pages[1], "Click TP Tool", function(on)
    clickTeleport = on
    if on then GiveTeleportTool() else RemoveTeleportTool() end
end)

-- ============================================================
-- TARGET TAB - KILASIK FLING + SIT ON HEAD
-- ============================================================

local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Size = UDim2.new(1, 0, 0, 160)
PlayerListFrame.BackgroundColor3 = Colors.Panel
PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.ScrollBarThickness = 4
PlayerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerListFrame.CanvasSize = UDim2.fromOffset(0, 0)
PlayerListFrame.LayoutOrder = 1
PlayerListFrame.Parent = Pages[2]
style(PlayerListFrame, 10, 1)

local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 4)
playerLayout.SortOrder = Enum.SortOrder.Name
playerLayout.Parent = PlayerListFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, 0, 0, 32)
SearchBox.BackgroundColor3 = Colors.Panel
SearchBox.Text = ""
SearchBox.PlaceholderText = "🔍 Search players..."
SearchBox.TextColor3 = Colors.Text
SearchBox.PlaceholderColor3 = Colors.TextSecondary
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.ClearTextOnFocus = false
SearchBox.LayoutOrder = 2
SearchBox.Parent = Pages[2]
style(SearchBox, 10, 1)

local TargetStatus = Instance.new("TextLabel")
TargetStatus.Size = UDim2.new(1, 0, 0, 25)
TargetStatus.BackgroundTransparency = 1
TargetStatus.Text = "👥 0 targets selected"
TargetStatus.TextColor3 = Colors.TextSecondary
TargetStatus.Font = Enum.Font.Gotham
TargetStatus.TextSize = 11
TargetStatus.TextXAlignment = Enum.TextXAlignment.Left
TargetStatus.LayoutOrder = 3
TargetStatus.Parent = Pages[2]

local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, 0, 0, 180)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.LayoutOrder = 4
ButtonContainer.Parent = Pages[2]

local ButtonGrid = Instance.new("UIGridLayout")
ButtonGrid.CellSize = UDim2.new(0.47, 0, 0, 28)
ButtonGrid.CellPadding = UDim2.new(0, 6, 0, 4)
ButtonGrid.SortOrder = Enum.SortOrder.LayoutOrder
ButtonGrid.Parent = ButtonContainer

local function CreateCleanButton(text, callback, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = color or Colors.Button
    btn.Text = text
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.AutoButtonColor = false
    btn.Parent = ButtonContainer
    style(btn, 6, 1)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Colors.ButtonHover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = color or Colors.Button end)
    btn.Activated:Connect(callback)
    return btn
end

local function UpdateTargetStatus()
    local count = 0
    for _ in pairs(SelectedTargets) do
        count = count + 1
    end
    TargetStatus.Text = "👥 " .. count .. " target(s) selected"
    TargetStatus.TextColor3 = count > 0 and Color3.fromRGB(100, 255, 100) or Colors.TextSecondary
end

local function RefreshPlayerList()
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    PlayerCheckboxes = {}

    local query = string.lower(SearchBox.Text)
    local PlayerList = Players:GetPlayers()
    table.sort(PlayerList, function(a, b) return a.Name:lower() < b.Name:lower() end)

    for _, player in ipairs(PlayerList) do
        if player ~= LocalPlayer then
            local matches = query == "" or string.find(string.lower(player.Name), query, 1, true) or string.find(string.lower(player.DisplayName), query, 1, true)
            if matches then
                local playerBtn = Instance.new("TextButton")
                playerBtn.Size = UDim2.new(1, -6, 0, 35)
                playerBtn.BackgroundColor3 = SelectedTargets[player] and Colors.Selected or Colors.Button
                playerBtn.Text = ""
                playerBtn.AutoButtonColor = false
                playerBtn.Parent = PlayerListFrame
                style(playerBtn, 8, 1)

                local thumbnail = Instance.new("ImageLabel")
                thumbnail.Size = UDim2.fromOffset(28, 28)
                thumbnail.Position = UDim2.fromOffset(4, 3.5)
                thumbnail.BackgroundTransparency = 1
                thumbnail.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=48&height=48&format=png"
                thumbnail.Parent = playerBtn
                local thumbCorner = Instance.new("UICorner")
                thumbCorner.CornerRadius = UDim.new(0, 14)
                thumbCorner.Parent = thumbnail

                local Checkmark = Instance.new("TextLabel")
                Checkmark.Size = UDim2.fromOffset(20, 20)
                Checkmark.Position = UDim2.new(1, -26, 0, 7.5)
                Checkmark.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
                Checkmark.Text = "✓"
                Checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
                Checkmark.Font = Enum.Font.GothamBold
                Checkmark.TextSize = 13
                Checkmark.Visible = SelectedTargets[player] ~= nil
                Checkmark.Parent = playerBtn
                style(Checkmark, 10, 0)

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -65, 1, 0)
                nameLabel.Position = UDim2.fromOffset(38, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = player.DisplayName
                nameLabel.TextColor3 = Colors.Text
                nameLabel.Font = Enum.Font.Gotham
                nameLabel.TextSize = 12
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = playerBtn

                playerBtn.Activated:Connect(function()
                    if SelectedTargets[player] then
                        SelectedTargets[player] = nil
                        Checkmark.Visible = false
                        playerBtn.BackgroundColor3 = Colors.Button
                    else
                        SelectedTargets[player] = player
                        Checkmark.Visible = true
                        playerBtn.BackgroundColor3 = Colors.Selected
                    end
                    UpdateTargetStatus()
                end)

                PlayerCheckboxes[player] = {
                    Button = playerBtn,
                    Checkmark = Checkmark
                }
            end
        end
    end
    UpdateTargetStatus()
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(RefreshPlayerList)

-- ============================================================
-- KILASIK FLING SYSTEM
-- ============================================================

local function SkidFling(TargetPlayer)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end

    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end

        if THumanoid and THumanoid.Sit then
            notify(TargetPlayer.Name .. " is sitting")
            return
        end

        if TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        elseif THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        end

        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end

        local function FPos(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e9, 9e9, 9e9)
        end

        local function SFBasePart(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid then
                    Angle = Angle + 200

                    if BasePart.Velocity.Magnitude < 50 then
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed * 2), CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed * 2), CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed * 2), CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                end
            until Time + TimeToWait < tick() or not flingActive
        end

        workspace.FallenPartsDestroyHeight = 0/0

        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

        if TRootPart then
            SFBasePart(TRootPart)
        elseif THead then
            SFBasePart(THead)
        elseif Handle then
            SFBasePart(Handle)
        else
            notify(TargetPlayer.Name .. " has no valid parts")
            return
        end

        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid

        if getgenv().OldPos then
            repeat
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
                task.wait()
            until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
            workspace.FallenPartsDestroyHeight = getgenv().FPDH
        end
    else
        notify("Your character is not ready")
    end
end

local function StartFling()
    if flingActive then notify("Fling already active!") return end
    local count = 0
    for _ in pairs(SelectedTargets) do count = count + 1 end
    if count == 0 then notify("Select at least one target first!") return end
    flingActive = true
    notify("🌀 Flinging " .. count .. " target(s)!")
    flingConnection = task.spawn(function()
        while flingActive do
            local validTargets = {}
            for player in pairs(SelectedTargets) do
                if player and player.Parent and player.Character then
                    validTargets[player] = player
                else
                    SelectedTargets[player] = nil
                    local checkbox = PlayerCheckboxes[player]
                    if checkbox then
                        checkbox.Checkmark.Visible = false
                        checkbox.Button.BackgroundColor3 = Colors.Button
                    end
                end
            end
            for player in pairs(validTargets) do
                if flingActive then
                    SkidFling(player)
                    task.wait(0.1)
                else
                    break
                end
            end
            task.wait(0.5)
        end
    end)
end

local function StopFling()
    flingActive = false
    if flingConnection then task.cancel(flingConnection); flingConnection = nil end
    notify("⏹️ Fling stopped")
end

-- ============================================================
-- SIT ON HEAD (Mode 1: Target button)
-- ============================================================

local function SitOnHead(targetPlayer)
    if not targetPlayer then return end
    local myChar = LocalPlayer.Character
    local myRoot = getRoot(myChar)
    local myHum = getHumanoid(myChar)
    local targetChar = targetPlayer.Character
    local targetHead = targetChar and targetChar:FindFirstChild("Head")
    
    if not myRoot or not myHum or not targetHead then
        notify("Cannot sit - missing parts")
        return
    end
    
    -- Freeze player on head
    myHum.PlatformStand = true
    myRoot.CFrame = targetHead.CFrame * CFrame.new(0, 2, 0)
    myRoot.Anchored = true
    
    currentSitTarget = targetPlayer
    sitHeadEnabled = true
    
    -- Follow target
    sitHeadConnection = disconnect(sitHeadConnection)
    sitHeadConnection = RunService.RenderStepped:Connect(function()
        if not sitHeadEnabled or not currentSitTarget then return end
        local tChar = currentSitTarget.Character
        local tHead = tChar and tChar:FindFirstChild("Head")
        local root = getRoot(LocalPlayer.Character)
        if tHead and root then
            root.CFrame = tHead.CFrame * CFrame.new(0, 2, 0)
        end
    end)
    
    notify("🎯 Sitting on " .. targetPlayer.Name)
end

local function UnsitFromHead()
    sitHeadEnabled = false
    currentSitTarget = nil
    sitHeadConnection = disconnect(sitHeadConnection)
    local root = getRoot(LocalPlayer.Character)
    local hum = getHumanoid(LocalPlayer.Character)
    if root then root.Anchored = false end
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    notify("Stopped sitting")
end

-- ============================================================
-- SIT ON HEAD TOOL (Mode 2: Click tool)
-- ============================================================

local function RemoveSitHeadTool()
    if sitHeadTool then sitHeadTool:Destroy(); sitHeadTool = nil end
end

local function GiveSitHeadTool()
    RemoveSitHeadTool()
    sitHeadTool = Instance.new("Tool")
    sitHeadTool.Name = "SitHeadTool"
    sitHeadTool.RequiresHandle = false
    sitHeadTool.CanBeDropped = false
    sitHeadTool.Parent = LocalPlayer.Backpack
    sitHeadTool.Activated:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        local target = mouse.Target
        if not target then notify("No target") return end
        
        -- Find player
        local char = target.Parent
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then
            char = target.Parent.Parent
            hum = char and char:FindFirstChildOfClass("Humanoid")
        end
        
        if not hum then notify("Not a player") return end
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character == char then
                SitOnHead(plr)
                return
            end
        end
        notify("Player not found")
    end)
end

-- ============================================================
-- ANTI-FLING
-- ============================================================

local function DisableAntiFling()
    antiFlingEnabled = false
    antiFlingConnection = disconnect(antiFlingConnection)
    local root = getRoot(LocalPlayer.Character)
    if root then pcall(function() root.CustomPhysicalProperties = nil end) end
end

local function EnableAntiFling()
    DisableAntiFling()
    antiFlingEnabled = true
    local root = getRoot(LocalPlayer.Character)
    if not root then notify("Character not ready") return end
    pcall(function() root.CustomPhysicalProperties = PhysicalProperties.new(500, 0.3, 0.5, 500, 500) end)
    antiFlingConnection = RunService.RenderStepped:Connect(function()
        if not antiFlingEnabled then return end
        local currentRoot = getRoot(LocalPlayer.Character)
        if not currentRoot then DisableAntiFling() return end
        if currentRoot.AssemblyLinearVelocity.Magnitude > 200 then currentRoot.AssemblyLinearVelocity = Vector3.zero end
        if currentRoot.AssemblyAngularVelocity.Magnitude > 80 then currentRoot.AssemblyAngularVelocity = Vector3.zero end
    end)
    notify("🛡️ Anti-Fling ON")
end

-- ============================================================
-- SPECTATE
-- ============================================================

local function ToggleSpectate()
    local target = nil
    for player in pairs(SelectedTargets) do target = player; break end
    if not target then notify("Select a target first!") return end
    if spectating then
        spectating = false
        local humanoid = getHumanoid(LocalPlayer.Character)
        if humanoid then Camera.CameraType = Enum.CameraType.Custom; Camera.CameraSubject = humanoid end
        notify("Spectate OFF")
    else
        local targetHumanoid = getHumanoid(target.Character)
        if not targetHumanoid then notify("Target not ready") return end
        spectating = true
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = targetHumanoid
        notify("👁️ Spectating: " .. target.Name)
    end
end

-- ============================================================
-- TARGET BUTTONS
-- ============================================================

CreateCleanButton("🔄 Refresh", RefreshPlayerList)
CreateCleanButton("🌀 FLING", StartFling, Color3.fromRGB(0, 150, 70))
CreateCleanButton("⏹️ STOP", StopFling, Color3.fromRGB(150, 25, 25))
CreateCleanButton("✅ Select All", function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            SelectedTargets[player] = player
            local checkbox = PlayerCheckboxes[player]
            if checkbox then
                checkbox.Checkmark.Visible = true
                checkbox.Button.BackgroundColor3 = Colors.Selected
            end
        end
    end
    UpdateTargetStatus()
end)
CreateCleanButton("❌ Deselect", function()
    table.clear(SelectedTargets)
    for _, checkbox in pairs(PlayerCheckboxes) do
        checkbox.Checkmark.Visible = false
        checkbox.Button.BackgroundColor3 = Colors.Button
    end
    UpdateTargetStatus()
end)

local AntiFlingBtn = CreateCleanButton("🛡️ Anti OFF", function()
    if antiFlingEnabled then
        DisableAntiFling()
        AntiFlingBtn.Text = "🛡️ Anti OFF"
        AntiFlingBtn.BackgroundColor3 = Colors.Button
    else
        EnableAntiFling()
        AntiFlingBtn.Text = "🛡️ Anti ON"
        AntiFlingBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    end
end)

CreateCleanButton("👁️ Spectate", ToggleSpectate)
CreateCleanButton("📍 Teleport", function()
    local target = nil
    for player in pairs(SelectedTargets) do target = player; break end
    if not target then notify("Select a target first!") return end
    local root = getRoot(LocalPlayer.Character)
    local targetRoot = getRoot(target.Character)
    if not root or not targetRoot then notify("Character not ready!") return end
    root.CFrame = targetRoot.CFrame * CFrame.new(0, 3, 0)
    notify("Teleported to " .. target.Name)
end)
CreateCleanButton("🎯 Sit On Head", function()
    local target = nil
    for player in pairs(SelectedTargets) do target = player; break end
    if not target then notify("Select a target first!") return end
    SitOnHead(target)
end)
CreateCleanButton("❌ Unsit", UnsitFromHead, Color3.fromRGB(150, 25, 25))
CreateCleanButton("🎯 Sit Tool", function()
    GiveSitHeadTool()
    notify("Sit Tool given - click a player")
end)
CreateCleanButton("❌ Clear", function()
    table.clear(SelectedTargets)
    for _, checkbox in pairs(PlayerCheckboxes) do
        checkbox.Checkmark.Visible = false
        checkbox.Button.BackgroundColor3 = Colors.Button
    end
    UpdateTargetStatus()
    notify("Targets cleared")
end)

-- ============================================================
-- TELEPORT TAB
-- ============================================================

CreateButton(Pages[3], "Save Position", function()
    local root = getRoot(LocalPlayer.Character)
    if not root then return end
    table.insert(savedPositions, root.Position)
    local index = #savedPositions
    positionNames[index] = "Position " .. index
    
    local posFrame = Instance.new("Frame")
    posFrame.Size = UDim2.new(1, 0, 0, 36)
    posFrame.BackgroundColor3 = Colors.Panel
    posFrame.LayoutOrder = index + 10
    posFrame.Parent = Pages[3]
    style(posFrame, 6, 1)
    
    local nameInput = Instance.new("TextBox")
    nameInput.Size = UDim2.new(0.5, -5, 1, 0)
    nameInput.BackgroundTransparency = 1
    nameInput.Text = positionNames[index]
    nameInput.TextColor3 = Colors.Text
    nameInput.Font = Enum.Font.Gotham
    nameInput.TextSize = 11
    nameInput.ClearTextOnFocus = false
    nameInput.Parent = posFrame
    
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0.25, -3, 1, 0)
    tpBtn.Position = UDim2.new(0.5, 2, 0, 0)
    tpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
    tpBtn.Text = "Go"
    tpBtn.TextColor3 = Colors.Text
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 10
    tpBtn.Parent = posFrame
    style(tpBtn, 5, 1)
    
    local delBtn = Instance.new("TextButton")
    delBtn.Size = UDim2.new(0.25, -3, 1, 0)
    delBtn.Position = UDim2.new(0.75, 3, 0, 0)
    delBtn.BackgroundColor3 = Color3.fromRGB(150, 25, 25)
    delBtn.Text = "X"
    delBtn.TextColor3 = Colors.Text
    delBtn.Font = Enum.Font.GothamBold
    delBtn.TextSize = 10
    delBtn.Parent = posFrame
    style(delBtn, 5, 1)
    
    tpBtn.Activated:Connect(function()
        local currentRoot = getRoot(LocalPlayer.Character)
        if currentRoot and savedPositions[index] then
            currentRoot.CFrame = CFrame.new(savedPositions[index])
        end
    end)
    
    delBtn.Activated:Connect(function()
        savedPositions[index] = nil
        positionNames[index] = nil
        posFrame:Destroy()
        notify("Position deleted")
    end)
    
    notify("Saved: " .. positionNames[index])
end)

CreateButton(Pages[3], "Clear All Positions", function()
    table.clear(savedPositions)
    table.clear(positionNames)
    for _, child in ipairs(Pages[3]:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChildOfClass("TextBox") then
            child:Destroy()
        end
    end
    notify("All positions cleared")
end)

-- ============================================================
-- GUI INPUT
-- ============================================================

local function SetGuiVisible(value)
    guiVisible = value
    MainFrame.Visible = value
    ToggleBtn.Visible = not value
end

CloseBtn.Activated:Connect(function() SetGuiVisible(false) end)
ToggleBtn.Activated:Connect(function() SetGuiVisible(true) end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == toggleKey then SetGuiVisible(not guiVisible) end
end)

-- ============================================================
-- RESPAWN-SAFE CLEANUP
-- ============================================================

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.75)
    table.clear(originalCanCollide)
    table.clear(originalTransparency)
    if invisible then SetInvisible(true) end
    if noclip then EnableNoclip() end
    ApplyWalkSpeed()
    ApplyJumpPower()
    if clickTeleport then GiveTeleportTool() end
    if freeCamera then StopFreeCamera() end
    if flingActive then StopFling() end
    if sitHeadEnabled then UnsitFromHead() end
end)

Players.PlayerAdded:Connect(function() RefreshPlayerList() end)
Players.PlayerRemoving:Connect(function(player)
    if SelectedTargets[player] then SelectedTargets[player] = nil end
    if currentSitTarget == player then UnsitFromHead() end
    RefreshPlayerList()
    UpdateTargetStatus()
end)

RefreshPlayerList()
ApplyWalkSpeed()
ApplyJumpPower()
notify("✅ PART 1 LOADED")
-- ============================================================
-- SERVER TAB
-- ============================================================

local function teleportToServer(placeId, jobId)
    if not placeId or not jobId then notify("Invalid server") return end
    if tostring(placeId) == tostring(game.PlaceId) and tostring(jobId) == tostring(game.JobId) then notify("Already in this server") return end
    local ok, err = pcall(function() TeleportService:TeleportToPlaceInstance(tonumber(placeId), tostring(jobId), LocalPlayer) end)
    if not ok then notify("Teleport failed") end
end

local function getRequestFunction()
    return (syn and syn.request) or (http and http.request) or (request)
end

local function getPublicServers()
    local req = getRequestFunction()
    if not req then notify("Server browser request unavailable") return nil end
    local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
    local ok, response = pcall(function() return req({Url = url, Method = "GET"}) end)
    if not ok or not response or not response.Body then return nil end
    local decoded, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
    if not decoded or not data or not data.data then return nil end
    local servers = {}
    for _, server in ipairs(data.data) do
        if server.id and server.playing ~= nil and server.maxPlayers ~= nil and server.id ~= game.JobId then
            table.insert(servers, server)
        end
    end
    return servers
end

local function joinEmptyServer()
    notify("Finding empty server...")
    task.spawn(function()
        local servers = getPublicServers()
        if not servers or #servers == 0 then notify("No public servers found") return end
        table.sort(servers, function(a, b) return (a.playing or 999999) < (b.playing or 999999) end)
        notify("Joining low-pop server...")
        teleportToServer(game.PlaceId, servers[1].id)
    end)
end

local function joinRandomServer()
    notify("Finding random server...")
    task.spawn(function()
        local servers = getPublicServers()
        if not servers or #servers == 0 then notify("No public servers found") return end
        teleportToServer(game.PlaceId, servers[math.random(1, #servers)].id)
    end)
end

local function joinPlayerServer(username)
    username = tostring(username or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if username == "" then notify("Enter a Roblox username") return end
    task.spawn(function()
        notify("Looking up @" .. username .. "...")
        local ok, userId = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
        if not ok or not userId then notify("Username not found") return end
        local req = getRequestFunction()
        if not req then notify("Player presence request unavailable") return end
        local body = HttpService:JSONEncode({userIds = {userId}})
        local requestOk, response = pcall(function()
            return req({Url = "https://presence.roblox.com/v1/presence/users", Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body})
        end)
        if not requestOk or not response or not response.Body then notify("Could not read player presence") return end
        local decoded, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
        local presence = decoded and data and data.userPresences and data.userPresences[1]
        if not presence then notify("No presence information") return end
        local placeId = presence.placeId
        local jobId = presence.gameId
        if not placeId or not jobId then notify("@" .. username .. " is not in a joinable server") return end
        notify("Joining @" .. username .. "'s server...")
        teleportToServer(placeId, jobId)
    end)
end

-- Player Count Display
local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Size = UDim2.new(1, 0, 0, 30)
playerCountLabel.BackgroundColor3 = Colors.Panel
playerCountLabel.Text = "👥 Players: 0 / 0"
playerCountLabel.TextColor3 = Colors.Text
playerCountLabel.Font = Enum.Font.GothamBold
playerCountLabel.TextSize = 12
playerCountLabel.LayoutOrder = 1
playerCountLabel.Parent = Pages[4]
style(playerCountLabel, 8, 1)

local function UpdatePlayerCount()
    local count = #Players:GetPlayers()
    local max = Players.MaxPlayers
    playerCountLabel.Text = "👥 Players: " .. count .. " / " .. max
end

Players.PlayerAdded:Connect(UpdatePlayerCount)
Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    UpdatePlayerCount()
end)
UpdatePlayerCount()

-- Saved Servers
local savedServers = {}
local savedServersFile = "ultimate_saved_servers.json"

local function hasFileAPI()
    return typeof(readfile) == "function" and typeof(isfile) == "function"
end

local function hasWriteAPI()
    return typeof(writefile) == "function"
end

local function loadSavedServers()
    if not hasFileAPI() or not isfile(savedServersFile) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(savedServersFile)) end)
    if ok and data and type(data) == "table" then
        savedServers = data
    end
end

local function saveSavedServers()
    if not hasWriteAPI() then return end
    pcall(function() writefile(savedServersFile, HttpService:JSONEncode(savedServers)) end
end

local function saveCurrentServer()
    if not hasWriteAPI() then notify("Executor doesn't support writefile") return end
    local name = "Server " .. (#savedServers + 1)
    table.insert(savedServers, {
        name = name,
        placeId = game.PlaceId,
        jobId = game.JobId,
        savedAt = os.time()
    })
    saveSavedServers()
    notify("✅ Saved: " .. name)
end

local function makeSection(parent, title, order)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 42)
    section.BackgroundColor3 = Colors.Panel
    section.LayoutOrder = order or 1
    section.ClipsDescendants = true
    section.Parent = parent
    style(section, 8, 1)
    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundTransparency = 1
    header.Text = "  " .. title .. "                                      +"
    header.TextColor3 = Colors.Text
    header.Font = Enum.Font.GothamBold
    header.TextSize = 11
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.AutoButtonColor = false
    header.Parent = section
    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, -16, 0, 0)
    body.Position = UDim2.fromOffset(8, 42)
    body.BackgroundTransparency = 1
    body.Parent = section
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = body
    local open = false
    header.Activated:Connect(function()
        open = not open
        section.Size = UDim2.new(1, 0, 0, open and 42 + layout.AbsoluteContentSize.Y + 10 or 42)
        header.Text = "  " .. title .. (open and "                                      −" or "                                      +")
    end)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if open then section.Size = UDim2.new(1, 0, 0, 42 + layout.AbsoluteContentSize.Y + 10) end
    end)
    return body
end

-- Join Player Section
local JoinSection = makeSection(Pages[4], "JOIN PLAYER", 2)
local JoinPlayerInput = Instance.new("TextBox")
JoinPlayerInput.Size = UDim2.new(1, 0, 0, 36)
JoinPlayerInput.BackgroundColor3 = Colors.Button
JoinPlayerInput.Text = ""
JoinPlayerInput.PlaceholderText = "Enter exact Roblox username..."
JoinPlayerInput.TextColor3 = Colors.Text
JoinPlayerInput.PlaceholderColor3 = Colors.TextSecondary
JoinPlayerInput.Font = Enum.Font.Gotham
JoinPlayerInput.TextSize = 12
JoinPlayerInput.ClearTextOnFocus = false
JoinPlayerInput.Parent = JoinSection
style(JoinPlayerInput, 7, 1)

CreateButton(JoinSection, "Join Username's Server", function() joinPlayerServer(JoinPlayerInput.Text) end)

-- Server Actions Section
local ServerActionsSection = makeSection(Pages[4], "SERVER ACTIONS", 3)
CreateButton(ServerActionsSection, "Join Empty / Low-Pop Server", joinEmptyServer)
CreateButton(ServerActionsSection, "Join Random Server", joinRandomServer)
CreateButton(ServerActionsSection, "Rejoin Current Server", function() teleportToServer(game.PlaceId, game.JobId) end)

-- Saved Servers Section
local SavedSection = makeSection(Pages[4], "SAVED SERVERS", 4)
CreateButton(SavedSection, "💾 Save Current Server", saveCurrentServer)

local SavedServersList = Instance.new("ScrollingFrame")
SavedServersList.Size = UDim2.new(1, 0, 0, 120)
SavedServersList.BackgroundColor3 = Colors.Button
SavedServersList.BorderSizePixel = 0
SavedServersList.ScrollBarThickness = 4
SavedServersList.AutomaticCanvasSize = Enum.AutomaticSize.Y
SavedServersList.Parent = SavedSection
style(SavedServersList, 7, 1)

local savedLayout = Instance.new("UIListLayout")
savedLayout.Padding = UDim.new(0, 4)
savedLayout.SortOrder = Enum.SortOrder.LayoutOrder
savedLayout.Parent = SavedServersList

local function RefreshSavedServers()
    for _, child in ipairs(SavedServersList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for i, server in ipairs(savedServers) do
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -6, 0, 32)
        frame.BackgroundColor3 = Colors.Panel
        frame.Parent = SavedServersList
        style(frame, 6, 1)
        
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.5, -4, 1, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = server.name or ("Server " .. i)
        nameLbl.TextColor3 = Colors.Text
        nameLbl.Font = Enum.Font.Gotham
        nameLbl.TextSize = 10
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = frame
        
        local joinBtn = Instance.new("TextButton")
        joinBtn.Size = UDim2.new(0.25, -2, 1, 0)
        joinBtn.Position = UDim2.new(0.5, 2, 0, 0)
        joinBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
        joinBtn.Text = "Join"
        joinBtn.TextColor3 = Colors.Text
        joinBtn.Font = Enum.Font.GothamBold
        joinBtn.TextSize = 10
        joinBtn.Parent = frame
        style(joinBtn, 5, 1)
        joinBtn.Activated:Connect(function()
            teleportToServer(server.placeId, server.jobId)
        end)
        
        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0.25, -2, 1, 0)
        delBtn.Position = UDim2.new(0.75, 2, 0, 0)
        delBtn.BackgroundColor3 = Color3.fromRGB(150, 25, 25)
        delBtn.Text = "X"
        delBtn.TextColor3 = Colors.Text
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 10
        delBtn.Parent = frame
        style(delBtn, 5, 1)
        delBtn.Activated:Connect(function()
            table.remove(savedServers, i)
            saveSavedServers()
            RefreshSavedServers()
            notify("Server deleted")
        end)
    end
end

loadSavedServers()
RefreshSavedServers()

-- Server Browser Section
local BrowserSection = makeSection(Pages[4], "SERVER BROWSER", 5)

local ServerBrowser = Instance.new("ScrollingFrame")
ServerBrowser.Size = UDim2.new(1, 0, 0, 150)
ServerBrowser.BackgroundColor3 = Colors.Button
ServerBrowser.BorderSizePixel = 0
ServerBrowser.ScrollBarThickness = 4
ServerBrowser.AutomaticCanvasSize = Enum.AutomaticSize.Y
ServerBrowser.Parent = BrowserSection
style(ServerBrowser, 7, 1)

local ServerBrowserLayout = Instance.new("UIListLayout")
ServerBrowserLayout.Padding = UDim.new(0, 5)
ServerBrowserLayout.SortOrder = Enum.SortOrder.LayoutOrder
ServerBrowserLayout.Parent = ServerBrowser

local ServerNumberInput = Instance.new("TextBox")
ServerNumberInput.Size = UDim2.new(1, 0, 0, 32)
ServerNumberInput.BackgroundColor3 = Colors.Button
ServerNumberInput.Text = ""
ServerNumberInput.PlaceholderText = "Enter server number (1, 2, 3...)"
ServerNumberInput.TextColor3 = Colors.Text
ServerNumberInput.PlaceholderColor3 = Colors.TextSecondary
ServerNumberInput.Font = Enum.Font.Gotham
ServerNumberInput.TextSize = 12
ServerNumberInput.ClearTextOnFocus = false
ServerNumberInput.Parent = BrowserSection
style(ServerNumberInput, 7, 1)

CreateButton(BrowserSection, "Join Server by Number", function()
    local num = tonumber(ServerNumberInput.Text)
    if not num then notify("Enter a number!") return end
    task.spawn(function()
        local servers = getPublicServers()
        if not servers or #servers == 0 then notify("No servers found") return end
        if num > #servers then notify("Only " .. #servers .. " servers found") return end
        notify("Joining server " .. num .. "...")
        teleportToServer(game.PlaceId, servers[num].id)
    end)
end)

local function refreshServerBrowser()
    for _, child in ipairs(ServerBrowser:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    notify("Loading public servers...")
    task.spawn(function()
        local servers = getPublicServers()
        if not servers then notify("Server list unavailable") return end
        table.sort(servers, function(a, b) return (a.playing or 0) < (b.playing or 0) end)
        for i, server in ipairs(servers) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 35)
            btn.BackgroundColor3 = Colors.Button
            btn.Text = "#" .. i .. " | " .. tostring(server.playing) .. "/" .. tostring(server.maxPlayers) .. " players"
            btn.TextColor3 = Colors.Text
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 10
            btn.AutoButtonColor = false
            btn.Parent = ServerBrowser
            style(btn, 6, 1)
            btn.Activated:Connect(function()
                teleportToServer(game.PlaceId, server.id)
            end)
        end
    end)
end

CreateButton(BrowserSection, "Refresh Server Browser", refreshServerBrowser)

-- ============================================================
-- ANIMATION TAB (Keep exactly as-is)
-- ============================================================

local AnimStatus = Instance.new("TextLabel")
AnimStatus.Size = UDim2.new(1, 0, 0, 20)
AnimStatus.BackgroundTransparency = 1
AnimStatus.Text = "Current: Default"
AnimStatus.TextColor3 = Colors.TextSecondary
AnimStatus.Font = Enum.Font.Gotham
AnimStatus.TextSize = 11
AnimStatus.TextXAlignment = Enum.TextXAlignment.Left
AnimStatus.LayoutOrder = 1
AnimStatus.Parent = Pages[5]

local AnimSearch = Instance.new("TextBox")
AnimSearch.Size = UDim2.new(1, 0, 0, 32)
AnimSearch.BackgroundColor3 = Colors.Panel
AnimSearch.Text = ""
AnimSearch.PlaceholderText = "🔍 Search animation..."
AnimSearch.TextColor3 = Colors.Text
AnimSearch.PlaceholderColor3 = Colors.TextSecondary
AnimSearch.Font = Enum.Font.Gotham
AnimSearch.TextSize = 11
AnimSearch.ClearTextOnFocus = false
AnimSearch.LayoutOrder = 2
AnimSearch.Parent = Pages[5]
style(AnimSearch, 10, 1)

local AnimListFrame = Instance.new("ScrollingFrame")
AnimListFrame.Size = UDim2.new(1, 0, 0, 200)
AnimListFrame.BackgroundColor3 = Colors.Panel
AnimListFrame.BorderSizePixel = 0
AnimListFrame.ScrollBarThickness = 3
AnimListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
AnimListFrame.CanvasSize = UDim2.fromOffset(0, 0)
AnimListFrame.LayoutOrder = 3
AnimListFrame.Parent = Pages[5]
style(AnimListFrame, 10, 1)

local animLayout = Instance.new("UIListLayout")
animLayout.Padding = UDim.new(0, 3)
animLayout.SortOrder = Enum.SortOrder.Name
animLayout.Parent = AnimListFrame

local function ApplyAnimation(bundleName)
    if bundleName == "Default" then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local defaultDesc = Instance.new("HumanoidDescription")
                humanoid:ApplyDescription(defaultDesc)
                defaultDesc:Destroy()
            end
        end
        currentAnimation = "Default"
        AnimStatus.Text = "Current: Default"
        notify("Animation: Default")
        return
    end
    getgenv().ChosenBundleName = bundleName
    getgenv().EnableHybridCustom = false
    pcall(function()
        loadstring(game:HttpGet("https://animationv3.sowonaha.workers.dev"))()
    end)
    currentAnimation = bundleName
    AnimStatus.Text = "Current: " .. bundleName
    notify("Animation: " .. bundleName)
end

local function RefreshAnimList()
    for _, child in ipairs(AnimListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local query = string.lower(AnimSearch.Text)
    for _, bundleName in ipairs(AnimationBundles) do
        local matches = query == "" or string.find(string.lower(bundleName), query, 1, true)
        if matches then
            local animBtn = Instance.new("TextButton")
            animBtn.Size = UDim2.new(1, -6, 0, 30)
            animBtn.BackgroundColor3 = bundleName == currentAnimation and Colors.Selected or Colors.Button
            animBtn.Text = bundleName
            animBtn.TextColor3 = Colors.Text
            animBtn.Font = Enum.Font.Gotham
            animBtn.TextSize = 11
            animBtn.AutoButtonColor = false
            animBtn.Parent = AnimListFrame
            style(animBtn, 6, 1)
            animBtn.Activated:Connect(function()
                ApplyAnimation(bundleName)
                RefreshAnimList()
            end)
        end
    end
end

AnimSearch:GetPropertyChangedSignal("Text"):Connect(RefreshAnimList)
RefreshAnimList()

CreateButton(Pages[5], "🔄 Reset to Default", function()
    ApplyAnimation("Default")
    RefreshAnimList()
end)

-- ============================================================
-- VISUALS TAB
-- ============================================================

-- ESP
local function ApplyHighlightToPlayer(player)
    if not player or player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    if highlightObjects[player.Name] then
        pcall(function() highlightObjects[player.Name]:Destroy() end)
        highlightObjects[player.Name] = nil
    end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = highlightColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    highlightObjects[player.Name] = highlight
end

local function RemoveHighlightFromPlayer(player)
    if not player then return end
    if highlightObjects[player.Name] then
        pcall(function() highlightObjects[player.Name]:Destroy() end)
        highlightObjects[player.Name] = nil
    end
end

local function ApplyESPToAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ApplyHighlightToPlayer(player)
        end
    end
end

local function ClearAllESP()
    for name, highlight in pairs(highlightObjects) do
        pcall(function() highlight:Destroy() end)
    end
    table.clear(highlightObjects)
end

CreateToggle(Pages[6], "👁️ Highlight ESP", function(on)
    highlightESP = on
    if on then
        ApplyESPToAll()
        notify("✅ ESP ON")
    else
        ClearAllESP()
        notify("ESP OFF")
    end
end)

local ColorBtn = CreateButton(Pages[6], "🎨 ESP Color: Red", function()
    colorIndex = colorIndex % #espColors + 1
    highlightColor = espColors[colorIndex].color
    ColorBtn.Text = "🎨 ESP Color: " .. espColors[colorIndex].name
    ColorBtn.BackgroundColor3 = espColors[colorIndex].color
    if highlightESP then ApplyESPToAll() end
end)
ColorBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

-- Aim Assist
local function CreateFOVCircle()
    if fovCircle then fovCircle:Destroy() end
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = showFOVCircle
    fovCircle.Radius = fovCircleSize
    fovCircle.Thickness = 1
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Transparency = 0.5
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function GetNearestPlayerInFOV()
    local nearest = nil
    local nearestDistance = fovCircleSize
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = nil
            if aimPart == "Head" then
                targetPart = player.Character:FindFirstChild("Head")
            else
                targetPart = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
            end
            if targetPart then
                local screenPos = Camera:WorldToScreenPoint(targetPart.Position)
                local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
                local distance = (screenPoint - screenCenter).Magnitude
                if distance < nearestDistance and screenPos.Z > 0 then
                    nearest = player
                    nearestDistance = distance
                end
            end
        end
    end
    return nearest
end

local function StartAimAssist()
    aimAssistEnabled = true
    aimAssistConnection = disconnect(aimAssistConnection)
    aimAssistConnection = RunService.RenderStepped:Connect(function()
        if not aimAssistEnabled then return end
        if fovCircle then
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
        aimTarget = GetNearestPlayerInFOV()
        if aimTarget and aimTarget.Character then
            local targetPart = nil
            if aimPart == "Head" then
                targetPart = aimTarget.Character:FindFirstChild("Head")
            else
                targetPart = aimTarget.Character:FindFirstChild("HumanoidRootPart") or aimTarget.Character:FindFirstChild("Torso") or aimTarget.Character:FindFirstChild("UpperTorso")
            end
            if targetPart then
                local targetPos = targetPart.Position
                local cameraCFrame = Camera.CFrame
                local lookAt = CFrame.lookAt(cameraCFrame.Position, targetPos)
                if aimMode == "Camera" then
                    Camera.CFrame = cameraCFrame:Lerp(lookAt, aimSmoothness)
                else
                    -- Silent Aim: just track target, don't move camera
                    -- (Not all games support actual silent aim)
                    Camera.CFrame = cameraCFrame
                end
            end
        end
    end)
    notify("🎯 Aim Assist ON (" .. aimMode .. ")")
end

local function StopAimAssist()
    aimAssistEnabled = false
    aimAssistConnection = disconnect(aimAssistConnection)
    aimTarget = nil
    notify("Aim Assist OFF")
end

CreateToggle(Pages[6], "🎯 Aim Assist", function(on)
    if on then StartAimAssist() else StopAimAssist() end
end)

local AimPartBtn = CreateButton(Pages[6], "🎯 Aim: Head", function()
    if aimPart == "Head" then
        aimPart = "Body"
        AimPartBtn.Text = "🎯 Aim: Body"
    else
        aimPart = "Head"
        AimPartBtn.Text = "🎯 Aim: Head"
    end
end)

local AimModeBtn = CreateButton(Pages[6], "🎯 Mode: Camera Lock", function()
    if aimMode == "Camera" then
        aimMode = "Silent"
        AimModeBtn.Text = "🎯 Mode: Silent Aim"
    else
        aimMode = "Camera"
        AimModeBtn.Text = "🎯 Mode: Camera Lock"
    end
end)

-- FOV Circle invisible button
local FOVBtn = CreateButton(Pages[6], "⭕ FOV Circle: OFF", function()
    showFOVCircle = not showFOVCircle
    FOVBtn.Text = showFOVCircle and "⭕ FOV Circle: ON" or "⭕ FOV Circle: OFF"
    CreateFOVCircle()
end)

-- Kill Aura
local function StartKillAura()
    killAuraEnabled = true
    killAuraConnection = disconnect(killAuraConnection)
    killAuraConnection = RunService.Heartbeat:Connect(function()
        if not killAuraEnabled then return end
        local myChar = LocalPlayer.Character
        local myRoot = getRoot(myChar)
        if not myRoot then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local targetRoot = getRoot(player.Character)
                local targetHum = getHumanoid(player.Character)
                if targetRoot and targetHum and targetHum.Health > 0 then
                    local distance = (targetRoot.Position - myRoot.Position).Magnitude
                    if distance <= killAuraRange then
                        targetHum.Health = 0
                    end
                end
            end
        end
    end)
    notify("⚔️ Kill Aura ON")
end

local function StopKillAura()
    killAuraEnabled = false
    killAuraConnection = disconnect(killAuraConnection)
    notify("Kill Aura OFF")
end

CreateToggle(Pages[6], "⚔️ Kill Aura", function(on)
    if on then StartKillAura() else StopKillAura() end
end)

-- Fullbright
local function EnableFullbright()
    fullbrightEnabled = true
    originalLighting.Ambient = Lighting.Ambient
    originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
    originalLighting.Brightness = Lighting.Brightness
    originalLighting.ClockTime = Lighting.ClockTime
    originalLighting.FogEnd = Lighting.FogEnd
    originalLighting.GlobalShadows = Lighting.GlobalShadows
    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    Lighting.Brightness = 3
    Lighting.ClockTime = 12
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    notify("☀️ Fullbright ON")
end

local function DisableFullbright()
    fullbrightEnabled = false
    if originalLighting.Ambient then
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.GlobalShadows = originalLighting.GlobalShadows
    end
    notify("Fullbright OFF")
end

CreateToggle(Pages[6], "☀️ Fullbright", function(on)
    if on then EnableFullbright() else DisableFullbright() end
end)

-- Anti-Lag (disables effects, low graphics)
local function EnableAntiLag()
    antiLagEnabled = true
    -- Disable lighting effects
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("ColorCorrectionEffect")
        or effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect") then
            if originalEffects[effect] == nil then originalEffects[effect] = effect.Enabled end
            effect.Enabled = false
        end
    end
    -- Disable workspace effects
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            if originalEffects[obj] == nil then originalEffects[obj] = obj.Enabled end
            obj.Enabled = false
        end
    end
    -- Lower terrain detail
    pcall(function() workspace.Terrain.WaterWaveSize = 0 end)
    pcall(function() workspace.Terrain.WaterWaveSpeed = 0 end)
    pcall(function() workspace.Terrain.WaterReflectance = 0 end)
    pcall(function() workspace.Terrain.WaterTransparency = 1 end)
    -- Lower graphics quality
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    notify("⚡ Anti-Lag ON")
end

local function DisableAntiLag()
    antiLagEnabled = false
    for obj, value in pairs(originalEffects) do
        if obj and obj.Parent then
            pcall(function() obj.Enabled = value end)
        end
    end
    table.clear(originalEffects)
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end)
    notify("Anti-Lag OFF")
end

CreateToggle(Pages[6], "⚡ Anti-Lag", function(on)
    if on then EnableAntiLag() else DisableAntiLag() end
end)

-- Reset Character
CreateButton(Pages[6], "🔄 Reset Character", function()
    local humanoid = getHumanoid(LocalPlayer.Character)
    if humanoid then humanoid.Health = 0 end
end)

-- ============================================================
-- ESP AUTO-UPDATE
-- ============================================================

RunService.Heartbeat:Connect(function()
    if highlightESP then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local hl = char:FindFirstChild("ESP_Highlight")
                if not hl then
                    ApplyHighlightToPlayer(player)
                end
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    if highlightESP then
        task.wait(0.5)
        ApplyHighlightToPlayer(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveHighlightFromPlayer(player)
end)

-- ============================================================
-- FINAL INIT
-- ============================================================

notify("✅ ULTIMATE UTILITY LOADED - ALL FEATURES")
