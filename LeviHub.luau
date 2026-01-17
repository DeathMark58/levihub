--[[
    LEVI HUB - Monolithic Edition (Reverted)
    Attack on Titan: Freedom War
]]

-- ============================================
-- CONFIGURATION
-- ============================================
local LOBBY_PLACE_ID = 11534222714
local CURRENT_PLACE_ID = game.PlaceId
local IS_LOBBY = (CURRENT_PLACE_ID == LOBBY_PLACE_ID)

getgenv().AOT_CONFIG = {
    PureTitanEnabled = false,
    NapeEnabled = false,
    NapeScaleX = 2.5,
    NapeScaleY = 2.5,
    NapeScaleZ = 2.5,
    NapeColor = Color3.fromRGB(255, 0, 0),
    NapeTransparency = 0,
    NapeMaterial = "ForceField",
    EyesEnabled = false,
    EyesScaleX = 2.0,
    EyesScaleY = 2.0,
    EyesScaleZ = 2.0,
    EyesColor = Color3.fromRGB(0, 255, 0),
    EyesTransparency = 0,
    EyesMaterial = "ForceField",
    DebugMode = false,
    AutoRefresh = true,
}

local MATERIAL_OPTIONS = {
    "ForceField", "Neon", "Glass", "SmoothPlastic", "Plastic", "Brick", "Metal"
}

-- ============================================
-- SERVICES & VARIABLES
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- SPOOF ENGINE
-- ============================================
local SpoofEngine = {}
SpoofEngine.SpoofedParts = {}
SpoofEngine.ProcessedParts = {}
SpoofEngine.HookedTitans = {}
SpoofEngine.Connections = {}
SpoofEngine.OldIndex = nil

function SpoofEngine:Apply(part, properties, category)
    if not part or not part:IsA("BasePart") then return false end
    if self.ProcessedParts[part] then return false end
    
    local originalData = {
        Size = part.Size,
        Transparency = part.Transparency,
        Color = part.Color,
        BrickColor = part.BrickColor,
        Material = part.Material,
        Category = category
    }
    
    self.SpoofedParts[part] = originalData
    self.ProcessedParts[part] = true
    
    if properties.Size then part.Size = properties.Size end
    if properties.Transparency then part.Transparency = properties.Transparency end
    if properties.Color then part.Color = properties.Color end
    if properties.Material then part.Material = properties.Material end
    
    return true
end

function SpoofEngine:Restore(part)
    local data = self.SpoofedParts[part]
    if not data then return false end
    
    if part and part.Parent then
        pcall(function()
            part.Size = data.Size
            part.Transparency = data.Transparency
            part.Color = data.Color
            part.Material = data.Material
        end)
    end
    
    self.SpoofedParts[part] = nil
    self.ProcessedParts[part] = nil
    return true
end

function SpoofEngine:RestoreCategory(category)
    local restored = 0
    for part, data in pairs(self.SpoofedParts) do
        if data.Category == category then
            if self:Restore(part) then restored = restored + 1 end
        end
    end
    return restored
end

function SpoofEngine:UpdateCategory(category, properties)
    local updated = 0
    for part, data in pairs(self.SpoofedParts) do
        if data.Category == category and part and part.Parent then
            pcall(function()
                if properties.Scale then
                    local origSize = data.Size
                    part.Size = Vector3.new(origSize.X * properties.Scale.X, origSize.Y * properties.Scale.Y, origSize.Z * properties.Scale.Z)
                end
                if properties.Transparency then part.Transparency = properties.Transparency end
                if properties.Color then part.Color = properties.Color end
                if properties.Material then part.Material = properties.Material end
                updated = updated + 1
            end)
        end
    end
    return updated
end

function SpoofEngine:SetupHooks()
    if IS_LOBBY then return end
    if self.OldIndex then return end
    
    self.OldIndex = hookmetamethod(game, "__index", newcclosure(function(self_ref, key)
        local spoofData = SpoofEngine.SpoofedParts[self_ref]
        if spoofData then
            local success, result = pcall(function()
                if key == "Size" and spoofData.Size then return spoofData.Size
                elseif key == "Transparency" and spoofData.Transparency then return spoofData.Transparency
                elseif key == "Color" and spoofData.Color then return spoofData.Color
                elseif key == "BrickColor" and spoofData.BrickColor then return spoofData.BrickColor
                elseif key == "Material" and spoofData.Material then return spoofData.Material
                end
                return nil
            end)
            if success and result ~= nil then return result end
        end
        return SpoofEngine.OldIndex(self_ref, key)
    end))
    print("[Levi Hub] Metatable hooks installed")
