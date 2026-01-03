-- Main Loader
-- This script loads the modules and connects the GUI to the features.

local function LoadScript(path)
    -- Attempt to load via readfile (Standard Exploit API)
    local success, result = pcall(function()
        return loadstring(readfile(path))()
    end)
    
    if not success then
        warn("Failed to load " .. path .. ": " .. tostring(result))
        return nil
    end
    return result
end

-- Load Modules
local Library = LoadScript("gui.lua")
local ESP = LoadScript("esp.lua")

-- Load Silent Aim (Logic runs immediately)
LoadScript("silentaim.lua")

if not Library or not ESP then
    warn("Critical modules failed to load.")
    return
end

-- Create UI
local Window = Library:CreateWindow("Cheat Loader")

-- Aimbot Tab (Controls for existing silent aim could go here if exposed, 
-- but since we can't edit silentaim.lua, we serve as a launcher/info mostly)
local AimbotTab = Window:CreateTab("Aimbot")
AimbotTab:CreateToggle("Silent Aim Enabled", function(val)
    -- Silent aim logic is internally managed by the loaded script
    -- We can't toggle it easily unless we modify silentaim.lua
    -- Typically, one would modify the global state or hooks.
    -- For now, this is a placeholder or could re-execute logic.
    print("Silent Aim Toggle: " .. tostring(val)) 
end)

-- Visuals Tab
local VisualsTab = Window:CreateTab("Visuals")

VisualsTab:CreateToggle("Enable ESP", function(val)
    ESP.Settings.Enabled = val
end)

VisualsTab:CreateToggle("Box", function(val)
    ESP.Settings.Box = val
end)

VisualsTab:CreateToggle("Name", function(val)
    ESP.Settings.Name = val
end)

VisualsTab:CreateToggle("Health", function(val)
    ESP.Settings.Health = val
end)

VisualsTab:CreateToggle("Team Check", function(val)
    ESP.Settings.TeamCheck = val
end)

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings")
SettingsTab:CreateToggle("Unload", function(val)
    if val then
        game.CoreGui:FindFirstChild("CheatGui"):Destroy()
        game.CoreGui:FindFirstChild("ESP_Folder"):Destroy()
    end
end)
