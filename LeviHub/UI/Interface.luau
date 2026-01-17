local Interface = {}
local Starlight = nil
local NebulaIcons = nil
local Config
local SpoofEngine
local TitanManager
local GlobalConfig

function Interface:Initialize(configModule, spoofEngine, titanManager)
    Config = configModule
    SpoofEngine = spoofEngine
    TitanManager = titanManager
    GlobalConfig = getgenv().AOT_CONFIG
end

function Interface:Create()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
    end)
    
    if not success then
        warn("[Levi Hub] Failed to load Starlight: " .. tostring(result))
        return nil
    end
    Starlight = result
    
    pcall(function()
        NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()
    end)
    
    local Window = Starlight:CreateWindow({
        Name = "Levi Hub",
        Subtitle = Config.IS_LOBBY and "Lobby Mode" or "Modular Edition",
        Icon = NebulaIcons and NebulaIcons:GetIcon('feather', 'Lucide') or 6031302931,
        LoadingSettings = { Title = "Levi Hub", Subtitle = "Loading Modules..." },
        FileSettings = { ConfigFolder = "LeviHub" },
    })
    
    if Config.IS_LOBBY then
        self:CreateLobbyUI(Window)
    else
        self:CreateGameUI(Window)
    end
    
    Starlight:LoadAutoloadConfig()
    
    -- Cleanup on destroy
    Starlight:OnDestroy(function()
        SpoofEngine:Cleanup()
        getgenv().AOT = nil
        getgenv().AOT_CONFIG = nil
    end)
    
    return Starlight
end

function Interface:CreateLobbyUI(Window)
    local MainSection = Window:CreateTabSection("Main")
    local LobbyTab = MainSection:CreateTab({ Name = "Lobby", Columns = 1 })
    
    local InfoBox = LobbyTab:CreateGroupbox({ Name = "Waiting", Column = 1 })
    InfoBox:CreateParagraph({ Name = "Status", Content = "You are in the lobby.\nFeature activation waiting for game join." })
    
    Starlight:Notification({ Title = "Levi Hub", Content = "Lobby Mode Active", Duration = 3 })
end

