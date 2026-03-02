-- ============================================
-- ExtractOrDie — Theme
-- Colors, shared state factory, persistent stash
-- ============================================

local Config = require("eod/core/config")

local Theme = {}

Theme.Colors = {
    WHITE      = Color.New(255, 255, 255),
    BLACK      = Color.New(0, 0, 0),
    YELLOW     = Color.New(255, 255, 100),
    RED        = Color.New(255, 80, 80),
    GREEN      = Color.New(100, 255, 100),
    CYAN       = Color.New(100, 220, 255),
    GRAY       = Color.New(160, 160, 160),
    ORANGE     = Color.New(230, 150, 50),
    DIM        = Color.New(100, 100, 100),
    DARK_BG    = Color.New(10, 10, 15, 240),
    CARD_BG    = Color.New(25, 25, 35, 220),
    PANEL_BG   = Color.New(20, 20, 30, 225),
    HP_FG      = Color.New(220, 50, 50),
    HP_BG      = Color.New(80, 20, 20, 200),
    AMMO_FG    = Color.New(220, 200, 50),
    AMMO_BG    = Color.New(80, 70, 20, 200),
    SLOT_BG    = Color.New(40, 40, 55, 200),
    SLOT_SEL   = Color.New(80, 80, 120, 230),
    EXTRACT_GREEN = Color.New(50, 255, 50, 60),
    EXTRACT_BORDER = Color.New(50, 255, 50, 150),
    VOID_COLOR = Color.New(8, 8, 12),
    FLOOR_A    = Color.New(45, 42, 38),
    FLOOR_B    = Color.New(50, 47, 42),
    WALL_TOP   = Color.New(80, 75, 68),
    WALL_FACE  = Color.New(55, 52, 48),
    CRATE_COLOR = Color.New(160, 120, 50),
    CRATE_BAND = Color.New(120, 90, 30),
}

-- Persistent stash (survives between raids)
Theme._stash = nil

function Theme.GetStash()
    if not Theme._stash then
        Theme._stash = {}
        for i = 1, Config.STASH_SIZE do
            Theme._stash[i] = nil
        end
    end
    return Theme._stash
end

-- Selected weapon for next raid (default pistol)
Theme._selectedWeapon = "pistol"

function Theme.GetSelectedWeapon()
    return Theme._selectedWeapon
end

function Theme.SetSelectedWeapon(wepId)
    Theme._selectedWeapon = wepId
end

-- Available weapons (unlocked by extracting with weapon loot)
Theme._unlockedWeapons = { pistol = true }

function Theme.GetUnlockedWeapons()
    return Theme._unlockedWeapons
end

function Theme.UnlockWeapon(wepId)
    Theme._unlockedWeapons[wepId] = true
end

-- Selected map type for next raid (default dungeon)
Theme._selectedMap = "dungeon"

function Theme.GetSelectedMap()
    return Theme._selectedMap
end

function Theme.SetSelectedMap(mapType)
    Theme._selectedMap = mapType
end

-- Last raid result (persists across scene switches)
Theme._lastRaidResult = nil
Theme._lastRaidLoot = {}

function Theme.SetRaidResult(result, loot)
    Theme._lastRaidResult = result
    Theme._lastRaidLoot = loot or {}
end

function Theme.GetRaidResult()
    return Theme._lastRaidResult, Theme._lastRaidLoot
end

function Theme.NewRaidShared()
    return {
        modId = "ExtractOrDie",
        tex = {},
        texturesReady = false,
        W = 0,
        H = 0,
        -- Map
        mapType = Theme._selectedMap,
        tiles = nil,
        rooms = nil,
        extractZones = nil,
        spawnRoom = nil,
        -- Player
        player = nil,
        -- Entities
        enemies = {},
        projectiles = {},
        particles = {},
        drops = {},
        crates = {},
        -- Systems
        backpack = nil,
        -- Camera
        camX = 0,
        camY = 0,
        camBounds = nil,
        -- Extraction
        extracting = false,
        extractTimer = 0,
        -- Spawning
        spawnTimer = 0,
        -- State
        raidOver = false,
        raidResult = nil, -- "extracted" or "died"
        raidLoot = {},    -- items collected during raid
    }
end

function Theme.ResolveTextures(shared)
    if shared.texturesReady then return true end
    local m = shared.modId
    shared.tex.pixel = Animation.FrameTextureIdFrom(m, "scrPixel", "base", "idle", 1)
    if not shared.tex.pixel then return false end
    shared.texturesReady = true
    return true
end

return Theme
