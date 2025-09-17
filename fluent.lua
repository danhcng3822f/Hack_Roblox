-- Roblox Error Fallback System
local ErrorHandler = {}

-- Services
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")

-- 1. Basic Fallback cho Roblox
function ErrorHandler.executeWithFallback(primaryFunc, fallbackFunc, ...)
    local success, result = pcall(primaryFunc, ...)
    
    if success then
        return result
    else
        warn("⚠️ Primary function failed: " .. tostring(result))
        warn("🔄 Using fallback function...")
        
        local fallbackSuccess, fallbackResult = pcall(fallbackFunc, ...)
        
        if fallbackSuccess then
            print("✅ Fallback succeeded!")
            return fallbackResult
        else
            error("❌ Both primary and fallback functions failed!\nPrimary: " .. tostring(result) .. "\nFallback: " .. tostring(fallbackResult))
        end
    end
end

-- 2. Fallback với retry cho network requests
function ErrorHandler.httpRequestWithFallback(url, fallbackUrls, maxRetries)
    local HttpService = game:GetService("HttpService")
    maxRetries = maxRetries or 3
    fallbackUrls = fallbackUrls or {}
    
    local urls = {url}
    for _, fallbackUrl in ipairs(fallbackUrls) do
        table.insert(urls, fallbackUrl)
    end
    
    for urlIndex, currentUrl in ipairs(urls) do
        for attempt = 1, maxRetries do
            local success, result = pcall(function()
                return HttpService:GetAsync(currentUrl)
            end)
            
            if success then
                if urlIndex > 1 or attempt > 1 then
                    warn("✅ Request succeeded using " .. (urlIndex == 1 and "primary URL" or "fallback URL #" .. (urlIndex - 1)) .. " on attempt #" .. attempt)
                end
                return result
            else
                warn("⚠️ URL #" .. urlIndex .. " attempt #" .. attempt .. " failed: " .. tostring(result))
                wait(attempt * 0.5)
            end
        end
    end
    
    error("❌ All HTTP requests failed!")
end

-- 3. Safe Remote Event Handler
function ErrorHandler.safeRemoteEventHandler(remoteEvent, handler, fallbackHandler)
    remoteEvent.OnServerEvent:Connect(function(player, ...)
        local success, result = pcall(handler, player, ...)
        
        if not success then
            warn("⚠️ Remote event handler failed for player " .. player.Name .. ": " .. tostring(result))
            
            if fallbackHandler then
                local fallbackSuccess, fallbackResult = pcall(fallbackHandler, player, ...)
                if not fallbackSuccess then
                    warn("❌ Fallback handler also failed: " .. tostring(fallbackResult))
                end
            end
        end
    end)
end

-- 4. Safe DataStore operations
function ErrorHandler.safeDataStoreOperation(operation, fallbackData, maxRetries)
    maxRetries = maxRetries or 5
    
    for attempt = 1, maxRetries do
        local success, result = pcall(operation)
        
        if success then
            if attempt > 1 then
                warn("✅ DataStore operation succeeded on attempt #" .. attempt)
            end
            return result
        else
            warn("⚠️ DataStore attempt #" .. attempt .. " failed: " .. tostring(result))
            
            if attempt < maxRetries then
                local waitTime = math.min(2^attempt, 10)
                wait(waitTime)
            end
        end
    end
    
    warn("❌ All DataStore attempts failed, using fallback data")
    return fallbackData
end

-- 5. Global Error Handler cho toàn bộ script
function ErrorHandler.setupGlobalErrorHandler()
    local function handleError(message, trace)
        warn("🚨 GLOBAL ERROR CAUGHT:")
        warn("Message: " .. tostring(message))
        warn("Stack trace: " .. tostring(trace))
        
        local errorInfo = {
            message = tostring(message),
            trace = tostring(trace),
            timestamp = os.time(),
            place = game.PlaceId
        }
        
        print("Error logged:", game:GetService("HttpService"):JSONEncode(errorInfo))
    end
    
    if RunService:IsServer() then
        game:GetService("ScriptContext").Error:Connect(handleError)
    end
end

