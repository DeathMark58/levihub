--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║                       LEVI HUB                            ║
    ║                       v0.0.01                             ║
    ╠═══════════════════════════════════════════════════════════╣
    ║  Hitbox Extender for Attack on Titan: Freedom War         ║
    ║  Anti-Cheat Bypass via Metatable Spoofing                 ║
    ╚═══════════════════════════════════════════════════════════╝
]]

--// SECURE MODE (Anti-Detection)
getgenv().SecureMode = true

--// CONSTANTS
local VERSION = "v0.0.01"
local LOBBY_PLACE_ID = 11534222714
local TITAN_CONTAINER = "OnGameTitans"
local HITBOX_NAMES = { "Nape", "Eyes" }

--// SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// STATE
local LocalPlayer = Players.LocalPlayer

--// CONFIGURATION
local Config = {
    ShowHitboxes = false, -- Master visual toggle
    Nape = {
        Enabled = false,
        MultX = 1,
        MultY = 1,
        MultZ = 1,
        Color = Color3.fromRGB(255, 0, 0),
        Material = Enum.Material.ForceField,
        Transparency = 0.3
    },
    Eyes = {
        Enabled = false,
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
SpoofEngine.SpoofedParts = {}    -- Original values storage
SpoofEngine.ProcessedParts = {}  -- Duplicate prevention
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
        HitboxType = hitboxType
    }
end

function SpoofEngine:Apply(part, hitboxType)
    -- Validation
    if not part:IsA("BasePart") then return end
    if self.ProcessedParts[part] then return end
    
    -- Get config for this hitbox type
    local config = Config[hitboxType]
    if not config then return end
    if not config.Enabled then return end
    
    -- Store originals BEFORE modification
    self:StoreOriginal(part, hitboxType)
    
    -- Apply modifications
    local original = self.SpoofedParts[part]
    local multiplier = Vector3.new(config.MultX, config.MultY, config.MultZ)
    
    part.Size = original.Size * multiplier
    part.Transparency = Config.ShowHitboxes and config.Transparency or original.Transparency
    part.Color = Config.ShowHitboxes and config.Color or original.Color
    part.Material = Config.ShowHitboxes and config.Material or original.Material
    
    -- Mark as processed
    self.ProcessedParts[part] = true
end

function SpoofEngine:Restore(part)
    local original = self.SpoofedParts[part]
    if not original then return end
    
    pcall(function()
        part.Size = original.Size
        part.Transparency = original.Transparency
        part.Color = original.Color
        part.Material = original.Material
        part.BrickColor = original.BrickColor
    end)
    
    self.SpoofedParts[part] = nil
    self.ProcessedParts[part] = nil
end

function SpoofEngine:RestoreAll()
    for part, _ in pairs(self.SpoofedParts) do
        self:Restore(part)
    end
end

function SpoofEngine:RestoreByType(hitboxType)
    for part, data in pairs(self.SpoofedParts) do
        if data.HitboxType == hitboxType then
            self:Restore(part)
        end
    end
end

function SpoofEngine:RefreshByType(hitboxType)
    for part, data in pairs(self.SpoofedParts) do
        if data.HitboxType == hitboxType then
            local config = Config[hitboxType]
            if not config.Enabled then
                self:Restore(part)
            else
                local multiplier = Vector3.new(config.MultX, config.MultY, config.MultZ)
                part.Size = data.Size * multiplier
                part.Transparency = Config.ShowHitboxes and config.Transparency or data.Transparency
                part.Color = Config.ShowHitboxes and config.Color or data.Color
                part.Material = Config.ShowHitboxes and config.Material or data.Material
            end
        end
    end
end

function SpoofEngine:RefreshVisuals()
    -- Only update visual properties (color, transparency, material)
    for part, data in pairs(self.SpoofedParts) do
        local config = Config[data.HitboxType]
        if config and config.Enabled then
            part.Transparency = Config.ShowHitboxes and config.Transparency or data.Transparency
            part.Color = Config.ShowHitboxes and config.Color or data.Color
            part.Material = Config.ShowHitboxes and config.Material or data.Material
        end
    end
end

function SpoofEngine:InstallHook()
    if self.HookInstalled then return end
    
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        -- Check if this part is spoofed and property is tracked
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
    
    for _, data in pairs(self.SpoofedParts) do
        count = count + 1
        if data.HitboxType == "Nape" then
            napeCount = napeCount + 1
        elseif data.HitboxType == "Eyes" then
            eyesCount = eyesCount + 1
        end
    end
    
    return {
        Total = count,
        Nape = napeCount,
        Eyes = eyesCount
    }
end

--// TITAN SCANNER MODULE
local TitanScanner = {}
TitanScanner.Connection = nil
TitanScanner.RefreshLoop = nil

function TitanScanner:FindHitbox(model, name, retries)
    retries = retries or 5
    local hitbox = model:FindFirstChild(name)
    
    if hitbox and hitbox:IsA("BasePart") then
        return hitbox
    end
    
    -- Retry for late-loading parts
    if retries > 0 then
        task.wait(0.5)
        return self:FindHitbox(model, name, retries - 1)
    end
    
    return nil
end

function TitanScanner:ProcessTitan(model)
    for _, hitboxName in ipairs(HITBOX_NAMES) do
        local hitbox = self:FindHitbox(model, hitboxName, 3)
        if hitbox then
            SpoofEngine:Apply(hitbox, hitboxName)
        end
    end
end

function TitanScanner:ScanAll()
    local container = workspace:FindFirstChild(TITAN_CONTAINER)
    if not container then return end
    
    for _, titan in ipairs(container:GetChildren()) do
        if titan:IsA("Model") then
            self:ProcessTitan(titan)
        end
    end
end

function TitanScanner:StartWatching()
    local container = workspace:FindFirstChild(TITAN_CONTAINER)
    if not container then
        -- Wait for container
        container = workspace:WaitForChild(TITAN_CONTAINER, 30)
        if not container then
            warn("[Levi Hub] Titan container not found!")
            return
        end
    end
    
    -- Watch for new titans
    self.Connection = container.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") and table.find(HITBOX_NAMES, desc.Name) then
            task.wait(0.1) -- Small delay for parent setup
            local parent = desc.Parent
            if parent and parent:IsA("Model") then
                SpoofEngine:Apply(desc, desc.Name)
            end
        end
    end)
    
    -- Initial scan
    self:ScanAll()
    
    -- Periodic refresh (for titans that spawn with delays)
    self.RefreshLoop = task.spawn(function()
        while task.wait(3) do
            self:ScanAll()
        end
    end)
    
    print("[Levi Hub] Titan watcher started")
