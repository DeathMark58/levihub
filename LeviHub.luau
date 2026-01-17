--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║                       LEVI HUB                            ║
    ║                       v0.0.03                             ║
    ╠═══════════════════════════════════════════════════════════╣
    ║  Hitbox Extender for Attack on Titan: Freedom War         ║
    ║  Anti-Cheat Bypass via Metatable Spoofing                 ║
    ╚═══════════════════════════════════════════════════════════╝
]]

--// SECURE MODE (Anti-Detection)
getgenv().SecureMode = true

--// CONSTANTS
local VERSION = "v0.0.03"
local LOBBY_PLACE_ID = 11534222714
local TITAN_CONTAINER = "OnGameTitans"
local HITBOX_NAMES = { "Nape", "Eyes" }
local MAIN_LOOP_INTERVAL = 3 -- seconds

--// MATERIAL OPTIONS
local MATERIAL_OPTIONS = {
    "ForceField", "Neon", "Glass", "SmoothPlastic", 
    "Plastic", "Metal", "DiamondPlate", "Foil"
}

--// SERVICES
local UserInputService = game:GetService("UserInputService")

--// STATE
local Running = true  -- Master flag for all loops
local MainLoopThread = nil
local KeybindConnection = nil

--// CONFIGURATION
local Config = {
    Nape = {
        Enabled = false,
        ShowHitbox = false,
        MultX = 1,
        MultY = 1,
        MultZ = 1,
        Color = Color3.fromRGB(255, 0, 0),
        Material = Enum.Material.ForceField,
        Transparency = 0.3
    },
    Eyes = {
        Enabled = false,
        ShowHitbox = false,
        MultX = 1,
        MultY = 1,
        MultZ = 1,
        Color = Color3.fromRGB(0, 255, 0),
        Material = Enum.Material.ForceField,
        Transparency = 0.3
    }
}

--// SPOOF ENGINE MODULE
local SpoofEngine = {}
SpoofEngine.SpoofedParts = {}     -- [part] = {original data}
SpoofEngine.ProcessedParts = {}   -- [part] = true
SpoofEngine.TitanConnections = {} -- [titan model] = {death connection}
SpoofEngine.HookInstalled = false
SpoofEngine.OldIndex = nil

function SpoofEngine:StoreOriginal(part, hitboxType)
    if self.SpoofedParts[part] then return end
    
    self.SpoofedParts[part] = {
        Size = part.Size,
        Transparency = part.Transparency,
        Color = part.Color,
        Material = part.Material,
        BrickColor = part.BrickColor,
        HitboxType = hitboxType,
        TitanModel = part.Parent -- Store reference to titan model
    }
end

function SpoofEngine:Apply(part, hitboxType)
    if not Running then return end
    if not part:IsA("BasePart") then return end
    if self.ProcessedParts[part] then return end
    
    local config = Config[hitboxType]
    if not config then return end
    if not config.Enabled then return end
    
    -- Check if titan is alive before applying
    local titanModel = part.Parent
    if titanModel then
        local humanoid = titanModel:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            return -- Don't apply to dead titans
        end
        
        -- Setup death listener for this titan
        self:SetupTitanDeathListener(titanModel)
    end
    
    -- Store originals BEFORE modification
    self:StoreOriginal(part, hitboxType)
    
    -- Apply modifications
    local original = self.SpoofedParts[part]
    local multiplier = Vector3.new(config.MultX, config.MultY, config.MultZ)
    
    part.Size = original.Size * multiplier
    
    if config.ShowHitbox then
        part.Transparency = config.Transparency
        part.Color = config.Color
        part.Material = config.Material
    end
    
    self.ProcessedParts[part] = true
end

function SpoofEngine:SetupTitanDeathListener(titanModel)
    -- Skip if already listening
    if self.TitanConnections[titanModel] then return end
    
    local humanoid = titanModel:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Listen for death
    local deathConnection = humanoid.Died:Connect(function()
        self:CleanupTitan(titanModel)
    end)
    
    -- Also listen for model removal (in case it's destroyed without dying)
    local destroyConnection = titanModel.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self:CleanupTitan(titanModel)
        end
    end)
    
    self.TitanConnections[titanModel] = {
        death = deathConnection,
        destroy = destroyConnection
    }
end