-- 6. Safe tween với fallback
function ErrorHandler.safeTween(object, info, properties, onComplete, onError)
    local TweenService = game:GetService("TweenService")
    
    local success, tween = pcall(function()
        return TweenService:Create(object, info, properties)
    end)
    
    if success then
        if onComplete then
            tween.Completed:Connect(onComplete)
        end
        
        local playSuccess = pcall(function()
            tween:Play()
        end)
        
        if not playSuccess and onError then
            warn("⚠️ Tween play failed, executing error callback")
            onError()
        end
        
        return tween
    else
        warn("❌ Failed to create tween: " .. tostring(tween))
        if onError then
            onError()
        end
        return nil
    end
end

-- 7. Heartbeat với error handling
function ErrorHandler.safeHeartbeat(func, errorCallback)
    local connection
    connection = RunService.Heartbeat:Connect(function(...)
        local success, result = pcall(func, ...)
        
        if not success then
            warn("⚠️ Heartbeat function error: " .. tostring(result))
            if errorCallback then
                errorCallback(result)
            end
        end
    end)
    
    return connection
end

-- 8. Safe Library Loading
function ErrorHandler.loadLibrarySafely(urls, libName)
    return ErrorHandler.executeWithFallback(
        function()
            return loadstring(game:HttpGet(urls[1]))()
        end,
        function()
            for i = 2, #urls do
                local success, result = pcall(function()
                    return loadstring(game:HttpGet(urls[i]))()
                end)
                if success then
                    warn("Loaded " .. libName .. " from backup URL #" .. (i-1))
                    return result
                end
            end
            error("All URLs failed for " .. libName)
        end
    )
end

-- 9. Safe Character Operations
function ErrorHandler.safeCharacterOperation(operation, fallbackOperation)
    return ErrorHandler.executeWithFallback(
        function()
            local char = Players.LocalPlayer.Character
            if not char then error("No character") end
            return operation(char)
        end,
        fallbackOperation or function()
            warn("Character operation failed, waiting for respawn...")
            Players.LocalPlayer.CharacterAdded:Wait()
            local char = Players.LocalPlayer.Character
            return operation(char)
        end
    )
end

-- ===== MAIN SCRIPT =====

repeat task.wait(0.25) until game:IsLoaded();

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- Setup global error handler
ErrorHandler.setupGlobalErrorHandler()

-- Bộ nhớ lưu lỗi console
local maxBugLog = 50
local bugLogs = {}

-- Override warn để log vào bugLogs
local originalWarn = warn
warn = function(...)
    originalWarn(...)
    local message = table.concat({...}, " ")
    if #bugLogs >= maxBugLog then
        table.remove(bugLogs, 1)
    end
    table.insert(bugLogs, "[WARN] " .. message)
end

-- Bắt lỗi console
local function onConsoleMessage(message, messageType)
    if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
        if #bugLogs >= maxBugLog then
            table.remove(bugLogs, 1)
        end
        table.insert(bugLogs, message)
    end
end
game:GetService("LogService").MessageOut:Connect(onConsoleMessage)

-- Safe notification helper
local function sendNotification(title, text, duration)
    duration = duration or 4
    return ErrorHandler.executeWithFallback(
        function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = tostring(title),
                Text = tostring(text),
                Duration = duration
            })
        end,
        function()
            -- Fallback UI notification
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
    )
end

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

-- Load Fluent UI với fallback URLs
local fluentUrls = {
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/main/src/init.lua"
}

local Fluent = ErrorHandler.loadLibrarySafely(fluentUrls, "Fluent")

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
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Bugs = Window:AddTab({ Title = "Bugs", Icon = "terminal" })
}

-- Reset Character với ErrorHandler
Tabs.LocalPlayer:AddButton({
    Title = "Reset Character",
    Callback = function()
        ErrorHandler.safeCharacterOperation(
            function(char)
                char:BreakJoints()
                sendNotification("Reset", "Nhân vật đã được reset!", 2)
            end,
            function()
                sendNotification("Reset Failed", "Không thể reset nhân vật!", 3)
            end
        )
    end
})

-- God Mode với ErrorHandler
local godModeEnabled = false
local godModeConnection = nil

