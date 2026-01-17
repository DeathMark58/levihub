--[[
    LEVI HUB - Premium Loader
    Fixed Animation & Watermark logic
]]

local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/DeathMark58/levihub/main/LeviHub.luau"
local LOADER_URL = "https://raw.githubusercontent.com/DeathMark58/levihub/main/Loader.luau"
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
    local parent = nil
    -- Attempt to find best parent
    if gethui then
        parent = gethui()
    elseif syn and syn.protect_gui then
        local gui = Instance.new("ScreenGui")
        syn.protect_gui(gui)
        gui.Parent = CoreGui
        parent = gui.Parent
    elseif CoreGui then
        parent = CoreGui
    else
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Cleanup existing
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == "LeviHubLoader_Final" then child:Destroy() end
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LeviHubLoader_Final"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 10000 
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = parent
    
    local function AddCorner(obj, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius)
        c.Parent = obj
        return c
    end
    
    -- 1. WATERMARK (Top Right)
    -- Hidden initially, shown after animation
    local Watermark = Instance.new("Frame")
    Watermark.Name = "Watermark"
    Watermark.AnchorPoint = Vector2.new(1, 0) -- Top-Right pivot
    Watermark.Size = UDim2.new(0, 140, 0, 35)
    Watermark.Position = UDim2.new(1, -20, 0, 20) -- Final position
    Watermark.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Watermark.BackgroundTransparency = 0 
    Watermark.Visible = false -- START HIDDEN
    Watermark.Parent = ScreenGui
    
    AddCorner(Watermark, 8)
    local WStroke = Instance.new("UIStroke")
    WStroke.Color = Color3.fromRGB(50, 50, 60)
    WStroke.Thickness = 1
    WStroke.Parent = Watermark
    
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
    Splash.AnchorPoint = Vector2.new(0.5, 0.5) -- Center pivot
    Splash.Size = UDim2.new(0, 400, 0, 250)
    Splash.Position = UDim2.new(0.5, 0, 0.5, 0) 
    Splash.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    Splash.BorderSizePixel = 0
    Splash.Parent = ScreenGui -- Add to GUI
    
    AddCorner(Splash, 16)
    
    -- Content Container (For easier fading)
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, 0)
    Content.BackgroundTransparency = 1
    Content.Parent = Splash
    
    local TopDeco = Instance.new("Frame")
    TopDeco.Size = UDim2.new(1, 0, 0, 2)
    TopDeco.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
    TopDeco.BorderSizePixel = 0
    TopDeco.Parent = Content
    
    local MainIcon = Instance.new("TextLabel")
    MainIcon.Size = UDim2.new(1, 0, 0, 80)
    MainIcon.Position = UDim2.new(0, 0, 0, 40)
    MainIcon.BackgroundTransparency = 1
    MainIcon.Text = "⚔️"
    MainIcon.TextSize = 64
    MainIcon.Parent = Content
    
    local MainTitle = Instance.new("TextLabel")
    MainTitle.Size = UDim2.new(1, 0, 0, 30)
    MainTitle.Position = UDim2.new(0, 0, 0, 110)
    MainTitle.BackgroundTransparency = 1
    MainTitle.Text = "LEVI HUB"
    MainTitle.Font = Enum.Font.GothamBlack
    MainTitle.TextSize = 28
    MainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    MainTitle.Parent = Content
    
    local SubTitle = Instance.new("TextLabel")
    SubTitle.Size = UDim2.new(1, 0, 0, 20)
    SubTitle.Position = UDim2.new(0, 0, 0, 140)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = "Made by Hak"
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.TextSize = 14
    SubTitle.TextColor3 = Color3.fromRGB(150, 150, 160)
    SubTitle.Parent = Content
    
    local BarBG = Instance.new("Frame")
    BarBG.Size = UDim2.new(0, 300, 0, 4)
    BarBG.Position = UDim2.new(0.5, -150, 0, 190)
    BarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    BarBG.BorderSizePixel = 0
    BarBG.Parent = Content
    AddCorner(BarBG, 2)
    
    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBG
    AddCorner(BarFill, 2)
    
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, 0, 0, 20)
    StatusText.Position = UDim2.new(0, 0, 0, 205)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Initializing..."
    StatusText.Font = Enum.Font.GothamMedium
    StatusText.TextSize = 12
    StatusText.TextColor3 = Color3.fromRGB(180, 180, 190)
    StatusText.Parent = Content
    
    local function SetProgress(percent, status)
        TweenService:Create(BarFill, TweenInfo.new(0.3), {Size = UDim2.new(percent/100, 0, 1, 0)}):Play()
        if status then StatusText.Text = status end
    end
    
    local function Finish()
        print("[Levi Hub] Starting Finish Animation")
        
        -- 1. FADE OUT CONTENT
        for _, obj in ipairs(Content:GetDescendants()) do
            if obj:IsA("TextLabel") then
                TweenService:Create(obj, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
            elseif obj:IsA("Frame") then
                TweenService:Create(obj, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
            end
        end
        
        task.wait(0.4)
        
        -- 2. MOVE SPLASH TO TOP RIGHT (Morph Effect)
        -- Target: Center of the desired Watermark position
        -- Watermark is at: Pos(1, -20, 0, 20) with Anchor(1,0)
        -- Its CENTER is at:
        -- X: 1 scale, offset -20 - (140/2) = -90
        -- Y: 0 scale, offset 20 + (35/2) = 37.5
        
        local targetSize = UDim2.new(0, 140, 0, 35)
        local targetPos = UDim2.new(1, -90, 0, 37.5)
        
        local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)
        
        local move = TweenService:Create(Splash, tweenInfo, {
            Size = targetSize,
            Position = targetPos,
            BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- Darker watermark color
        })
        
        move:Play()
        move.Completed:Wait() -- Wait for move to finish
        
        -- 3. SWAP
        Splash.Visible = false
        Watermark.Visible = true
        
        -- Make sure Watermark content is visible
        WLogo.TextTransparency = 0
        WText.TextTransparency = 0
        
        print("[Levi Hub] Animation Complete")
    end
    
    return {
        SetProgress = SetProgress,
        Finish = Finish
    }
end

local GUI = CreateGUI()

if CURRENT_PLACE_ID == LOBBY_PLACE_ID then
    -- LOBBY LOGIC
    GUI.SetProgress(10, "Lobby Detected...")
    task.wait(0.5)
    
    if queue_on_teleport then
        GUI.SetProgress(50, "Hooking Teleport...")
        task.wait(0.5)
        
        local queueScript = [[
            task.wait(2)
            pcall(function()
                loadstring(game:HttpGet("]] .. LOADER_URL .. [["))()
            end)
        ]]
        queue_on_teleport(queueScript)
        
        GUI.SetProgress(100, "Ready! Join a game.")
        task.wait(1)
        GUI.Finish()
    else
        GUI.SetProgress(0, "Error: No queue_on_teleport")
    end
else
    -- GAME LOGIC
    GUI.SetProgress(20, "Loading LeviHub...")
    task.wait(0.3)
    
    local success, content = pcall(function() return game:HttpGet(MAIN_SCRIPT_URL) end)
    
    if success then
        GUI.SetProgress(60, "Compiling...")
        local func = loadstring(content)
        if func then
            task.spawn(func)
            GUI.SetProgress(100, "Done!")
            task.wait(0.5)
            GUI.Finish()
        else
            GUI.SetProgress(0, "Error: Compile Fail")
            warn("Compile Fail")
        end
    else
        GUI.SetProgress(0, "Error: HTTP Fail")
        warn("HTTP Fail")
    end
end