end

function TitanScanner:Stop()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    if self.RefreshLoop then
        task.cancel(self.RefreshLoop)
        self.RefreshLoop = nil
    end
end

--// UI MODULE
local UI = {}
UI.Starlight = nil
UI.Window = nil
UI.NebulaIcons = nil
UI.Visible = true

function UI:Load()
    -- Load Starlight
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
    end)
    
    if not success then
        warn("[Levi Hub] Failed to load Starlight: " .. tostring(result))
        return false
    end
    
    self.Starlight = result
    
    -- Load Icons
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
    -- Main Section
    local MainSection = self.Window:CreateTabSection("Main")
    
    -- General Tab
    local GeneralTab = MainSection:CreateTab({
        Name = "General",
        Icon = self.NebulaIcons:GetIcon('home', 'Material'),
        Columns = 2
    }, "GeneralTab")
    
    -- Titans Tab
    local TitansTab = MainSection:CreateTab({
        Name = "Titans",
        Icon = self.NebulaIcons:GetIcon('crosshair', 'Lucide'),
        Columns = 2
    }, "TitansTab")
    
    -- Settings Tab
    local SettingsTab = MainSection:CreateTab({
        Name = "Settings",
        Icon = self.NebulaIcons:GetIcon('settings', 'Material'),
        Columns = 2
    }, "SettingsTab")
    
    return {
        General = GeneralTab,
        Titans = TitansTab,
        Settings = SettingsTab
    }
end

function UI:SetupGeneralTab(tab)
    -- Info Group
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
    
    -- Stats Group
    local StatsGroup = tab:CreateGroupbox({
        Name = "Statistics",
        Column = 2
    }, "StatsGroup")
    
    local statsLabel = StatsGroup:CreateLabel({
        Name = "Spoofed Parts: 0"
    }, "Idx_Stats")
    
    -- Update stats periodically
    task.spawn(function()
        while task.wait(2) do
            local stats = SpoofEngine:GetStats()
            pcall(function()
                statsLabel:SetName("Spoofed: " .. stats.Total .. " (N:" .. stats.Nape .. " E:" .. stats.Eyes .. ")")
            end)
        end
    end)
end

