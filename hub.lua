local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local vim = game:GetService("VirtualInputManager")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Variables
local targetPlayer = nil
local isLeftMouseDown = false
local isRightMouseDown = false
local autoClickConnection = nil
local ESP_Folder = Instance.new("Folder", Workspace)
ESP_Folder.Name = "AqwozHub_ESP"

-- Functions
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
            if not isLobbyVisible() then
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

-- ESP Functions (Same as before)
local function createESP(player)
    if player == localPlayer then return end

    local Billboard = Instance.new("BillboardGui")
    Billboard.Name = player.Name .. "_ESP"
    Billboard.Adornee = player.Character.Head
    Billboard.Size = UDim2.new(0, 100, 0, 150)
    Billboard.StudsOffset = Vector3.new(0, 3, 0)
    Billboard.AlwaysOnTop = true
    
    local NameLabel = Instance.new("TextLabel", Billboard)
    NameLabel.Size = UDim2.new(1, 0, 0.2, 0)
    NameLabel.Position = UDim2.new(0, 0, -0.5, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.TextColor3 = Color3.new(1, 1, 1)
    NameLabel.TextStrokeTransparency = 0
    NameLabel.Text = player.Name
    NameLabel.Visible = false

    local Box = Instance.new("BoxHandleAdornment", ESP_Folder)
    Box.Adornee = player.Character
    Box.Size = Vector3.new(4, 5, 1)
    Box.SizeRelativeOffset = Vector3.new(0, 0, 0)
    Box.Transparency = 0.5
    Box.Color3 = Color3.fromRGB(0, 100, 255)
    Box.AlwaysOnTop = true
    Box.ZIndex = 5
    Box.Visible = false
    
    return {Billboard = Billboard, NameLabel = NameLabel, Box = Box, Player = player}
end

local ESP_Table = {}

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
             if not ESP_Table[player] then
                 local data = createESP(player)
                 if data then
                    data.Billboard.Parent = player.Character.Head
                    ESP_Table[player] = data
                 end
             end
             
             local data = ESP_Table[player]
             if data then
                 local show = Config.Visuals.Enabled
                 if Config.Visuals.TeamCheck and isTeammate(player) then show = false end
                 
                 data.Billboard.Enabled = show
                 data.Box.Visible = show and Config.Visuals.Boxes
                 data.NameLabel.Visible = show and Config.Visuals.Names
                 
                 if show then
                    if Config.Visuals.Health then
                        local hum = player.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local hpPercent = hum.Health / hum.MaxHealth
                            data.NameLabel.TextColor3 = Color3.fromHSV(hpPercent * 0.3, 1, 1)
                        end
                    else
                        data.NameLabel.TextColor3 = Color3.new(1, 1, 1)
                    end
                 end
             end
        else
            if ESP_Table[player] then
                ESP_Table[player].Billboard:Destroy()
                ESP_Table[player].Box:Destroy()
                ESP_Table[player] = nil
            end
        end
    end
end

-- Rayfield UI Window
local Window = Rayfield:CreateWindow({
   Name = "Aqwoz Hub",
   LoadingTitle = "Loading Aqwoz Hub...",
   LoadingSubtitle = "By Aqwoz",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AqwozHub",
      FileName = "Configuration"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink", 
      RememberJoins = true 
   },
   KeySystem = false,
})

-- Combat Tab
local CombatTab = Window:CreateTab("Combat", 4483345998)

CombatTab:CreateToggle({
   Name = "Silent Aim (Auto-Shoot)",
   CurrentValue = false,
   Flag = "SilentAim", 
   Callback = function(Value)
        Config.SilentAim = Value
   end,
})

CombatTab:CreateToggle({
   Name = "Aimlock (Camera Lock)",
   CurrentValue = false,
   Flag = "Aimlock", 
   Callback = function(Value)
        Config.Aimlock = Value
        if not Value then targetPlayer = nil end
   end,
})

CombatTab:CreateToggle({
   Name = "Team Check",
   CurrentValue = false,
   Flag = "TeamCheck", 
   Callback = function(Value)
        Config.TeamCheck = Value
   end,
})

-- Whitelist Tab
local WhitelistTab = Window:CreateTab("Whitelist", 4483345998)

local whitelistInput = ""
WhitelistTab:CreateInput({
   Name = "Player Name",
   PlaceholderText = "Enter Name",
   RemoveTextAfterFocusLost = true,
   Callback = function(Text)
        whitelistInput = Text
   end,
})

WhitelistTab:CreateButton({
   Name = "Add to Whitelist",
   Callback = function()
      if whitelistInput ~= "" then
          table.insert(Config.Whitelist, whitelistInput)
          Rayfield:Notify({
             Title = "Whitelist",
             Content = "Added " .. whitelistInput,
             Duration = 3,
             Image = 4483345998,
          })
      end
   end,
})

WhitelistTab:CreateButton({
   Name = "Clear Whitelist",
   Callback = function()
      Config.Whitelist = {}
      Rayfield:Notify({
         Title = "Whitelist",
         Content = "Cleared Whitelist",
         Duration = 3,
         Image = 4483345998,
      })
   end,
})

-- Visuals Tab
local VisualsTab = Window:CreateTab("Visuals", 4483345998)

VisualsTab:CreateToggle({
   Name = "Enable Visuals",
   CurrentValue = false,
   Flag = "VisualsEnabled", 
   Callback = function(Value)
        Config.Visuals.Enabled = Value
   end,
})

VisualsTab:CreateToggle({
   Name = "Boxes",
   CurrentValue = false,
   Flag = "VisualsBoxes", 
   Callback = function(Value)
        Config.Visuals.Boxes = Value
   end,
})

VisualsTab:CreateToggle({
   Name = "Names",
   CurrentValue = false,
   Flag = "VisualsNames", 
   Callback = function(Value)
        Config.Visuals.Names = Value
   end,
})

VisualsTab:CreateToggle({
   Name = "Health Color",
   CurrentValue = false,
   Flag = "VisualsHealth", 
   Callback = function(Value)
        Config.Visuals.Health = Value
   end,
})

VisualsTab:CreateToggle({
   Name = "Visuals Team Check",
   CurrentValue = false,
   Flag = "VisualsTeamCheck", 
   Callback = function(Value)
        Config.Visuals.TeamCheck = Value
   end,
})


-- Logic Connections (Input & Loops)
UserInputService.InputBegan:Connect(function(input, isProcessed)
    if isProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not isLeftMouseDown then
            isLeftMouseDown = true
            if Config.SilentAim then autoClick() end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        if not isRightMouseDown then
            isRightMouseDown = true
            if Config.SilentAim then autoClick() end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isLeftMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = false
    end
end)

RunService.Heartbeat:Connect(function()
    if not isLobbyVisible() then
        if Config.Aimlock then
             targetPlayer = getClosestPlayerToMouse()
             if targetPlayer then
                 lockCameraToHead()
             end
        end
        
        if Config.Visuals.Enabled then
            updateESP()
        else
            for player, data in pairs(ESP_Table) do
                if data.Billboard then data.Billboard.Enabled = false end
                if data.Box then data.Box.Visible = false end
            end
        end
    end
end)

-- Notify loaded
Rayfield:Notify({
   Title = "Aqwoz Hub Loaded",
   Content = "Welcome! Press Right Control to toggle UI.",
   Duration = 6.5,
   Image = 4483345998,
})
