--[[
    LEVI HUB - Attack on Titan: Freedom War
    Version: v0.0.01
]]

-- ============================================================================
-- 1. INIT & VARIABLES
-- ============================================================================
getgenv().SecureMode = true -- Starlight Secure Mode

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

-- BYPASS LOADING (Before anything else)
local BYPASS_URL = "https://raw.githubusercontent.com/Pixeluted/adoniscries/refs/heads/main/Source.lua"
pcall(function() loadstring(game:HttpGet(BYPASS_URL))() end)

-- CONFIG
local Config = {
    -- Titans
    NapeEnabled = false,
    NapeScale = 5,
    NapeTransparency = 0.5,
    NapeColor = Color3.fromRGB(255, 0, 0),
    
    EyesEnabled = false,
    EyesScale = 3,
    EyesTransparency = 0.5,
    EyesColor = Color3.fromRGB(0, 255, 0),
    
    HitboxMaterial = "ForceField",
}

-- SERVICES & VARS
local SpoofEngine = {}
local TitanManager = {}
local Interface = {}

-- ============================================================================
-- 2. SPOOF ENGINE (Modular)
-- ============================================================================
SpoofEngine.SpoofedParts = {}
SpoofEngine.Originals = {} -- Backup of original properties
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
    
    -- Init tables if new part
    if not self.SpoofedParts[part] then
        self.SpoofedParts[part] = {}
        self.Originals[part] = {}
    end
    
    -- Save original if not saved
    if self.Originals[part][property] == nil then
        self.Originals[part][property] = part[property]
    end
    
    -- Mark as spoofed
    self.SpoofedParts[part][property] = true
    
    -- Apply visual change safely
    pcall(function()
        part[property] = value
    end)
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
-- 3. TITAN MANAGER (Logic)
-- ============================================================================
TitanManager.Connections = {}

function TitanManager:GetHitboxMaterial()
    return Enum.Material[Config.HitboxMaterial] or Enum.Material.ForceField
end

function TitanManager:Refresh()
    -- Only refresh what's needed, simplest way is to re-apply active settings
    -- Because SpoofEngine prevents duplicates, we can just re-scan relevant parts
    local container = Workspace:FindFirstChild("OnGameTitans")
    if not container then return end
    
    for _, model in ipairs(container:GetChildren()) do
        if model:IsA("Model") then
            -- Nape
            local nape = model:FindFirstChild("Nape")
            if nape and nape:IsA("BasePart") then
                if Config.NapeEnabled then
                    local size = Vector3.new(Config.NapeScale, Config.NapeScale, Config.NapeScale) -- Simplification for now
                    if nape.Size.X < 50 then -- Sanity check preventing infinite growth if logic fails
                         -- For precise scaling we need original size, but for now we just set fixed large size or multiplier
                         -- Best approach: Reset first then apply
                         SpoofEngine:Restore(nape) 
                         
                         -- Apply changes
                         SpoofEngine:Register(nape, "Size", nape.Size * Config.NapeScale)
                         SpoofEngine:Register(nape, "Transparency", Config.NapeTransparency)
                         SpoofEngine:Register(nape, "Color", Config.NapeColor)
                         SpoofEngine:Register(nape, "Material", self:GetHitboxMaterial())
                         SpoofEngine:Register(nape, "CanCollide", false)
                    end
                else
                    SpoofEngine:Restore(nape)
                end
            end
            
            -- Eyes
            local eyes = model:FindFirstChild("Eyes")
            if eyes and eyes:IsA("BasePart") then
                if Config.EyesEnabled then
                     SpoofEngine:Restore(eyes)
                     SpoofEngine:Register(eyes, "Size", eyes.Size * Config.EyesScale)
                     SpoofEngine:Register(eyes, "Transparency", Config.EyesTransparency)
                     SpoofEngine:Register(eyes, "Color", Config.EyesColor)
                     SpoofEngine:Register(eyes, "Material", self:GetHitboxMaterial())
                     SpoofEngine:Register(eyes, "CanCollide", false)
                else
                    SpoofEngine:Restore(eyes)
                end
            end
        end
    end
end

function TitanManager:StartLoop()
    -- Watch for new titans
    local function Watch(container)
        local c = container.ChildAdded:Connect(function(child)
            task.wait(0.5) -- Wait for parts to load
            TitanManager:Refresh()
        end)
        table.insert(self.Connections, c)
    end
    
    if Workspace:FindFirstChild("OnGameTitans") then
        Watch(Workspace.OnGameTitans)
    end
    
    local c2 = Workspace.ChildAdded:Connect(function(child)
        if child.Name == "OnGameTitans" then
            Watch(child)
        end
    end)
    table.insert(self.Connections, c2)
    
    -- Auto refresh loop
    task.spawn(function()
        while true do
            task.wait(2)
            TitanManager:Refresh()
        end
    end)
