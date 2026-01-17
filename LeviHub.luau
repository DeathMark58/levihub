--[[
    Levi Hub v4.0 - Starlight Edition (Modular)
    Loader Script
]]

local USE_GITHUB = true
local REPO_URL = "https://raw.githubusercontent.com/DeathMark58/levihub/main/"

local function LoadModule(path)
    if USE_GITHUB then
        -- Remove 'fw/' prefix if present, as repo root is likely the content of fw
        local cleanPath = path:gsub("^fw/", "")
        local url = REPO_URL .. cleanPath
        
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        
        if not success then
             error("[Levi Hub] Failed to download module from GitHub: " .. url .. "\nError: " .. tostring(result))
        end
        
        local func, err = loadstring(result, path)
        if not func then
            error("[Levi Hub] Failed to compile module: " .. path .. "\nError: " .. tostring(err))
        end
        
        return func()
    else
        -- Local Mode
        if not isfile(path) then
             error("[Levi Hub] Module not found: " .. path)
        end
        
        local func, err = loadstring(readfile(path), path)
        if not func then
            error("[Levi Hub] Failed to compile module: " .. path .. "\nError: " .. tostring(err))
        end
        
        return func()
    end
end

local function Initialize()
    print("[Levi Hub] Initializing Modular Edition...")
    
    -- Load Config
    local Config = LoadModule("fw/LeviHub/Config.luau")
    if not Config then return end

    -- Initialize Global State
    getgenv().AOT_CONFIG = Config.DefaultConfig
    
    -- Load Services
    local SpoofEngine = LoadModule("fw/LeviHub/Services/SpoofEngine.luau")
    local TitanManager = LoadModule("fw/LeviHub/Services/TitanManager.luau")
    local Interface = LoadModule("fw/LeviHub/UI/Interface.luau")
    
    -- Dependency Injection
    SpoofEngine:Initialize(Config)
    TitanManager:Initialize(SpoofEngine, Config)
    Interface:Initialize(Config, SpoofEngine, TitanManager)
    
    if Config.IS_LOBBY then
        print("[Levi Hub] Lobby Mode Active")
    else
        print("[Levi Hub] Game Mode Active")
        SpoofEngine:SetupHooks(Config.IS_LOBBY)
        TitanManager:SetupWatcher()
        
        -- Auto refresh loop
        task.spawn(function()
            while getgenv().AOT_CONFIG do
                task.wait(3)
                if getgenv().AOT_CONFIG.AutoRefresh and not Config.IS_LOBBY then
                    TitanManager:ScanAllTitans()
                end
            end
        end)
    end
    
    -- Load UI
    Interface:Create()
    
    -- Export global API
    getgenv().AOT = {
        Config = getgenv().AOT_CONFIG,
        Scan = function() return TitanManager:ScanAllTitans() end,
        Rescan = function() return TitanManager:RescanAllTitans() end,
        Refresh = function() return TitanManager:RefreshAllHitboxes() end,
        Stats = function() return SpoofEngine:GetStats() end,
        Unload = function()
            SpoofEngine:Cleanup()
            getgenv().AOT = nil
            getgenv().AOT_CONFIG = nil
        end,
        IsLobby = Config.IS_LOBBY,
        SpoofEngine = SpoofEngine,
    }
    
    print("[Levi Hub] Ready!")
end

Initialize()