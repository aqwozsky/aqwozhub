-- Aqwoz Hub - Custom UI Version
-- Fully custom GUI to ensure compatibility and clickability on all executors

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local vim = game:GetService("VirtualInputManager")

-- Configuration
local Config = {
    SilentAim = false,
    Aimlock = false,
    TeamCheck = false,
    Visuals = {
        Enabled = false,
        Boxes = false,
        Names = false,
        Health = false,
        TeamCheck = false
    },
    Whitelist = {}
}

-- Variables
local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local targetPlayer = nil
local isLeftMouseDown = false
local isRightMouseDown = false
local autoClickConnection = nil
local ESP_Folder = Instance.new("Folder", Workspace)
ESP_Folder.Name = "AqwozHub_ESP"

-- UI Functions
local function create_ui()
    -- Cleanup existing
    if CoreGui:FindFirstChild("AqwozHub") then
        CoreGui.AqwozHub:Destroy()
    elseif localPlayer.PlayerGui:FindFirstChild("AqwozHub") then
        localPlayer.PlayerGui.AqwozHub:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AqwozHub"
    ScreenGui.ResetOnSpawn = false
    
    -- Try parenting to CoreGui for security/overlay priority, fallback to PlayerGui
    local success, _ = pcall(function() ScreenGui.Parent = CoreGui end)
    if not success then ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui") end

    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderColor3 = Color3.fromRGB(0, 170, 255) -- Blue border
    MainFrame.BorderSizePixel = 2
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175) -- Centered
    MainFrame.Size = UDim2.new(0, 500, 0, 350)
    MainFrame.Active = true
    MainFrame.Draggable = true 

    -- Background Image (Placeholder)
    local BackgroundImage = Instance.new("ImageLabel")
    BackgroundImage.Name = "Background"
    BackgroundImage.Parent = MainFrame
    BackgroundImage.BackgroundTransparency = 1
    BackgroundImage.Size = UDim2.new(1, 0, 1, 0)
    BackgroundImage.Image = "rbxassetid://0" -- REPLACE THIS WITH YOUR ID
    BackgroundImage.ImageTransparency = 0.8 -- Subtle background
    BackgroundImage.ScaleType = Enum.ScaleType.Slice

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Parent = MainFrame
    TitleBar.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    TitleBar.BorderSizePixel = 0
    TitleBar.Size = UDim2.new(1, 0, 0, 30)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent = TitleBar
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(1, -60, 1, 0) -- Adjusted for buttons
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = "Aqwoz Hub"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 18
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local CloseButton = Instance.new("TextButton")
    CloseButton.Parent = TitleBar
    CloseButton.BackgroundTransparency = 1
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 16
    CloseButton.MouseButton1Click:Connect(function() ScreenGui.Enabled = false end)

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Parent = TitleBar
    MinimizeButton.BackgroundTransparency = 1
    MinimizeButton.Position = UDim2.new(1, -60, 0, 0)
    MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Text = "-"
    MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeButton.TextSize = 18

    -- Navigation (Sidebar)
    local Sidebar = Instance.new("Frame")
    Sidebar.Parent = MainFrame
    Sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Sidebar.BorderSizePixel = 0
    Sidebar.Position = UDim2.new(0, 0, 0, 30)
    Sidebar.Size = UDim2.new(0, 120, 1, -30)

    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Parent = MainFrame
    ContentArea.BackgroundTransparency = 1
    ContentArea.Position = UDim2.new(0, 130, 0, 40)
    ContentArea.Size = UDim2.new(1, -140, 1, -50)

    -- Minimize Logic
    local minimized = false
    MinimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            MainFrame.Size = UDim2.new(0, 500, 0, 30)
            Sidebar.Visible = false
            ContentArea.Visible = false
            MinimizeButton.Text = "+"
        else
            MainFrame.Size = UDim2.new(0, 500, 0, 350)
            Sidebar.Visible = true
            ContentArea.Visible = true
            MinimizeButton.Text = "-"
        end
    end)

    -- Tabs Storage
    local Tabs = {}
    local CurrentTab = nil

    local function SwitchTab(tabName)
        if CurrentTab then CurrentTab.Visible = false end
        if Tabs[tabName] then 
            Tabs[tabName].Visible = true
            CurrentTab = Tabs[tabName]
        end
    end

    local function CreateTabButton(name, yPos)
        local Button = Instance.new("TextButton")
        Button.Parent = Sidebar
        Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Button.BorderSizePixel = 0
        Button.Position = UDim2.new(0, 0, 0, yPos)
        Button.Size = UDim2.new(1, 0, 0, 40)
        Button.Font = Enum.Font.GothamSemibold
        Button.Text = name
        Button.TextColor3 = Color3.fromRGB(200, 200, 200)
        Button.TextSize = 14
        
        Button.MouseButton1Click:Connect(function()
            SwitchTab(name)
        end)
        
        -- Create corresponding page
        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Parent = ContentArea
        Page.BackgroundTransparency = 1
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.ScrollBarThickness = 4
        Page.Visible = false
        
        local UIListLayout = Instance.new("UIListLayout")
        UIListLayout.Parent = Page
        UIListLayout.Padding = UDim.new(0, 10)
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

        Tabs[name] = Page
        return Page
    end

    -- Toggle Component
    local function CreateToggle(parent, text, callback, default)
        local Frame = Instance.new("Frame")
        Frame.Parent = parent
        Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Frame.BorderSizePixel = 0
        Frame.Size = UDim2.new(1, 0, 0, 40)

        local Label = Instance.new("TextLabel")
        Label.Parent = Frame
        Label.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 10, 0, 0)
        Label.Size = UDim2.new(0, 200, 1, 0)
        Label.Font = Enum.Font.Gotham
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextSize = 14
        Label.TextXAlignment = Enum.TextXAlignment.Left

        local Button = Instance.new("TextButton")
        Button.Parent = Frame
        Button.BackgroundColor3 = default and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 60)
        Button.Position = UDim2.new(1, -60, 0.5, -10)
        Button.Size = UDim2.new(0, 50, 0, 20)
        Button.Text = ""
        Button.AutoButtonColor = false -- Custom anim handles color

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(1, 0)
        Corner.Parent = Button
        
        local toggled = default
        
        Button.MouseButton1Click:Connect(function()
            toggled = not toggled
            Button.BackgroundColor3 = toggled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 60)
            callback(toggled)
        end)
    end

    -- Button Component
    local function CreateButton(parent, text, callback)
        local Button = Instance.new("TextButton")
        Button.Parent = parent
        Button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        Button.Size = UDim2.new(1, 0, 0, 35)
        Button.Font = Enum.Font.GothamBold
        Button.Text = text
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.TextSize = 14
        
        local Corner = Instance.new("UICorner")
        Corner.Parent = Button
        
        Button.MouseButton1Click:Connect(callback)
    end
    
    -- TextBox Component
    local function CreateInput(parent, placeholder, callback)
        local Frame = Instance.new("Frame")
        Frame.Parent = parent
        Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Frame.Size = UDim2.new(1, 0, 0, 40)
        
        local Box = Instance.new("TextBox")
        Box.Parent = Frame
        Box.BackgroundTransparency = 1
        Box.Position = UDim2.new(0, 10, 0, 0)
        Box.Size = UDim2.new(1, -20, 1, 0)
        Box.Font = Enum.Font.Gotham
        Box.PlaceholderText = placeholder
        Box.Text = ""
        Box.TextColor3 = Color3.fromRGB(255, 255, 255)
        Box.TextSize = 14
        
        Box.FocusLost:Connect(function(enter)
            if enter then
                callback(Box.Text)
                Box.Text = ""
            end
        end)
    end


    -- Build Pages
    local CombatPage = CreateTabButton("Combat", 0)
    local VisualsPage = CreateTabButton("Visuals", 40)
    local WhitelistPage = CreateTabButton("Whitelist", 80)
    
    -- Combat Items
    CreateToggle(CombatPage, "Silent Aim (Right Click)", function(val) Config.SilentAim = val end, false)
    CreateToggle(CombatPage, "Aimlock", function(val) 
        Config.Aimlock = val 
        if not val then targetPlayer = nil end
    end, false)
    CreateToggle(CombatPage, "Team Check", function(val) Config.TeamCheck = val end, false)

    -- Visuals Items
    CreateToggle(VisualsPage, "Enabled", function(val) Config.Visuals.Enabled = val end, false)
    CreateToggle(VisualsPage, "2D Box + Health", function(val) Config.Visuals.Boxes = val end, false)
    CreateToggle(VisualsPage, "Names", function(val) Config.Visuals.Names = val end, false)
    CreateToggle(VisualsPage, "Health Based Color", function(val) Config.Visuals.Health = val end, false)
    CreateToggle(VisualsPage, "Hide Teammates", function(val) Config.Visuals.TeamCheck = val end, false)
    
    -- Whitelist Items
    CreateInput(WhitelistPage, "Enter Player Name (Press Enter)", function(text)
        if text ~= "" then
            table.insert(Config.Whitelist, text)
        end
    end)
    
    CreateButton(WhitelistPage, "Clear Whitelist", function()
        Config.Whitelist = {}
    end)

    print("Aqwoz Hub: Custom GUI Created Successfully")
    SwitchTab("Combat") -- Open first tab
