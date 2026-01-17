--[[
    LEVI HUB - Premium Loader
    Version: v0.0.01
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local LOBBY_PLACE_ID = 11534222714
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/DeathMark58/levihub/main/LeviHub.luau"
local LOADER_URL = "https://raw.githubusercontent.com/DeathMark58/levihub/main/Loader.luau" 

-- ============================================================================
-- UI LIBRARY (Miniature)
-- ============================================================================
local function CreateUI()
    local parent = gethui and gethui() or CoreGui
    
    -- Cleanup Old
    for _, c in ipairs(parent:GetChildren()) do
        if c.Name == "LeviHub_Loader" then c:Destroy() end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LeviHub_Loader"
    ScreenGui.DisplayOrder = 10000
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = parent

    -- Main Container
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 350, 0, 180)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MainFrame.BorderSizePixel = 0
    MainFrame.BackgroundTransparency = 1 
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(40, 40, 40)
    UIStroke.Thickness = 1
    UIStroke.Transparency = 1
    UIStroke.Parent = MainFrame

    -- Inner Content Holder (For easy fading)
    local ContentHolder = Instance.new("Frame")
    ContentHolder.Size = UDim2.new(1, 0, 1, 0)
    ContentHolder.BackgroundTransparency = 1
    ContentHolder.Parent = MainFrame

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 20)
    Title.BackgroundTransparency = 1
    Title.Text = "LEVI HUB"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 24
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextTransparency = 1
    Title.Parent = ContentHolder

    local SubTitle = Instance.new("TextLabel")
    SubTitle.Size = UDim2.new(1, 0, 0, 20)
    SubTitle.Position = UDim2.new(0, 0, 0, 50)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = "Attack on Titan: Freedom War"
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.TextSize = 14
    SubTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
    SubTitle.TextTransparency = 1
    SubTitle.Parent = ContentHolder

    -- Progress Bar
    local BarBG = Instance.new("Frame")
    BarBG.Size = UDim2.new(0, 250, 0, 4)
    BarBG.Position = UDim2.new(0.5, 0, 0, 100)
    BarBG.AnchorPoint = Vector2.new(0.5, 0)
    BarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    BarBG.BorderSizePixel = 0
    BarBG.BackgroundTransparency = 1
    BarBG.Parent = ContentHolder

    Instance.new("UICorner", BarBG).CornerRadius = UDim.new(1, 0)

    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(200, 50, 50) 
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBG

    Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

    -- Status Text
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, 0, 0, 20)
    Status.Position = UDim2.new(0, 0, 0, 115)
    Status.BackgroundTransparency = 1
    Status.Text = "Initializing..."
    Status.Font = Enum.Font.GothamMedium
    Status.TextSize = 12
    Status.TextColor3 = Color3.fromRGB(100, 100, 100)
    Status.TextTransparency = 1
    Status.Parent = ContentHolder

    -- Watermark Text (Initially Hidden)
    local Watermark = Instance.new("TextLabel")
    Watermark.Size = UDim2.new(1, 0, 1, 0)
    Watermark.BackgroundTransparency = 1
    Watermark.Text = "🛡️ Levi Hub Ready"
    Watermark.Font = Enum.Font.GothamBold
    Watermark.TextSize = 14
    Watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
    Watermark.TextTransparency = 1
    Watermark.Visible = false
    Watermark.Parent = MainFrame

    -- Animations
    local function FadeIn()
        local Ti = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(MainFrame, Ti, {BackgroundTransparency = 0.05}):Play()
        TweenService:Create(UIStroke, Ti, {Transparency = 0}):Play()
        task.wait(0.2)
        TweenService:Create(Title, Ti, {TextTransparency = 0}):Play()
        TweenService:Create(SubTitle, Ti, {TextTransparency = 0}):Play()
        task.wait(0.1)
        TweenService:Create(BarBG, Ti, {BackgroundTransparency = 0}):Play()
        TweenService:Create(Status, Ti, {TextTransparency = 0}):Play()
    end

    local function SetProgress(pct, text)
        local Ti = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(BarFill, Ti, {Size = UDim2.new(pct, 0, 1, 0)}):Play()
        Status.Text = text
    end

    local function Finish()
        local Ti = TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        local FastTi = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        -- 1. Fade OUT Content
        for _, v in ipairs(ContentHolder:GetDescendants()) do
            if v:IsA("GuiObject") then
                if v:IsA("TextLabel") then
                    TweenService:Create(v, FastTi, {TextTransparency = 1}):Play()
                else
                    TweenService:Create(v, FastTi, {Transparency = 1}):Play()
                end
            end
        end
        
        task.wait(0.3)
        ContentHolder.Visible = false
        Watermark.Visible = true

        -- 2. Shrink and Move to Top Right
        -- Target: Small pill in top right
        local TargetSize = UDim2.new(0, 160, 0, 36)
        local TargetPos = UDim2.new(1, -100, 0, 50) -- Approx position to be safe from playerlist
        
        -- We keep anchor point 0.5, 0.5 so we target the center point
        TweenService:Create(MainFrame, Ti, {
            Size = TargetSize,
            Position = TargetPos,
            BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        }):Play()
        
        task.wait(0.6)
        
        -- 3. Show Watermark
        TweenService:Create(Watermark, FastTi, {TextTransparency = 0}):Play()
        
        -- 4. Final Cleanup (Optional: Remove after 5 seconds)
        task.delay(5, function()
            TweenService:Create(MainFrame, Ti, {BackgroundTransparency = 1}):Play()
            TweenService:Create(UIStroke, Ti, {Transparency = 1}):Play()
            TweenService:Create(Watermark, Ti, {TextTransparency = 1}):Play()
            task.wait(1)
            ScreenGui:Destroy()
        end)
    end

    return {
        FadeIn = FadeIn,
        SetProgress = SetProgress,
        Finish = Finish
    }
end

-- ============================================================================
-- LOGIC
-- ============================================================================

local function LoadScript()
    local success, err = pcall(function()
        loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
    end)
    if not success then
        warn("[LeviHub] Failed to load main script:", err)
    end
end

if game.PlaceId == LOBBY_PLACE_ID then
    -- LOBBY MODE
    local UI = CreateUI()
    UI.FadeIn()
    task.wait(1)
    
    UI.SetProgress(0.3, "Checking Queue Service...")
    task.wait(0.5)

    if queue_on_teleport then
        UI.SetProgress(0.6, "Hooking Teleport...")
        
        -- Queue the LOADER again so it runs in the next game
        queue_on_teleport([[
            task.wait(3) -- Wait for game to load
            loadstring(game:HttpGet("]] .. LOADER_URL .. [["))()
        ]])
        
        UI.SetProgress(1, "Ready! Waiting for game join...")
        task.wait(2)
        UI.Finish() -- Shrink to watermark
    else
        UI.SetProgress(0, "Error: executor missing queue_on_teleport")
        task.wait(3)
        -- Just fade out normally if error
        UI.Finish()
    end
else
    -- GAME MODE - Just load
    local UI = CreateUI()
    UI.FadeIn() 
    UI.SetProgress(0.5, "Loading Levi Hub...")
    task.wait(0.5)
    
    LoadScript()
    
    UI.SetProgress(1, "Loaded!")
    task.wait(1)
    UI.Finish() -- Shrink to watermark
end
