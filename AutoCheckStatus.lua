-- Bộ nhớ lưu lỗi console gần đây, giới hạn 50 lỗi
local maxBugLog = 50
local bugLogs = {}

-- Bắt lỗi console, ghi lại lỗi đỏ
local function onConsoleMessage(message, messageType)
    if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
        if #bugLogs >= maxBugLog then
            table.remove(bugLogs, 1)
        end
        table.insert(bugLogs, message)
    end
end
game:GetService("LogService").MessageOut:Connect(onConsoleMessage)

-- Tạo Frame UI cho show bug (AutoBugWindow)
local function createAutoBugWindow()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoBugWindow"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game.CoreGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.fromOffset(480, 350)
    Frame.Position = UDim2.new(0.5, -240, 0.5, -175)  -- đặt giữa màn hình
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BorderSizePixel = 0
    Frame.Visible = true
    Frame.Parent = ScreenGui

    -- Enable draggable behavior
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragInput
    local dragStart
    local startPos

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

    -- Tiêu đề
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = "Auto Bug Status"
    TitleLabel.Size = UDim2.new(1, 0, 0, 40)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 24
    TitleLabel.Parent = Frame

    -- Nút đóng
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

    -- ScrollFrame chứa log lỗi
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
        NoBugLabel.Text = "No Bugs"
        NoBugLabel.Size = UDim2.new(1, 0, 0, 30)
        NoBugLabel.BackgroundTransparency = 1
        NoBugLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        NoBugLabel.Font = Enum.Font.SourceSansBold
        NoBugLabel.TextSize = 20
        NoBugLabel.Parent = ScrollFrame
    else
        local yPos = 0
        for i, log in ipairs(bugLogs) do
            local label = Instance.new("TextLabel")
            label.Text = log
            label.TextWrapped = true
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(255, 0, 0)
            label.Font = Enum.Font.SourceSans
            label.TextSize = 18
            label.Size = UDim2.new(1, 0, 0, 40)
            label.Position = UDim2.new(0, 0, 0, yPos)
            label.Parent = ScrollFrame
            yPos = yPos + 40
        end
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
    end
end

-- Tự động kiểm tra menu chính trong 5 giây, nếu không có hoặc lỗi thì mở AutoBugWindow
task.spawn(function()
    task.wait(5)
    local Fluent = _G.FluentGlobalObject or nil
    local Window = Fluent and Fluent:GetWindow() or nil
    local Tabs = Window and Window.Tabs or nil
    if not Window or not Tabs or not Tabs.LocalPlayer or not Tabs.Server or not Tabs.Settings then
        if not game.CoreGui:FindFirstChild("AutoBugWindow") then
            createAutoBugWindow()
        end
    end
end)