function SpoofEngine:CleanupTitan(titanModel)
    -- Disconnect listeners
    local connections = self.TitanConnections[titanModel]
    if connections then
        if connections.death then connections.death:Disconnect() end
        if connections.destroy then connections.destroy:Disconnect() end
        self.TitanConnections[titanModel] = nil
    end
    
    -- Find and restore all parts belonging to this titan
    local partsToRestore = {}
    for part, data in pairs(self.SpoofedParts) do
        if data.TitanModel == titanModel then
            table.insert(partsToRestore, part)
        end
    end
    
    for _, part in ipairs(partsToRestore) do
        self:Restore(part)
    end
end

function SpoofEngine:Restore(part)
    local original = self.SpoofedParts[part]
    if not original then return end
    
    pcall(function()
        if part and part.Parent then
            part.Size = original.Size
            part.Transparency = original.Transparency
            part.Color = original.Color
            part.Material = original.Material
            part.BrickColor = original.BrickColor
        end
    end)
    
    self.SpoofedParts[part] = nil
    self.ProcessedParts[part] = nil
end

function SpoofEngine:RestoreAll()
    -- Disconnect all titan connections first
    for titanModel, connections in pairs(self.TitanConnections) do
        if connections.death then pcall(function() connections.death:Disconnect() end) end
        if connections.destroy then pcall(function() connections.destroy:Disconnect() end) end
    end
    self.TitanConnections = {}
    
    -- Restore all parts
    local partsToRestore = {}
    for part, _ in pairs(self.SpoofedParts) do
        table.insert(partsToRestore, part)
    end
    
    for _, part in ipairs(partsToRestore) do
        self:Restore(part)
    end
    
    self.SpoofedParts = {}
    self.ProcessedParts = {}
end

function SpoofEngine:RestoreByType(hitboxType)
    local partsToRestore = {}
    for part, data in pairs(self.SpoofedParts) do
        if data.HitboxType == hitboxType then
            table.insert(partsToRestore, part)
        end
    end
    
    for _, part in ipairs(partsToRestore) do
        self:Restore(part)
    end
end

function SpoofEngine:RefreshByType(hitboxType)
    for part, data in pairs(self.SpoofedParts) do
        if data.HitboxType == hitboxType then
            local config = Config[hitboxType]
            if not config.Enabled then
                self:Restore(part)
            else
                pcall(function()
                    local multiplier = Vector3.new(config.MultX, config.MultY, config.MultZ)
                    part.Size = data.Size * multiplier
                    
                    if config.ShowHitbox then
                        part.Transparency = config.Transparency
                        part.Color = config.Color
                        part.Material = config.Material
                    else
                        part.Transparency = data.Transparency
                        part.Color = data.Color
                        part.Material = data.Material
                    end
                end)
            end
        end
    end
end

function SpoofEngine:RefreshVisualsByType(hitboxType)
    for part, data in pairs(self.SpoofedParts) do
        if data.HitboxType == hitboxType then
            local config = Config[hitboxType]
            if config and config.Enabled then
                pcall(function()
                    if config.ShowHitbox then
                        part.Transparency = config.Transparency
                        part.Color = config.Color
                        part.Material = config.Material
                    else
                        part.Transparency = data.Transparency
                        part.Color = data.Color
                        part.Material = data.Material
                    end
                end)
            end
        end
    end
end

function SpoofEngine:CleanupDeadTitans()
    -- Check all tracked parts for dead titans
    local partsToRestore = {}
    
    for part, data in pairs(self.SpoofedParts) do
        local titanModel = data.TitanModel
        if titanModel then
            -- Check if titan model still exists
            if not titanModel.Parent then
                table.insert(partsToRestore, part)
            else
                -- Check if humanoid is dead
                local humanoid = titanModel:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health <= 0 then
                    table.insert(partsToRestore, part)
                end
            end
        end
    end
    
    for _, part in ipairs(partsToRestore) do
        self:Restore(part)
    end
    
    return #partsToRestore
end

function SpoofEngine:InstallHook()
    if self.HookInstalled then return end
    
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if SpoofEngine.SpoofedParts[self] and SpoofEngine.SpoofedParts[self][key] then
            return SpoofEngine.SpoofedParts[self][key]
        end
        return oldIndex(self, key)
    end))
    
    self.OldIndex = oldIndex
    self.HookInstalled = true
    print("[Levi Hub] Metatable hook installed")
end

