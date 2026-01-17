local Config = {}

Config.LOBBY_PLACE_ID = 11534222714
Config.CURRENT_PLACE_ID = game.PlaceId
Config.IS_LOBBY = (Config.CURRENT_PLACE_ID == Config.LOBBY_PLACE_ID)

-- Default configuration
Config.DefaultConfig = {
    -- Master Toggle
    PureTitanEnabled = false,
    
    -- Nape settings
    NapeEnabled = false,
    NapeScaleX = 2.5,
    NapeScaleY = 2.5,
    NapeScaleZ = 2.5,
    NapeColor = Color3.fromRGB(255, 0, 0),
    NapeTransparency = 0,
    NapeMaterial = "ForceField",
    
    -- Eyes settings
    EyesEnabled = false,
    EyesScaleX = 2.0,
    EyesScaleY = 2.0,
    EyesScaleZ = 2.0,
    EyesColor = Color3.fromRGB(0, 255, 0),
    EyesTransparency = 0,
    EyesMaterial = "ForceField",
    
    -- General
    DebugMode = false,
    AutoRefresh = true,
}

Config.MATERIAL_OPTIONS = {
    "ForceField", "Neon", "Glass", "SmoothPlastic", "Plastic", "Brick", "Metal"
}

return Config
