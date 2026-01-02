print("Aqwoz Hub: Script connection started...")

local function loadLibrary()
    local libraryUrls = {
        "https://raw.githubusercontent.com/jensonhirst/Orion/main/source",
        "https://raw.githubusercontent.com/shlexware/Orion/main/source",
        "https://raw.githubusercontent.com/Seven7-lua/Roblox/refs/heads/main/Librarys/Orion/Orion.lua"
    }

    for i, url in ipairs(libraryUrls) do
        print("Aqwoz Hub: Attempting to download Orion Library from Mirror " .. i .. "...")
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        
        if success and result and #result > 0 then
            print("Aqwoz Hub: Download successful from Mirror " .. i .. ". Compiling...")
            local func, err = loadstring(result)
            if func then
                return func()
            else
                warn("Aqwoz Hub: Compilation Failed for Mirror " .. i .. "! Error: " .. tostring(err))
            end
        else
            warn("Aqwoz Hub: Failed to fetch from Mirror " .. i)
        end
    end
    
    return nil
end

local OrionLib = loadLibrary()
if not OrionLib then
    warn("Aqwoz Hub Critical Error: Orion Library could not be loaded. Script stopped.")
    return
end

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
        TeamCheck = false -- Visuals team check
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

-- Theme & Window
local Window = OrionLib:MakeWindow({
    Name = "Aqwoz Hub",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "AqwozHub",
    IntroEnabled = true,
    IntroText = "Aqwoz Hub",
    -- Blue and Black Theme
    IntroIcon = "rbxassetid://6034926597", -- Generic premium icon, user can change
    Icon = "rbxassetid://6034926597",
})

-- Attempts to set a custom theme or colors if library supports deep customization, 
-- but Orion has specific built-in themes. We'll use "Dark" and force some colors if possible, 
-- or rely on the user to replace the MainSource for the background image.

-- Placeholder for Background Image. 
-- User must check their executor's workspace or upload to Roblox.
-- Since we can't upload, we use a placeholder Asset ID.
-- Replace with proper Asset ID: "rbxassetid://YOUR_ID_HERE"
OrionLib.Flags["Orion_Background_Image"] = "rbxassetid://0" 
-- Note without a direct "Image" property exposed in MakeWindow for background in all Orion versions,
-- we often rely on the UI Library's default dark theme which fits "Black".
-- We will proceed with the "Dark" theme which is predominantly black/grey.

-- Functions

local function isLobbyVisible()
    -- User provided specific check
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
    
    -- Recalculate target if current one is invalid
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then
        targetPlayer = getClosestPlayerToMouse()
    end

    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
        local head = targetPlayer.Character.Head
        -- Still valid?
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

-- Silent Aim Auto Click
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
                -- In standard scripts mouse1click is often available, or we use VirtualInputManager
                -- User provided code used `mouse1click()`. We assume executor supports it.
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

-- ESP Functions
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
    Box.Size = Vector3.new(4, 5, 1) -- Approximate size
    Box.SizeRelativeOffset = Vector3.new(0, 0, 0)
    Box.Transparency = 0.5
    Box.Color3 = Color3.fromRGB(0, 0, 255) -- Blue
    Box.AlwaysOnTop = true
    Box.ZIndex = 5
    Box.Visible = false
    
    -- Store references to update visibility
    local espData = {
        Billboard = Billboard,
        NameLabel = NameLabel,
        Box = Box,
        Player = player
    }
    
    return espData
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
                    -- Update Box Size/Pos if needed, or Health color
                    if Config.Visuals.Health then
                        local hum = player.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local hpPercent = hum.Health / hum.MaxHealth
                            data.NameLabel.TextColor3 = Color3.fromHSV(hpPercent * 0.3, 1, 1) -- Red to Green
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


-- UI Setup

local CombatTab = Window:MakeTab({
	Name = "Combat",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

CombatTab:AddToggle({
	Name = "Silent Aim (Auto-Shoot)",
	Default = false,
	Callback = function(Value)
		Config.SilentAim = Value
	end    
})

CombatTab:AddToggle({
	Name = "Aimlock (Camera Lock)",
	Default = false,
	Callback = function(Value)
		Config.Aimlock = Value
        if not Value then targetPlayer = nil end
	end    
})

CombatTab:AddToggle({
	Name = "Team Check",
	Default = false,
	Callback = function(Value)
		Config.TeamCheck = Value
	end    
})

-- Whitelist UI
local WhitelistTab = Window:MakeTab({
	Name = "Whitelist",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local whitelistInput = ""
WhitelistTab:AddTextbox({
	Name = "Player Name",
	Default = "",
	TextDisappear = true,
	Callback = function(Value)
		whitelistInput = Value
	end	  
})

WhitelistTab:AddButton({
	Name = "Add to Whitelist",
	Callback = function()
      if whitelistInput ~= "" then
          table.insert(Config.Whitelist, whitelistInput)
          OrionLib:MakeNotification({Name = "Whitelist", Content = "Added " .. whitelistInput, Image = "rbxassetid://4483345998", Time = 5})
      end
  	end    
})

WhitelistTab:AddButton({
	Name = "Clear Whitelist",
	Callback = function()
      Config.Whitelist = {}
      OrionLib:MakeNotification({Name = "Whitelist", Content = "Cleared Whitelist", Image = "rbxassetid://4483345998", Time = 5})
  	end    
})


-- Visuals UI
local VisualsTab = Window:MakeTab({
	Name = "Visuals",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

VisualsTab:AddToggle({
	Name = "Enable Visuals",
	Default = false,
	Callback = function(Value)
		Config.Visuals.Enabled = Value
	end    
})

VisualsTab:AddToggle({
	Name = "Boxes",
	Default = false,
	Callback = function(Value)
		Config.Visuals.Boxes = Value
	end    
})

VisualsTab:AddToggle({
	Name = "Names",
	Default = false,
	Callback = function(Value)
		Config.Visuals.Names = Value
	end    
})

VisualsTab:AddToggle({
	Name = "Health Color",
	Default = false,
	Callback = function(Value)
		Config.Visuals.Health = Value
	end    
})

VisualsTab:AddToggle({
	Name = "Visuals Team Check",
	Default = false,
	Callback = function(Value)
		Config.Visuals.TeamCheck = Value
	end    
})


-- Main Logic Connections

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
        -- Handle Aimlock
        if Config.Aimlock then
             targetPlayer = getClosestPlayerToMouse()
             if targetPlayer then
                 lockCameraToHead()
             end
        end
        
        -- Handle Visuals Update
        if Config.Visuals.Enabled then
            updateESP()
        else
            -- Cleanup if disabled
            for player, data in pairs(ESP_Table) do
                if data.Billboard then data.Billboard.Enabled = false end
                if data.Box then data.Box.Visible = false end
            end
        end
    end
end)

OrionLib:MakeNotification({
	Name = "Aqwoz Hub Loaded",
	Content = "Welcome! Press Right Control to toggle UI.",
	Image = "rbxassetid://4483345998",
	Time = 5
})

OrionLib:Init()