function UI:SetupTitansTab(tab)
    -- Master Controls Group
    local MasterGroup = tab:CreateGroupbox({
        Name = "Master Controls",
        Column = 1
    }, "MasterGroup")
    
    MasterGroup:CreateToggle({
        Name = "Show Hitboxes",
        CurrentValue = Config.ShowHitboxes,
        Callback = function(val)
            Config.ShowHitboxes = val
            SpoofEngine:RefreshVisuals()
        end
    }, "Idx_ShowHitboxes")
    
    MasterGroup:CreateDivider()
    
    -- Scan button
    MasterGroup:CreateButton({
        Name = "Force Scan Titans",
        Callback = function()
            TitanScanner:ScanAll()
            self.Starlight:Notification({
                Title = "Levi Hub",
                Content = "Titan scan complete!",
                Duration = 3
            })
        end
    }, "Idx_ForceScan")
    
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
    
    -- Nape color picker (attached to label)
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
    
    -- Eyes color picker
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
end

function UI:SetupSettingsTab(tab)
    -- Config Group
    local ConfigGroup = tab:CreateGroupbox({
        Name = "Configuration",
        Column = 1
    }, "ConfigGroup")
    
    -- Built-in config system
    tab:BuildConfigGroupbox(1)
    
    -- Controls Group
    local ControlsGroup = tab:CreateGroupbox({
        Name = "Controls",
        Column = 2
    }, "ControlsGroup")
    
    ControlsGroup:CreateParagraph({
        Name = "Keybinds",
        Content = "Insert - Toggle UI\nHome - Unload Script"
    }, "Idx_Keybinds")
    
    ControlsGroup:CreateDivider()
    
    ControlsGroup:CreateButton({
        Name = "Unload Script",
        Callback = function()
            Unload()
        end
    }, "Idx_UnloadBtn")
    
    -- Credits Group
    local CreditsGroup = tab:CreateGroupbox({
        Name = "Credits",
        Column = 2
    }, "CreditsGroup")
    
    CreditsGroup:CreateParagraph({
        Name = "Developers",
        Content = "Levi Hub\nby DeathMark58\n\nUI: Starlight by Nebula Softworks"
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
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Insert then
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
            TitanScanner:ScanAll()
            print("[Levi Hub] Manual scan complete")
        end,
        Refresh = function()
            SpoofEngine:RefreshByType("Nape")
            SpoofEngine:RefreshByType("Eyes")
            print("[Levi Hub] Refreshed all hitboxes")
        end,
        Stats = function()
            local stats = SpoofEngine:GetStats()
            print("[Levi Hub] Stats:", "Total:", stats.Total, "Nape:", stats.Nape, "Eyes:", stats.Eyes)
            return stats
        end,
        Unload = function()
            Unload()
        end,
        Config = Config
    }
end

--// UNLOAD
function Unload()
    print("[Levi Hub] Unloading...")
    
    -- Stop scanner
    TitanScanner:Stop()
    
    -- Restore all parts
    SpoofEngine:RestoreAll()
    
    -- Destroy UI
    UI:Destroy()
    
    -- Clear debug commands
    getgenv().AOT = nil
    
    print("[Levi Hub] Unloaded successfully")
end

--// INITIALIZATION
local function Initialize()
    -- Check if in lobby
    if game.PlaceId == LOBBY_PLACE_ID then
        warn("[Levi Hub] Cannot run in lobby! Use the Loader instead.")
        return
    end
    
    print("[Levi Hub] Initializing " .. VERSION)
    
    -- Install metatable hook
    SpoofEngine:InstallHook()
    
    -- Load UI
    if not UI:Load() then
        warn("[Levi Hub] Failed to load UI, running headless")
    else
        UI:CreateWindow()
        local tabs = UI:SetupTabs()
        UI:SetupGeneralTab(tabs.General)
        UI:SetupTitansTab(tabs.Titans)
        UI:SetupSettingsTab(tabs.Settings)
        
        -- Load autoload config
        UI.Starlight:LoadAutoloadConfig()
    end
    
    -- Setup keybinds
    SetupKeybinds()
    
    -- Setup debug commands
    SetupDebugCommands()
    
    -- Start titan watcher
    TitanScanner:StartWatching()
    
    -- Notification
    if UI.Starlight then
        UI.Starlight:Notification({
            Title = "Levi Hub",
            Content = "Loaded successfully! " .. VERSION,
            Duration = 5
        })
    end
    
    print("[Levi Hub] Initialization complete")
end

-- Run
Initialize()