end

function SpoofEngine:GetStats()
    local napeCount, eyesCount, titanCount = 0, 0, 0
    for _, data in pairs(self.SpoofedParts) do
        if data.Category == "PureTitan_Nape" then napeCount = napeCount + 1
        elseif data.Category == "PureTitan_Eyes" then eyesCount = eyesCount + 1 end
    end
    for _ in pairs(self.HookedTitans) do titanCount = titanCount + 1 end
    return { Titans = titanCount, NapeParts = napeCount, EyesParts = eyesCount }
end

function SpoofEngine:Cleanup()
    for _, conn in ipairs(self.Connections) do if conn.Connected then conn:Disconnect() end end
    self.Connections = {}
    for part, data in pairs(self.SpoofedParts) do
        if part and part.Parent then
            pcall(function()
                part.Size = data.Size
                part.Transparency = data.Transparency
                part.Color = data.Color
                part.Material = data.Material
            end)
        end
    end
    self.SpoofedParts = {}
    self.ProcessedParts = {}
    self.HookedTitans = {}
end

-- ============================================
-- TITAN MANAGER
-- ============================================

local function GetMaterialEnum(materialName)
    local materials = { ForceField = Enum.Material.ForceField, Neon = Enum.Material.Neon, Glass = Enum.Material.Glass, SmoothPlastic = Enum.Material.SmoothPlastic, Plastic = Enum.Material.Plastic, Brick = Enum.Material.Brick, Metal = Enum.Material.Metal }
    return materials[materialName] or Enum.Material.ForceField
end

local function ProcessHitbox(part, hitboxType)
    if not part or not part:IsA("BasePart") then return false end
    local config = getgenv().AOT_CONFIG
    local category = "PureTitan_" .. hitboxType
    local scaleX, scaleY, scaleZ, color, list_transparency, material
    
    if hitboxType == "Nape" then
        if not config.NapeEnabled then return false end
        scaleX, scaleY, scaleZ = config.NapeScaleX, config.NapeScaleY, config.NapeScaleZ
        color = config.NapeColor
        list_transparency = config.NapeTransparency
        material = GetMaterialEnum(config.NapeMaterial)
    else
        if not config.EyesEnabled then return false end
        scaleX, scaleY, scaleZ = config.EyesScaleX, config.EyesScaleY, config.EyesScaleZ
        color = config.EyesColor
        list_transparency = config.EyesTransparency
        material = GetMaterialEnum(config.EyesMaterial)
    end
    
    local newSize = Vector3.new(part.Size.X * scaleX, part.Size.Y * scaleY, part.Size.Z * scaleZ)
    return SpoofEngine:Apply(part, { Size = newSize, Transparency = list_transparency, Color = color, Material = material }, category)
end

local function FindHitboxWithRetry(titanModel, hitboxName, maxAttempts)
    maxAttempts = maxAttempts or 5
    for attempt = 1, maxAttempts do
        for _, child in ipairs(titanModel:GetDescendants()) do
            if child:IsA("BasePart") and child.Name == hitboxName then return child end
        end
        if attempt < maxAttempts then task.wait(0.3) end
    end
    return nil
end

local function ProcessTitan(titanModel)
    if SpoofEngine.HookedTitans[titanModel] then return 0 end
    SpoofEngine.HookedTitans[titanModel] = true
    if not getgenv().AOT_CONFIG.PureTitanEnabled then return 0 end
    
    local totalParts = 0
    if getgenv().AOT_CONFIG.NapeEnabled then
        local nape = FindHitboxWithRetry(titanModel, "Nape", 5)
        if nape and ProcessHitbox(nape, "Nape") then totalParts = totalParts + 1 end
    end
    if getgenv().AOT_CONFIG.EyesEnabled then
        local eyes = FindHitboxWithRetry(titanModel, "Eyes", 5)
        if eyes and ProcessHitbox(eyes, "Eyes") then totalParts = totalParts + 1 end
    end
    return totalParts
end

local function ScanAllTitans()
    if IS_LOBBY then return 0, 0 end
    local totalTitans, totalParts = 0, 0
    local titanContainer = workspace:FindFirstChild("OnGameTitans")
    if titanContainer then
        for _, titan in ipairs(titanContainer:GetChildren()) do
            if titan:IsA("Model") and not SpoofEngine.HookedTitans[titan] then
                local parts = ProcessTitan(titan)
                if parts > 0 then totalTitans = totalTitans + 1; totalParts = totalParts + parts end
            end
        end
    end
    return totalTitans, totalParts
end

