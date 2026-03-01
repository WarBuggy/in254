-- ============================================
-- Terraria2D — Theme
-- Colors and shared state factory
-- ============================================

local Config = require("core/config")

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
    DARK_BG    = Color.New(20, 20, 35, 230),
    CARD_BG    = Color.New(30, 30, 50, 220),
    PANEL_BG   = Color.New(25, 25, 40, 225),
    HP_FG      = Color.New(220, 50, 50),
    HP_BG      = Color.New(80, 20, 20, 200),
    MANA_FG    = Color.New(50, 100, 220),
    MANA_BG    = Color.New(20, 30, 80, 200),
    SLOT_BG    = Color.New(40, 40, 55, 200),
    SLOT_SEL   = Color.New(80, 80, 120, 230),
    SKY_DAY    = Color.New(135, 206, 235),
    SKY_SUNSET = Color.New(255, 140, 50),
    SKY_NIGHT  = Color.New(15, 15, 40),
}

function Theme.NewGameplayShared()
    return {
        modId = "Terraria2D",
        tex = {},
        texturesReady = false,
        W = 0,
        H = 0,
        -- World
        worldTiles = nil,
        lightMap = nil,
        -- Player
        player = nil,
        -- Entities
        enemies = {},
        npcs = {},
        projectiles = {},
        particles = {},
        drops = {},
        boss = nil,
        -- Systems
        inventory = nil,
        dayTime = 0,
        dayFraction = 0,
        isNight = false,
        -- Camera
        camX = 0,
        camY = 0,
        -- UI state
        showInventory = false,
        showCrafting = false,
        showPause = false,
        gameOver = false,
        respawnTimer = 0,
        -- Mining
        mineTarget = nil,
        mineProgress = 0,
        -- Spawn point
        spawnX = 0,
        spawnY = 0,
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

function Theme.Unpack(packed)
    if packed < 0 then packed = packed + 0x100000000 end
    local b = packed % 256
    local g = math.floor(packed / 256) % 256
    local r = math.floor(packed / 65536) % 256
    return r, g, b
end

function Theme.LerpColor(a, b, t)
    t = math.max(0, math.min(1, t))
    local ar, ag, ab = Theme.Unpack(a)
    local br, bg, bb = Theme.Unpack(b)
    return Color.New(
        math.floor(ar + (br - ar) * t),
        math.floor(ag + (bg - ag) * t),
        math.floor(ab + (bb - ab) * t))
end

return Theme
