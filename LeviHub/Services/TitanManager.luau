local TitanManager = {}
local SpoofEngine
local Config
local GlobalConfig -- Reference to getgenv().AOT_CONFIG

function TitanManager:Initialize(spoofEngine, configModule)
    SpoofEngine = spoofEngine
    Config = configModule
    GlobalConfig = getgenv().AOT_CONFIG
end

local function GetMaterialEnum(materialName)
    local materials = {
        ForceField = Enum.Material.ForceField,
        Neon = Enum.Material.Neon,
        Glass = Enum.Material.Glass,
        SmoothPlastic = Enum.Material.SmoothPlastic,
        Plastic = Enum.Material.Plastic,
        Brick = Enum.Material.Brick,
        Metal = Enum.Material.Metal,
    }
    return materials[materialName] or Enum.Material.ForceField
end

local function ProcessHitbox(part, hitboxType)
    if not part or not part:IsA("BasePart") then return false end
    
    local config = GlobalConfig
    local category = "PureTitan_" .. hitboxType
    
    local scaleX, scaleY, scaleZ, color, transparency, material
    
    if hitboxType == "Nape" then
        if not config.NapeEnabled then return false end
        scaleX = config.NapeScaleX
        scaleY = config.NapeScaleY
        scaleZ = config.NapeScaleZ
        color = config.NapeColor
        transparency = config.NapeTransparency
        material = GetMaterialEnum(config.NapeMaterial)
    else -- Eyes
        if not config.EyesEnabled then return false end
        scaleX = config.EyesScaleX
        scaleY = config.EyesScaleY
        scaleZ = config.EyesScaleZ
        color = config.EyesColor
        transparency = config.EyesTransparency
        material = GetMaterialEnum(config.EyesMaterial)
    end
    
    local newSize = Vector3.new(
        part.Size.X * scaleX,
        part.Size.Y * scaleY,
        part.Size.Z * scaleZ
    )
    
    return SpoofEngine:Apply(part, {
        Size = newSize,
        Transparency = transparency,
        Color = color,
        Material = material
    }, category)
end

local function FindHitboxWithRetry(titanModel, hitboxName, maxAttempts)
    maxAttempts = maxAttempts or 5
    for attempt = 1, maxAttempts do
        for _, child in ipairs(titanModel:GetDescendants()) do
            if child:IsA("BasePart") and child.Name == hitboxName then
                return child
            end
        end
        if attempt < maxAttempts then task.wait(0.3) end
    end
    return nil
end

local function ProcessTitan(titanModel)
    if SpoofEngine.HookedTitans[titanModel] then return 0 end
    SpoofEngine.HookedTitans[titanModel] = true
    
    local config = GlobalConfig
    if not config.PureTitanEnabled then return 0 end
    
    local totalParts = 0
    
    -- Nape
    if config.NapeEnabled then
        local nape = FindHitboxWithRetry(titanModel, "Nape", 5)
        if nape and ProcessHitbox(nape, "Nape") then
            totalParts = totalParts + 1
        end
    end
    
    -- Eyes
    if config.EyesEnabled then
        local eyes = FindHitboxWithRetry(titanModel, "Eyes", 5)
        if eyes and ProcessHitbox(eyes, "Eyes") then
            totalParts = totalParts + 1
        end
    end
    
    return totalParts
end

function TitanManager:ScanAllTitans()
    if Config.IS_LOBBY then return 0, 0 end
    
    local totalTitans = 0
    local totalParts = 0
    
    local titanContainer = workspace:FindFirstChild("OnGameTitans")
    if titanContainer then
        for _, titan in ipairs(titanContainer:GetChildren()) do
            if titan:IsA("Model") and not SpoofEngine.HookedTitans[titan] then
                local parts = ProcessTitan(titan)
                if parts > 0 then
                    totalTitans = totalTitans + 1
                    totalParts = totalParts + parts
                end
            end
        end
    end
    
    return totalTitans, totalParts
end

function TitanManager:SetupWatcher()
    if Config.IS_LOBBY then return end
    
    local function WatchContainer(container)
        local conn = container.ChildAdded:Connect(function(child)
            if child:IsA("Model") then
                task.wait(0.5)
                ProcessTitan(child)
            end
        end)
        table.insert(SpoofEngine.Connections, conn)
    end
    
    local titanContainer = workspace:FindFirstChild("OnGameTitans")
    if titanContainer then
        WatchContainer(titanContainer)
    end
    
    local conn2 = workspace.ChildAdded:Connect(function(child)
        if child.Name == "OnGameTitans" then
            task.wait(0.5)
            self:ScanAllTitans()
            WatchContainer(child)
        end
    end)
    table.insert(SpoofEngine.Connections, conn2)
end

function TitanManager:RefreshAllHitboxes()
    local config = GlobalConfig
    
    SpoofEngine:UpdateCategory("PureTitan_Nape", {
        Scale = Vector3.new(config.NapeScaleX, config.NapeScaleY, config.NapeScaleZ),
        Transparency = config.NapeTransparency,
        Color = config.NapeColor,
        Material = GetMaterialEnum(config.NapeMaterial)
    })
    
    SpoofEngine:UpdateCategory("PureTitan_Eyes", {
        Scale = Vector3.new(config.EyesScaleX, config.EyesScaleY, config.EyesScaleZ),
        Transparency = config.EyesTransparency,
        Color = config.EyesColor,
        Material = GetMaterialEnum(config.EyesMaterial)
    })
end

function TitanManager:RescanAllTitans()
    -- Reset state
    SpoofEngine.HookedTitans = {}
    SpoofEngine.ProcessedParts = {}
    
    -- Restore all first
    for part, data in pairs(SpoofEngine.SpoofedParts) do
        if part and part.Parent then
            pcall(function()
                part.Size = data.Size
                part.Transparency = data.Transparency
                part.Color = data.Color
                part.Material = data.Material
            end)
        end
    end
    SpoofEngine.SpoofedParts = {}
    
    return self:ScanAllTitans()
end

return TitanManager
