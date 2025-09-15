repeat task.wait(0.25) until game:IsLoaded();

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- Nút ImageButton toggle menu logo mới, kích thước 60x60
local ScreenGui = Instance.new("ScreenGui")
local ImageButton = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

ImageButton.Parent = ScreenGui
ImageButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ImageButton.BorderSizePixel = 0
ImageButton.Position = UDim2.new(0.1, 0, 0.15, 0)
ImageButton.Size = UDim2.new(0, 60, 0, 60)
ImageButton.Draggable = true
ImageButton.Image = "rbxassetid://117785786479587"

UICorner.CornerRadius = UDim.new(1, 10)
UICorner.Parent = ImageButton

ImageButton.MouseButton1Down:Connect(function()
    local VirtualInputManager = game:GetService("VirtualInputManager")
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.End, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.End, false, game)
end)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Hacker Script - Premium",
    SubTitle = "By Danhcng",
    TabWidth = 200,
    Size = UDim2.fromOffset(480, 350),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.End
})

local Tabs = {
    LocalPlayer = Window:AddTab({ Title = "LocalPlayer", Icon = "box" }),
    Server = Window:AddTab({ Title = "Server", Icon = "server" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- LocalPlayer Tab --

-- Reset Character (sửa lại, không còn lỗi khi bấm)
Tabs.LocalPlayer:AddButton({
    Title = "Reset Character",
    Callback = function()
        local char = LocalPlayer and LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local ok, err = pcall(function()
                char:BreakJoints()
            end)
            if ok then
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Reset",
                    Text = "Nhân vật đã được reset!",
                    Duration = 2
                })
            else
                game.StarterGui:SetCore("SendNotification", {
                    Title = "Reset Failed",
                    Text = "Lỗi khi reset nhân vật!",
                    Duration = 3
                })
                warn("Reset Character error:", err)
            end
        else
            game.StarterGui:SetCore("SendNotification", {
                Title = "Reset Failed",
                Text = "Không tìm thấy nhân vật!",
                Duration = 3
            })
        end
    end
})

-- WalkSpeed & JumpPower Save State Fix
local defaultWalkSpeed = 16
local defaultJumpPower = 50
local currentWalkSpeed = defaultWalkSpeed
local currentJumpPower = defaultJumpPower

local function applyStats()
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = currentWalkSpeed
        char:FindFirstChildOfClass("Humanoid").JumpPower = currentJumpPower
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    wait(1)
    applyStats()
end)

Tabs.LocalPlayer:AddSlider("WalkSpeedSlider", {
    Title = "Speed",
    Min = 8,
    Max = 100,
    Default = defaultWalkSpeed,
    Rounding = 0,
    Callback = function(val)
        currentWalkSpeed = val
        applyStats()
    end
})

Tabs.LocalPlayer:AddSlider("JumpPowerSlider", {
    Title = "Jump Power",
    Description = "Độ cao khi nhảy",
    Min = 20,
    Max = 200,
    Default = defaultJumpPower,
    Rounding = 0,
    Callback = function(val)
        currentJumpPower = val
        applyStats()
    end
})