function Interface:CreateGameUI(Window)
    local MainSection = Window:CreateTabSection("Main")
    
    -- General Tab
    local GeneralTab = MainSection:CreateTab({ Name = "General", Icon = NebulaIcons and NebulaIcons:GetIcon('home', 'Lucide') })
    local InfoBox = GeneralTab:CreateGroupbox({ Name = "Info", Column = 1 })
    InfoBox:CreateParagraph({ Name = "Welcome", Content = "Levi Hub Modular\nAttack on Titan: Freedom War" })
    
    -- Titans Tab
    local TitansTab = MainSection:CreateTab({ Name = "Titans", Icon = NebulaIcons and NebulaIcons:GetIcon('crosshair', 'Lucide') })
    
    -- Master
    local MasterBox = TitansTab:CreateGroupbox({ Name = "Pure Titans", Column = 1 })
    MasterBox:CreateToggle({
        Name = "Pure Titan Hitbox Changer",
        CurrentValue = false,
        Callback = function(value)
            GlobalConfig.PureTitanEnabled = value
            if value then TitanManager:RescanAllTitans()
            else
                SpoofEngine:RestoreCategory("PureTitan_Nape")
                SpoofEngine:RestoreCategory("PureTitan_Eyes")
            end
        end
    })
    
    -- Nape
    local NapeBox = TitansTab:CreateGroupbox({ Name = "Nape Hitbox", Column = 1 })
    NapeBox:CreateToggle({
        Name = "Enable Nape Hitbox",
        CurrentValue = false,
        Callback = function(value)
            GlobalConfig.NapeEnabled = value
            if GlobalConfig.PureTitanEnabled then
                if value then TitanManager:RescanAllTitans()
                else SpoofEngine:RestoreCategory("PureTitan_Nape") end
            end
        end
    })
    
    -- Nape Sliders (Simplified for brevity, similar to original)
    NapeBox:CreateSlider({ Name = "Scale X", Range = {1, 6}, Increment = 0.25, CurrentValue = 2.5, Callback = function(v) GlobalConfig.NapeScaleX = v; TitanManager:RefreshAllHitboxes() end })
    NapeBox:CreateSlider({ Name = "Scale Y", Range = {1, 6}, Increment = 0.25, CurrentValue = 2.5, Callback = function(v) GlobalConfig.NapeScaleY = v; TitanManager:RefreshAllHitboxes() end })
    NapeBox:CreateSlider({ Name = "Scale Z", Range = {1, 6}, Increment = 0.25, CurrentValue = 2.5, Callback = function(v) GlobalConfig.NapeScaleZ = v; TitanManager:RefreshAllHitboxes() end })
    
    NapeBox:CreateLabel({Name="Color"}):AddColorPicker({ CurrentValue = Color3.fromRGB(255,0,0), Callback = function(c) GlobalConfig.NapeColor = c; TitanManager:RefreshAllHitboxes() end })
    NapeBox:CreateSlider({ Name = "Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0, Callback = function(v) GlobalConfig.NapeTransparency = v; TitanManager:RefreshAllHitboxes() end })
    NapeBox:CreateLabel({Name="Material"}):AddDropdown({ Options = Config.MATERIAL_OPTIONS, CurrentOptions = {"ForceField"}, Callback = function(o) GlobalConfig.NapeMaterial = o[1]; TitanManager:RefreshAllHitboxes() end })

    -- Eyes (Similar structure)
    local EyesBox = TitansTab:CreateGroupbox({ Name = "Eyes Hitbox", Column = 2 })
    EyesBox:CreateToggle({
        Name = "Enable Eyes Hitbox",
        CurrentValue = false,
        Callback = function(value)
            GlobalConfig.EyesEnabled = value
            if GlobalConfig.PureTitanEnabled then
                if value then TitanManager:RescanAllTitans()
                else SpoofEngine:RestoreCategory("PureTitan_Eyes") end
            end
        end
    })
    
    EyesBox:CreateSlider({ Name = "Scale X", Range = {1, 6}, Increment = 0.25, CurrentValue = 2, Callback = function(v) GlobalConfig.EyesScaleX = v; TitanManager:RefreshAllHitboxes() end })
    EyesBox:CreateSlider({ Name = "Scale Y", Range = {1, 6}, Increment = 0.25, CurrentValue = 2, Callback = function(v) GlobalConfig.EyesScaleY = v; TitanManager:RefreshAllHitboxes() end })
    EyesBox:CreateSlider({ Name = "Scale Z", Range = {1, 6}, Increment = 0.25, CurrentValue = 2, Callback = function(v) GlobalConfig.EyesScaleZ = v; TitanManager:RefreshAllHitboxes() end })
    
    EyesBox:CreateLabel({Name="Color"}):AddColorPicker({ CurrentValue = Color3.fromRGB(0,255,0), Callback = function(c) GlobalConfig.EyesColor = c; TitanManager:RefreshAllHitboxes() end })
    EyesBox:CreateSlider({ Name = "Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0, Callback = function(v) GlobalConfig.EyesTransparency = v; TitanManager:RefreshAllHitboxes() end })
    EyesBox:CreateLabel({Name="Material"}):AddDropdown({ Options = Config.MATERIAL_OPTIONS, CurrentOptions = {"ForceField"}, Callback = function(o) GlobalConfig.EyesMaterial = o[1]; TitanManager:RefreshAllHitboxes() end })
    
    -- Settings
    local SettingsTab = MainSection:CreateTab({ Name = "Settings", Icon = NebulaIcons and NebulaIcons:GetIcon('settings', 'Lucide') })
    local OptionsBox = SettingsTab:CreateGroupbox({ Name = "Options", Column = 1 })
    
    OptionsBox:CreateToggle({ Name = "Auto Refresh", CurrentValue = true, Callback = function(v) GlobalConfig.AutoRefresh = v end })
    OptionsBox:CreateToggle({ Name = "Debug Mode", CurrentValue = false, Callback = function(v) GlobalConfig.DebugMode = v end })
    
    OptionsBox:CreateDivider()
    OptionsBox:CreateButton({ Name = "Force Scan", Callback = function() local t,p = TitanManager:ScanAllTitans(); Starlight:Notification({Title="Scan", Content=t.." titans", Duration=3}) end })
    OptionsBox:CreateButton({ Name = "Show Stats", Callback = function() local s = SpoofEngine:GetStats(); Starlight:Notification({Title="Stats", Content="Nape: "..s.NapeParts.." | Eyes: "..s.EyesParts, Duration=3}) end })
    
    SettingsTab:BuildConfigGroupbox(2)
end

return Interface
