-- LocalScript: UltimateScript_Final.lua

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Ultimate Script UI",
    LoadingTitle = "Ultimate Script",
    LoadingSubtitle = "Speed, ESP, Noclip, Aim",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "UltimateScriptSettings"
    },
    Discord = { Enabled = false }
})

local MainTab = Window:CreateTab("Main", 4483362458)

-- Speed setup with immediate reset when menu hidden
local defaultWalkSpeed = 16
local currentWalkSpeed = defaultWalkSpeed

local function setSpeed(value)
    local char = player.Character or player.CharacterAdded:Wait()
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = value
        currentWalkSpeed = value
    end
end

local SpeedSlider = MainTab:CreateSlider({
    Name = "Chỉnh tốc độ chạy",
    Range = {8, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = defaultWalkSpeed,
    Flag = "WalkSpeed",
    Callback = setSpeed,
})

MainTab:CreateButton({
    Name = "Reset tốc độ",
    Callback = function()
        SpeedSlider:Set(defaultWalkSpeed)
        setSpeed(defaultWalkSpeed)
    end
})

-- Reset tốc độ khi menu ẩn (không ẩn slider)
spawn(function()
    local lastVisible = true
    while true do
        local nowVisible = Window.Visible
        if nowVisible ~= lastVisible then
            if not nowVisible then
                setSpeed(defaultWalkSpeed)
            end
            lastVisible = nowVisible
        end
        wait(0.1)
    end
end)

-- Infinite Jump toggle
local infiniteJumpEnabled = false
MainTab:CreateToggle({
    Name = "Bật Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJumpToggle",
    Callback = function(v) infiniteJumpEnabled = v end,
})

-- ESP Player toggle
local espEnabled = false
local espHighlights = {}

local function addESP(p)
    if p ~= player and p.Character and not espHighlights[p] then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = p.Character
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
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

local function toggleESP(enabled)
    espEnabled = enabled
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

MainTab:CreateToggle({
    Name = "Bật ESP Player",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = toggleESP,
})

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if espEnabled then addESP(p) end
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

-- Noclip toggle
local noclipEnabled = false
MainTab:CreateToggle({
    Name = "Bật Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(v) noclipEnabled = v end,
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

-- Infinite Jump handler
RunService.Heartbeat:Connect(function()
    if infiniteJumpEnabled then
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Aim Enemy settings
local aimEnabled = false
local aimKey = Enum.KeyCode.E
local Camera = workspace.CurrentCamera

MainTab:CreateToggle({
    Name = "Bật Aim Enemy (Chỉ aim kẻ địch)",
    CurrentValue = false,
    Flag = "AimToggle",
    Callback = function(v) aimEnabled = v end,
})

local function isEnemy(playerA, playerB)
    if playerA.Team and playerB.Team then
        return playerA.Team ~= playerB.Team
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
    if not gameProcessed and input.KeyCode == aimKey then
        aimEnabled = not aimEnabled
        local toggle = MainTab:FindFirstChild("AimToggle")
        if toggle then toggle.Flag = aimEnabled end
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

Rayfield:Init()
