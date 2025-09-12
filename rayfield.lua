-- LocalScript: UltimateScript_NoAim_FlyFixed_Noclip.lua

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Ultimate Script UI",
    LoadingTitle = "Ultimate Script",
    LoadingSubtitle = "Speed, Fly (Fixed), ESP, Noclip",
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

-- Fly Toggle và điều khiển fly
local flying = false
local flySpeed = 50
local flyBodyVelocity, flyBodyGyro

local function startFly()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVelocity.Velocity = Vector3.new(0,0,0)
    flyBodyVelocity.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp
end

local function stopFly()
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    if flyBodyGyro then
        flyBodyGyro:Destroy()
        flyBodyGyro = nil
    end
end

MainTab:CreateToggle({
    Name = "Bật Fly (Dùng WSAD + Space/Shift để bay lên/xuống)",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        flying = Value
        if flying then
            startFly()
        else
            stopFly()
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

-- Noclip Toggle
local noclipEnabled = false

MainTab:CreateToggle({
    Name = "Bật Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(Value)
        noclipEnabled = Value
    end
})

RunService.Stepped:Connect(function()
    local char = player.Character
    if char then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then
                if noclipEnabled then
                    part.CanCollide = false
                else
                    part.CanCollide = true
                end
            end
        end
    end
end)

-- Sự kiện kiểm soát bay
RunService.Heartbeat:Connect(function()
    if flying and flyBodyVelocity and flyBodyGyro then
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

                flyBodyVelocity.Velocity = moveVec.Unit * flySpeed

                -- Bay lên và xuống
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    flyBodyVelocity.Velocity = flyBodyVelocity.Velocity + Vector3.new(0, flySpeed, 0)
                elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    flyBodyVelocity.Velocity = flyBodyVelocity.Velocity - Vector3.new(0, flySpeed, 0)
                end

                flyBodyGyro.CFrame = workspace.CurrentCamera.CFrame
            end
        end
    end
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
end)

Rayfield:Init()