local function applyGodMode(humanoid)
    return ErrorHandler.executeWithFallback(
        function()
            humanoid.Health = humanoid.MaxHealth
            return humanoid.HealthChanged:Connect(function(health)
                if health < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
        end,
        function()
            warn("HealthChanged failed, using Heartbeat fallback")
            return RunService.Heartbeat:Connect(function()
                if humanoid and humanoid.Parent then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
        end
    )
end

Tabs.LocalPlayer:AddToggle("GodModeToggle", {
    Title = "God Mode",
    Default = false,
    Callback = function(val)
        godModeEnabled = val
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end
        if godModeEnabled then
            ErrorHandler.safeCharacterOperation(function(char)
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    godModeConnection = applyGodMode(humanoid)
                end
            end)
        end
    end
})

-- WalkSpeed & JumpPower với ErrorHandler
local defaultWalkSpeed = 16
local defaultJumpPower = 50
local currentWalkSpeed = defaultWalkSpeed
local currentJumpPower = defaultJumpPower

local function applyStats()
    ErrorHandler.safeCharacterOperation(function(char)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = currentWalkSpeed
            humanoid.JumpPower = currentJumpPower
        end
    end)
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
    Description = "Nhảy Cao",
    Min = 20,
    Max = 200,
    Default = defaultJumpPower,
    Rounding = 0,
    Callback = function(val)
        currentJumpPower = val
        applyStats()
    end
})