-- Infinite Jump Fix
local infiniteJumpEnabled = false
Tabs.LocalPlayer:AddToggle("InfiniteJumpToggle", {
    Title = "Infinite Jump",
    Default = false,
    Callback = function(val)
        infiniteJumpEnabled = val
    end
})

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character:FindFirstChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and infiniteJumpEnabled and input.KeyCode == Enum.KeyCode.Space then
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ===== Safe notification helper (add once near top if not present) =====
local function sendNotification(title, text, duration)
    duration = duration or 4
    local ok = pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration
        })
    end)
    if ok then return end

    -- fallback small banner
    if game.CoreGui:FindFirstChild("_HackNotify") then
        pcall(function() game.CoreGui._HackNotify:Destroy() end)
    end
    local sg = Instance.new("ScreenGui")
    sg.Name = "_HackNotify"
    sg.ResetOnSpawn = false
    sg.Parent = game.CoreGui

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 420, 0, 72)
    frame.Position = UDim2.new(0.5, -210, 0.04, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BackgroundTransparency = 0.12
    frame.BorderSizePixel = 0

    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -20, 0, 24)
    titleLbl.Position = UDim2.new(0,10,0,6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.SourceSansBold
    titleLbl.TextSize = 18
    titleLbl.TextColor3 = Color3.fromRGB(255,255,255)
    titleLbl.Text = tostring(title)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local bodyLbl = Instance.new("TextLabel", frame)
    bodyLbl.Size = UDim2.new(1, -20, 1, -34)
    bodyLbl.Position = UDim2.new(0,10,0,30)
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.Font = Enum.Font.SourceSans
    bodyLbl.TextSize = 14
    bodyLbl.TextColor3 = Color3.fromRGB(230,230,230)
    bodyLbl.TextWrapped = true
    bodyLbl.Text = tostring(text)
    bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
    bodyLbl.TextYAlignment = Enum.TextYAlignment.Top

    task.delay(duration, function()
        pcall(function() sg:Destroy() end)
    end)
end

-- ===== FIXED ESP (robust, auto-add for new players/respawns, clean disconnect) =====
local espEnabled = false
local espHighlights = {}        -- player -> Highlight instance
local espCharConns = {}        -- player -> CharacterAdded connection
local espPlayerAddedConn = nil

local function removeHighlightFor(player)
    if espHighlights[player] then
        pcall(function() espHighlights[player]:Destroy() end)
        espHighlights[player] = nil
    end
end

local function createHighlightForCharacter(player)
    if not player or not player.Character then return end
    -- remove old highlight if any
    removeHighlightFor(player)
    local ok, err = pcall(function()
        local h = Instance.new("Highlight")
        h.Name = "ESP_Highlight"
        h.Adornee = player.Character
        h.FillColor = Color3.fromRGB(255, 0, 0)
        h.OutlineColor = Color3.fromRGB(255, 0, 0)
        h.Parent = player.Character
        espHighlights[player] = h
    end)
    if not ok then warn("createHighlightForCharacter error:", err) end
end

local function onCharacterAdded(player, char)
    -- delay tiny bit so character parts fully exist
    task.delay(0.12, function()
        if espEnabled then
            createHighlightForCharacter(player)
        end
    end)
end

local function enableESP()
    -- for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                createHighlightForCharacter(player)
            end
            -- connect CharacterAdded if not already
            if not espCharConns[player] then
                espCharConns[player] = player.CharacterAdded:Connect(function(c) onCharacterAdded(player, c) end)
            end
        end
    end
    -- listen for newly joined players
    if not espPlayerAddedConn then
        espPlayerAddedConn = Players.PlayerAdded:Connect(function(player)
            -- connect to their CharacterAdded
            espCharConns[player] = player.CharacterAdded:Connect(function(c) onCharacterAdded(player, c) end)
            -- if they already have a character immediately (rare), add highlight
            if player.Character then
                task.delay(0.12, function() if espEnabled then createHighlightForCharacter(player) end end)
            end
        end)
    end
end

local function disableESP()
    -- destroy highlights
    for p, h in pairs(espHighlights) do
        pcall(function() h:Destroy() end)
    end
    espHighlights = {}

    -- disconnect CharacterAdded connections
    for p, conn in pairs(espCharConns) do
        pcall(function() conn:Disconnect() end)
    end
    espCharConns = {}

    -- disconnect PlayerAdded
    if espPlayerAddedConn then
        pcall(function() espPlayerAddedConn:Disconnect() end)
        espPlayerAddedConn = nil
    end
end

-- Replace/Add this toggle (remove old AddToggle for "ESPToggle")
-- If you already have a Toggle, remove the earlier one to avoid duplicate callbacks.
Tabs.LocalPlayer:AddToggle("ESPToggle", {
    Title = "Esp",
    Description = "esp player",
    Default = false,
    Callback = function(val)
        espEnabled = val
        if espEnabled then
            enableESP()
            sendNotification("ESP", "ESP đã bật", 2)
        else
            disableESP()
            sendNotification("ESP", "ESP đã tắt", 2)
        end
    end
})

-- Clean up when a player leaves
Players.PlayerRemoving:Connect(function(player)
    -- remove highlight and disconnect character-connections for that player
    removeHighlightFor(player)
    if espCharConns[player] then
        pcall(function() espCharConns[player]:Disconnect() end)
        espCharConns[player] = nil
    end
end)

local noclipEnabled = false
Tabs.LocalPlayer:AddToggle("NoclipToggle", {
    Title = "Noclip",
    Description = "đi xuyên vật thể",
    Default = false,
    Callback = function(val)
        noclipEnabled = val
    end
})

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = not noclipEnabled
            end
        end
    end
end)