function SpoofEngine:GetStats()
    local count = 0
    local napeCount = 0
    local eyesCount = 0
    local titanCount = 0
    
    local trackedTitans = {}
    for _, data in pairs(self.SpoofedParts) do
        count = count + 1
        if data.HitboxType == "Nape" then
            napeCount = napeCount + 1
        elseif data.HitboxType == "Eyes" then
            eyesCount = eyesCount + 1
        end
        if data.TitanModel and not trackedTitans[data.TitanModel] then
            trackedTitans[data.TitanModel] = true
            titanCount = titanCount + 1
        end
    end
    
    return {
        Total = count,
        Nape = napeCount,
        Eyes = eyesCount,
        Titans = titanCount,
        Connections = 0
    }
end

--// TITAN SCANNER (no longer has its own loop - uses main loop)
local TitanScanner = {}
TitanScanner.WatchConnection = nil

function TitanScanner:FindHitbox(model, name)
    local hitbox = model:FindFirstChild(name)
    if hitbox and hitbox:IsA("BasePart") then
        return hitbox
    end
    return nil
end

function TitanScanner:ProcessTitan(model)
    if not Running then return end
    
    -- Check if titan is alive
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        return
    end
    
    for _, hitboxName in ipairs(HITBOX_NAMES) do
        local hitbox = self:FindHitbox(model, hitboxName)
        if hitbox then
            SpoofEngine:Apply(hitbox, hitboxName)
        end
    end
end

function TitanScanner:ScanAll()
    if not Running then return end
    
    local container = workspace:FindFirstChild(TITAN_CONTAINER)
    if not container then return 0 end
    
    local processedCount = 0
    for _, titan in ipairs(container:GetChildren()) do
        if titan:IsA("Model") then
            self:ProcessTitan(titan)
            processedCount = processedCount + 1
        end
    end
    
    return processedCount
end

function TitanScanner:SetupWatcher()
    local container = workspace:FindFirstChild(TITAN_CONTAINER)
    if not container then
        container = workspace:WaitForChild(TITAN_CONTAINER, 30)
        if not container then
            warn("[Levi Hub] Titan container not found!")
            return
        end
    end
    
    -- Watch for new titans (instant detection)
    self.WatchConnection = container.ChildAdded:Connect(function(child)
        if not Running then return end
        if child:IsA("Model") then
            task.wait(0.2) -- Small delay for parts to load
            self:ProcessTitan(child)
        end
    end)
    
    print("[Levi Hub] Titan watcher started")
end

function TitanScanner:Stop()
    if self.WatchConnection then
        self.WatchConnection:Disconnect()
        self.WatchConnection = nil
    end
end

--// MAIN LOOP (single optimized loop for everything)
local function StartMainLoop()
    MainLoopThread = task.spawn(function()
        print("[Levi Hub] Main loop started")
        
        while Running do
            -- 1. Cleanup dead titans and orphaned parts
            local cleaned = SpoofEngine:CleanupDeadTitans()
            
            -- 2. Scan for new titans (in case watcher missed any)
            TitanScanner:ScanAll()
            
            -- Wait for next cycle
            task.wait(MAIN_LOOP_INTERVAL)
        end
        
        print("[Levi Hub] Main loop stopped")
    end)
end

local function StopMainLoop()
    Running = false
    if MainLoopThread then
        pcall(function() task.cancel(MainLoopThread) end)
        MainLoopThread = nil
    end
end

--// UI MODULE
local UI = {}
UI.Starlight = nil
UI.Window = nil
UI.NebulaIcons = nil
UI.Visible = true

function UI:Load()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
    end)
    
    if not success then
        warn("[Levi Hub] Failed to load Starlight: " .. tostring(result))
        return false
    end
    
    self.Starlight = result
    self.NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()
    
    return true
end

function UI:CreateWindow()
    self.Window = self.Starlight:CreateWindow({
        Name = "Levi Hub",
        Subtitle = "Attack on Titan: Freedom War",
        Icon = self.NebulaIcons:GetIcon('feather', 'Lucide'),
        LoadingSettings = {
            Title = "Levi Hub",
            Subtitle = VERSION,
        },
        FileSettings = {
            ConfigFolder = "LeviHub"
        },
    })
    
    return self.Window
end

