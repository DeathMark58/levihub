--[[
    LEVI HUB - Premium Loader (Starlight Ver.)
    Execute this script to start.
]]

local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/DeathMark58/levihub/main/LeviHub.luau"
local LOBBY_PLACE_ID = 11534222714
local CURRENT_PLACE_ID = game.PlaceId

local Starlight = nil
local NebulaIcons = nil

-- Initialize Starlight
local function InitUI()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
    end)
    
    if not success then
        warn("[Loader] Failed to load Starlight: " .. tostring(result))
        return nil
    end
    
    Starlight = result
    
    pcall(function()
        NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()
    end)
    
    return Starlight
end

local function LoadMain()
    local success, err = pcall(function()
        loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
    end)
    
    if not success then
        if Starlight then
            Starlight:Notification({
                Title = "Error",
                Content = "Failed to load script: " .. tostring(err),
                Duration = 5
            })
        end
        warn("[Loader] Error: " .. tostring(err))
    end
end

if CURRENT_PLACE_ID == LOBBY_PLACE_ID then
    -- LOBBY MODE
    InitUI()
    if not Starlight then return end
    
    local Window = Starlight:CreateWindow({
        Name = "Levi Hub",
        Subtitle = "Loader",
        Icon = NebulaIcons and NebulaIcons:GetIcon('cloud', 'Lucide') or 6031302931,
        LoadingSettings = {
            Title = "Levi Hub",
            Subtitle = "Preparing...",
        }
    })
    
    local MainSection = Window:CreateTabSection("Main")
    local LoaderTab = MainSection:CreateTab({ Name = "Status", Columns = 1 })
    
    local InfoBox = LoaderTab:CreateGroupbox({ Name = "Ready to Join", Column = 1 })
    
    InfoBox:CreateParagraph({
        Name = "Status",
        Content = "Script is queued.\nJoin a game to auto-execute."
    })
    
    Starlight:Notification({
        Title = "Levi Hub",
        Content = "Script queued for teleport!",
        Duration = 5
    })
    
    if queue_on_teleport then
        local queueScript = [[
            repeat task.wait() until game:IsLoaded()
            task.wait(2)
            loadstring(game:HttpGet("]] .. MAIN_SCRIPT_URL .. [["))()
        ]]
        queue_on_teleport(queueScript)
    else
        Starlight:Notification({
            Title = "Warning",
            Content = "queue_on_teleport not supported!",
            Duration = 5
        })
    end
    
else
    -- GAME MODE - Load Immediately
    -- We can optionally show a notification here before loading
    InitUI() -- Init basic UI for notifications if needed, or just load main
    
    if Starlight then
        Starlight:Notification({
            Title = "Levi Hub",
            Content = "Loading main script...",
            Duration = 2
        })
    end
    
    -- Load Main Script
    LoadMain()
    
    -- Cleanup Loader UI if it persists (Starlight creates instances)
    -- Main script will create its own UI.
end
