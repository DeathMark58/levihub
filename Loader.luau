--[[
    LEVI HUB - Premium Loader
    Custom Splash Screen + Watermark
]]

local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/DeathMark58/levihub/main/LeviHub.luau"
local LOBBY_PLACE_ID = 11534222714
local CURRENT_PLACE_ID = game.PlaceId

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- UI CREATION
-- ============================================
local function CreateGUI()
    -- Try to put in CoreGui or gethui() for security and rendering on top
    local parent = nil
    pcall(function()
        if gethui then
            parent = gethui()
        elseif syn and syn.protect_gui then
            local gui = Instance.new("ScreenGui")
            syn.protect_gui(gui)
            gui.Parent = CoreGui
            parent = gui.Parent -- Use the protected location
        elseif CoreGui then
            parent = CoreGui
        end
    end)
    
    if not parent then
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Cleanup existing
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == "LeviHubLoader_v4" then child:Destroy() end
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LeviHubLoader_v4"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 10000 -- Make sure it's on top
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = parent
    
    -- Function to create rounded corner
    local function AddCorner(obj, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius)
        c.Parent = obj
        return c
    end
    
    -- Function to Add Stroke
    local function AddStroke(obj, color, thickness)
        local s = Instance.new("UIStroke")
        s.Color = color
        s.Thickness = thickness
        s.Parent = obj
        return s
    end
    
    -- 1. WATERMARK (Top Right, Hidden initially or Visible)
    local Watermark = Instance.new("Frame")
    Watermark.Name = "Watermark"
    Watermark.Size = UDim2.new(0, 140, 0, 35)
    Watermark.Position = UDim2.new(1, -160, 0, 20) -- Top right
    Watermark.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Watermark.BackgroundTransparency = 0 -- Keep visible
    Watermark.Visible = false -- Show after splash
    Watermark.Parent = ScreenGui
    
    AddCorner(Watermark, 8)
    AddStroke(Watermark, Color3.fromRGB(50, 50, 60), 1)
    
    local WLogo = Instance.new("TextLabel")
    WLogo.Size = UDim2.new(0, 30, 1, 0)
    WLogo.Position = UDim2.new(0, 5, 0, 0)
    WLogo.BackgroundTransparency = 1
    WLogo.Text = "⚔️"
    WLogo.TextSize = 18
    WLogo.Parent = Watermark
    
    local WText = Instance.new("TextLabel")
    WText.Size = UDim2.new(1, -40, 1, 0)
    WText.Position = UDim2.new(0, 35, 0, 0)
    WText.BackgroundTransparency = 1
    WText.Text = "LEVI HUB"
    WText.Font = Enum.Font.GothamBold
    WText.TextSize = 14
    WText.TextColor3 = Color3.fromRGB(230, 230, 230)
    WText.TextXAlignment = Enum.TextXAlignment.Left
    WText.Parent = Watermark
    
    -- 2. SPLASH SCREEN (Center)
    local Splash = Instance.new("Frame")
    Splash.Name = "Splash"
    Splash.Size = UDim2.new(0, 400, 0, 250)
    Splash.Position = UDim2.new(0.5, -200, 0.5, -125)
    Splash.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    Splash.BorderSizePixel = 0
    Splash.Parent = ScreenGui
    
    AddCorner(Splash, 16)
    
    -- Splash Glow/Shadow
    local SplashGlow = Instance.new("ImageLabel")
    SplashGlow.Size = UDim2.new(1, 100, 1, 100)
    SplashGlow.Position = UDim2.new(0, -50, 0, -50)
    SplashGlow.BackgroundTransparency = 1
    SplashGlow.Image = "rbxassetid://5028857084" -- Soft glow
    SplashGlow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    SplashGlow.ImageTransparency = 0.4
    SplashGlow.ScaleType = Enum.ScaleType.Slice
    SplashGlow.SliceCenter = Rect.new(24, 24, 276, 276)
    SplashGlow.ZIndex = 0
    SplashGlow.Parent = Splash
    
    -- Top Bar Decoration
    local TopDeco = Instance.new("Frame")
    TopDeco.Size = UDim2.new(1, 0, 0, 2)
    TopDeco.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
    TopDeco.BorderSizePixel = 0
    TopDeco.Parent = Splash
    
    local TopGrad = Instance.new("UIGradient")
    TopGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(236, 72, 153))
    })
    TopGrad.Parent = TopDeco
    
    -- Main Icon
    local MainIcon = Instance.new("TextLabel")
    MainIcon.Size = UDim2.new(1, 0, 0, 80)
    MainIcon.Position = UDim2.new(0, 0, 0, 40)
    MainIcon.BackgroundTransparency = 1
    MainIcon.Text = "⚔️"
    MainIcon.TextSize = 64
    MainIcon.Parent = Splash
    
    -- Main Title
    local MainTitle = Instance.new("TextLabel")
    MainTitle.Size = UDim2.new(1, 0, 0, 30)
    MainTitle.Position = UDim2.new(0, 0, 0, 110)
    MainTitle.BackgroundTransparency = 1
    MainTitle.Text = "LEVI HUB"
    MainTitle.Font = Enum.Font.GothamBlack
    MainTitle.TextSize = 28
    MainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    MainTitle.Parent = Splash
    
    local SubTitle = Instance.new("TextLabel")
    SubTitle.Size = UDim2.new(1, 0, 0, 20)
    SubTitle.Position = UDim2.new(0, 0, 0, 140)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = "Made by Hak"
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.TextSize = 14
    SubTitle.TextColor3 = Color3.fromRGB(150, 150, 160)
    SubTitle.Parent = Splash
    
    -- Progress Bar
    local BarBG = Instance.new("Frame")
    BarBG.Size = UDim2.new(0, 300, 0, 4)
    BarBG.Position = UDim2.new(0.5, -150, 0, 190)
    BarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    BarBG.BorderSizePixel = 0
    BarBG.Parent = Splash
    AddCorner(BarBG, 2)
    
    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBG
    AddCorner(BarFill, 2)
    
    local BarGrad = Instance.new("UIGradient")
    BarGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(236, 72, 153))
    })
    BarGrad.Parent = BarFill
    
    -- Status Text
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, 0, 0, 20)
    StatusText.Position = UDim2.new(0, 0, 0, 205)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Initializing..."
    StatusText.Font = Enum.Font.GothamMedium
    StatusText.TextSize = 12
    StatusText.TextColor3 = Color3.fromRGB(180, 180, 190)
    StatusText.Parent = Splash
    
    -- Animation Functions
    local function SetProgress(percent, status)
        local tween = TweenService:Create(BarFill, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
            Size = UDim2.new(percent/100, 0, 1, 0)
        })
        tween:Play()
        if status then
            StatusText.Text = status
        end
        return tween
    end
    
    local function Finish()
        -- Animation: Splash shrinks and moves to top right (Watermark position)
        local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        
        -- 1. Fade out the contents of the Splash screen first
        for _, child in ipairs(Splash:GetDescendants()) do
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            elseif child:IsA("ImageLabel") or child:IsA("Frame") then
                TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 1, ImageTransparency = 1}):Play()
            end
        end
        
        task.wait(0.3) -- Wait for text to fade
        
        -- 2. Morph Splash Frame into Watermark Frame
        -- Watermark Position: UDim2.new(1, -160, 0, 20)
        -- Watermark Size: UDim2.new(0, 140, 0, 35)
        
        local morph = TweenService:Create(Splash, tweenInfo, {
            Position = UDim2.new(1, -160, 0, 20),
            Size = UDim2.new(0, 140, 0, 35),
            BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- Match Watermark color
        })
        morph:Play()
        
        -- 3. Show Watermark content interacting with the morph
        morph.Completed:Connect(function()
            Watermark.Visible = true
            Watermark.BackgroundTransparency = 1 -- Hide watermark BG, let Splash be the dummy
            Splash:Destroy() -- Or keep it, but easier to swap
             
             -- Make actual watermark visible
            Watermark.BackgroundTransparency = 0
            
            -- Animate Watermark text in
            WLogo.TextTransparency = 1
            WText.TextTransparency = 1
            TweenService:Create(WLogo, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
            TweenService:Create(WText, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
        end)
    end
    
    return {
        SetProgress = SetProgress,
        Finish = Finish
    }
end

-- ============================================
-- MAIN LOGIC
-- ============================================

local GUI = CreateGUI()

local function LoadMainScript()
    GUI.SetProgress(20, "Connecting to server...")
    task.wait(0.3)
    
    GUI.SetProgress(40, "Downloading script...")
    local success, content
    local netSuccess, netErr = pcall(function()
        content = game:HttpGet(MAIN_SCRIPT_URL)
    end)
    
    if not netSuccess then
        GUI.SetProgress(0, "Error: Download Failed!")
        warn("[Levi Hub] Download Error: " .. tostring(netErr))
        return
    end
    
    GUI.SetProgress(70, "Compiling...")
    task.wait(0.2)
    
    local func, loadErr = loadstring(content)
    if not func then
        GUI.SetProgress(0, "Error: Compile Failed!")
        warn("[Levi Hub] Compile Error: " .. tostring(loadErr))
        return
    end
    
    GUI.SetProgress(90, "Executing...")
    task.wait(0.2)
    
    local execSuccess, execErr = pcall(func)
    if not execSuccess then
        GUI.SetProgress(0, "Error: Execution Failed!")
        warn("[Levi Hub] Execution Error: " .. tostring(execErr))
        return
    end
    
    GUI.SetProgress(100, "Ready!")
    task.wait(0.5)
    GUI.Finish()
    
    -- Create Notification in Interface.luau eventually handles notifications, 
    -- but our splash screen handles the initial feel.
end

if CURRENT_PLACE_ID == LOBBY_PLACE_ID then
    -- LOBBY MODE
    GUI.SetProgress(10, "Lobby Detected...")
    task.wait(0.5)
    
local LOADER_URL = "https://raw.githubusercontent.com/DeathMark58/levihub/main/Loader.luau"

    if queue_on_teleport then
        GUI.SetProgress(50, "Preparing teleport hook...")
        task.wait(0.5)
        
        local queueScript = [[
            pcall(function()
                if not game:IsLoaded() then game.Loaded:Wait() end
                wait(3)
                local url = "]] .. LOADER_URL .. [["
                loadstring(game:HttpGet(url))()
            end)
        ]]
        queue_on_teleport(queueScript)
        
        GUI.SetProgress(100, "Script Queued! Join a game.")
        task.wait(1)
        GUI.Finish()
        
        print("[Levi Hub] Queued for teleport.")
    else
        GUI.SetProgress(0, "Error: queue_on_teleport missing")
        warn("queue_on_teleport unavailable")
    end
else
    -- GAME MODE
    LoadMainScript()
end