end


-- Logic Functions (Same logic as before, just kept clean)

local function isLobbyVisible()
    pcall(function() 
        if localPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency.Visible == true then
            return true
        end
    end)
    return false
end

local function isTeammate(player)
    if not Config.TeamCheck then return false end
    if localPlayer.Team and player.Team and localPlayer.Team == player.Team then
        return true
    end
    return false
end

local function isWhitelisted(player)
    for _, name in ipairs(Config.Whitelist) do
        if player.Name:lower() == name:lower() or player.DisplayName:lower() == name:lower() then
            return true
        end
    end
    return false
end

local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if isTeammate(player) then continue end
            if isWhitelisted(player) then continue end
            
            local head = player.Character.Head
            local headPosition, onScreen = camera:WorldToViewportPoint(head.Position)

            if onScreen then
                local screenPosition = Vector2.new(headPosition.X, headPosition.Y)
                local distance = (screenPosition - mousePosition).Magnitude

                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

local function lockCameraToHead()
    if not Config.Aimlock then return end
    
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then
        targetPlayer = getClosestPlayerToMouse()
    end

    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
        local head = targetPlayer.Character.Head
        if isTeammate(targetPlayer) or isWhitelisted(targetPlayer) then 
            targetPlayer = nil 
            return 
        end

        local headPosition = camera:WorldToViewportPoint(head.Position)
        if headPosition.Z > 0 then
            local cameraPosition = camera.CFrame.Position
            camera.CFrame = CFrame.new(cameraPosition, head.Position)
        end
    end
