local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kinlei/Rayfield/main/source.lua"))()

local player = game.Players.LocalPlayer
local humanoid = nil
local infiniteJumpEnabled = false

local function onCharacterAdded(character)
    humanoid = character:WaitForChild("Humanoid")
end

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

local Window = Rayfield:CreateWindow({
    Title = "Tùy chỉnh tốc độ & nhảy vô hạn",
    Center = true,
    AutoShow = true,
})

local PlayerTab = Window:CreateTab("Player Settings")

local function setWalkSpeed(speed)
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

PlayerTab:CreateSlider({
    Name = "Tốc độ chạy",
    Range = {16, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = setWalkSpeed,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    Flag = "InfiniteJumpToggle",
    CurrentValue = false,
    Callback = function(value)
        infiniteJumpEnabled = value
    end,
})

local UserInputService = game:GetService("UserInputService")

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

Rayfield:Init()
