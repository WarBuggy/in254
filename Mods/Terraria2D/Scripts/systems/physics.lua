-- ============================================
-- Terraria2D — Physics
-- Fixed-timestep gravity, AABB tile collision
-- ============================================

local Config = require("core/config")
local WorldData = require("world/worlddata")

-- Localize hot-path math functions
local floor = math.floor
local max = math.max
local min = math.min
local sqrt = math.sqrt
local abs = math.abs
local ceil = math.ceil

local Physics = {}

local GRAVITY = Config.GRAVITY
local TERMINAL_VEL = Config.TERMINAL_VEL
local TS = Config.TILE_SIZE
local WORLD_PX_W = Config.WORLD_PX_W
local WORLD_PX_H = Config.WORLD_PX_H

-- Single-step physics: gravity + move + collide
-- Engine calls onFixedUpdate at 120Hz, so no accumulator needed.
function Physics.Update(ent, dt)
    -- Gravity
    ent.vy = ent.vy + GRAVITY * dt
    if ent.vy > TERMINAL_VEL then ent.vy = TERMINAL_VEL end

    -- Move X
    ent.x = ent.x + ent.vx * dt
    Physics.ResolveX(ent, TS)

    -- Move Y
    ent.y = ent.y + ent.vy * dt
    ent.onGround = false
    Physics.ResolveY(ent, TS)

    -- Clamp to world bounds
    ent.x = max(0, min(ent.x, WORLD_PX_W - ent.w))
    if ent.y > WORLD_PX_H then
        ent.y = WORLD_PX_H - ent.h
        ent.vy = 0
        ent.onGround = true
    end
end

-- Legacy wrappers (kept for any edge callers)
function Physics.ApplyGravity(ent, dt)
    ent.vy = ent.vy + GRAVITY * dt
    if ent.vy > TERMINAL_VEL then
        ent.vy = TERMINAL_VEL
    end
end

function Physics.MoveAndCollide(ent, dt)
    -- Move X
    ent.x = ent.x + ent.vx * dt
    Physics.ResolveX(ent, TS)

    -- Move Y
    ent.y = ent.y + ent.vy * dt
    ent.onGround = false
    Physics.ResolveY(ent, TS)

    -- Clamp to world bounds
    ent.x = max(0, min(ent.x, WORLD_PX_W - ent.w))
    if ent.y > WORLD_PX_H then
        ent.y = WORLD_PX_H - ent.h
        ent.vy = 0
        ent.onGround = true
    end
end

function Physics.ResolveX(ent, ts)
    local left = floor(ent.x / ts)
    local right = floor((ent.x + ent.w - 1) / ts)
    local top = floor(ent.y / ts)
    local bottom = floor((ent.y + ent.h - 1) / ts)

    for ty = top, bottom do
        for tx = left, right do
            if WorldData.IsSolid(tx, ty) then
                local tileLeft = tx * ts
                local tileRight = tileLeft + ts
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

function Physics.ResolveY(ent, ts)
    local left = floor(ent.x / ts)
    local right = floor((ent.x + ent.w - 1) / ts)
    local top = floor(ent.y / ts)
    local bottom = floor((ent.y + ent.h - 1) / ts)

    for tx = left, right do
        for ty = top, bottom do
            if WorldData.IsSolid(tx, ty) then
                local tileTop = ty * ts
                local tileBottom = tileTop + ts
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
