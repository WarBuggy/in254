-- ============================================
-- ExtractOrDie — Projectiles
-- Object pool, no gravity (top-down)
-- ============================================

local Config = require("eod/core/config")
local Tilemap = require("eod/world/tilemap")
local Physics = require("eod/systems/physics")
local UI = require("eod/core/ui")

local Projectile = {}

local _DR = Drawing.Rect
local _ps -- pixel sprite id

-- Object pool
local _pool = {}
local _poolSize = 0

local floor = math.floor
local TS = Config.TILE_SIZE

local function acquireProjectile()
    for i = 1, _poolSize do
        if not _pool[i].alive then
            return _pool[i]
        end
    end
    _poolSize = _poolSize + 1
    local proj = { x = 0, y = 0, vx = 0, vy = 0, w = 3, h = 3,
                   damage = 0, friendly = true, lifetime = 0, alive = false }
    _pool[_poolSize] = proj
    return proj
end

function Projectile.Spawn(shared, x, y, vx, vy, damage, friendly)
    local proj = acquireProjectile()
    proj.x = x - 1.5
    proj.y = y - 1.5
    proj.vx = vx
    proj.vy = vy
    proj.w = 3
    proj.h = 3
    proj.damage = damage
    proj.friendly = friendly
    proj.lifetime = 0
    proj.alive = true
end

-- Cached projectile colors
local _cFriendly = Color.New(255, 240, 100)
local _cEnemy    = Color.New(255, 80, 80)
local _cTrail    = Color.New(255, 255, 200, 100)

local function updateProjectile(proj, shared, dt)
    proj.lifetime = proj.lifetime + dt

    -- No gravity (top-down)
    proj.x = proj.x + proj.vx * dt
    proj.y = proj.y + proj.vy * dt

    -- Out of map bounds
    if proj.x < -32 or proj.x > Config.MAP_PX_W + 32 or
       proj.y < -32 or proj.y > Config.MAP_PX_H + 32 then
        proj.alive = false
        return
    end

    -- Tile collision
    local tx = floor((proj.x + 1.5) / TS)
    local ty = floor((proj.y + 1.5) / TS)
    if Tilemap.IsSolid(tx, ty) then
        proj.alive = false
        -- Spark particle
        local Particles = require("eod/entities/particles")
        Particles.Spark(shared, proj.x + 1.5, proj.y + 1.5)
        return
    end

    -- Entity collision
    if proj.friendly then
        -- Hit enemies
        for _, enemy in ipairs(shared.enemies) do
            if enemy.alive and enemy.invTimer <= 0 then
                if Physics.Overlaps(proj, enemy) then
                    local Combat = require("eod/systems/combat")
                    Combat.DamageEnemy(shared, enemy, proj.damage, proj.vx, proj.vy)
                    proj.alive = false
                    return
                end
            end
        end
        -- Hit crates
        for _, crate in ipairs(shared.crates) do
            if crate.alive and Physics.Overlaps(proj, crate) then
                local LootCrate = require("eod/entities/lootcrate")
                LootCrate.Damage(crate, proj.damage, shared)
                proj.alive = false
                return
            end
        end
    else
        -- Hit player
        local p = shared.player
        if p.alive and p.invTimer <= 0 then
            if Physics.Overlaps(proj, p) then
                local Player = require("eod/entities/player")
                Player.TakeDamage(p, proj.damage, shared, proj.vx, proj.vy)
                proj.alive = false
                return
            end
        end
    end

    -- Despawn after 3 seconds
    if proj.lifetime > 3 then
        proj.alive = false
    end
end

function Projectile.UpdateAll(shared, dt)
    for i = 1, _poolSize do
        local proj = _pool[i]
        if proj.alive then
            updateProjectile(proj, shared, dt)
        end
    end
end

function Projectile.DrawAll(shared)
    if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

    local b = shared.camBounds
    if not b then return end
    local R = _DR

    for i = 1, _poolSize do
        local proj = _pool[i]
        if proj.alive then
            local sx = floor(proj.x)
            local sy = floor(proj.y)

            -- Viewport culling
            if proj.x + 6 < b.x or proj.x - 3 > b.x + b.w
            or proj.y + 6 < b.y or proj.y - 3 > b.y + b.h then
                -- skip
            else
                local color = proj.friendly and _cFriendly or _cEnemy
                R(_ps, sx, sy, 3, 3, color)
            end
        end
    end
end

-- Reset pool between raids
function Projectile.Reset()
    for i = 1, _poolSize do
        _pool[i].alive = false
    end
end

return Projectile
