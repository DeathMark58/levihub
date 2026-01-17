--[[
    LEVI HUB - Attack on Titan: Freedom War
    Version: v0.0.01 (Updated)
]]

-- ============================================================================
-- 1. INIT & VARIABLES
-- ============================================================================
getgenv().SecureMode = true -- Starlight Secure Mode

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- BYPASS LOADING
local BYPASS_URL = "https://raw.githubusercontent.com/Pixeluted/adoniscries/refs/heads/main/Source.lua"
pcall(function() loadstring(game:HttpGet(BYPASS_URL))() end)

-- CONFIG
local Config = {
    -- Nape
    NapeEnabled = false,
    NapeMultiX = 5,
    NapeMultiY = 5,
    NapeMultiZ = 5,
    NapeTransparency = 0,
    NapeColor = Color3.fromRGB(255, 0, 0),
    NapeMaterial = "ForceField",
    
    -- Eyes
    EyesEnabled = false,
    EyesMultiX = 5,
    EyesMultiY = 5,
    EyesMultiZ = 5,
    EyesTransparency = 0,
    EyesColor = Color3.fromRGB(0, 255, 0),
    EyesMaterial = "ForceField",
}

-- SERVICES & VARS
local SpoofEngine = {}
local TitanManager = {}
local Interface = {}

-- ============================================================================
-- 2. SPOOF ENGINE (Modular)
-- ============================================================================
SpoofEngine.SpoofedParts = {}
SpoofEngine.Originals = {} 
SpoofEngine.OldIndex = nil

function SpoofEngine:Setup()
    if self.OldIndex then return end
    
    self.OldIndex = hookmetamethod(game, "__index", newcclosure(function(self_inst, key)
        local spoofed = SpoofEngine.SpoofedParts[self_inst]
        if spoofed and spoofed[key] ~= nil then
            return SpoofEngine.Originals[self_inst][key]
        end
        return SpoofEngine.OldIndex(self_inst, key)
    end))
end

function SpoofEngine:Register(part, property, value)
    if not part then return end
    
    -- Init tables
    if not self.SpoofedParts[part] then
        self.SpoofedParts[part] = {}
        self.Originals[part] = {}
    end
    
    -- Save original (IMPORTANT: Only if not already saved to avoid overwriting with modified value)
    if self.Originals[part][property] == nil then
        self.Originals[part][property] = part[property]
    end
    
    -- Mark as spoofed
    self.SpoofedParts[part][property] = true
    
    -- Apply visual change
    pcall(function()
        part[property] = value
    end)
end

function SpoofEngine:GetBaseProperty(part, property)
    if self.Originals[part] and self.Originals[part][property] ~= nil then
        return self.Originals[part][property]
    end
    return part[property]
end

function SpoofEngine:Restore(part)
    if not part or not self.Originals[part] then return end
    
    for prop, val in pairs(self.Originals[part]) do
        pcall(function() part[prop] = val end)
    end
    
    self.SpoofedParts[part] = nil
    self.Originals[part] = nil
end

function SpoofEngine:RestoreAll()
    for part, _ in pairs(self.SpoofedParts) do
        self:Restore(part)
    end
end

-- ============================================================================
-- 3. TITAN MANAGER
-- ============================================================================
TitanManager.Connections = {}

function TitanManager:ProcessHitbox(part, configPrefix)
    if not part or not part:IsA("BasePart") then return end

    local isEnabled = Config[configPrefix .. "Enabled"]
    
    if isEnabled then
        -- 1. Ensure Original Size is Captured FIRST
        -- We trigger a dummy read or register to ensure 'Size' is in Originals
        if not SpoofEngine.Originals[part] or not SpoofEngine.Originals[part]["Size"] then
            SpoofEngine:Register(part, "Size", part.Size) -- Saves current as original, sets current
        end
        
        -- 2. Calculate New Size based on ORIGINAL size
        local baseSize = SpoofEngine:GetBaseProperty(part, "Size")
        local newSize = baseSize * Vector3.new(
            Config[configPrefix .. "MultiX"],
            Config[configPrefix .. "MultiY"],
            Config[configPrefix .. "MultiZ"]
        )
        
        -- 3. Apply Properties
        SpoofEngine:Register(part, "Size", newSize)
        SpoofEngine:Register(part, "Transparency", Config[configPrefix .. "Transparency"])
        SpoofEngine:Register(part, "Color", Config[configPrefix .. "Color"])
        SpoofEngine:Register(part, "Material", Enum.Material[Config[configPrefix .. "Material"]] or Enum.Material.ForceField)
        SpoofEngine:Register(part, "CanCollide", false)
    else
        SpoofEngine:Restore(part)
    end
end

function TitanManager:Refresh()
    local container = Workspace:FindFirstChild("OnGameTitans")
    if not container then return end
    
    for _, model in ipairs(container:GetChildren()) do
        if model:IsA("Model") then
            -- Nape
            local nape = model:FindFirstChild("Nape")
            if nape then self:ProcessHitbox(nape, "Nape") end
            
            -- Eyes
            local eyes = model:FindFirstChild("Eyes")
            if eyes then self:ProcessHitbox(eyes, "Eyes") end
        end
    end
end

function TitanManager:StartLoop()
    -- Watch Logic
    local function Watch(container)
        local c = container.ChildAdded:Connect(function()
            task.wait(0.5) 
            TitanManager:Refresh()
        end)
        table.insert(self.Connections, c)
    end
    
    if Workspace:FindFirstChild("OnGameTitans") then
        Watch(Workspace.OnGameTitans)
    end
    local c2 = Workspace.ChildAdded:Connect(function(child)
        if child.Name == "OnGameTitans" then Watch(child) end
    end)
    table.insert(self.Connections, c2)
    
    task.spawn(function()
        while true do
            task.wait(2)
            TitanManager:Refresh()
        end
    end)
