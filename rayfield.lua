local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Ultimate Script UI",
    LoadingTitle = "Ultimate Script",
    LoadingSubtitle = "Speed, ESP, Noclip, Aim, Fly, Infinite Jump, Teleport",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "UltimateScriptSettings"
    },
    Discord = { Enabled = false }
})

local MainTab = Window:CreateTab("Main", 4483362458)

-- Speed Input
local defaultWalkSpeed = 16

local function setSpeed(value)
    local char = player.Character or player.CharacterAdded:Wait()
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local numValue = tonumber(value)
    if humanoid then
        if numValue and numValue >= 8 and numValue <= 100 then
            humanoid.WalkSpeed = numValue
        else
            humanoid.WalkSpeed = defaultWalkSpeed
        end
    end
end

MainTab:CreateInput({
    Name = "Chỉnh tốc độ chạy",
    PlaceholderText = tostring(defaultWalkSpeed),
    RemoveTextAfterFocusLost = false,
    Callback = setSpeed,
})

MainTab:CreateButton({
    Name = "Reset tốc độ",
    Callback = function()
        setSpeed(tostring(defaultWalkSpeed))
    end
})

-- Infinite Jump Toggle
local infiniteJumpEnabled = false
MainTab:CreateToggle({
    Name = "Bật Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJumpToggle",
    Callback = function(v)
        infiniteJumpEnabled = v
    end,
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and infiniteJumpEnabled and input.KeyCode == Enum.KeyCode.Space then
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

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
    Callback = toggleESP,
})

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if espEnabled then addESP(p) end
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

-- Noclip Toggle
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

-- Aim Enemy Toggle
local aimEnabled = false
local aimKey = Enum.KeyCode.E
local Camera = workspace.CurrentCamera

MainTab:CreateToggle({
    Name = "Bật Aim Enemy (Chỉ aim kẻ địch)",
    CurrentValue = false,
    Flag = "AimToggle",
    Callback = function(v)
        aimEnabled = v
    end,
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

-- Fly Mode (mobile-friendly)
local flying = false
local flyUp = false
local flyDown = false
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
        bodyVelocity=nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro=nil
    end
end

MainTab:CreateToggle({
    Name = "Bật Fly Mode (Mobile friendly)",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(value)
        flying = value
        flyUp = false
        flyDown = false
        if flying then
            startFly()
        else
            stopFly()
        end
    end
})

MainTab:CreateToggle({
    Name = "Bay lên (cho mobile)",
    CurrentValue = false,
    Flag = "FlyUpToggle",
    Callback = function(value)
        flyUp = value
        if value then flyDown = false end
    end
})

MainTab:CreateToggle({
    Name = "Bay xuống (cho mobile)",
    CurrentValue = false,
    Flag = "FlyDownToggle",
    Callback = function(value)
        flyDown = value
        if value then flyUp = false end
    end
})

RunService.Heartbeat:Connect(function()
    if flying and bodyVelocity and bodyGyro then
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Di chuyển theo hướng camera với tốc độ thấp hơn để dễ dàng kiểm soát trên mobile
                local moveVector = workspace.CurrentCamera.CFrame.LookVector * 0.5
                bodyVelocity.Velocity = moveVector * flySpeed

                if flyUp then
                    bodyVelocity.Velocity = bodyVelocity.Velocity + Vector3.new(0, flySpeed, 0)
                elseif flyDown then
                    bodyVelocity.Velocity = bodyVelocity.Velocity - Vector3.new(0, flySpeed, 0)
                end

                bodyGyro.CFrame = workspace.CurrentCamera.CFrame
            end
        end
    end
end)

-- Teleport toggles for up and down
local teleportUp = false
local teleportDown = false
local teleportHeight = 50

MainTab:CreateToggle({
    Name = "Dịch chuyển lên trên trời (Giữ bật)",
    CurrentValue = false,
    Flag = "TeleportUpToggle",
    Callback = function(value)
        teleportUp = value
        if teleportUp then teleportDown = false end
    end,
})

MainTab:CreateToggle({
    Name = "Dịch chuyển xuống lòng đất (Giữ bật)",
    CurrentValue = false,
    Flag = "TeleportDownToggle",
    Callback = function(value)
        teleportDown = value
        if teleportDown then teleportUp = false end
    end,
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

Rayfield:Init()
