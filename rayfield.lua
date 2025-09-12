-- Load Orion UI
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local Window = OrionLib:MakeWindow({
    Name = "Ultimate Script UI",
    HidePremium = false,
    IntroText = "Speed, Fly, ESP, Aim, Infinite Jump, Noclip",
})

local MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483362458",
    PremiumOnly = false,
})

-- Speed setup
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

MainTab:AddSlider({
    Name = "Chỉnh tốc độ chạy",
    Min = 8,
    Max = 100,
    Default = defaultWalkSpeed,
    Color = Color3.fromRGB(255, 170, 0),
    Increment = 1,
    ValueName = "Speed",
    Callback = setSpeed
})

MainTab:AddButton({
    Name = "Reset tốc độ",
    Callback = function()
        setSpeed(defaultWalkSpeed)
    end
})

-- Infinite Jump toggle & improved
local infiniteJumpEnabled = false

MainTab:AddToggle({
    Name = "Bật Infinite Jump",
    Default = false,
    Callback = function(value)
        infiniteJumpEnabled = value
    end,
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and infiniteJumpEnabled then
        if input.KeyCode == Enum.KeyCode.Space then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end
end)

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

MainTab:AddToggle({
    Name = "Bật ESP Player",
    Default = false,
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
MainTab:AddToggle({
    Name = "Bật Noclip",
    Default = false,
    Callback = function(value) noclipEnabled = value end,
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

-- Aim Enemy (giữ nguyên code cũ hoặc có thể thay đổi theo yêu cầu)

-- Fly mode
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

MainTab:AddToggle({
    Name = "Bật Fly Mode (WSAD + Space/Shift bay lên xuống)",
    Default = false,
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
                    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
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

OrionLib:Init()