end

-- ============================================================================
-- 4. INTERFACE (Starlight)
-- ============================================================================
function Interface:Load()
    local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
    local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()

    local Window = Starlight:CreateWindow({
        Name = "Levi Hub",
        Subtitle = "v0.0.01",
        Icon = NebulaIcons:GetIcon('feather', 'Lucide'),
        LoadingSettings = {
            Title = "Levi Hub",
            Subtitle = "Loading...",
        },
        FileSettings = {
            ConfigFolder = "LeviHub"
        },
    })

    local MainSection = Window:CreateTabSection("Main")

    -- 1. General Tab
    local GeneralTab = MainSection:CreateTab({
        Name = "General",
        Icon = NebulaIcons:GetIcon('home', 'Material'),
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
    -- Placeholders
    HumanTab:CreateGroupbox({Name = "Movement", Column = 1}, "MoveGroup"):CreateLabel({Name = "Coming Soon"}, "CS1")

    -- 3. Titan Tab (Features)
    local TitanTab = MainSection:CreateTab({
        Name = "Titans",
        Icon = NebulaIcons:GetIcon('crosshair', 'Material'), 
        Columns = 2
    }, "TitanTab")

    -- Nape Group
    local NapeGroup = TitanTab:CreateGroupbox({ Name = "Nape Hitbox", Column = 1 }, "NapeGroup")
    
    NapeGroup:CreateToggle({
        Name = "Enable Nape Expander",
        CurrentValue = false,
        Callback = function(v)
            Config.NapeEnabled = v
            TitanManager:Refresh()
        end
    }, "NapeToggle")
    
    NapeGroup:CreateSlider({
        Name = "Scale",
        Range = {1, 20},
        Increment = 0.5,
        CurrentValue = 5,
        Callback = function(v)
            Config.NapeScale = v
            TitanManager:Refresh()
        end
    }, "NapeScale")
    
    NapeGroup:CreateSlider({
        Name = "Transparency",
        Range = {0, 1},
        Increment = 0.1,
        CurrentValue = 0.5,
        Callback = function(v)
            Config.NapeTransparency = v
            TitanManager:Refresh()
        end
    }, "NapeTrans")
    
    NapeGroup:CreateLabel({Name = "Color"}):AddColorPicker({
        CurrentValue = Color3.fromRGB(255, 0, 0),
        Callback = function(v)
            Config.NapeColor = v
            TitanManager:Refresh()
        end
    }, "NapeColor")

    -- Eyes Group
    local EyesGroup = TitanTab:CreateGroupbox({ Name = "Eyes Hitbox", Column = 2 }, "EyesGroup")
    
    EyesGroup:CreateToggle({
        Name = "Enable Eyes Expander",
        CurrentValue = false,
        Callback = function(v)
            Config.EyesEnabled = v
            TitanManager:Refresh()
        end
    }, "EyesToggle")
    
    EyesGroup:CreateSlider({
        Name = "Scale",
        Range = {1, 20},
        Increment = 0.5,
        CurrentValue = 3,
        Callback = function(v)
            Config.EyesScale = v
            TitanManager:Refresh()
        end
    }, "EyesScale")
    
    EyesGroup:CreateSlider({
        Name = "Transparency",
        Range = {0, 1},
        Increment = 0.1,
        CurrentValue = 0.5,
        Callback = function(v)
            Config.EyesTransparency = v
            TitanManager:Refresh()
        end
    }, "EyesTrans")
    
    EyesGroup:CreateLabel({Name = "Color"}):AddColorPicker({
        CurrentValue = Color3.fromRGB(0, 255, 0),
        Callback = function(v)
            Config.EyesColor = v
            TitanManager:Refresh()
        end
    }, "EyesColor")
    
    -- Material (Shared)
    local MiscGroup = TitanTab:CreateGroupbox({ Name = "Shared Settings", Column = 1 }, "MiscGroup")
    MiscGroup:CreateLabel({Name = "Material"}):AddDropdown({
        Options = {"ForceField", "Neon", "Plastic", "Glass"},
        CurrentOptions = {"ForceField"},
        Callback = function(v)
            if type(v) == "table" then v = v[1] end
            Config.HitboxMaterial = v
            TitanManager:Refresh()
        end
    }, "MatDrop")

    -- 4. Shifter Tab
    local ShifterTab = MainSection:CreateTab({
        Name = "Shifters",
        Icon = NebulaIcons:GetIcon('flash_on', 'Material'),
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
    
    -- Auto Load
    Starlight:LoadAutoloadConfig()
end

-- ============================================================================
-- 5. MAIN EXECUTION
-- ============================================================================
SpoofEngine:Setup()
TitanManager:StartLoop()
Interface:Load()
print("[Levi Hub] v0.0.01 Loaded")