local function SetupTitanWatcher()
    if IS_LOBBY then return end
    
    local function WatchContainer(container)
        local conn = container.ChildAdded:Connect(function(child)
            if child:IsA("Model") then task.wait(0.5); ProcessTitan(child) end
        end)
        table.insert(SpoofEngine.Connections, conn)
    end
    
    local titanContainer = workspace:FindFirstChild("OnGameTitans")
    if titanContainer then WatchContainer(titanContainer) end
    
    local conn2 = workspace.ChildAdded:Connect(function(child)
        if child.Name == "OnGameTitans" then
            task.wait(0.5)
            ScanAllTitans()
            WatchContainer(child)
        end
    end)
    table.insert(SpoofEngine.Connections, conn2)
end

local function RefreshAllHitboxes()
    local config = getgenv().AOT_CONFIG
    SpoofEngine:UpdateCategory("PureTitan_Nape", { Scale = Vector3.new(config.NapeScaleX, config.NapeScaleY, config.NapeScaleZ), Transparency = config.NapeTransparency, Color = config.NapeColor, Material = GetMaterialEnum(config.NapeMaterial) })
    SpoofEngine:UpdateCategory("PureTitan_Eyes", { Scale = Vector3.new(config.EyesScaleX, config.EyesScaleY, config.EyesScaleZ), Transparency = config.EyesTransparency, Color = config.EyesColor, Material = GetMaterialEnum(config.EyesMaterial) })
end

local function RescanAllTitans()
    SpoofEngine.HookedTitans = {}
    SpoofEngine.ProcessedParts = {}
    for part, data in pairs(SpoofEngine.SpoofedParts) do
        if part and part.Parent then
            pcall(function() part.Size = data.Size; part.Transparency = data.Transparency; part.Color = data.Color; part.Material = data.Material end)
        end
    end
    SpoofEngine.SpoofedParts = {}
    return ScanAllTitans()
end

-- ============================================
-- UI SETUP
-- ============================================

local Starlight = nil
local NebulaIcons = nil