end

local function autoClick()
    if autoClickConnection then
        autoClickConnection:Disconnect()
    end
    autoClickConnection = RunService.Heartbeat:Connect(function()
        if not Config.SilentAim then 
            autoClickConnection:Disconnect()
            return 
        end

        if isLeftMouseDown or isRightMouseDown then
            -- Attempting lobby check safety
            local lobbySafe = true
            pcall(function()
                 if isLobbyVisible() then lobbySafe = false end
            end)
            
            if lobbySafe then
                if mouse1click then
                    mouse1click()
                elseif vim then
                     vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                     vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end
            end
        else
            autoClickConnection:Disconnect()
        end
    end)
end

-- Clean ESP Function
local function clearESP(player)
    if player.Character then
        local esp = player.Character:FindFirstChild("AqwozESP")
        if esp then esp:Destroy() end
    end
end

-- Update Visuals
local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
             local root = player.Character.HumanoidRootPart
             local hum = player.Character.Humanoid
             
             -- Master Advertisement
             local espGui = root:FindFirstChild("AqwozESP")
             if not espGui and Config.Visuals.Enabled then
                 espGui = Instance.new("BillboardGui")
                 espGui.Name = "AqwozESP"
                 espGui.Adornee = root
                 espGui.Size = UDim2.new(4, 0, 5.5, 0) -- Bounds size in studs
                 espGui.StudsOffset = Vector3.new(0, 0, 0)
                 espGui.AlwaysOnTop = true
                 espGui.Parent = root
                 
                 -- Main Box Frame
                 local box = Instance.new("Frame")
                 box.Name = "Box"
                 box.Parent = espGui
                 box.Size = UDim2.new(1, 0, 1, 0)
                 box.BackgroundTransparency = 1
                 
                 -- UIStroke for Box (The Modern Look)
                 local stroke = Instance.new("UIStroke")
                 stroke.Parent = box
                 stroke.Color = Color3.fromRGB(0, 170, 255)
                 stroke.Thickness = 1.5
                 stroke.Transparency = 0
                 
                 -- Health Bar Background
                 local healthBg = Instance.new("Frame")
                 healthBg.Name = "HealthBg"
                 healthBg.Parent = box
                 healthBg.BackgroundColor3 = Color3.new(0,0,0)
                 healthBg.BorderSizePixel = 0
                 healthBg.Position = UDim2.new(-0.1, 0, 0, 0) -- Left side
                 healthBg.Size = UDim2.new(0.05, 0, 1, 0)
                 
                 -- Health Bar Fill
                 local healthFill = Instance.new("Frame")
                 healthFill.Name = "HealthFill"
                 healthFill.Parent = healthBg
                 healthFill.BackgroundColor3 = Color3.new(0, 1, 0) -- Green
                 healthFill.BorderSizePixel = 0
                 healthFill.Size = UDim2.new(1, 0, 1, 0) -- Will update scale Y
                 healthFill.Position = UDim2.new(0,0,1,0)
                 healthFill.AnchorPoint = Vector2.new(0,1) -- Grow upwards
                 
                 -- Name Label
                 local nameLab = Instance.new("TextLabel")
                 nameLab.Name = "NameLabel"
                 nameLab.Parent = box
                 nameLab.BackgroundTransparency = 1
                 nameLab.Position = UDim2.new(0, 0, -0.2, 0) -- Top
                 nameLab.Size = UDim2.new(1, 0, 0.2, 0)
                 nameLab.Font = Enum.Font.GothamBold
                 nameLab.Text = player.Name
                 nameLab.TextColor3 = Color3.new(1, 1, 1)
                 nameLab.TextSize = 12
                 nameLab.TextStrokeTransparency = 0.5
             end
             
             if espGui then
                 local show = Config.Visuals.Enabled
                 if Config.Visuals.TeamCheck and isTeammate(player) then show = false end
                 
                 espGui.Enabled = show
                 
                 if show then
                     -- Toggle Components
                     local box = espGui:FindFirstChild("Box")
                     local stroke = box:FindFirstChild("UIStroke")
                     local nameLab = box:FindFirstChild("NameLabel")
                     local healthBg = box:FindFirstChild("HealthBg")
                     
                     -- Box Visibility
                     stroke.Enabled = Config.Visuals.Boxes
                     
                     -- Name Visibility
                     nameLab.Visible = Config.Visuals.Names
                     if Config.Visuals.Health then
                         nameLab.TextColor3 = Color3.new(1,1,1) -- Reset if formerly health colored
                     end

                     -- Health Bar Logic
                     local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                     
                     if Config.Visuals.Health then
                         -- Show bar if Health enabled (or we can separate bar vs health text color, but keeping simple)
                         healthBg.Visible = true 
                         local fill = healthBg:FindFirstChild("HealthFill")
                         fill.Size = UDim2.new(1, 0, healthPercent, 0)
                         fill.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.3, 1, 1) -- Red to Green gradient
                     else
                         healthBg.Visible = false
                     end
                 end
             end
        else
            clearESP(player)
        end
    end
