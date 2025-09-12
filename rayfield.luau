-- Load Rayfield UI library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local player = game.Players.LocalPlayer
local humanoid = nil
local infiniteJumpEnabled = false

-- Tạo cửa sổ giao diện người dùng
local Window = Rayfield:CreateWindow({
    Title = "Tùy chỉnh tốc độ & nhảy vô hạn",
    Center = true,
    AutoShow = true,
})

local PlayerTab = Window:CreateTab("Player Settings")

-- Hàm thay đổi tốc độ chạy của người chơi
local function setWalkSpeed(speed)
    humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

-- Tạo slider điều chỉnh tốc độ chạy
PlayerTab:CreateSlider({
    Name = "Tốc độ chạy",
    Range = {16, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(value)
        setWalkSpeed(value)
    end,
})

-- Tạo toggle cho tính năng infinite jump
PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    Flag = "InfiniteJumpToggle",
    CurrentValue = false,
    Callback = function(value)
        infiniteJumpEnabled = value
    end,
})

-- Xử lý nhảy vô hạn trên sự kiện UserInputService
local UserInputService = game:GetService("UserInputService")

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

Rayfield:Init()
