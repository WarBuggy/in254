-- ============================================
-- Terraria2D — Projectiles
-- Arrows, magic bolts
-- ============================================

local Config = require("core/config")
local WorldData = require("world/worlddata")
local Camera = require("core/camera")
local Physics = require("systems/physics")
local UI = require("core/ui")
local Batch = require("core/batch")

local Projectile = {}

-- Batch state (lazy init)
local _batch = Batch.new()
local _ps -- pixel sprite id

function Projectile.Spawn(shared, x, y, vx, vy, damage, projType, friendly)
    local proj = {
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        w = 4,
        h = 4,
        damage = damage,
        type = projType,
        friendly = friendly,
        lifetime = 0,
        alive = true,
    }
    table.insert(shared.projectiles, proj)
end

function Projectile.UpdateAll(shared, dt)
    local TS = Config.TILE_SIZE
    local toRemove = {}

    for i, proj in ipairs(shared.projectiles) do
        if not proj.alive then
            table.insert(toRemove, i)
        else
            proj.lifetime = proj.lifetime + dt

            -- Apply gravity to arrows
            if proj.type == "arrow" then
                proj.vy = proj.vy + 200 * dt
            end

            -- Move
            proj.x = proj.x + proj.vx * dt
            proj.y = proj.y + proj.vy * dt

            -- Check tile collision
            local tx = math.floor(proj.x / TS)
            local ty = math.floor(proj.y / TS)
            if WorldData.IsSolid(tx, ty) then
                proj.alive = false
                table.insert(toRemove, i)
                goto continue
            end

            -- Check entity collision
            if proj.friendly then
                -- Hit enemies
                for _, enemy in ipairs(shared.enemies) do
                    if enemy.alive and enemy.invTimer <= 0 then
                        if Physics.Overlaps(proj, enemy) then
                            local Combat = require("systems/combat")
                            local fromRight = proj.vx > 0
                            Combat.DamageEnemy(shared, enemy, proj.damage, 3, fromRight)
                            proj.alive = false
                            table.insert(toRemove, i)
                            break
                        end
                    end
                end
                -- Hit boss
                if proj.alive and shared.boss and shared.boss.alive then
                    if Physics.Overlaps(proj, shared.boss) then
                        local Combat = require("systems/combat")
                        Combat.DamageBoss(shared, proj.damage, 2, proj.vx > 0)
                        proj.alive = false
                        table.insert(toRemove, i)
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
                        table.insert(toRemove, i)
                    end
                end
            end

            -- Despawn after 5 seconds
            if proj.lifetime > 5 then
                proj.alive = false
                table.insert(toRemove, i)
            end

            ::continue::
        end
    end

    for i = #toRemove, 1, -1 do
        table.remove(shared.projectiles, toRemove[i])
    end
end

-- Pre-packed colors for projectile parts
local _cArrowShaft = Color.New(180, 160, 120)
local _cArrowHead = Color.New(140, 140, 140)
local _cMagicGlow = Color.New(120, 60, 255, 180)
local _cMagicCore = Color.New(200, 150, 255)

function Projectile.DrawAll(shared)
    -- Lazy init pixel sprite
    if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

    local camX = Camera.GetX()
    local camY = Camera.GetY()
    local screenW = shared.W
    local screenH = shared.H
    local b = _batch
    local R = Batch.rect
    Batch.clear(b)

    for _, proj in ipairs(shared.projectiles) do
        if proj.alive then
            local sx = math.floor(proj.x - camX)
            local sy = math.floor(proj.y - camY)

            -- Viewport culling (8px margin for projectile sizes)
            if sx + 8 < 0 or sx - 8 > screenW or sy + 8 < 0 or sy - 8 > screenH then
                goto continue
            end

            if proj.type == "arrow" then
                R(b, _ps, sx, sy, 6, 2, _cArrowShaft)
                R(b, _ps, sx + 5, sy - 1, 2, 4, _cArrowHead)
            elseif proj.type == "magic" then
                R(b, _ps, sx - 1, sy - 1, 6, 6, _cMagicGlow)
                R(b, _ps, sx, sy, 4, 4, _cMagicCore)
            end

            ::continue::
        end
    end

    Batch.flush(b)
end

return Projectile
