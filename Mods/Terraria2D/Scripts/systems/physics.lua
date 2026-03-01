-- ============================================
-- Terraria2D — Physics
-- Gravity, AABB tile collision
-- ============================================

local Config = require("core/config")
local WorldData = require("world/worlddata")

-- Localize hot-path math functions
local floor = math.floor
local max = math.max
local min = math.min
local sqrt = math.sqrt

local Physics = {}

-- Apply gravity to an entity with { x, y, vx, vy, w, h }
function Physics.ApplyGravity(ent, dt)
    ent.vy = ent.vy + Config.GRAVITY * dt
    if ent.vy > Config.TERMINAL_VEL then
        ent.vy = Config.TERMINAL_VEL
    end
end

-- Resolve AABB collision with tiles, per-axis
-- ent = { x, y, vx, vy, w, h, onGround }
function Physics.MoveAndCollide(ent, dt)
    local TS = Config.TILE_SIZE

    -- Move X
    ent.x = ent.x + ent.vx * dt
    Physics.ResolveX(ent, TS)

    -- Move Y
    ent.y = ent.y + ent.vy * dt
    ent.onGround = false
    Physics.ResolveY(ent, TS)

    -- Clamp to world bounds
    ent.x = max(0, min(ent.x, Config.WORLD_PX_W - ent.w))
    if ent.y > Config.WORLD_PX_H then
        ent.y = Config.WORLD_PX_H - ent.h
        ent.vy = 0
        ent.onGround = true
    end
end

function Physics.ResolveX(ent, TS)
    local left = floor(ent.x / TS)
    local right = floor((ent.x + ent.w - 1) / TS)
    local top = floor(ent.y / TS)
    local bottom = floor((ent.y + ent.h - 1) / TS)

    for ty = top, bottom do
        for tx = left, right do
            if WorldData.IsSolid(tx, ty) then
                local tileLeft = tx * TS
                local tileRight = tileLeft + TS
                if ent.vx > 0 then
                    ent.x = tileLeft - ent.w
                elseif ent.vx < 0 then
                    ent.x = tileRight
                end
                ent.vx = 0
                return
            end
        end
    end
end

function Physics.ResolveY(ent, TS)
    local left = floor(ent.x / TS)
    local right = floor((ent.x + ent.w - 1) / TS)
    local top = floor(ent.y / TS)
    local bottom = floor((ent.y + ent.h - 1) / TS)

    for tx = left, right do
        for ty = top, bottom do
            if WorldData.IsSolid(tx, ty) then
                local tileTop = ty * TS
                local tileBottom = tileTop + TS
                if ent.vy > 0 then
                    ent.y = tileTop - ent.h
                    ent.onGround = true
                elseif ent.vy < 0 then
                    ent.y = tileBottom
                end
                ent.vy = 0
                return
            end
        end
    end
end

-- Check AABB overlap between two entities
function Physics.Overlaps(a, b)
    return a.x < b.x + b.w and a.x + a.w > b.x and
           a.y < b.y + b.h and a.y + a.h > b.y
end

-- Distance between center of two entities
function Physics.Distance(a, b)
    local dx = (a.x + a.w * 0.5) - (b.x + b.w * 0.5)
    local dy = (a.y + a.h * 0.5) - (b.y + b.h * 0.5)
    return sqrt(dx * dx + dy * dy)
end

-- Squared distance (avoids sqrt for comparison-only checks)
function Physics.DistanceSq(a, b)
    local dx = (a.x + a.w * 0.5) - (b.x + b.w * 0.5)
    local dy = (a.y + a.h * 0.5) - (b.y + b.h * 0.5)
    return dx * dx + dy * dy
end

return Physics
