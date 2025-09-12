-- LocalScript: UltimateScript_Complete.lua

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Ultimate Script UI",
    LoadingTitle = "Ultimate Script",
    LoadingSubtitle = "Speed, ESP, Noclip, Aim, Fly, Infinite Jump",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "UltimateScriptSettings"
    },
    Discord = { Enabled = false }
})

local MainTab = Window:CreateTab("Main", 4483362458)

-- Speed setup
local defaultWalkSpeed = 16

local function setSpeed(value)
    local char = player.Character or player.CharacterAdded:Wait()
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = value
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

spawn(function()
    local wasVisible = true
    while true do
        local visible = Window.Visible
        if visible ~= wasVisible then
            if not visible then
                setSpeed(defaultWalkSpeed)
            end
            wasVisible = visible
        end
        wait(0.1)
    end
end)

-- Infinite Jump with delay
local infiniteJumpEnabled = false
local lastJumpTime = 0

MainTab:CreateToggle({
    Name = "Bật Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJumpToggle",
    Callback = function(value)
        infiniteJumpEnabled = value
    end,
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
    Callback = function(value)
        noclipEnabled = value
    end,
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

-- Aim Enemy toggle and logic
local aimEnabled = false
local aimKey = Enum.KeyCode.E
local Camera = workspace.CurrentCamera

MainTab:CreateToggle({
    Name = "Bật Aim Enemy (Chỉ aim kẻ địch)",
    CurrentValue = false,
    Flag = "AimToggle",
    Callback = function(value)
        aimEnabled = value
    end,
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

-- Fly mode implementation
local flying = false
local flySpeed = 50
local bodyVelocity, bodyGyro

local function startFly()
    local char = player.Character or player.CharacterAdded:Wait()
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

MainTab:CreateToggle({
    Name = "Bật Fly Mode (WSAD + Space/Shift bay lên xuống)",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(value)
        flying = value
        if flying then
            startFly()
        else
            stopFly()
        end
    end,
})

RunService.Heartbeat:Connect(function()
    if flying and bodyVelocity and bodyGyro then
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local moveVector = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveVector = moveVector + workspace.CurrentCamera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveVector = moveVector - workspace.CurrentCamera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveVector = moveVector - workspace.CurrentCamera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveVector = moveVector + workspace.CurrentCamera.CFrame.RightVector
                end
                
                if moveVector.Magnitude > 0 then
                    bodyVelocity.Velocity = moveVector.Unit * flySpeed
                else
                    bodyVelocity.Velocity = Vector3.new(0,0,0)
                end

                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    bodyVelocity.Velocity = bodyVelocity.Velocity + Vector3.new(0, flySpeed, 0)
                elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    bodyVelocity.Velocity = bodyVelocity.Velocity - Vector3.new(0, flySpeed, 0)
                end

                bodyGyro.CFrame = workspace.CurrentCamera.CFrame
            end
        end
    end
end)

-- Infinite Jump improved with delay
local lastJumpTime = 0
RunService.Heartbeat:Connect(function()
    if infiniteJumpEnabled then
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local currentTime = tick()
                if currentTime - lastJumpTime > 0.25 then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    lastJumpTime = currentTime
                end
            end
        end
    end
end)

Rayfield:Init()
