-- ============================================
-- ScorchridgeV2 — Camera
-- Horizontal scroll only — all 4 rows always visible
-- ============================================

local Config = require("core/config")

local Camera = {}

local state = {
    x = 0,
    targetX = 0,
    lerpSpeed = 8,
}

function Camera.Init()
    state.x = 0
    state.targetX = 0
end

function Camera.GetX() return state.x end

-- Follow an entity horizontally, centering it on screen
function Camera.Follow(entityX, screenW)
    state.targetX = entityX - math.floor(screenW / 2)
    local maxX = Config.WORLD_W - screenW
    state.targetX = math.max(0, math.min(state.targetX, maxX))
end

-- Get the screen Y for a given row (top of header bar)
function Camera.LevelScreenY(level)
    return Config.TOP_H + (level - 1) * (Config.ROW_H + Config.ROW_GAP)
end

-- Get the screen Y for the cell body (below header)
function Camera.CellScreenY(level)
    return Camera.LevelScreenY(level) + Config.HEADER_H
end

-- Get the hallway screen Y for a given row
function Camera.HallwayScreenY(level)
    return Camera.CellScreenY(level) + Config.CELL_H
end

-- Update with smooth lerp
function Camera.Update(dt)
    local speed = state.lerpSpeed * dt
    speed = math.min(speed, 1)
    state.x = state.x + (state.targetX - state.x) * speed
    if math.abs(state.x - state.targetX) < 0.5 then state.x = state.targetX end
end

-- Convert world X to screen X (horizontal scroll only)
function Camera.WorldToScreenX(wx)
    return wx - state.x
end

return Camera
