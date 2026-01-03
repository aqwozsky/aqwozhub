-- Main Loader
-- This script loads the modules and connects the GUI to the features.

local function FindFile(name)
    -- 1. Try direct file access (Standard)
    if isfile and isfile(name) then return name end
    
    -- 2. Try adding ./ (Some executors need explicit current dir)
    if isfile and isfile("./" .. name) then return "./" .. name end

    -- 3. Search in subfolders (If user dropped folder in workspace)
    if listfiles then
        local files = listfiles("")
        for _, file in ipairs(files) do
            -- check if the path ends with /name aka it's the file in a folder
            if file:sub(-#name) == name then
                -- Check if it's strictly that file (handle potential suffix matches)
                -- file is usually "folder/file.lua" or "file.lua"
                local endMatch = file:sub(-#name-1)
                if endMatch == "/" .. name or endMatch == "\\" .. name or file == name then
                     return file
                end
            end
        end
    end
    
    return nil
end

local function LoadScript(name)
    local path = FindFile(name)
    if not path then
        warn("Could not find file: " .. name)
        return nil
    end

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
    warn("Critical modules failed to load. Check that files are in your Executor's Workspace.")
    return
end

-- Create UI
local Window = Library:CreateWindow("Cheat Loader")

-- Aimbot Tab
local AimbotTab = Window:CreateTab("Aimbot")
AimbotTab:CreateToggle("Silent Aim Enabled", function(val)
    print("Silent Aim Toggle: " .. tostring(val)) 
end)

-- Visuals Tab
local VisualsTab = Window:CreateTab("Visuals")

VisualsTab:CreateToggle("Enable ESP", function(val)
    if ESP then ESP.Settings.Enabled = val end
end)

VisualsTab:CreateToggle("Box", function(val)
    if ESP then ESP.Settings.Box = val end
end)

VisualsTab:CreateToggle("Name", function(val)
    if ESP then ESP.Settings.Name = val end
end)

VisualsTab:CreateToggle("Health", function(val)
    if ESP then ESP.Settings.Health = val end
end)

VisualsTab:CreateToggle("Team Check", function(val)
    if ESP then ESP.Settings.TeamCheck = val end
end)

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings")
SettingsTab:CreateToggle("Unload", function(val)
    if val then
        if game.CoreGui:FindFirstChild("CheatGui") then 
            game.CoreGui:FindFirstChild("CheatGui"):Destroy() 
        end
        if game.CoreGui:FindFirstChild("ESP_Folder") then
             game.CoreGui:FindFirstChild("ESP_Folder"):Destroy() 
        end
        -- Break loop in ESP if possible, or just destroy the UI
    end
end)
