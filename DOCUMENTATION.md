# Levi Hub - Complete Technical Documentation

> **Last Updated:** 2026-01-17  
> **UI Library:** Starlight Interface Suite  
> **Game:** Attack On Titan: Freedom War (Roblox)

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [File Structure](#file-structure)
3. [Game Mechanics](#game-mechanics)
4. [Anti-Cheat Bypass](#anti-cheat-bypass)
5. [Starlight UI Library Reference](#starlight-ui-library-reference)
6. [Agent Rules](#agent-rules)
7. [Current Status](#current-status)
8. [Roadmap](#roadmap)

---

## Project Overview

**Objective:** Create a hitbox extender for Pure Titans that bypasses the game's anti-cheat using metatable spoofing.

**Technique:** Intercept property reads via `__index` hook to return original values while visually modifying hitboxes.

**GitHub Raw URL:**
```
https://raw.githubusercontent.com/DeathMark58/levihub/refs/heads/main/levihub
```

---

## File Structure

```
c:\Users\kerim\Desktop\Burak\fw\
├── LeviHub.luau        # Main script
├── Loader.luau         # Premium loading screen + teleport queue
├── Adonisbypass.luau   # Obfuscated Adonis bypass (user-provided)
└── DOCUMENTATION.md    # This file
```

---

## Game Mechanics

### Place IDs
| Place | ID |
|-------|-----|
| Lobby | `11534222714` |
| Game | Various (not lobby) |

### Titan Structure
**Location:** `game.Workspace.OnGameTitans`

**Pure Titans contain:**
- `Nape` - BasePart (kill zone, main hitbox)
- `Eyes` - BasePart (weak point for some titans)

> [!IMPORTANT]
> **Hitbox Detection Rules:**
> - ONLY target BaseParts named **exactly** "Nape" or "Eyes"
> - Do NOT process descendants of hitbox models
> - Do NOT use fuzzy/lowercase matching
> - Shifters (Female Titan, Armored, etc.) are in **different containers** - ignore them for now

### Titan Types
| Type | Container | Status |
|------|-----------|--------|
| Pure Titans | `OnGameTitans` | ✅ Supported |
| Shifter Titans | TBD | ⏳ Future |
| NPC Titans | TBD | ⏳ Future |

---

## Anti-Cheat Bypass

### Game Anti-Cheats
1. **Adonis** - Detects namecall hooks, remote tampering. Bypass provided separately.
2. **Labyrinth** - Obfuscated, checks part properties (Size, Transparency, etc.)

### Spoofing Technique
```lua
-- Store original values BEFORE modification
SpoofedParts[part] = {
    Size = originalSize,
    Transparency = originalTransparency,
    Color = originalColor,
    Material = originalMaterial,
    BrickColor = originalBrickColor,
    HitboxType = "Nape" or "Eyes" -- Category tracking
}

-- Modify the actual part (visual)
part.Size = originalSize * multiplier
part.Transparency = 0.3
part.Color = Color3.fromRGB(255, 0, 0)

-- Hook __index to return originals when anti-cheat reads
hookmetamethod(game, "__index", function(self, key)
    if SpoofedParts[self] and SpoofedParts[self][key] then
        return SpoofedParts[self][key]  -- Return fake original
    end
    return oldIndex(self, key)
end)
```

> [!CAUTION]
> **Always spoof EVERY property you modify.** If you change Color but don't spoof it, anti-cheat can detect.

### Executor Requirements
- **sUNC or higher**
- Must support:
  - `hookmetamethod` - For __index spoofing
  - `newcclosure` - For hook safety
  - `queue_on_teleport` - For TP persistence
  - `loadstring` + `game:HttpGet` - For loading from GitHub

---

## Starlight UI Library Reference

> **Documentation Links:**
> - Starlight: https://docs.nebulasoftworks.xyz/starlight
> - Nebula Icons: https://docs.nebulasoftworks.xyz/nebula-icons
> - Lucide Icons (for icon names): https://lucide.dev/icons

**Load:**
```lua
local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()
```

**Secure Mode (anti-detection):**
```lua
getgenv().SecureMode = true -- Place at top of script
```

### Hierarchy
```
Window → TabSection → Tab → Groupbox → Elements
                                ↓
                           Nested Elements
```

### Window
```lua
local Window = Starlight:CreateWindow({
    Name = "Levi Hub",
    Subtitle = "v4.0",
    Icon = 123456789,
    
    LoadingSettings = {
        Title = "Levi Hub",
        Subtitle = "Welcome!",
    },
    
    FileSettings = {
        ConfigFolder = "LeviHub"
    },
})
```

### TabSection
```lua
local TabSection = Window:CreateTabSection("Main")
-- Parameters: Name (string), Visible (boolean, optional)
```

### Tab
```lua
local Tab = TabSection:CreateTab({
    Name = "Titans",
    Icon = NebulaIcons:GetIcon('crosshair', 'Material'),
    Columns = 2,
}, "TitansTab")
```

### Groupbox
```lua
local Groupbox = Tab:CreateGroupbox({
    Name = "Nape Settings",
    Column = 1,
}, "NapeGroup")
```

### Elements

| Element | Syntax | Key Parameters |
|---------|--------|----------------|
| **Toggle** | `Groupbox:CreateToggle({...}, "IDX")` | `Name`, `CurrentValue`, `Style (1-3)`, `Callback` |
| **Slider** | `Groupbox:CreateSlider({...}, "IDX")` | `Name`, `Range={min,max}`, `Increment`, `Suffix`, `Callback` |
| **Button** | `Groupbox:CreateButton({...}, "IDX")` | `Name`, `Callback` |
| **Input** | `Groupbox:CreateInput({...}, "IDX")` | `PlaceholderText`, `CurrentValue`, `Callback` |
| **Label** | `Groupbox:CreateLabel({...}, "IDX")` | `Name` (parent for nested) |
| **Paragraph** | `Groupbox:CreateParagraph({...}, "IDX")` | `Name`, `Content` |
| **Divider** | `Groupbox:CreateDivider()` | None |

### Nested Elements (attached to Label/Toggle)

| Element | Syntax | Key Parameters |
|---------|--------|----------------|
| **Dropdown** | `Label:AddDropdown({...}, "IDX")` | `Options`, `CurrentOptions`, `MultipleOptions`, `Callback` |
| **ColorPicker** | `Label:AddColorPicker({...}, "IDX")` | `CurrentValue`, `Transparency`, `Callback` |
| **Keybind** | `Label:AddBind({...}, "IDX")` | `CurrentValue`, `HoldToInteract`, `Callback` |

### Config System
```lua
-- Add config UI to a tab
Tab:BuildConfigGroupbox(Column)

-- Load autoload config at script end
Starlight:LoadAutoloadConfig()

-- Ignore config for specific element
{..., IgnoreConfig = true}
```

### Extras
```lua
-- Notification
Starlight:Notification({Title = "...", Content = "...", Duration = 5})

-- Dialog
Window:PromptDialog({Name = "...", Content = "...", Actions = {...}})

-- Cleanup
Starlight:OnDestroy(function()
    -- cleanup code
end)
Starlight:Destroy()
```

---

## Agent Rules

> [!WARNING]
> **Critical rules for any AI agent working on this project:**

### Hitbox Rules
1. **STRICT NAME MATCHING:** Only modify BaseParts named exactly `"Nape"` or `"Eyes"`
2. **NO DESCENDANTS:** Never process children of hitbox models
3. **NO DUPLICATES:** Use `ProcessedParts` table to prevent double-processing
4. **CATEGORY TRACKING:** Store `HitboxType` in spoof data for category-based toggle

### Spoof Rules
1. **SPOOF EVERYTHING:** Every modified property MUST be spoofed
2. **STORE BEFORE MODIFY:** Always store original values before changing anything
3. **PCALL PROTECTION:** Wrap hook returns in pcall for safety

### UI Rules (Starlight)
1. **UNIQUE INDEX:** Every element needs a unique string index
2. **NESTED PARENTS:** Dropdown/ColorPicker/Keybind must attach to Label or Toggle
3. **FILESETTINGS REQUIRED:** For config to work, FileSettings must be set in Window
4. **NO EMOJIS:** Never use emojis in element names (❌🎮🎯 etc.)
5. **USE NEBULA ICONS:** Always use NebulaIcons library for icons
   - Window icon: `NebulaIcons:GetIcon('feather', 'Lucide')` (wings theme)
   - General tab: `'home'`
   - Titans tab: `'crosshair'`
   - Settings tab: `'settings'`
6. **TAB ORDER:** General (top) → Feature tabs → Settings (bottom)

### Code Rules
1. **MODULAR:** Use functions that can be reused for Shifters later
2. **NO CODE DUPLICATION:** Spoof engine should be centralized
3. **DEFAULT OFF:** All toggles should default to OFF/false
4. **LOBBY CHECK:** Never activate hooks in lobby (PlaceId check)

---

## Current Status

### ✅ Completed
- Metatable spoofing for Size, Transparency, Color, Material, BrickColor
- Pure Titan detection in OnGameTitans
- Retry mechanism for late-loading hitboxes
- DescendantAdded watcher for dynamic hitbox creation
- Premium loading screen (Loader.luau)
- **Starlight UI migration** (v4.0)
- Toggle-based hitbox system (Master + Nape + Eyes)
- Material dropdown for hitboxes
- Modular SpoofEngine

### 🔄 In Progress
- Testing and refinement

### ⏳ Pending
- Shifter titan support
- ESP for titans
- Config save/load with Starlight
- Aimbot integration

---

## Roadmap

### Phase 1: UI Migration ⬅️ CURRENT
- [ ] Replace xan.bar with Starlight
- [ ] Restructure tabs: Settings (first) → Titans
- [ ] Add master toggle: "Pure Titan Hitbox Changer"
- [ ] Add individual Nape/Eyes toggles
- [ ] Add Material dropdown
- [ ] Default all toggles to OFF
- [ ] Default transparency to 0
- [ ] Implement config save/load

### Phase 2: Modular Spoof Engine
- [ ] Create centralized SpoofEngine module
- [ ] Category-based apply/restore
- [ ] Reusable for Shifters

### Phase 3: Shifter Support
- [ ] Identify Shifter titan containers
- [ ] Add Shifters tab to UI
- [ ] Implement Shifter-specific hitbox detection

### Phase 4: Advanced Features
- [ ] ESP for titans (boxes, names, health)
- [ ] Titan tracking/radar
- [ ] Aimbot integration
- [ ] Kill aura option

---

## Debug Commands

After script loads, available in console (F9):

```lua
getgenv().AOT.Scan()      -- Force scan titans
getgenv().AOT.Refresh()   -- Re-apply current settings
getgenv().AOT.Stats()     -- Get hook statistics
getgenv().AOT.Unload()    -- Clean unload
getgenv().AOT.Config      -- Current config table
```

---

## Quick Reference

### Titan Processing Flow
```
Initialize()
├── SetupMetatableHooks()
├── SetupTitanWatcher()
├── SetupUI()
└── Auto-refresh loop (3s)

ProcessTitan(model)
├── FindHitboxWithRetry("Nape", 5)
├── FindHitboxWithRetry("Eyes", 5)
└── ModifyPart() for each found

ModifyPart(part, scaleX, scaleY, scaleZ, color, transparency, type)
├── Check: BasePart && !ProcessedParts[part]
├── Store original in SpoofedParts
├── Apply modifications
└── Mark in ProcessedParts
```