function UI:SetupTabs()
    local MainSection = self.Window:CreateTabSection("Main")
    
    local GeneralTab = MainSection:CreateTab({
        Name = "General",
        Icon = self.NebulaIcons:GetIcon('home', 'Lucide'),
        Columns = 2
    }, "GeneralTab")
    
    local TitansTab = MainSection:CreateTab({
        Name = "Titans",
        Icon = self.NebulaIcons:GetIcon('crosshair', 'Lucide'),
        Columns = 2
    }, "TitansTab")
    
    local SettingsTab = MainSection:CreateTab({
        Name = "Settings",
        Icon = self.NebulaIcons:GetIcon('settings', 'Lucide'),
        Columns = 2
    }, "SettingsTab")
    
    return {
        General = GeneralTab,
        Titans = TitansTab,
        Settings = SettingsTab
    }
end

function UI:SetupGeneralTab(tab)
    local InfoGroup = tab:CreateGroupbox({
        Name = "Information",
        Column = 1
    }, "InfoGroup")
    
    InfoGroup:CreateParagraph({
        Name = "Welcome",
        Content = "Levi Hub - Hitbox Extender\n\nBypass: Metatable Spoofing\nStatus: Active"
    }, "Idx_Welcome")
    
    InfoGroup:CreateLabel({
        Name = "Version: " .. VERSION
    }, "Idx_Version")
    
    local StatsGroup = tab:CreateGroupbox({
        Name = "Statistics",
        Column = 2
    }, "StatsGroup")
    
    local statsLabel = StatsGroup:CreateLabel({
        Name = "Loading..."
    }, "Idx_Stats")
    
    -- Stats update is now part of main loop concept - but we do it via UI refresh
    task.spawn(function()
        while Running do
            local stats = SpoofEngine:GetStats()
            pcall(function()
                statsLabel:SetName("Parts: " .. stats.Total .. " | Titans: " .. stats.Titans)
            end)
            task.wait(2)
        end
    end)
end

