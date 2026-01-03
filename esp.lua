local ESP = {}

-- Settings
ESP.Settings = {
    Enabled = true,
    Box = true,
    Name = true,
    Health = true,
    Tracer = false,
    TeamCheck = false,
    BoxColor = Color3.fromRGB(0, 255, 255), -- Cyan
    TracerColor = Color3.fromRGB(255, 255, 255)
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local ESP_Folder = Instance.new("Folder")
ESP_Folder.Name = "ESP_Folder"
ESP_Folder.Parent = game.CoreGui

-- Helper function to create drawing objects (simplified for compatibility using GUI objects)
-- We use BillboardGui as it is compatible with almost all executors and renders standard UI.

local function CreateESP(player)
    if player == LocalPlayer then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = player.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(4, 0, 5.5, 0)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.Adornee = nil 
    billboard.Parent = ESP_Folder

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    -- Box Border
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1.5
    boxStroke.Transparency = 0
    boxStroke.Color = ESP.Settings.BoxColor
    boxStroke.Parent = frame

    -- Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.2, 0)
    nameLabel.Position = UDim2.new(0, 0, -0.2, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = frame

    -- Health Bar
    local healthBarBg = Instance.new("Frame")
    healthBarBg.Size = UDim2.new(0.05, 0, 1, 0)
    healthBarBg.Position = UDim2.new(-0.1, 0, 0, 0)
    healthBarBg.BackgroundColor3 = Color3.new(0, 0, 0)
    healthBarBg.BorderSizePixel = 0
    healthBarBg.Parent = frame

    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, 0, 1, 0) -- Will scale with health
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.AnchorPoint = Vector2.new(0, 1)
    healthBar.Position = UDim2.new(0, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBg

    -- Check Loop
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not player or not player.Parent then
            billboard:Destroy()
            connection:Disconnect()
            return
        end

        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and ESP.Settings.Enabled then
            if ESP.Settings.TeamCheck and player.Team == LocalPlayer.Team then
                billboard.Enabled = false
            else
                billboard.Enabled = true
                billboard.Adornee = char.HumanoidRootPart
                
                -- Update Settings
                boxStroke.Enabled = ESP.Settings.Box
                boxStroke.Color = ESP.Settings.BoxColor
                nameLabel.Visible = ESP.Settings.Name
                healthBarBg.Visible = ESP.Settings.Health

                -- Health Logic
                local hum = char.Humanoid
                local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                healthBar.Size = UDim2.new(1, 0, healthPercent, 0)
                healthBar.BackgroundColor3 = Color3.fromHSV((healthPercent * 120)/360, 1, 1)
            end
        else
            billboard.Enabled = false
        end
    end)
end

-- Init for existing players
for _, p in ipairs(Players:GetPlayers()) do
    CreateESP(p)
end

-- Init for new players
Players.PlayerAdded:Connect(function(p)
    CreateESP(p)
end)

return ESP
