local SpoofEngine = {}
SpoofEngine.SpoofedParts = {}   -- {[Instance] = {Size, Transparency, Color, Material, BrickColor, Category}}
SpoofEngine.ProcessedParts = {} -- Track processed parts to avoid duplicates
SpoofEngine.HookedTitans = {}   -- Track processed titans
SpoofEngine.Connections = {}    -- Store all connections for cleanup
SpoofEngine.OldIndex = nil      -- Store original __index

-- Dependencies (injected or assumed global config for now)
local Config = nil

function SpoofEngine:Initialize(configModule)
    Config = configModule
end

-- Apply spoof to a part
function SpoofEngine:Apply(part, properties, category)
    if not part or not part:IsA("BasePart") then return false end
    if self.ProcessedParts[part] then return false end
    
    -- Store ALL original values
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
    
    -- Apply modifications
    if properties.Size then part.Size = properties.Size end
    if properties.Transparency then part.Transparency = properties.Transparency end
    if properties.Color then part.Color = properties.Color end
    if properties.Material then part.Material = properties.Material end
    
    if Config and Config.DefaultConfig.DebugMode then
        print("[Levi Hub] Applied spoof: " .. part:GetFullName() .. " | Category: " .. category)
    end
    
    return true
end

-- Restore a single part to original
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

-- Restore all parts in a category
function SpoofEngine:RestoreCategory(category)
    local restored = 0
    for part, data in pairs(self.SpoofedParts) do
        if data.Category == category then
            if self:Restore(part) then
                restored = restored + 1
            end
        end
    end
    return restored
end

-- Update all parts in a category with new properties
function SpoofEngine:UpdateCategory(category, properties)
    local updated = 0
    for part, data in pairs(self.SpoofedParts) do
        if data.Category == category and part and part.Parent then
            pcall(function()
                if properties.Scale then
                    local origSize = data.Size
                    part.Size = Vector3.new(
                        origSize.X * properties.Scale.X,
                        origSize.Y * properties.Scale.Y,
                        origSize.Z * properties.Scale.Z
                    )
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

-- Setup metatable hooks (call ONCE at startup)
function SpoofEngine:SetupHooks(isLobby)
    if isLobby then return end
    if self.OldIndex then return end -- Already hooked
    
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
            if success and result ~= nil then
                return result
            end
        end
        return SpoofEngine.OldIndex(self_ref, key)
    end))
    
    print("[Levi Hub] Metatable hooks installed")
end

-- Get stats
function SpoofEngine:GetStats()
    local napeCount = 0
    local eyesCount = 0
    
    for _, data in pairs(self.SpoofedParts) do
        if data.Category == "PureTitan_Nape" then napeCount = napeCount + 1
        elseif data.Category == "PureTitan_Eyes" then eyesCount = eyesCount + 1
        end
    end
    
    local titanCount = 0
    for _ in pairs(self.HookedTitans) do titanCount = titanCount + 1 end
    
    return {
        Titans = titanCount,
        NapeParts = napeCount,
        EyesParts = eyesCount,
        TotalParts = napeCount + eyesCount
    }
end

-- Cleanup everything
function SpoofEngine:Cleanup()
    -- Disconnect all connections
    for _, conn in ipairs(self.Connections) do
        if conn.Connected then conn:Disconnect() end
    end
    self.Connections = {}
    
    -- Restore all parts
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
    
    print("[Levi Hub] Cleanup complete")
end

return SpoofEngine
