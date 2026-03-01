-- ============================================
-- Terraria2D — Camera
-- 2D camera with smooth follow (X and Y)
-- ============================================

local Config = require("core/config")

local Camera = {}

local state = {
    x = 0,
    y = 0,
    targetX = 0,
    targetY = 0,
    lerpSpeed = 6,
}

function Camera.Init(x, y)
    state.x = x or 0
    state.y = y or 0
    state.targetX = state.x
    state.targetY = state.y
end

function Camera.GetX() return state.x end
function Camera.GetY() return state.y end

function Camera.Follow(entityX, entityY, screenW, screenH)
    state.targetX = entityX - math.floor(screenW / 2)
    state.targetY = entityY - math.floor(screenH / 2)

    -- Clamp to world bounds
    local maxX = Config.WORLD_PX_W - screenW
    local maxY = Config.WORLD_PX_H - screenH
    state.targetX = math.max(0, math.min(state.targetX, maxX))
    state.targetY = math.max(0, math.min(state.targetY, maxY))
end

function Camera.Update(dt)
    local speed = state.lerpSpeed * dt
    speed = math.min(speed, 1)
    state.x = state.x + (state.targetX - state.x) * speed
    state.y = state.y + (state.targetY - state.y) * speed
    if math.abs(state.x - state.targetX) < 0.5 then state.x = state.targetX end
    if math.abs(state.y - state.targetY) < 0.5 then state.y = state.targetY end
end

function Camera.WorldToScreenX(wx)
    return wx - state.x
end

function Camera.WorldToScreenY(wy)
    return wy - state.y
end

function Camera.ScreenToWorldX(sx)
    return sx + state.x
end

function Camera.ScreenToWorldY(sy)
    return sy + state.y
end

function Camera.Snap(x, y)
    state.x = x
    state.y = y
    state.targetX = x
    state.targetY = y
end

return Camera
