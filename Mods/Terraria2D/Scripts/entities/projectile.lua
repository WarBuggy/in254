-- ============================================
-- Terraria2D — Projectiles
-- Arrows, magic bolts
-- ============================================

local Config = require("core/config")
local WorldData = require("world/worlddata")
local Camera = require("core/camera")
local Physics = require("systems/physics")
local UI = require("core/ui")
local Projectile = {}

local _DR = Drawing.Rect
local _ps -- pixel sprite id

-- Object pool
local _pool = {}
local _poolSize = 0

local function acquireProjectile()
    -- Reuse a dead projectile from the pool
    for i = 1, _poolSize do
        if not _pool[i].alive then
            return _pool[i]
        end
    end
    -- Grow pool
    _poolSize = _poolSize + 1
    local proj = { x = 0, y = 0, vx = 0, vy = 0, w = 4, h = 4,
                   damage = 0, type = "", friendly = true, lifetime = 0, alive = false }
    _pool[_poolSize] = proj
    return proj
end

function Projectile.Spawn(shared, x, y, vx, vy, damage, projType, friendly)
    local proj = acquireProjectile()
    proj.x = x
    proj.y = y
    proj.vx = vx
    proj.vy = vy
    proj.w = 4
    proj.h = 4
    proj.damage = damage
    proj.type = projType
    proj.friendly = friendly
    proj.lifetime = 0
    proj.alive = true
end

local function updateProjectile(proj, shared, dt, TS)
    proj.lifetime = proj.lifetime + dt

    -- Apply gravity to arrows
    if proj.type == "arrow" then
        proj.vy = proj.vy + 200 * dt
    end

    -- Move
    proj.x = proj.x + proj.vx * dt
    proj.y = proj.y + proj.vy * dt

    -- Out of world bounds — recycle immediately
    local worldPxW = Config.WORLD_W * TS
    local worldPxH = Config.WORLD_H * TS
    if proj.x < -32 or proj.x > worldPxW + 32 or proj.y < -32 or proj.y > worldPxH + 32 then
        proj.alive = false
        return
    end

    -- Check tile collision
    local tx = math.floor(proj.x / TS)
    local ty = math.floor(proj.y / TS)
    if WorldData.IsSolid(tx, ty) then
        proj.alive = false
        return
    end

    -- Check entity collision
    if proj.friendly then
        -- Hit enemies
        for _, enemy in ipairs(shared.enemies) do
            if enemy.alive and enemy.invTimer <= 0 then
                if Physics.Overlaps(proj, enemy) then
                    local Combat = require("systems/combat")
                    Combat.DamageEnemy(shared, enemy, proj.damage, 3, proj.vx > 0)
                    proj.alive = false
                    return
                end
            end
        end
        -- Hit boss
        if shared.boss and shared.boss.alive then
            if Physics.Overlaps(proj, shared.boss) then
                local Combat = require("systems/combat")
                Combat.DamageBoss(shared, proj.damage, 2, proj.vx > 0)
                proj.alive = false
                return
            end
        end
    else
        -- Hit player
        local p = shared.player
        if p.alive and p.invTimer <= 0 then
            if Physics.Overlaps(proj, p) then
                local Player = require("entities/player")
                local dir = proj.vx > 0 and 1 or -1
                Player.TakeDamage(p, proj.damage, shared, dir)
                proj.alive = false
                return
            end
        end
    end

    -- Despawn after 5 seconds
    if proj.lifetime > 5 then
        proj.alive = false
    end
end

function Projectile.UpdateAll(shared, dt)
    local TS = Config.TILE_SIZE
    for i = 1, _poolSize do
        local proj = _pool[i]
        if proj.alive then
            updateProjectile(proj, shared, dt, TS)
        end
    end
end

-- Pre-packed colors for projectile parts
local _cArrowShaft = Color.New(180, 160, 120)
local _cArrowHead = Color.New(140, 140, 140)
local _cMagicGlow = Color.New(120, 60, 255, 180)
local _cMagicCore = Color.New(200, 150, 255)
local _cBullet = Color.New(220, 200, 50)
local _cBulletTrail = Color.New(255, 240, 150, 120)

local _abs = math.abs
local _floor = math.floor

function Projectile.DrawAll(shared)
    -- Lazy init pixel sprite
    if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

    local b = shared.camBounds
    local R = _DR

    for i = 1, _poolSize do
        local proj = _pool[i]
        if proj.alive then
            local sx = _floor(proj.x)
            local sy = _floor(proj.y)

            -- Viewport culling (world-space, 8px margin)
            if proj.x + 8 < b.x or proj.x - 8 > b.x + b.w
            or proj.y + 8 < b.y or proj.y - 8 > b.y + b.h then
                -- skip
            elseif proj.type == "arrow" then
                -- Orient arrow along velocity
                local avx, avy = _abs(proj.vx), _abs(proj.vy)
                if avy > avx then
                    -- More vertical
                    R(_ps, sx, sy, 2, 6, _cArrowShaft)
                    local headY = proj.vy > 0 and sy + 5 or sy - 3
                    R(_ps, sx - 1, headY, 4, 2, _cArrowHead)
                else
                    -- More horizontal
                    R(_ps, sx, sy, 6, 2, _cArrowShaft)
                    local headX = proj.vx > 0 and sx + 5 or sx - 3
                    R(_ps, headX, sy - 1, 2, 4, _cArrowHead)
                end
            elseif proj.type == "magic" then
                R(_ps, sx - 1, sy - 1, 6, 6, _cMagicGlow)
                R(_ps, sx, sy, 4, 4, _cMagicCore)
            elseif proj.type == "bullet" then
                -- Orient bullet along velocity
                local avx, avy = _abs(proj.vx), _abs(proj.vy)
                if avy > avx then
                    -- More vertical
                    local trailDir = proj.vy > 0 and -4 or 2
                    R(_ps, sx, sy + trailDir, 2, 4, _cBulletTrail)
                    R(_ps, sx, sy, 2, 3, _cBullet)
                else
                    -- More horizontal
                    local trailDir = proj.vx > 0 and -4 or 2
                    R(_ps, sx + trailDir, sy, 4, 2, _cBulletTrail)
                    R(_ps, sx, sy, 3, 2, _cBullet)
                end
            end
        end
    end
end

return Projectile
