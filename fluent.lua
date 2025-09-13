repeat task.wait(0.25) until game:IsLoaded();

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Nút ImageButton toggle menu logo mới, kích thước 60x60
local ScreenGui = Instance.new("ScreenGui")
local ImageButton = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

ImageButton.Parent = ScreenGui
ImageButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ImageButton.BorderSizePixel = 0
ImageButton.Position = UDim2.new(0.1, 0, 0.15, 0)
ImageButton.Size = UDim2.new(0, 60, 0, 60)
ImageButton.Draggable = true
ImageButton.Image = "rbxassetid://117785786479587"

UICorner.CornerRadius = UDim.new(1, 10)
UICorner.Parent = ImageButton

ImageButton.MouseButton1Down:Connect(function()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.End, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.End, false, game)
end)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Hacker Script",
    SubTitle = "By Danhcng",
    TabWidth = 200,
    Size = UDim2.fromOffset(480, 350),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.End
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "box" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

local defaultWalkSpeed = 16
-- Speed slider with description
Tabs.Main:AddSlider("WalkSpeedSlider", {
    Title = "Speed",
    Description = "Speed", -- mô tả
    Min = 8,
    Max = 100,
    Default = defaultWalkSpeed,
    Rounding = 0,
    Callback = function(val)
        local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = val
        end
    end
})

local defaultJumpPower = 50
-- Jump Power slider with description
Tabs.Main:AddSlider("JumpPowerSlider", {
    Title = "Jump Power",
    Description = "Jump Power", -- mô tả
    Min = 20,
    Max = 200,
    Default = defaultJumpPower,
    Rounding = 0,
    Callback = function(val)
        local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = val
        end
    end
})

-- Infinite Jump toggle with description
local infiniteJumpEnabled = false
Tabs.Main:AddToggle("InfiniteJumpToggle", {
    Title = "Infinite Jump",
    Description = "Infinite Jump", -- mô tả
    Default = false,
    Callback = function(val)
        infiniteJumpEnabled = val
    end
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and infiniteJumpEnabled and input.KeyCode == Enum.KeyCode.Space then
        local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ESP toggle with description
local espEnabled = false
local espHighlights = {}

local function addESP(p)
    if p ~= game.Players.LocalPlayer and p.Character and not espHighlights[p] then
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
    Title = "Esp",
    Description = "esp player",
    Default = false,
    Callback = function(val)
        espEnabled = val
        if espEnabled then
            for _, p in pairs(game.Players:GetPlayers()) do
                addESP(p)
            end
        else
            for _, p in pairs(game.Players:GetPlayers()) do
                removeESP(p)
            end
        end
    end
})

game.Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if espEnabled then addESP(p) end
    end)
end)

game.Players.PlayerRemoving:Connect(removeESP)

-- Noclip toggle without description (giữ nguyên cũ)
local noclipEnabled = false
Tabs.Main:AddToggle("NoclipToggle", {
    Title = "Noclip",
    Default = false,
    Callback = function(val)
        noclipEnabled = val
    end
})

RunService.Stepped:Connect(function()
    local char = game.Players.LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = not noclipEnabled
            end
        end
    end
end)

-- Aim toggle with description
local aimEnabled = false
local aimKey = Enum.KeyCode.T

Tabs.Main:AddToggle("AimToggle", {
    Title = "Aim",
    Description = "aim player",
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
    if not game.Players.LocalPlayer.Character or not game.Players.LocalPlayer.Character:FindFirstChild("Head") then return nil end
    local nearest, nearestDist = nil, math.huge
    local ownHeadPos = game.Players.LocalPlayer.Character.Head.Position
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and isEnemy(game.Players.LocalPlayer, p) then
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
    if not gameProcessed and input.KeyCode == aimKey then
        aimEnabled = not aimEnabled
    end
end)

RunService.RenderStepped:Connect(function()
    if aimEnabled then
        local target = getNearestEnemy()
        if target then
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, target.Position)
        end
    end
end)

-- Fly toggle with description
local flying = false
local flySpeed = 50
local bodyVelocity, bodyGyro

local function startFly()
    local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
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
    Title = "Fly",
    Description = "dành cho mobile",
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
        local char = game.Players.LocalPlayer.Character
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

-- Teleport Up toggle with description
local teleportUp = false
local teleportHeight = 50

Tabs.Main:AddToggle("TeleportUpToggle", {
    Title = "Tele Up",
    Description = "teleport lên trời",
    Default = false,
    Callback = function(val)
        teleportUp = val
        if teleportUp then
            teleportDown = false
        end
    end
})

-- Teleport Down toggle with description
local teleportDown = false

Tabs.Main:AddToggle("TeleportDownToggle", {
    Title = "Tele Down",
    Description = "teleport xuống dưới đất",
    Default = false,
    Callback = function(val)
        teleportDown = val
        if teleportDown then
            teleportUp = false
        end
    end
})

RunService.Heartbeat:Connect(function()
    local char = game.Players.LocalPlayer.Character
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

-- SaveManager & InterfaceManager
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

task.delay(1, function()
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)

    local configPath = "FluentScriptHub/specific-game"
    local config = SaveManager:LoadConfig(configPath)
    if config then
        if not config.MinimizeKey or config.MinimizeKey == "..." then
            config.MinimizeKey = "End"
            SaveManager:SaveConfig(configPath, config)
        end
    end
end)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Hacker Script",
    Content = "By Danhcng đã tải!",
    Duration = 6
})

-- Không gọi Window:Init()
