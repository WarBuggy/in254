-- ============================================
-- Terraria2D — Combat System
-- Damage, knockback, invincibility
-- ============================================

local Config = require("core/config")
local Physics = require("systems/physics")

local Combat = {}

-- Melee swing: check all enemies in attack box
function Combat.MeleeSwing(shared, attackBox, damage, knockback, facingRight)
    local Particles = require("entities/particles")

    -- Hit enemies
    for i, enemy in ipairs(shared.enemies) do
        if enemy.alive and enemy.invTimer <= 0 then
            if Physics.Overlaps(attackBox, enemy) then
                Combat.DamageEnemy(shared, enemy, damage, knockback, facingRight)
            end
        end
    end

    -- Hit boss
    if shared.boss and shared.boss.alive and shared.boss.invTimer <= 0 then
        if Physics.Overlaps(attackBox, shared.boss) then
            Combat.DamageBoss(shared, damage, knockback, facingRight)
        end
    end
end

function Combat.DamageEnemy(shared, enemy, damage, knockback, fromRight)
    enemy.hp = enemy.hp - damage
    enemy.invTimer = 0.3

    -- Knockback
    local dir = fromRight and 1 or -1
    enemy.vx = dir * (knockback or Config.KNOCKBACK)
    enemy.vy = -100

    -- Damage number
    local Particles = require("entities/particles")
    Particles.DamageNumber(shared, enemy.x + enemy.w / 2, enemy.y, damage, {255, 255, 100})

    if enemy.hp <= 0 then
        enemy.alive = false
        -- Drop loot
        local Drops = require("systems/drops")
        if enemy.drops then
            for _, drop in ipairs(enemy.drops) do
                if math.random() < (drop.chance or 1.0) then
                    Drops.Spawn(shared, drop.id, drop.count or 1, enemy.x + enemy.w / 2, enemy.y)
                end
            end
        end
        -- Particles
        Particles.BlockBreak(shared, enemy.x + enemy.w / 2, enemy.y + enemy.h / 2, enemy.color or {200, 50, 50})
    end
end

function Combat.DamageBoss(shared, damage, knockback, fromRight)
    local boss = shared.boss
    boss.hp = boss.hp - damage
    boss.invTimer = 0.2

    local Particles = require("entities/particles")
    Particles.DamageNumber(shared, boss.x + boss.w / 2, boss.y, damage, {255, 200, 50})

    if boss.hp <= 0 then
        boss.alive = false
        -- Boss death drops
        local Drops = require("systems/drops")
        Drops.Spawn(shared, "diamond", 5, boss.x + boss.w / 2, boss.y)
        Drops.Spawn(shared, "gold_bar", 10, boss.x + boss.w / 2, boss.y + 10)
        Particles.BlockBreak(shared, boss.x + boss.w / 2, boss.y + boss.h / 2, {220, 40, 40})
    end
end

-- Check enemy-player collisions
function Combat.CheckEnemyCollisions(shared)
    local p = shared.player
    if not p.alive or p.invTimer > 0 then return end
    local Player = require("entities/player")

    for _, enemy in ipairs(shared.enemies) do
        if enemy.alive and Physics.Overlaps(p, enemy) then
            local dir = (p.x + p.w / 2) > (enemy.x + enemy.w / 2) and 1 or -1
            Player.TakeDamage(p, enemy.damage, shared, dir)
            break
        end
    end

    -- Boss collision
    if shared.boss and shared.boss.alive and Physics.Overlaps(p, shared.boss) then
        local dir = (p.x + p.w / 2) > (shared.boss.x + shared.boss.w / 2) and 1 or -1
        Player.TakeDamage(p, 25, shared, dir)
    end
end

return Combat
