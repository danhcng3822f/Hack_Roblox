-- LocalScript: SpeedUI.lua

-- Tải Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Tạo cửa sổ giao diện
local Window = Rayfield:CreateWindow({
    Name = "Speed_Option",
    LoadingTitle = "Speed Control UI",
    LoadingSubtitle = "by Danh",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "SpeedSettings"
    },
    Discord = {
        Enabled = false
    }
})

-- Tạo tab "Main"
local MainTab = Window:CreateTab("Main", 4483362458) -- icon ID Roblox

-- Slider chỉnh tốc độ
local SpeedSlider = MainTab:CreateSlider({
    Name = "Chỉnh tốc độ chạy",
    Range = {8, 100}, -- tốc độ min - max
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16, -- mặc định
    Flag = "WalkSpeed",
    Callback = function(Value)
        -- Khi chỉnh slider, thay tốc độ
        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:WaitForChild("Humanoid")
        humanoid.WalkSpeed = Value
    end
})

-- Nút reset tốc độ về mặc định
MainTab:CreateButton({
    Name = "Reset tốc độ",
    Callback = function()
        SpeedSlider:Set(16)
    end
})