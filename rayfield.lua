-- LocalScript: UltimateScript.lua

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Ultimate Script UI",
    LoadingTitle = "Ultimate Script",
    LoadingSubtitle = "Speed, Fly, ESP, Aim",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "UltimateScriptSettings"
    },
    Discord = { Enabled = false }
})

local MainTab = Window:CreateTab("Main", 4483362458)

-- Speed Control
local SpeedSlider = MainTab:CreateSlider({
    Name = "Chỉnh tốc độ chạy",
    Range = {8, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")
        humanoid.WalkSpeed = Value
    end
})

MainTab:CreateButton({
    Name = "Reset tốc độ",
    Callback = function()
        SpeedSlider:Set(16)
    end
})

-- Infinite Jump Toggle
local infiniteJumpEnabled = false
MainTab:CreateToggle({
    Name = "Bật Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJumpToggle",
    Callback = function(Value)
        infiniteJumpEnabled = Value
    end
})

-- Fly Toggle
local flying = false
local flySpeed = 50
local bodyVelocity

MainTab:CreateToggle({
    Name = "Bật Fly (Nhấn F để tắt bật)",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        flying = Value
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        if flying then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bodyVelocity.Parent = hrp
        else
            if bodyVelocity then
                bodyVelocity:Destroy()
                bodyVelocity = nil
            end
        end
    end
})

-- ESP Player Toggle
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
    Callback = toggleESP
})

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if espEnabled then
            addESP(p)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
end)

-- Aim Enemy Toggle
local aimEnabled = false
local aimKey = Enum.KeyCode.E
local Camera = workspace.CurrentCamera

MainTab:CreateToggle({
    Name = "Bật Aim Enemy (Game Arsenal)",
    CurrentValue = false,
    Flag = "AimToggle",
    Callback = function(value)
        aimEnabled = value
    end
})

local function getNearestEnemy()
    local nearest, nearestDist
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            local headPos = p.Character.Head.Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if not nearestDist or dist < nearestDist then
                    nearestDist = dist
                    nearest = p.Character.Head
                end
            end
        end
    end
    return nearest
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == aimKey then
        aimEnabled = not aimEnabled
        MainTab:FindFirstChild("AimToggle").Flag = aimEnabled
    end
end)

RunService.Heartbeat:Connect(function()
    -- Infinite Jump
    if infiniteJumpEnabled then
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end

    -- Fly
    if flying and bodyVelocity then
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local moveVec = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveVec = moveVec + workspace.CurrentCamera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveVec = moveVec - workspace.CurrentCamera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveVec = moveVec - workspace.CurrentCamera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveVec = moveVec + workspace.CurrentCamera.CFrame.RightVector
                end
                if moveVec.Magnitude > 0 then
                    bodyVelocity.Velocity = moveVec.Unit * flySpeed
                else
                    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end

    -- Aim Enemy
    if aimEnabled then
        local target = getNearestEnemy()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

Rayfield:Init()
