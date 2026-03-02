-- ============================================
-- ExtractOrDie — Physics
-- Top-down AABB collision, line-of-sight raycast
-- No gravity — 8-directional movement
-- ============================================

local Config = require("eod/core/config")
local Tilemap = require("eod/world/tilemap")

local floor = math.floor
local max = math.max
local min = math.min
local sqrt = math.sqrt
local abs = math.abs

local Physics = {}

local TS = Config.TILE_SIZE
local MAP_PX_W = Config.MAP_PX_W
local MAP_PX_H = Config.MAP_PX_H

-- Top-down physics: move X → resolve → move Y → resolve (no gravity)
function Physics.Update(ent, dt)
    -- Move X
    ent.x = ent.x + ent.vx * dt
    Physics.ResolveX(ent)

    -- Move Y
    ent.y = ent.y + ent.vy * dt
    Physics.ResolveY(ent)

    -- Clamp to map bounds
    ent.x = max(0, min(ent.x, MAP_PX_W - ent.w))
    ent.y = max(0, min(ent.y, MAP_PX_H - ent.h))
end

function Physics.ResolveX(ent)
    local left = floor(ent.x / TS)
    local right = floor((ent.x + ent.w - 1) / TS)
    local top = floor(ent.y / TS)
    local bottom = floor((ent.y + ent.h - 1) / TS)

    for ty = top, bottom do
        for tx = left, right do
            if Tilemap.IsSolid(tx, ty) then
                if ent.vx > 0 then
                    ent.x = tx * TS - ent.w
                elseif ent.vx < 0 then
                    ent.x = (tx + 1) * TS
                end
                ent.vx = 0
                return
            end
        end
    end
end

function Physics.ResolveY(ent)
    local left = floor(ent.x / TS)
    local right = floor((ent.x + ent.w - 1) / TS)
    local top = floor(ent.y / TS)
    local bottom = floor((ent.y + ent.h - 1) / TS)

    for tx = left, right do
        for ty = top, bottom do
            if Tilemap.IsSolid(tx, ty) then
                if ent.vy > 0 then
                    ent.y = ty * TS - ent.h
                elseif ent.vy < 0 then
                    ent.y = (ty + 1) * TS
                end
                ent.vy = 0
                return
            end
        end
    end
end

-- AABB overlap
function Physics.Overlaps(a, b)
    return a.x < b.x + b.w and a.x + a.w > b.x and
           a.y < b.y + b.h and a.y + a.h > b.y
end

-- Distance between centers
function Physics.Distance(a, b)
    local dx = (a.x + a.w * 0.5) - (b.x + b.w * 0.5)
    local dy = (a.y + a.h * 0.5) - (b.y + b.h * 0.5)
    return sqrt(dx * dx + dy * dy)
end

function Physics.DistanceSq(a, b)
    local dx = (a.x + a.w * 0.5) - (b.x + b.w * 0.5)
    local dy = (a.y + a.h * 0.5) - (b.y + b.h * 0.5)
    return dx * dx + dy * dy
end

-- Point distance
function Physics.PointDist(ax, ay, bx, by)
    local dx = ax - bx
    local dy = ay - by
    return sqrt(dx * dx + dy * dy)
end

-- Line-of-sight raycast (tile-based, Bresenham-like stepping)
function Physics.HasLineOfSight(ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    local dist = sqrt(dx * dx + dy * dy)
    if dist < 1 then return true end

    local steps = floor(dist / (TS * 0.5))
    if steps < 1 then steps = 1 end
    local stepX = dx / steps
    local stepY = dy / steps

    local cx, cy = ax, ay
    for i = 1, steps do
        cx = cx + stepX
        cy = cy + stepY
        local tx = floor(cx / TS)
        local ty = floor(cy / TS)
        if Tilemap.IsSolid(tx, ty) then
            return false
        end
    end
    return true
end

-- Check if a point is on a floor tile
function Physics.IsOnFloor(px, py)
    local tx = floor(px / TS)
    local ty = floor(py / TS)
    return not Tilemap.IsSolid(tx, ty)
end

return Physics