local aimEnabled = false
local aimKey = Enum.KeyCode.T
Tabs.LocalPlayer:AddToggle("AimToggle", {
    Title = "Aim",
    Description = "aim tâm vào player, chỉ phù hợp với game bắn súng",
    Default = false,
    Callback = function(val)
        aimEnabled = val
    end
})

local function isEnemy(p1, p2)
    if p1.Team and p2.Team then
        return p1.Team ~= p2.Team
    end
    return true
end

local function getNearestEnemy()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then return nil end
    local nearest, nearestDist = nil, math.huge
    local ownHeadPos = LocalPlayer.Character.Head.Position
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and isEnemy(LocalPlayer, p) then
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
    end
end)

RunService.RenderStepped:Connect(function()
    if aimEnabled then
        local target = getNearestEnemy()
        if target then
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, target.Position)
        end
    end
end)

local plr = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local flying = false
local speed = 50
local maxSpeed = 150

local torso, humanoid
local bodyVelocity, bodyGyro

local ctrl = {f=0,b=0,l=0,r=0}

local function disableHumanoidStates()
    if humanoid then
        local con
        con = humanoid.StateChanged:Connect(function(old,new)
            if flying then
                humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
            else
                con:Disconnect()
            end
        end)
    end
end

local function teleSmall()
    if torso and flying then
        local char = plr.Character
        if char and humanoid then
            local moveDir = humanoid.MoveDirection
            if moveDir.Magnitude > 0 then
                local cam = workspace.CurrentCamera.CFrame
                local moveVector = (cam.RightVector * moveDir.X + cam.LookVector * moveDir.Z).Unit * speed / 10
                char:TranslateBy(moveVector)
            end
        end
    end
end

local function Fly()
    local char = plr.Character or plr.CharacterAdded:Wait()
    torso = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")

    disableHumanoidStates()

    bodyGyro = Instance.new("BodyGyro", torso)
    bodyGyro.P = 9e4
    bodyGyro.maxTorque = Vector3.new(9e9,9e9,9e9)
    bodyGyro.cframe = torso.CFrame

    bodyVelocity = Instance.new("BodyVelocity", torso)
    bodyVelocity.velocity = Vector3.new(0,0.1,0)
    bodyVelocity.maxForce = Vector3.new(9e9,9e9,9e9)

    flying = true
    humanoid.PlatformStand = true
    char.Animate.Disabled = true

    spawn(function()
        while flying do
            teleSmall()
            wait(0.05)
        end
    end)

    while flying do
        RunService.Heartbeat:Wait()
        local moveVector = humanoid.MoveDirection
        if moveVector.Magnitude > 0 then
            local cam = workspace.CurrentCamera.CFrame
            local velocity = (cam.RightVector * moveVector.X + cam.LookVector * moveVector.Z).Unit * speed
            bodyVelocity.Velocity = Vector3.new(velocity.X,0,velocity.Z)
            bodyGyro.CFrame = CFrame.new(torso.Position, torso.Position + workspace.CurrentCamera.CFrame.LookVector)
        else
            bodyVelocity.Velocity = Vector3.new(0,0,0)
        end
    end
    -- Cleanup
    flying = false
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    if humanoid then humanoid.PlatformStand = false end
    if char.Animate then char.Animate.Disabled = false end
end

local function startFly() 
    if not flying then coroutine.wrap(Fly)() end 
end

