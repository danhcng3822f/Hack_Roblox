-- LocalScript: SpeedInfiniteJumpUI.lua

-- Tải Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Tạo cửa sổ giao diện
local Window = Rayfield:CreateWindow({
    Name = "Speed + Infinite Jump",
    LoadingTitle = "Speed & Jump UI",
    LoadingSubtitle = "by Danh",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "SpeedJumpSettings"
    },
    Discord = { Enabled = false }
})

local MainTab = Window:CreateTab("Main", 4483362458) -- icon ID Roblox

local player = game.Players.LocalPlayer
local infiniteJumpEnabled = false

-- Slider chỉnh tốc độ chạy
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

-- Nút Reset tốc độ
MainTab:CreateButton({
    Name = "Reset tốc độ",
    Callback = function()
        SpeedSlider:Set(16)
    end
})

-- Toggle bật/tắt Infinite Jump
MainTab:CreateToggle({
    Name = "Bật Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJumpToggle",
    Callback = function(Value)
        infiniteJumpEnabled = Value
    end
})

-- Xử lý sự kiện nhảy vô hạn
local UserInputService = game:GetService("UserInputService")

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

Rayfield:Init()
