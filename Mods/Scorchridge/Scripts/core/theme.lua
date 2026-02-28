-- ============================================
-- Scorchridge — Theme
-- Shared colors, layout constants, texture helpers.
-- ============================================

local Theme = {}

-- ---- Colors ----

Theme.Colors = {
    WHITE      = {255, 255, 255},
    YELLOW     = {255, 255, 100},
    RED        = {255, 80, 80},
    GREEN      = {100, 255, 100},
    CYAN       = {100, 220, 255},
    GRAY       = {160, 160, 160},
    ORANGE     = {230, 150, 50},
    DIM        = {100, 100, 100},
    GOLD       = {255, 215, 60},
    DARK_BG    = {20, 20, 35, 230},
    CARD_BG    = {30, 30, 50, 220},
    CARD_HOVER = {40, 40, 65, 230},
    CARD_SEL   = {50, 50, 75, 240},
    SIDE_BG    = {25, 25, 40, 225},
    TIER_COLORS = {
        {180, 140, 100},  -- copper
        {200, 200, 220},  -- silver
        {255, 215, 60}    -- gold
    }
}

-- ---- Layout ----

Theme.Layout = {
    TOP_H  = 48,
    BOT_H  = 80,
    SIDE_W = 220,
}

-- ---- Phase name helper ----

function Theme.PhaseName(phase)
    return Localize("scorchridge.phase." .. phase)
end

-- ---- Gameplay shared state factory ----

function Theme.NewGameplayShared()
    return {
        modId          = "Scorchridge",
        bobTimer       = 0,
        phaseTransText  = "",
        phaseTransTimer = 0,
        prevPhase      = "",
        lastDrawPhase  = "",
        characters     = {},
        tex            = {},
        texturesReady  = false,
        state      = nil,
        inmates    = nil,
        resources  = nil,
        production = nil,
        W = 0,
        H = 0,
    }
end

-- ---- Texture resolution ----

function Theme.ResolveTextures(shared)
    if shared.texturesReady then return true end
    local m = shared.modId
    shared.tex.inmate     = Animation.FrameTextureIdFrom(m, "scrInmate",     "base", "idle", 1)
    shared.tex.inmateWork = Animation.FrameTextureIdFrom(m, "scrInmateWork", "base", "idle", 1)
    shared.tex.inmateEat  = Animation.FrameTextureIdFrom(m, "scrInmateEat",  "base", "idle", 1)
    shared.tex.inmateRest = Animation.FrameTextureIdFrom(m, "scrInmateRest", "base", "idle", 1)
    shared.tex.pickaxe    = Animation.FrameTextureIdFrom(m, "scrPickaxe",    "base", "idle", 1)
    shared.tex.foodBowl   = Animation.FrameTextureIdFrom(m, "scrFoodBowl",   "base", "idle", 1)
    shared.tex.bed        = Animation.FrameTextureIdFrom(m, "scrBed",        "base", "idle", 1)
    shared.tex.table      = Animation.FrameTextureIdFrom(m, "scrTable",      "base", "idle", 1)
    shared.tex.ore        = Animation.FrameTextureIdFrom(m, "scrOre",        "base", "idle", 1)
    shared.tex.pcho       = Animation.FrameTextureIdFrom(m, "scrPcho",       "base", "idle", 1)
    shared.tex.sky        = Animation.FrameTextureIdFrom(m, "scrSky",        "base", "idle", 1)
    for _, v in pairs(shared.tex) do
        if not v then return false end
    end
    shared.texturesReady = true
    return true
end

-- ---- Sprite drawing helper ----

function Theme.Spr(id, x, y, w, h, sx, sy, color, flipX, flipY)
    sx = sx or 1; sy = sy or sx
    Drawing.AddRequest(id, {x, y}, 0, {sx, sy}, color, 0, w, h, 0, 0, flipX or false, flipY or false)
end

return Theme
