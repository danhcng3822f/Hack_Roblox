local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Window = Fluent:CreateWindow({
    Title = "Ultimate Script UI",
    SubTitle = "Script By Danhcng",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Toggle bật tắt menu ngoài UI (nút bấm)
local ToggleGui = Instance.new("ScreenGui")
local Toggle = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ToggleGui.Name = "ToggleGui"
ToggleGui.Parent = player:WaitForChild("PlayerGui")
ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleGui.ResetOnSpawn = false

UICorner.Parent = Toggle
Toggle.Name = "Toggle"
Toggle.Parent = ToggleGui
Toggle.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
Toggle.Position = UDim2.new(0, 10, 0, 200) -- bạn chỉnh vị trí tùy ý
Toggle.Size = UDim2.new(0, 80, 0, 38)
Toggle.Font = Enum.Font.SourceSans
Toggle.Text = "Close Gui"
Toggle.TextColor3 = Color3.fromRGB(203, 122, 49)
Toggle.TextSize = 19
Toggle.Draggable = true

local isOpen = true

local function updateToggleText()
    if isOpen then
        Toggle.Text = "Close Gui"
    else
        Toggle.Text = "Open Gui"
    end
end

updateToggleText()

Toggle.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    if isOpen then
        Window:Open()
    else
        Window:Close()
    end
    updateToggleText()
end)

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "box" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Speed input
local defaultWalkSpeed = 16
Tabs.Main:AddInput("WalkSpeedInput", {
    Title = "Chỉnh tốc độ chạy",
    Placeholder = tostring(defaultWalkSpeed),
    Callback = function(val)
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local numVal = tonumber(val)
        if humanoid and numVal and numVal >= 8 and numVal <= 100 then
            humanoid.WalkSpeed = numVal
        elseif humanoid then
            humanoid.WalkSpeed = defaultWalkSpeed
        end
    end
})

Tabs.Main:AddButton({
    Title = "Reset tốc độ",
    Callback = function()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = defaultWalkSpeed end
    end
})

-- JumpPower input
local defaultJumpPower = 50
Tabs.Main:AddInput("JumpPowerInput", {
    Title = "Chỉnh Jump Power",
    Placeholder = tostring(defaultJumpPower),
    Callback = function(val)
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local numVal = tonumber(val)
        if humanoid and numVal and numVal >= 20 and numVal <= 200 then
            humanoid.JumpPower = numVal
        elseif humanoid then
            humanoid.JumpPower = defaultJumpPower
        end
    end
})

Tabs.Main:AddButton({
    Title = "Reset Jump Power",
    Callback = function()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.JumpPower = defaultJumpPower end
    end
})

-- Infinite Jump toggle
local infiniteJumpEnabled = false
Tabs.Main:AddToggle("InfiniteJumpToggle", {
    Title = "Bật Infinite Jump",
    Default = false,
    Callback = function(val)
        infiniteJumpEnabled = val
    end
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and infiniteJumpEnabled and input.KeyCode == Enum.KeyCode.Space then
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ESP toggle (màu đỏ)
local espEnabled = false
local espHighlights = {}

local function addESP(p)
    if p ~= player and p.Character and not espHighlights[p] then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = p.Character
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
        highlight.Name = "ESP_Highlight"
        highlight.Parent = p.Character
        espHighlights[p] = highlight
    end
end

local function removeESP(p)
    if espHighlights[p] then
        espHighlights[p]:Destroy()
        espHighlights[p] = nil
    end
end

Tabs.Main:AddToggle("ESPToggle", {
    Title = "Bật ESP Player",
    Default = false,
    Callback = function(val)
        espEnabled = val
        if espEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                addESP(p)
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                removeESP(p)
            end
        end
    end
})

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if espEnabled then addESP(p) end
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

-- Noclip toggle
local noclipEnabled = false
Tabs.Main:AddToggle("NoclipToggle", {
    Title = "Bật Noclip",
    Default = false,
    Callback = function(val)
        noclipEnabled = val
    end
})

RunService.Stepped:Connect(function()
    local char = player.Character
    if char then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = not noclipEnabled
            end
        end
    end
end)

-- Aim toggle
local aimEnabled = false
local aimKey = Enum.KeyCode.E

Tabs.Main:AddToggle("AimToggle", {
    Title = "Bật Aim Enemy (Chỉ aim kẻ địch)",
    Default = false,
    Callback = function(val)
        aimEnabled = val
    end
})

local function isEnemy(p1, p2)
    if p1.Team and p2.Team then
        return p1.Team ~= p2.Team
    end
    return true
end

local function getNearestEnemy()
    if not player.Character or not player.Character:FindFirstChild("Head") then return nil end
    local nearest, nearestDist = nil, math.huge
    local ownHeadPos = player.Character.Head.Position
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") and isEnemy(player, p) then
            local dist = (ownHeadPos - p.Character.Head.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = p.Character.Head
            end
        end
    end
    return nearest
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode==aimKey then
        aimEnabled = not aimEnabled
        Tabs.Main:GetOption("AimToggle"):SetValue(aimEnabled)
    end
end)

RunService.RenderStepped:Connect(function()
    if aimEnabled then
        local target = getNearestEnemy()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

-- Fly Mode (mobile friendly)
local flying = false
local flySpeed = 50
local bodyVelocity, bodyGyro

local function startFly()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
    bodyVelocity.Velocity = Vector3.new(0,0,0)
    bodyVelocity.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp
end

local function stopFly()
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
end

Tabs.Main:AddToggle("FlyToggle", {
    Title = "Bật Fly Mode (Mobile friendly)",
    Default = false,
    Callback = function(val)
        flying = val
        if flying then
            startFly()
        else
            stopFly()
        end
    end
})

RunService.Heartbeat:Connect(function()
    if flying and bodyVelocity and bodyGyro then
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local moveVector = workspace.CurrentCamera.CFrame.LookVector * 0.5
                bodyVelocity.Velocity = moveVector * flySpeed
                bodyGyro.CFrame = workspace.CurrentCamera.CFrame
            end
        end
    end
end)

-- Teleport toggle
local teleportUp = false
local teleportDown = false
local teleportHeight = 50

Tabs.Main:AddToggle("TeleportUpToggle", {
    Title = "Dịch chuyển lên trên trời (Giữ bật)",
    Default = false,
    Callback = function(val)
        teleportUp = val
        if teleportUp then teleportDown = false end
    end
})

Tabs.Main:AddToggle("TeleportDownToggle", {
    Title = "Dịch chuyển xuống lòng đất (Giữ bật)",
    Default = false,
    Callback = function(val)
        teleportDown = val
        if teleportDown then teleportUp = false end
    end
})

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if teleportUp then
                hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, teleportHeight, 0))
            elseif teleportDown then
                hrp.CFrame = CFrame.new(hrp.Position - Vector3.new(0, teleportHeight, 0))
            end
        end
    end
end)

-- Setup SaveManager and InterfaceManager for config saving
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("FluentScriptHub")
InterfaceManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent UI",
    Content = "Ultimate Script has loaded!",
    Duration = 6
})

Window:Init()