local function stopFly() 
    flying = false 
end

-- Thêm toggle fly trong Fluent UI LocalPlayer tab
Tabs.LocalPlayer:AddToggle("FlyToggle", {
    Title = "Fly (Demo)",
    Default = false,
    Callback = function(val)
        if val then startFly() else stopFly() end
    end
})

-- Thêm slider điều chỉnh tốc độ bay trong Fluent UI tab LocalPlayer
Tabs.LocalPlayer:AddSlider("FlySpeedSlider", {
    Title = "Fly",
    Description = "Speed",
    Min = 10,
    Max = 150,
    Default = speed,
    Rounding = 0,
    Callback = function(val)
        speed = val
    end
})

local teleportUp = false
local teleportDown = false
local teleportHeight = 50

Tabs.LocalPlayer:AddToggle("TeleportUpToggle", {
    Title = "Teleport Up",
    Description = "teleport lên trời",
    Default = false,
    Callback = function(val)
        teleportUp = val
        if teleportUp then
            teleportDown = false
        end
    end
})

Tabs.LocalPlayer:AddToggle("TeleportDownToggle", {
    Title = "Teleport Down",
    Description = "teleport xuống dưới đất",
    Default = false,
    Callback = function(val)
        teleportDown = val
        if teleportDown then
            teleportUp = false
        end
    end
})

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
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

local autoClickEnabled = false
local autoClickDelay = 0.1

Tabs.LocalPlayer:AddToggle("AutoClickToggle", {
    Title = "Auto Click",
    Description = "Click như bình thường, không can thiệp",
    Default = false,
    Callback = function(val)
        autoClickEnabled = val
    end
})

RunService.RenderStepped:Connect(function()
    if autoClickEnabled then
        local vm = game:GetService("VirtualInputManager")
        vm:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(autoClickDelay)
        vm:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end)

-- ========== Others Player Section (as you requested) ==========
Tabs.LocalPlayer:AddSection("Others Player")

-- state for teleporting
local selectedPlayer = nil
local teleportEnabled = false
local teleportDelay = 1 -- default 1 second as you requested earlier; but slider will set 0.1-1
-- We'll set default to 1s to match your earlier preference (you asked default 1s before)
teleportDelay = 1

-- helper to build player list
local function getPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