end

-- ============================================================================
-- 4. INTERFACE
-- ============================================================================
function Interface:Load()
    local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
    local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()

    local Window = Starlight:CreateWindow({
        Name = "Levi Hub",
        Subtitle = "v0.0.01",
        Icon = NebulaIcons:GetIcon('feather', 'Lucide'),
        LoadingSettings = { Title = "Levi Hub", Subtitle = "Loading..." },
        FileSettings = { ConfigFolder = "LeviHub" },
    })

    local MainSection = Window:CreateTabSection("Main")

    -- 1. General Tab
    local GeneralTab = MainSection:CreateTab({
        Name = "General",
        Icon = NebulaIcons:GetIcon('layout-dashboard', 'Lucide'),
        Columns = 1
    }, "GeneralTab")
    
    local HomeGroup = GeneralTab:CreateGroupbox({ Name = "Dashboard", Column = 1 }, "HomeGroup")
    HomeGroup:CreateParagraph({ Name = "Welcome", Content = "Welcome to Levi Hub.\nVersion: v0.0.01\nStatus: Beta" }, "WelcomePara")

    -- 2. Human Tab
    local HumanTab = MainSection:CreateTab({
        Name = "Human",
        Icon = NebulaIcons:GetIcon('person', 'Material'),
        Columns = 2
    }, "HumanTab")
    HumanTab:CreateGroupbox({Name = "Movement", Column = 1}, "MoveGroup"):CreateLabel({Name = "Coming Soon"}, "CS1")

    -- 3. Titan Tab
    local TitanTab = MainSection:CreateTab({
        Name = "Titans",
        Icon = NebulaIcons:GetIcon('skull', 'Lucide'), 
        Columns = 2
    }, "TitanTab")

    -- Helper to create Hitbox UI
    local function CreateHitboxUI(group, prefix, title)
        group:CreateToggle({
            Name = "Enable " .. title,
            CurrentValue = false,
            Callback = function(v)
                Config[prefix.."Enabled"] = v
                TitanManager:Refresh()
            end
        }, prefix.."Toggle")
        
        -- Multipliers
        group:CreateSlider({ Name = "Multiplier X", Range = {1, 20}, Increment = 0.5, CurrentValue = 5,
            Callback = function(v) Config[prefix.."MultiX"] = v; TitanManager:Refresh() end }, prefix.."MultiX")
            
        group:CreateSlider({ Name = "Multiplier Y", Range = {1, 20}, Increment = 0.5, CurrentValue = 5,
            Callback = function(v) Config[prefix.."MultiY"] = v; TitanManager:Refresh() end }, prefix.."MultiY")
            
        group:CreateSlider({ Name = "Multiplier Z", Range = {1, 20}, Increment = 0.5, CurrentValue = 5,
            Callback = function(v) Config[prefix.."MultiZ"] = v; TitanManager:Refresh() end }, prefix.."MultiZ")
        
        -- Visuals
        group:CreateSlider({ Name = "Transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = 0,
            Callback = function(v) Config[prefix.."Transparency"] = v; TitanManager:Refresh() end }, prefix.."Trans")
            
        group:CreateLabel({Name = "Materials & Color"}):AddColorPicker({
            CurrentValue = (prefix == "Nape" and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)),
            Callback = function(v) Config[prefix.."Color"] = v; TitanManager:Refresh() end
        }, prefix.."Color")
        
        group:CreateLabel({Name = "Material Type"}):AddDropdown({
            Options = {"ForceField", "Neon", "Plastic", "Glass", "SmoothPlastic"},
            CurrentOptions = {"ForceField"},
            Callback = function(v)
                if type(v) == "table" then v = v[1] end
                Config[prefix.."Material"] = v
                TitanManager:Refresh()
            end
        }, prefix.."Mat")
    end

    local NapeGroup = TitanTab:CreateGroupbox({ Name = "Nape Configuration", Column = 1 }, "NapeGroup")
    CreateHitboxUI(NapeGroup, "Nape", "Nape")

    local EyesGroup = TitanTab:CreateGroupbox({ Name = "Eyes Configuration", Column = 2 }, "EyesGroup")
    CreateHitboxUI(EyesGroup, "Eyes", "Eyes")

    -- 4. Shifter Tab
    local ShifterTab = MainSection:CreateTab({
        Name = "Shifters",
        Icon = NebulaIcons:GetIcon('flash', 'Lucide'), -- flash_on is Material, flash is Lucide
        Columns = 2
    }, "ShifterTab")
    ShifterTab:CreateGroupbox({Name = "Shifters", Column = 1}, "ShifterGroup"):CreateLabel({Name = "Coming Soon"}, "CS2")

    -- 5. Settings Tab
    local SettingsTab = MainSection:CreateTab({
        Name = "Settings",
        Icon = NebulaIcons:GetIcon('settings', 'Material'),
        Columns = 2
    }, "SettingsTab")
    
    local ConfigGroup = SettingsTab:CreateGroupbox({ Name = "Configuration", Column = 1 }, "ConfigGroup")
    ConfigGroup:CreateButton({
        Name = "Unload Script",
        Callback = function()
            SpoofEngine:RestoreAll()
            Starlight:Destroy()
        end
    }, "UnloadBtn")
    
    Starlight:LoadAutoloadConfig()
end

-- ============================================================================
-- 5. MAIN EXECUTION
-- ============================================================================
SpoofEngine:Setup()
TitanManager:StartLoop()
Interface:Load()
print("[Levi Hub] v0.0.01 Loaded")