function UI:SetupTitansTab(tab)
    -- Nape Hitbox Group
    local NapeGroup = tab:CreateGroupbox({
        Name = "Nape Hitbox",
        Column = 1
    }, "NapeGroup")
    
    NapeGroup:CreateToggle({
        Name = "Enable Nape",
        CurrentValue = Config.Nape.Enabled,
        Callback = function(val)
            Config.Nape.Enabled = val
            if val then
                TitanScanner:ScanAll()
            else
                SpoofEngine:RestoreByType("Nape")
            end
        end
    }, "Idx_NapeEnabled")
    
    NapeGroup:CreateToggle({
        Name = "Show Hitbox",
        CurrentValue = Config.Nape.ShowHitbox,
        Callback = function(val)
            Config.Nape.ShowHitbox = val
            SpoofEngine:RefreshVisualsByType("Nape")
        end
    }, "Idx_NapeShowHitbox")
    
    NapeGroup:CreateSlider({
        Name = "Size X",
        Range = {1, 10},
        Increment = 0.5,
        CurrentValue = Config.Nape.MultX,
        Suffix = "x",
        Callback = function(val)
            Config.Nape.MultX = val
            SpoofEngine:RefreshByType("Nape")
        end
    }, "Idx_NapeX")
    
    NapeGroup:CreateSlider({
        Name = "Size Y",
        Range = {1, 10},
        Increment = 0.5,
        CurrentValue = Config.Nape.MultY,
        Suffix = "x",
        Callback = function(val)
            Config.Nape.MultY = val
            SpoofEngine:RefreshByType("Nape")
        end
    }, "Idx_NapeY")
    
    NapeGroup:CreateSlider({
        Name = "Size Z",
        Range = {1, 10},
        Increment = 0.5,
        CurrentValue = Config.Nape.MultZ,
        Suffix = "x",
        Callback = function(val)
            Config.Nape.MultZ = val
            SpoofEngine:RefreshByType("Nape")
        end
    }, "Idx_NapeZ")
    
    NapeGroup:CreateSlider({
        Name = "Transparency",
        Range = {0, 1},
        Increment = 0.1,
        CurrentValue = Config.Nape.Transparency,
        Callback = function(val)
            Config.Nape.Transparency = val
            SpoofEngine:RefreshByType("Nape")
        end
    }, "Idx_NapeTransparency")
    
    local napeColorLabel = NapeGroup:CreateLabel({
        Name = "Color"
    }, "Idx_NapeColorLabel")
    
    napeColorLabel:AddColorPicker({
        CurrentValue = Config.Nape.Color,
        Callback = function(val)
            Config.Nape.Color = val
            SpoofEngine:RefreshByType("Nape")
        end
    }, "Idx_NapeColor")
    
    local napeMaterialLabel = NapeGroup:CreateLabel({
        Name = "Material"
    }, "Idx_NapeMaterialLabel")
    
    napeMaterialLabel:AddDropdown({
        Options = MATERIAL_OPTIONS,
        CurrentOption = "ForceField",
        Callback = function(val)
            Config.Nape.Material = Enum.Material[val]
            SpoofEngine:RefreshByType("Nape")
        end
    }, "Idx_NapeMaterial")
    
    NapeGroup:CreateButton({
        Name = "Force Scan",
        Callback = function()
            local count = TitanScanner:ScanAll()
            self.Starlight:Notification({
                Title = "Levi Hub",
                Content = "Scanned " .. count .. " titans",
                Duration = 3
            })
        end
    }, "Idx_ForceScan")
    
    -- Eyes Hitbox Group
    local EyesGroup = tab:CreateGroupbox({
        Name = "Eyes Hitbox",
        Column = 2
    }, "EyesGroup")
    
    EyesGroup:CreateToggle({
        Name = "Enable Eyes",
        CurrentValue = Config.Eyes.Enabled,
        Callback = function(val)
            Config.Eyes.Enabled = val
            if val then
                TitanScanner:ScanAll()
            else
                SpoofEngine:RestoreByType("Eyes")
            end
        end
    }, "Idx_EyesEnabled")
    
    EyesGroup:CreateToggle({
        Name = "Show Hitbox",
        CurrentValue = Config.Eyes.ShowHitbox,
        Callback = function(val)
            Config.Eyes.ShowHitbox = val
            SpoofEngine:RefreshVisualsByType("Eyes")
        end
    }, "Idx_EyesShowHitbox")
    
    EyesGroup:CreateSlider({
        Name = "Size X",
        Range = {1, 10},
        Increment = 0.5,
        CurrentValue = Config.Eyes.MultX,
        Suffix = "x",
        Callback = function(val)
            Config.Eyes.MultX = val
            SpoofEngine:RefreshByType("Eyes")
        end
    }, "Idx_EyesX")
    
    EyesGroup:CreateSlider({
        Name = "Size Y",
        Range = {1, 10},
        Increment = 0.5,
        CurrentValue = Config.Eyes.MultY,
        Suffix = "x",
        Callback = function(val)
            Config.Eyes.MultY = val
            SpoofEngine:RefreshByType("Eyes")
        end
    }, "Idx_EyesY")
    
    EyesGroup:CreateSlider({
        Name = "Size Z",
        Range = {1, 10},
        Increment = 0.5,
        CurrentValue = Config.Eyes.MultZ,
        Suffix = "x",
        Callback = function(val)
            Config.Eyes.MultZ = val
            SpoofEngine:RefreshByType("Eyes")
        end
    }, "Idx_EyesZ")
    
    EyesGroup:CreateSlider({
        Name = "Transparency",
        Range = {0, 1},
        Increment = 0.1,
        CurrentValue = Config.Eyes.Transparency,
        Callback = function(val)
            Config.Eyes.Transparency = val
            SpoofEngine:RefreshByType("Eyes")
        end
    }, "Idx_EyesTransparency")
    
    local eyesColorLabel = EyesGroup:CreateLabel({
        Name = "Color"
    }, "Idx_EyesColorLabel")
    
    eyesColorLabel:AddColorPicker({
        CurrentValue = Config.Eyes.Color,
        Callback = function(val)
            Config.Eyes.Color = val
            SpoofEngine:RefreshByType("Eyes")
        end
    }, "Idx_EyesColor")
    
    local eyesMaterialLabel = EyesGroup:CreateLabel({
        Name = "Material"
    }, "Idx_EyesMaterialLabel")
    
    eyesMaterialLabel:AddDropdown({
        Options = MATERIAL_OPTIONS,
        CurrentOption = "ForceField",
        Callback = function(val)
            Config.Eyes.Material = Enum.Material[val]
            SpoofEngine:RefreshByType("Eyes")
        end
    }, "Idx_EyesMaterial")
end