-- Dropdown to select player (no description added since you asked not to add descriptions you didn't provide)
local teleportDropdown = Tabs.LocalPlayer:AddDropdown("TeleportPlayerDropdown", {
    Title = "Teleport to",
    Values = getPlayerList(),
    Multi = false,
    Default = "",
    Callback = function(val)
        selectedPlayer = val
    end
})

-- ===== Refresh Player List Button (Full) =====
-- Đảm bảo teleportDropdown đã được khai báo ở trên và Tabs.LocalPlayer tồn tại

local function safeRefreshPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end

    if teleportDropdown and type(teleportDropdown.SetValues) == "function" then
        local ok, err = pcall(function() teleportDropdown:SetValues(list) end)
        if ok then
            sendNotification("Player List", "Đã làm mới danh sách player!", 2)
        else
            warn("SetValues failed:", err)
            sendNotification("Refresh Failed", "Không thể cập nhật dropdown!", 3)
        end
    elseif teleportDropdown and teleportDropdown.Values ~= nil then
        local ok, err = pcall(function() teleportDropdown.Values = list end)
        if ok then
            sendNotification("Player List", "Đã làm mới danh sách player!", 2)
        else
            warn("Assign Values failed:", err)
            sendNotification("Refresh Failed", "Không thể cập nhật dropdown!", 3)
        end
    else
        sendNotification("Refresh Failed", "Dropdown chưa được tạo hoặc không hỗ trợ!", 3)
    end
end

-- Đây là nút sẽ hiện trong tab LocalPlayer
Tabs.LocalPlayer:AddButton({
    Title = "Refresh Player List",
    Callback = function()
        safeRefreshPlayerList()
    end
})

-- Teleport speed slider (0.1 - 1) — keep rounding 1 (Fluent uses Rounding as decimals count in some versions)
Tabs.LocalPlayer:AddSlider("TeleportSpeed", {
    Title = "Teleport",
    Description = "Speed",
    Min = 0.1,
    Max = 1,
    Default = 1,
    Rounding = 1,
    Callback = function(val)
        teleportDelay = val
    end
})

-- Teleport Toggle (continuous teleport while on)
local teleportToggleControl = nil
teleportToggleControl = Tabs.LocalPlayer:AddToggle("TeleportToggle", {
    Title = "Teleport To Player",
    Default = false,
    Callback = function(val)
        teleportEnabled = val
        if teleportEnabled then
            -- spawn loop
            task.spawn(function()
                while teleportEnabled do
                    if selectedPlayer and selectedPlayer ~= "" then
                        local target = Players:FindFirstChild(selectedPlayer)
                        local okTarget = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                        local okSelf = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if okTarget and okSelf then
                            pcall(function()
                                LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(2, 0, 0)
                            end)
                        else
                            -- if target not found (left or not loaded), auto disable teleport
                            teleportEnabled = false
                            pcall(function() teleportToggleControl:SetValue(false) end)
                            sendNotification("Teleport", "Target không tồn tại hoặc chưa load. Teleport đã tắt.", 3)
                            break
                        end
                    else
                        -- no selected player
                        teleportEnabled = false
                        pcall(function() teleportToggleControl:SetValue(false) end)
                        sendNotification("Teleport", "Bạn chưa chọn player. Teleport đã tắt.", 3)
                        break
                    end
                    task.wait(teleportDelay)
                end
            end)
        end
    end
})

-- Auto-disable teleport when selected player leaves
Players.PlayerRemoving:Connect(function(p)
    if p and p.Name == selectedPlayer then
        teleportEnabled = false
        pcall(function() teleportToggleControl:SetValue(false) end)
        sendNotification("Teleport", "Player đã rời. Teleport tự tắt.", 3)
    end
end)

-- Server Tab --

Tabs.Server:AddButton({
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

-- Thêm Server Hop vào tab Server
Tabs.Server:AddButton({
    Title = "Hop Server",
    Callback = function()
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")

        local success, result = pcall(function()
            local servers = HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            ))
            return servers
        end)

        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
                    return
                end
            end
            game.StarterGui:SetCore("SendNotification", {
                Title = "Server Hop",
                Text = "Không tìm thấy server khác!",
                Duration = 3
            })
        else
            game.StarterGui:SetCore("SendNotification", {
                Title = "Server Hop",
                Text = "Lỗi lấy danh sách server!",
                Duration = 3
            })
        end
    end
})

-- SaveManager & InterfaceManager section an toàn hơn --

local SaveManagerLib = game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua")
local SaveManager, InterfaceManager

local success
success, SaveManager = pcall(loadstring(SaveManagerLib))
if not success then
    warn("Failed to load SaveManager")
    SaveManager = nil
end

local InterfaceManagerLib = game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua")
success, InterfaceManager = pcall(loadstring(InterfaceManagerLib))
if not success then
    warn("Failed to load InterfaceManager")
    InterfaceManager = nil
end

if SaveManager and InterfaceManager then
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    
    InterfaceManager:SetFolder("FluentScriptHub")
    SaveManager:SetFolder("FluentScriptHub/specific-game")
    
    task.delay(1, function()
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
        SaveManager:BuildConfigSection(Tabs.Settings)
    
        local configPath = "FluentScriptHub/specific-game"
        if SaveManager.LoadConfig then
            local config = SaveManager:LoadConfig(configPath)
            if config then
                if not config.MinimizeKey or config.MinimizeKey == "..." then
                    config.MinimizeKey = "End"
                    if SaveManager.SaveConfig then
                        SaveManager:SaveConfig(configPath, config)
                    end
                end
            end
        end
    end)
else
    warn("SaveManager or InterfaceManager not loaded, config disabled")
end

Window:SelectTab(1)

Fluent:Notify({
    Title = "Owner",
    Content = "Hacker Script Loaded!",
    Duration = 6
})

-- Không gọi Window:Init()
