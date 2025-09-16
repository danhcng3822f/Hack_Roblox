-- Bộ nhớ lưu tất cả message console gần đây, giới hạn 50 dòng
local maxLogCount = 50
local allConsoleLogs = {}

-- Bắt tất cả message console (lỗi, cảnh báo, thông tin)
local function onConsoleMessage(message, messageType)
    if #allConsoleLogs >= maxLogCount then
        table.remove(allConsoleLogs, 1)
    end
    table.insert(allConsoleLogs, {Text = message, Type = messageType})
end
game:GetService("LogService").MessageOut:Connect(onConsoleMessage)

-- Tạo UI hiển thị tất cả console logs
local function createAutoBugWindow()
    if game.CoreGui:FindFirstChild("AutoBugWindow") then
        return -- tránh tạo nhiều cửa sổ
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoBugWindow"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game.CoreGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.fromOffset(600, 400)
    Frame.Position = UDim2.new(0.5, -300, 0.5, -200)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BorderSizePixel = 0
    Frame.Visible = true
    Frame.Parent = ScreenGui

    -- Dragging support
    local UserInputService = game:GetService("UserInputService")
    local dragging, dragInput, dragStart, startPos

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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
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
    TitleLabel.Text = "Auto Check Status"
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

    -- ScrollFrame chứa log
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -20, 1, -50)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 40)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.ScrollBarThickness = 6
    ScrollFrame.Parent = Frame

    local function createLogLabel(text, messageType, yPos)
        local label = Instance.new("TextLabel")
        label.Text = text
        label.TextWrapped = true
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.SourceSans
        label.TextSize = 18
        label.Size = UDim2.new(1, 0, 0, 40)
        label.Position = UDim2.new(0, 0, 0, yPos)
        if messageType == Enum.MessageType.MessageError then
            label.TextColor3 = Color3.fromRGB(255, 80, 80)
        elseif messageType == Enum.MessageType.MessageWarning then
            label.TextColor3 = Color3.fromRGB(255, 200, 80)
        else
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        label.Parent = ScrollFrame
        return label
    end

    if #allConsoleLogs == 0 then
        local NoLogLabel = Instance.new("TextLabel")
        NoLogLabel.Text = "No Console Messages"
        NoLogLabel.Size = UDim2.new(1, 0, 0, 30)
        NoLogLabel.BackgroundTransparency = 1
        NoLogLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        NoLogLabel.Font = Enum.Font.SourceSansBold
        NoLogLabel.TextSize = 20
        NoLogLabel.Parent = ScrollFrame
    else
        local yPos = 0
        for i, log in ipairs(allConsoleLogs) do
            createLogLabel(log.Text, log.Type, yPos)
            yPos = yPos + 40
        end
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
    end
end

-- Tự động kiểm tra Fluent UI lỗi và tự mở UI báo bug
task.spawn(function()
    task.wait(5) -- Đợi 5s cho các UI Fluent load
    local FluentGlobal = _G.FluentGlobalObject or nil
    local Window = FluentGlobal and FluentGlobal:GetWindow() or nil
    local Tabs = Window and Window.Tabs or nil
    if not Window or not Tabs or not Tabs.LocalPlayer or not Tabs.Server or not Tabs.Settings then
        if not game.CoreGui:FindFirstChild("AutoBugWindow") then
            createAutoBugWindow()
        end
    end
end)