function UI:SetupSettingsTab(tab)
    tab:BuildConfigGroupbox(1)
    
    local ControlsGroup = tab:CreateGroupbox({
        Name = "Controls",
        Column = 2
    }, "ControlsGroup")
    
    ControlsGroup:CreateParagraph({
        Name = "Keybinds",
        Content = "K - Toggle UI\nHome - Unload Script"
    }, "Idx_Keybinds")
    
    ControlsGroup:CreateDivider()
    
    ControlsGroup:CreateButton({
        Name = "Unload Script",
        Callback = function()
            Unload()
        end
    }, "Idx_UnloadBtn")
    
    local CreditsGroup = tab:CreateGroupbox({
        Name = "Credits",
        Column = 2
    }, "CreditsGroup")
    
    CreditsGroup:CreateParagraph({
        Name = "Developers",
        Content = "Levi Hub\nby DeathMark58\n\nUI: Starlight"
    }, "Idx_Credits")
end

function UI:Toggle()
    self.Visible = not self.Visible
    if self.Window then
        self.Window:SetHidden(not self.Visible)
    end
end

function UI:Destroy()
    if self.Starlight then
        self.Starlight:Destroy()
    end
end

--// KEYBIND HANDLER
local function SetupKeybinds()
    KeybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.K then
            UI:Toggle()
        elseif input.KeyCode == Enum.KeyCode.Home then
            Unload()
        end
    end)
end

--// DEBUG COMMANDS
local function SetupDebugCommands()
    getgenv().AOT = {
        Scan = function()
            local count = TitanScanner:ScanAll()
            print("[Levi Hub] Scanned " .. count .. " titans")
        end,
        Cleanup = function()
            local cleaned = SpoofEngine:CleanupDeadTitans()
            print("[Levi Hub] Cleaned up " .. cleaned .. " dead titan parts")
        end,
        Stats = function()
            local stats = SpoofEngine:GetStats()
            print("[Levi Hub] Parts:", stats.Total, "| Titans:", stats.Titans, "| Nape:", stats.Nape, "| Eyes:", stats.Eyes)
            return stats
        end,
        Unload = Unload,
        Config = Config
    }
end

--// UNLOAD
function Unload()
    print("[Levi Hub] Unloading...")
    
    -- Stop running flag FIRST - this stops all loops
    Running = false
    
    -- Stop main loop
    StopMainLoop()
    
    -- Stop titan watcher
    TitanScanner:Stop()
    
    -- Disconnect keybinds
    if KeybindConnection then
        KeybindConnection:Disconnect()
        KeybindConnection = nil
    end
    
    -- Restore ALL parts
    local stats = SpoofEngine:GetStats()
    print("[Levi Hub] Restoring " .. stats.Total .. " parts...")
    SpoofEngine:RestoreAll()
    
    -- Destroy UI
    UI:Destroy()
    
    -- Clear debug
    getgenv().AOT = nil
    
    print("[Levi Hub] Unloaded - all restored")
end

--// INITIALIZATION
local function Initialize()
    if game.PlaceId == LOBBY_PLACE_ID then
        warn("[Levi Hub] Cannot run in lobby! Use the Loader instead.")
        return
    end
    
    print("[Levi Hub] Initializing " .. VERSION)
    
    -- Install hook
    SpoofEngine:InstallHook()
    
    -- Load UI
    if UI:Load() then
        UI:CreateWindow()
        local tabs = UI:SetupTabs()
        UI:SetupGeneralTab(tabs.General)
        UI:SetupTitansTab(tabs.Titans)
        UI:SetupSettingsTab(tabs.Settings)
        UI.Starlight:LoadAutoloadConfig()
    else
        warn("[Levi Hub] Failed to load UI, running headless")
    end
    
    -- Setup keybinds
    SetupKeybinds()
    
    -- Setup debug
    SetupDebugCommands()
    
    -- Setup titan watcher (instant detection)
    TitanScanner:SetupWatcher()
    
    -- Initial scan
    TitanScanner:ScanAll()
    
    -- Start main loop (single loop for cleanup + scanning)
    StartMainLoop()
    
    -- Notification
    if UI.Starlight then
        UI.Starlight:Notification({
            Title = "Levi Hub",
            Content = "Loaded! " .. VERSION,
            Duration = 5
        })
    end
    
    print("[Levi Hub] Ready")
end

Initialize()
