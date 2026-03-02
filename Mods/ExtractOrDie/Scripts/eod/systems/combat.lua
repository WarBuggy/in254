-- ============================================
-- ExtractOrDie — Combat System
-- Damage, knockback, enemy contact damage
-- ============================================

local Config = require("eod/core/config")
local Physics = require("eod/systems/physics")

local Combat = {}

function Combat.DamageEnemy(shared, enemy, damage, knockDirX, knockDirY)
    enemy.hp = enemy.hp - damage
    enemy.invTimer = 0.2

    -- Knockback in direction of hit
    if knockDirX and knockDirY then
        local len = math.sqrt(knockDirX * knockDirX + knockDirY * knockDirY)
        if len > 0 then
            enemy.vx = (knockDirX / len) * Config.KNOCKBACK
            enemy.vy = (knockDirY / len) * Config.KNOCKBACK
        end
    end

    -- Damage number
    local Particles = require("eod/entities/particles")
    Particles.DamageNumber(shared, enemy.x + enemy.w / 2, enemy.y, damage, {255, 255, 100})

    if enemy.hp <= 0 then
        enemy.alive = false
        -- Drop loot
        if enemy.drops then
            for _, drop in ipairs(enemy.drops) do
                if math.random() < (drop.chance or 1.0) then
                    local dx = math.random(-20, 20)
                    local dy = math.random(-20, 20)
                    table.insert(shared.drops, {
                        x = enemy.x + enemy.w / 2 + dx - 3,
                        y = enemy.y + enemy.h / 2 + dy - 3,
                        w = 6, h = 6,
                        vx = 0, vy = 0,
                        itemId = drop.id,
                        count = drop.count or 1,
                        lifetime = 0,
                    })
                end
            end
        end
        -- Death burst
        Particles.DeathBurst(shared, enemy.x + enemy.w / 2, enemy.y + enemy.h / 2, enemy.color)
    end
end

-- Check enemy contact damage on player
function Combat.CheckEnemyCollisions(shared)
    local p = shared.player
    if not p.alive or p.invTimer > 0 then return end

    for _, enemy in ipairs(shared.enemies) do
        if enemy.alive and Physics.Overlaps(p, enemy) then
            local Player = require("eod/entities/player")
            local dx = (p.x + p.w / 2) - (enemy.x + enemy.w / 2)
            local dy = (p.y + p.h / 2) - (enemy.y + enemy.h / 2)
            Player.TakeDamage(p, enemy.damage, shared, dx, dy)
            break
        end
    end
end

return Combat