end

-- Connections
UserInputService.InputBegan:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not isLeftMouseDown then
            isLeftMouseDown = true
            -- Only fire if silent aim is valid and not clicking UI
            if Config.SilentAim and not isProcessed then 
                 autoClick() 
            end 
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        if not isRightMouseDown then
            isRightMouseDown = true
            if Config.SilentAim then autoClick() end
        end
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        if CoreGui:FindFirstChild("AqwozHub") then
            CoreGui.AqwozHub.Enabled = not CoreGui.AqwozHub.Enabled
        elseif localPlayer.PlayerGui:FindFirstChild("AqwozHub") then
            localPlayer.PlayerGui.AqwozHub.Enabled = not localPlayer.PlayerGui.AqwozHub.Enabled
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isLeftMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = false
    end
end)

-- Aimlock Loop (RenderStepped for smoother camera)
RunService.RenderStepped:Connect(function()
    if Config.Aimlock then
         -- Constant check to keep locking current target
         if not targetPlayer or (targetPlayer and (not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head"))) then
             targetPlayer = getClosestPlayerToMouse()
         end
         
         if targetPlayer then 
             lockCameraToHead() 
         end
    end
end)

-- Visuals Loop
RunService.Heartbeat:Connect(function()
    if Config.Visuals.Enabled then
        updateESP()
    end
end)


-- Init
create_ui()
