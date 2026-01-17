--[[
    LEVI HUB - Premium Loader
    Execute this in LOBBY
    It will queue the main script for after teleport
]]

local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/DeathMark58/levihub/refs/heads/main/levihub"
local LOBBY_PLACE_ID = 11534222714

-- ============================================
-- PREMIUM LOADING UI
-- ============================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function CreateLoadingUI(status, isLobby)
    -- Clean up existing
    local existing = PlayerGui:FindFirstChild("LeviHubLoader")
    if existing then existing:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LeviHubLoader"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui
    
    -- Main container (TOP right corner)
    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(0, 280, 0, 90)
    Container.Position = UDim2.new(1, -300, 0, 20)
    Container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Container.BorderSizePixel = 0
    Container.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Container
    
    -- Gradient border effect
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(139, 92, 246) -- Purple
    Stroke.Thickness = 2
    Stroke.Transparency = 0.3
    Stroke.Parent = Container
    
    -- Glow effect
    local Glow = Instance.new("ImageLabel")
    Glow.Name = "Glow"
    Glow.Size = UDim2.new(1, 40, 1, 40)
    Glow.Position = UDim2.new(0, -20, 0, -20)
    Glow.BackgroundTransparency = 1
    Glow.Image = "rbxassetid://5028857084"
    Glow.ImageColor3 = Color3.fromRGB(139, 92, 246)
    Glow.ImageTransparency = 0.85
    Glow.ScaleType = Enum.ScaleType.Slice
    Glow.SliceCenter = Rect.new(24, 24, 276, 276)
    Glow.Parent = Container
    
    -- Icon (sword/blade symbol)
    local Icon = Instance.new("TextLabel")
    Icon.Name = "Icon"
    Icon.Size = UDim2.new(0, 50, 0, 50)
    Icon.Position = UDim2.new(0, 15, 0.5, -25)
    Icon.BackgroundTransparency = 1
    Icon.Text = "⚔️"
    Icon.TextSize = 32
    Icon.Font = Enum.Font.GothamBold
    Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
    Icon.Parent = Container
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0, 200, 0, 24)
    Title.Position = UDim2.new(0, 70, 0, 15)
    Title.BackgroundTransparency = 1
    Title.Text = "LEVI HUB v4.0"
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBlack
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Container
    
    -- Status text
    local Status = Instance.new("TextLabel")
    Status.Name = "Status"
    Status.Size = UDim2.new(0, 200, 0, 18)
    Status.Position = UDim2.new(0, 70, 0, 40)
    Status.BackgroundTransparency = 1
    Status.Text = status
    Status.TextSize = 13
    Status.Font = Enum.Font.Gotham
    Status.TextColor3 = Color3.fromRGB(180, 180, 180)
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Container
    
    -- Progress bar background
    local ProgressBG = Instance.new("Frame")
    ProgressBG.Name = "ProgressBG"
    ProgressBG.Size = UDim2.new(0, 190, 0, 4)
    ProgressBG.Position = UDim2.new(0, 70, 0, 65)
    ProgressBG.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    ProgressBG.BorderSizePixel = 0
    ProgressBG.Parent = Container
    
    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(0, 2)
    ProgressCorner.Parent = ProgressBG
    
    -- Progress bar fill
    local ProgressFill = Instance.new("Frame")
    ProgressFill.Name = "Fill"
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressFill.BackgroundColor3 = Color3.fromRGB(139, 92, 246)
    ProgressFill.BorderSizePixel = 0
    ProgressFill.Parent = ProgressBG
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 2)
    FillCorner.Parent = ProgressFill
    
    -- Gradient on progress bar
    local FillGradient = Instance.new("UIGradient")
    FillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(236, 72, 153))
    })
    FillGradient.Parent = ProgressFill
    
    -- Slide in animation (from right, TOP position)
    Container.Position = UDim2.new(1, 50, 0, 20)
    local slideIn = TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -300, 0, 20)
    })
    slideIn:Play()
    
    -- Pulse glow animation
    task.spawn(function()
        while ScreenGui.Parent do
            local pulseOut = TweenService:Create(Glow, TweenInfo.new(1, Enum.EasingStyle.Sine), {
                ImageTransparency = 0.7
            })
            pulseOut:Play()
            pulseOut.Completed:Wait()
            
            local pulseIn = TweenService:Create(Glow, TweenInfo.new(1, Enum.EasingStyle.Sine), {
                ImageTransparency = 0.85
            })
            pulseIn:Play()
            pulseIn.Completed:Wait()
        end
    end)
    
    return {
        Gui = ScreenGui,
        Container = Container,
        Status = Status,
        ProgressFill = ProgressFill,
        ProgressBG = ProgressBG,
        
        SetStatus = function(text)
            Status.Text = text
        end,
        
        SetProgress = function(percent)
            local targetWidth = (percent / 100) * 190
            TweenService:Create(ProgressFill, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0, targetWidth, 1, 0)
            }):Play()
        end,
        
        SetSuccess = function()
            Status.Text = "✓ Ready!"
            Status.TextColor3 = Color3.fromRGB(34, 197, 94)
            Stroke.Color = Color3.fromRGB(34, 197, 94)
            ProgressFill.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
            
            -- Green gradient
            FillGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 197, 94)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 185, 129))
            })
        end,
        
        Close = function(delay)
            if delay then
                task.delay(delay, function()
                    local slideOut = TweenService:Create(Container, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                        Position = UDim2.new(1, 50, 0, 20)
                    })
                    slideOut:Play()
                    slideOut.Completed:Wait()
                    ScreenGui:Destroy()
                end)
            end
            -- If no delay passed, don't close (stay visible)
        end
    }
