-- ============================================
-- Terraria2D — Theme
-- Colors and shared state factory
-- ============================================

local Config = require("core/config")

local Theme = {}

Theme.Colors = {
    WHITE      = {255, 255, 255},
    BLACK      = {0, 0, 0},
    YELLOW     = {255, 255, 100},
    RED        = {255, 80, 80},
    GREEN      = {100, 255, 100},
    CYAN       = {100, 220, 255},
    GRAY       = {160, 160, 160},
    ORANGE     = {230, 150, 50},
    DIM        = {100, 100, 100},
    DARK_BG    = {20, 20, 35, 230},
    CARD_BG    = {30, 30, 50, 220},
    PANEL_BG   = {25, 25, 40, 225},
    HP_FG      = {220, 50, 50},
    HP_BG      = {80, 20, 20, 200},
    MANA_FG    = {50, 100, 220},
    MANA_BG    = {20, 30, 80, 200},
    SLOT_BG    = {40, 40, 55, 200},
    SLOT_SEL   = {80, 80, 120, 230},
    SKY_DAY    = {135, 206, 235},
    SKY_SUNSET = {255, 140, 50},
    SKY_NIGHT  = {15, 15, 40},
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

function Theme.LerpColor(a, b, t)
    t = math.max(0, math.min(1, t))
    return {
        math.floor(a[1] + (b[1] - a[1]) * t),
        math.floor(a[2] + (b[2] - a[2]) * t),
        math.floor(a[3] + (b[3] - a[3]) * t),
    }
end

return Theme