local function SetupUI()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
    end)
    if not success then warn("Failed to load Starlight"); return end
    Starlight = result
    pcall(function() NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))() end)

    local Window = Starlight:CreateWindow({
        Name = "Levi Hub",
        Subtitle = IS_LOBBY and "Lobby Mode" or "Monolithic Edition",
        Icon = NebulaIcons and NebulaIcons:GetIcon('feather', 'Lucide') or 6031302931,
        LoadingSettings = { Title = "Levi Hub", Subtitle = "Loading..." },
        FileSettings = { ConfigFolder = "LeviHub" },
    })
    
    if IS_LOBBY then
        local MainSection = Window:CreateTabSection("Main")
        local LobbyTab = MainSection:CreateTab({ Name = "Lobby", Columns = 1 })
        local InfoBox = LobbyTab:CreateGroupbox({ Name = "Waiting", Column = 1 })
        InfoBox:CreateParagraph({ Name = "Status", Content = "You are in the lobby.\nFeature activation waiting for game join." })
        Starlight:Notification({ Title = "Levi Hub", Content = "Lobby Mode Active", Duration = 3 })
    else
        local MainSection = Window:CreateTabSection("Main")
        
        -- Titans Tab
        local TitansTab = MainSection:CreateTab({ Name = "Titans", Icon = NebulaIcons and NebulaIcons:GetIcon('crosshair', 'Lucide') })
        
        local MasterBox = TitansTab:CreateGroupbox({ Name = "Pure Titans", Column = 1 })
        MasterBox:CreateToggle({
            Name = "Pure Titan Hitbox Changer",
            CurrentValue = false,
            Callback = function(value)
                getgenv().AOT_CONFIG.PureTitanEnabled = value
                if value then RescanAllTitans()
                else SpoofEngine:RestoreCategory("PureTitan_Nape"); SpoofEngine:RestoreCategory("PureTitan_Eyes") end
            end
        })
        
        local NapeBox = TitansTab:CreateGroupbox({ Name = "Nape Hitbox", Column = 1 })
        NapeBox:CreateToggle({
            Name = "Enable Nape Hitbox",
            CurrentValue = false,
            Callback = function(value)
                getgenv().AOT_CONFIG.NapeEnabled = value
                if getgenv().AOT_CONFIG.PureTitanEnabled then
                    if value then RescanAllTitans() else SpoofEngine:RestoreCategory("PureTitan_Nape") end
                end
            end
        })
        NapeBox:CreateSlider({ Name = "Scale X", Range = {1, 6}, Increment = 0.25, CurrentValue = 2.5, Callback = function(v) getgenv().AOT_CONFIG.NapeScaleX = v; RefreshAllHitboxes() end })
        NapeBox:CreateSlider({ Name = "Scale Y", Range = {1, 6}, Increment = 0.25, CurrentValue = 2.5, Callback = function(v) getgenv().AOT_CONFIG.NapeScaleY = v; RefreshAllHitboxes() end })
        NapeBox:CreateSlider({ Name = "Scale Z", Range = {1, 6}, Increment = 0.25, CurrentValue = 2.5, Callback = function(v) getgenv().AOT_CONFIG.NapeScaleZ = v; RefreshAllHitboxes() end })
        NapeBox:CreateLabel({Name="Color"}):AddColorPicker({ CurrentValue = Color3.fromRGB(255,0,0), Callback = function(c) getgenv().AOT_CONFIG.NapeColor = c; RefreshAllHitboxes() end })
        NapeBox:CreateSlider({ Name = "Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0, Callback = function(v) getgenv().AOT_CONFIG.NapeTransparency = v; RefreshAllHitboxes() end })
        
        local EyesBox = TitansTab:CreateGroupbox({ Name = "Eyes Hitbox", Column = 2 })
        EyesBox:CreateToggle({
            Name = "Enable Eyes Hitbox",
            CurrentValue = false,
            Callback = function(value)
                getgenv().AOT_CONFIG.EyesEnabled = value
                if getgenv().AOT_CONFIG.PureTitanEnabled then
                    if value then RescanAllTitans() else SpoofEngine:RestoreCategory("PureTitan_Eyes") end
                end
            end
        })
        EyesBox:CreateSlider({ Name = "Scale X", Range = {1, 6}, Increment = 0.25, CurrentValue = 2, Callback = function(v) getgenv().AOT_CONFIG.EyesScaleX = v; RefreshAllHitboxes() end })
        EyesBox:CreateSlider({ Name = "Scale Y", Range = {1, 6}, Increment = 0.25, CurrentValue = 2, Callback = function(v) getgenv().AOT_CONFIG.EyesScaleY = v; RefreshAllHitboxes() end })
        EyesBox:CreateSlider({ Name = "Scale Z", Range = {1, 6}, Increment = 0.25, CurrentValue = 2, Callback = function(v) getgenv().AOT_CONFIG.EyesScaleZ = v; RefreshAllHitboxes() end })
        EyesBox:CreateLabel({Name="Color"}):AddColorPicker({ CurrentValue = Color3.fromRGB(0,255,0), Callback = function(c) getgenv().AOT_CONFIG.EyesColor = c; RefreshAllHitboxes() end })
        EyesBox:CreateSlider({ Name = "Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0, Callback = function(v) getgenv().AOT_CONFIG.EyesTransparency = v; RefreshAllHitboxes() end })
        
        local SettingsTab = MainSection:CreateTab({ Name = "Settings", Icon = NebulaIcons and NebulaIcons:GetIcon('settings', 'Lucide') })
        local OptionsBox = SettingsTab:CreateGroupbox({ Name = "Options", Column = 1 })
        OptionsBox:CreateToggle({ Name = "Auto Refresh", CurrentValue = true, Callback = function(v) getgenv().AOT_CONFIG.AutoRefresh = v end })
        OptionsBox:CreateToggle({ Name = "Debug Mode", CurrentValue = false, Callback = function(v) getgenv().AOT_CONFIG.DebugMode = v end })
        OptionsBox:CreateButton({ Name = "Force Scan", Callback = function() local t,p = ScanAllTitans(); Starlight:Notification({Title="Scan", Content=t.." titans", Duration=3}) end })
        OptionsBox:CreateButton({ Name = "Show Stats", Callback = function() local s = SpoofEngine:GetStats(); Starlight:Notification({Title="Stats", Content="Nape: "..s.NapeParts.." | Eyes: "..s.EyesParts, Duration=3}) end })
    end
    
    Starlight:LoadAutoloadConfig()
    Starlight:OnDestroy(function()
        SpoofEngine:Cleanup()
        getgenv().AOT = nil
        getgenv().AOT_CONFIG = nil
    end)
end

-- ============================================
-- INITIALIZE
-- ============================================
print("╔═══════════════════════════════════════╗")
print("║          LEVI HUB - Loaded            ║")
print("╚═══════════════════════════════════════╝")

if not IS_LOBBY then
    SpoofEngine:SetupHooks()
     task.spawn(function()
         task.wait(1)
         ScanAllTitans()
         SetupTitanWatcher()
     end)
end

SetupUI()
print("[Levi Hub] Ready!")