end

-- ============================================
-- MAIN LOADER LOGIC
-- ============================================
print("╔═══════════════════════════════════════╗")
print("║          LEVI HUB - Loader            ║")
print("╚═══════════════════════════════════════╝")

local function LoadMainScript()
    local ui = CreateLoadingUI("Initializing...", false)
    ui.SetProgress(10)
    task.wait(0.5)
    
    ui.SetStatus("Connecting to GitHub...")
    ui.SetProgress(25)
    task.wait(0.4)
    
    ui.SetStatus("Downloading script...")
    ui.SetProgress(50)
    task.wait(0.3)
    
    local success, err = pcall(function()
        loadstring(game:HttpGet(MAIN_SCRIPT_URL))()
    end)
    
    ui.SetStatus("Executing...")
    ui.SetProgress(80)
    task.wait(0.3)
    
    if success then
        ui.SetProgress(100)
        ui.SetSuccess()
        -- Don't close, stay visible
    else
        ui.SetStatus("✗ Failed: " .. tostring(err):sub(1, 30))
        warn("[Loader] Failed to load main script: " .. tostring(err))
    end
end

if game.PlaceId == LOBBY_PLACE_ID then
    -- We're in lobby
    local ui = CreateLoadingUI("Lobby detected...", true)
    ui.SetProgress(10)
    task.wait(0.5)
    
    if queue_on_teleport then
        ui.SetStatus("Preparing teleport hook...")
        ui.SetProgress(30)
        task.wait(0.4)
        
        ui.SetStatus("Queueing script...")
        ui.SetProgress(60)
        task.wait(0.3)
        
        local queueScript = [[
            repeat task.wait() until game:IsLoaded()
            task.wait(2)
            loadstring(game:HttpGet("]] .. MAIN_SCRIPT_URL .. [["))()
        ]]
        queue_on_teleport(queueScript)
        
        ui.SetProgress(100)
        ui.SetStatus("✓ Queued! Join a game")
        ui.SetSuccess()
        -- Don't close, stay visible
        
        print("[Loader] ✓ Script queued for teleport")
    else
        ui.SetStatus("✗ queue_on_teleport unavailable")
        -- Don't close
        warn("[Loader] queue_on_teleport not available!")
    end
else
    -- We're in game - load directly
    print("[Loader] GAME detected - Loading directly...")
    LoadMainScript()
end