-- Infinite Jump
local infiniteJumpEnabled = false
Tabs.LocalPlayer:AddToggle("InfiniteJumpToggle", {
    Title = "Infinite Jump",
    Default = false,
    Callback = function(val)
        infiniteJumpEnabled = val
    end
})

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        ErrorHandler.safeCharacterOperation(function(char)
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- ESP với ErrorHandler và fallback
local espEnabled = false
local espHighlights = {}
local espCharConns = {}
local espPlayerAddedConn = nil

local function removeHighlightFor(player)
    if espHighlights[player] then
        pcall(function() espHighlights[player]:Destroy() end)
        espHighlights[player] = nil
    end
end

local function createHighlightForCharacter(player)
    if not player or not player.Character then return end
    
    return ErrorHandler.executeWithFallback(
        function()
            removeHighlightFor(player)
            local h = Instance.new("Highlight")
            h.Name = "ESP_Highlight"
            h.Adornee = player.Character
            h.FillColor = Color3.fromRGB(255, 0, 0)
            h.OutlineColor = Color3.fromRGB(255, 0, 0)
            h.Parent = player.Character
            espHighlights[player] = h
            return h
        end,
        function()
            warn("Highlight failed, using BillboardGui fallback")
            local head = player.Character:FindFirstChild("Head")
            if not head then return nil end
            
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_Billboard"
            billboard.Parent = head
            billboard.Size = UDim2.new(0, 100, 0, 50)
            
            local frame = Instance.new("Frame", billboard)
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            frame.BackgroundTransparency = 0.5
            frame.BorderSizePixel = 2
            
            local label = Instance.new("TextLabel", frame)
            label.Text = player.Name
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextScaled = true
            
            espHighlights[player] = billboard
            return billboard
        end
    )
end

local function onCharacterAdded(player, char)
    task.delay(0.12, function()
        if espEnabled then
            createHighlightForCharacter(player)
        end
    end)
end

local function enableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                createHighlightForCharacter(player)
            end
            if not espCharConns[player] then
                espCharConns[player] = player.CharacterAdded:Connect(function(c) onCharacterAdded(player, c) end)
            end
        end
    end
    if not espPlayerAddedConn then
        espPlayerAddedConn = Players.PlayerAdded:Connect(function(player)
            espCharConns[player] = player.CharacterAdded:Connect(function(c) onCharacterAdded(player, c) end)
            if player.Character then
                task.delay(0.12, function() if espEnabled then createHighlightForCharacter(player) end end)
            end
        end)
    end
end

local function disableESP()
    for p, h in pairs(espHighlights) do
        pcall(function() h:Destroy() end)
    end
    espHighlights = {}
    
    for p, conn in pairs(espCharConns) do
        pcall(function() conn:Disconnect() end)
    end
    espCharConns = {}
    
    if espPlayerAddedConn then
        pcall(function() espPlayerAddedConn:Disconnect() end)
        espPlayerAddedConn = nil
    end
end

Tabs.LocalPlayer:AddToggle("ESPToggle", {
    Title = "Esp",
    Description = "Esp Player",
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

Players.PlayerRemoving:Connect(function(player)
    removeHighlightFor(player)
    if espCharConns[player] then
        pcall(function() espCharConns[player]:Disconnect() end)
        espCharConns[player] = nil
    end
end)

-- Noclip
local noclipEnabled = false
Tabs.LocalPlayer:AddToggle("NoclipToggle", {
    Title = "Noclip",
    Default = false,
    Callback = function(val)
        noclipEnabled = val
    end
})

ErrorHandler.safeHeartbeat(function()
    if noclipEnabled then
        ErrorHandler.safeCharacterOperation(function(char)
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end)

-- Aim với ErrorHandler
local aimEnabled = false
Tabs.LocalPlayer:AddToggle("AimToggle", {
    Title = "Aim",
    Description = "Aim tâm, không phải skill",
    Default = false,
    Callback = function(val)
        aimEnabled = val
    end
})

local function getNearestEnemy()
    return ErrorHandler.executeWithFallback(
        function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("Head") then return nil end
            
            local nearest, nearestDist = nil, math.huge
            local ownHeadPos = char.Head.Position
            
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                    local dist = (ownHeadPos - p.Character.Head.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = p.Character.Head
                    end
                end
            end
            return nearest
        end,
        function()
            return nil
        end
    )
end

ErrorHandler.safeHeartbeat(function()
    if aimEnabled then
        local target = getNearestEnemy()
        if target then
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, target.Position)
        end
    end
end)

-- Fly với ErrorHandler
local flying = false
local speed = 50

local function Fly()
    return ErrorHandler.safeCharacterOperation(function(char)
        local torso = char:WaitForChild("HumanoidRootPart")
        local humanoid = char:WaitForChild("Humanoid")

        local bodyGyro = Instance.new("BodyGyro", torso)
        bodyGyro.P = 9e4
        bodyGyro.maxTorque = Vector3.new(9e9,9e9,9e9)
        bodyGyro.cframe = torso.CFrame

        local bodyVelocity = Instance.new("BodyVelocity", torso)
        bodyVelocity.velocity = Vector3.new(0,0.1,0)
        bodyVelocity.maxForce = Vector3.new(9e9,9e9,9e9)

        flying = true
        humanoid.PlatformStand = true
        char.Animate.Disabled = true

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
        
        flying = false
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        if humanoid then humanoid.PlatformStand = false end
        if char.Animate then char.Animate.Disabled = false end
    end)
end

Tabs.LocalPlayer:AddToggle("FlyToggle", {
    Title = "Fly (Demo)",
    Default = false,
    Callback = function(val)
        if val and not flying then 
            task.spawn(Fly)
        else 
            flying = false 
        end
    end
})

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

-- Auto Click
local autoClickEnabled = false
Tabs.LocalPlayer:AddToggle("AutoClickToggle", {
    Title = "Auto Click",
    Description = "Click như bình thường, nhưng nó tự động",
    Default = false,
    Callback = function(val)
        autoClickEnabled = val
    end
})

ErrorHandler.safeHeartbeat(function()
    if autoClickEnabled then
        ErrorHandler.executeWithFallback(
            function()
                local vm = game:GetService("VirtualInputManager")
                vm:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.1)
                vm:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end,
            function()
                warn("Auto click failed")
            end
        )
    end
end)

-- Others Player Section
Tabs.LocalPlayer:AddSection("Others Player")

local selectedPlayer = nil
local teleportEnabled = false
local spectateEnabled = false
local teleportDelay = 1

local function getPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

local playerDropdown = Tabs.LocalPlayer:AddDropdown("PlayerDropdown", {
    Title = "Player List",
    Values = getPlayerList(),
    Multi = false,
    Default = "",
    Callback = function(val)
        selectedPlayer = val
    end
})

local function safeRefreshPlayerList()
    return ErrorHandler.executeWithFallback(
        function()
            local list = getPlayerList()
            playerDropdown:SetValues(list)
            sendNotification("Player List", "Đã làm mới danh sách player!", 2)
        end,
        function()
            sendNotification("Refresh Failed", "Không thể cập nhật dropdown!", 3)
        end
    )
end

Tabs.LocalPlayer:AddButton({
    Title = "Refresh Player List",
    Callback = function()
        safeRefreshPlayerList()
    end
})

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

local teleportToggleControl
teleportToggleControl = Tabs.LocalPlayer:AddToggle("TeleportToggle", {
    Title = "Teleport To Player",
    Default = false,
    Callback = function(val)
        teleportEnabled = val
        if teleportEnabled then
            task.spawn(function()
                while teleportEnabled do
                    ErrorHandler.executeWithFallback(
                        function()
                            if selectedPlayer and selectedPlayer ~= "" then
                                local target = Players:FindFirstChild(selectedPlayer)
                                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and
                                   LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    LocalPlayer.Character.HumanoidRootPart.CFrame =
                                        target.Character.HumanoidRootPart.CFrame + Vector3.new(2, 0, 0)
                                else
                                    error("Target not found")
                                end
                            else
                                error("No player selected")
                            end
                        end,
                        function()
                            teleportEnabled = false
                            teleportToggleControl:SetValue(false)
                        end
                    )
                    task.wait(teleportDelay)
                end
            end)
        end
    end
})

local spectateToggleControl
spectateToggleControl = Tabs.LocalPlayer:AddToggle("SpectateToggle", {
    Title = "Spectate Player",
    Default = false,
    Callback = function(val)
        spectateEnabled = val
        if spectateEnabled then
            task.spawn(function()
                while spectateEnabled do
                    ErrorHandler.executeWithFallback(
                        function()
                            if selectedPlayer and selectedPlayer ~= "" then
                                local target = Players:FindFirstChild(selectedPlayer)
                                if target and target.Character and target.Character:FindFirstChild("Head") then
                                    workspace.CurrentCamera.CameraSubject = target.Character:FindFirstChild("Head")
                                else
                                    error("Target not found")
                                end
                            else
                                error("No player selected")
                            end
                        end,
                        function()
                            spectateEnabled = false
                            spectateToggleControl:SetValue(false)
                            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                                workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Head")
                            end
                        end
                    )
                    task.wait(0.1)
                end
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Head")
                end
            end)
        else
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Head")
            end
        end
    end
})

-- Auto disable teleport/spectate khi player rời game
Players.PlayerRemoving:Connect(function(p)
    if p and p.Name == selectedPlayer then
        if teleportEnabled then
            teleportEnabled = false
            teleportToggleControl:SetValue(false)
        end
        if spectateEnabled then
            spectateEnabled = false
            spectateToggleControl:SetValue(false)
        end
    end
end)

-- Server Tab
Tabs.Server:AddButton({
    Title = "Rejoin Server",
    Callback = function()
        ErrorHandler.executeWithFallback(
            function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end,
            function()
                sendNotification("Rejoin Failed", "Không thể rejoin server!", 3)
            end
        )
    end
})

Tabs.Server:AddButton({
    Title = "Hop Server",
    Callback = function()
        ErrorHandler.executeWithFallback(
            function()
                local HttpService = game:GetService("HttpService")
                local servers = HttpService:JSONDecode(game:HttpGet(
                    "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                ))
                
                if servers and servers.data then
                    for _, server in ipairs(servers.data) do
                        if server.playing < server.maxPlayers and server.id ~= game.JobId then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
                            return
                        end
                    end
                    sendNotification("Server Hop", "Không tìm thấy server khác!", 3)
                else
                    error("No server data")
                end
            end,
            function()
                sendNotification("Server Hop", "Lỗi lấy danh sách server!", 3)
            end
        )
    end
})

-- Bug Window Creation với ErrorHandler
local function createBugWindow()
    return ErrorHandler.executeWithFallback(
        function()
            local ScreenGui = Instance.new("ScreenGui")
            ScreenGui.Name = "BugWindow"
            ScreenGui.ResetOnSpawn = false
            ScreenGui.Parent = game.CoreGui

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.fromOffset(480, 350)
            Frame.Position = UDim2.new(0.5, -240, 0.5, -175)
            Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            Frame.BorderSizePixel = 0
            Frame.Visible = true
            Frame.Parent = ScreenGui

            -- Draggable behavior
            local dragging = false
            local dragInput, dragStart, startPos

            local function update(input)
                local delta = input.Position - dragStart
                Frame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end

            Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    dragStart = input.Position
                    startPos = Frame.Position

                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end)

            Frame.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    dragInput = input
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and dragging then
                    update(input)
                end
            end)

            -- Title
            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Text = "Bugs Status"
            TitleLabel.Size = UDim2.new(1, 0, 0, 40)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            TitleLabel.Font = Enum.Font.SourceSansBold
            TitleLabel.TextSize = 24
            TitleLabel.Parent = Frame

            -- Close Button
            local CloseButton = Instance.new("TextButton")
            CloseButton.Text = "X"
            CloseButton.Size = UDim2.new(0, 30, 0, 30)
            CloseButton.Position = UDim2.new(1, -35, 0, 5)
            CloseButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            CloseButton.TextColor3 = Color3.fromRGB(255, 0, 0)
            CloseButton.Font = Enum.Font.SourceSansBold
            CloseButton.TextSize = 20
            CloseButton.Parent = Frame

            CloseButton.MouseButton1Click:Connect(function()
                ScreenGui:Destroy()
            end)

            -- ScrollFrame
            local ScrollFrame = Instance.new("ScrollingFrame")
            ScrollFrame.Size = UDim2.new(1, -20, 1, -50)
            ScrollFrame.Position = UDim2.new(0, 10, 0, 40)
            ScrollFrame.BackgroundTransparency = 1
            ScrollFrame.BorderSizePixel = 0
            ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            ScrollFrame.Parent = Frame
            ScrollFrame.ScrollBarThickness = 6

            if #bugLogs == 0 then
                local NoBugLabel = Instance.new("TextLabel")
                NoBugLabel.Text = "No Bugs Found - All Systems Running Smoothly!"
                NoBugLabel.Size = UDim2.new(1, 0, 0, 50)
                NoBugLabel.BackgroundTransparency = 1
                NoBugLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                NoBugLabel.Font = Enum.Font.SourceSansBold
                NoBugLabel.TextSize = 18
                NoBugLabel.TextWrapped = true
                NoBugLabel.Parent = ScrollFrame
            else
                local yPos = 0
                for i, log in ipairs(bugLogs) do
                    local label = Instance.new("TextLabel")
                    label.Text = "[" .. i .. "] " .. log
                    label.TextWrapped = true
                    label.BackgroundTransparency = 1
                    label.TextColor3 = Color3.fromRGB(255, 100, 100)
                    label.Font = Enum.Font.SourceSans
                    label.TextSize = 14
                    label.Size = UDim2.new(1, 0, 0, 40)
                    label.Position = UDim2.new(0, 0, 0, yPos)
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    label.Parent = ScrollFrame
                    yPos = yPos + 40
                end
                ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
            end
            
            return ScreenGui
        end,
        function()
            warn("Failed to create bug window, using simple notification")
            sendNotification("Bug Status", #bugLogs .. " bugs logged", 5)
            return nil
        end
    )
end

-- Bugs Tab
Tabs.Bugs:AddButton({
    Title = "Check Status",
    Description = "Xem tình trạng lỗi trong game",
    Callback = function()
        if not game.CoreGui:FindFirstChild("BugWindow") then
            createBugWindow()
        else
            sendNotification("Bug Window", "Cửa sổ bug đã mở!", 2)
        end
    end
})

Tabs.Bugs:AddButton({
    Title = "Clear Bug Logs",
    Description = "Xóa tất cả log lỗi",
    Callback = function()
        bugLogs = {}
        sendNotification("Bug Logs", "Đã xóa tất cả log lỗi!", 2)
    end
})

Tabs.Bugs:AddSection("Setting Bug Logs")

Tabs.Bugs:AddToggle("GlobalErrorHandlerToggle", {
    Title = "Global Error Handler",
    Description = "Hệ thống bắt lỗi toàn cục",
    Default = true,
    Callback = function(val)
        if val then
            ErrorHandler.setupGlobalErrorHandler()
            sendNotification("Error Handler", "Global Error Handler đã bật!", 2)
        else
            sendNotification("Error Handler", "Global Error Handler đã tắt!", 2)
        end
    end
})

Tabs.Bugs:AddSlider("MaxBugLogs", {
    Title = "Max Bug Logs",
    Description = "Số lượng log lỗi tối đa",
    Min = 10,
    Max = 100,
    Default = 50,
    Rounding = 0,
    Callback = function(val)
        maxBugLog = val
        while #bugLogs > maxBugLog do
            table.remove(bugLogs, 1)
        end
        sendNotification("Bug Logs", "Đã cập nhật giới hạn log: " .. val, 2)
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

-- Final Notification với ErrorHandler
ErrorHandler.executeWithFallback(
    function()
        Fluent:Notify({
            Title = "Script Loaded!",
            Content = "Hacker Script Premium đã tải thành công với ErrorHandler!",
            Duration = 6
        })
    end,
    function()
        sendNotification("Script Loaded", "Hacker Script Premium đã sẵn sàng!", 4)
    end
)
    
    -- Cleanup function để tránh memory leaks
local function cleanup()
    -- Disconnect all connections
    if godModeConnection then godModeConnection:Disconnect() end
    disableESP()
    flying = false
    
    -- Clear bug logs
    bugLogs = {}
    
    print("✅ Script cleanup completed!")
end

-- Return ErrorHandler để có thể sử dụng externally nếu cần
return ErrorHandler