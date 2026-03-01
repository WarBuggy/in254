-- ============================================
-- Terraria2D — Enemies
-- Slime, Zombie, Skeleton AI + physics
-- ============================================

local Config = require("core/config")
local Physics = require("systems/physics")
local Camera = require("core/camera")
local UI = require("core/ui")
local Combat = require("systems/combat")

local Enemy = {}

-- Enemy type definitions
Enemy.types = {
    slime = {
        hp = 20, damage = 6, speed = 40, w = 12, h = 10,
        color = {80, 200, 80},
        jumpTimer = 1.5,
        drops = {{ id = "cobblestone", count = 2, chance = 0.5 }},
    },
    zombie = {
        hp = 40, damage = 14, speed = 50, w = 12, h = 24,
        color = {60, 120, 60},
        drops = {
            { id = "iron_ore", count = 1, chance = 0.3 },
            { id = "coal", count = 2, chance = 0.4 },
        },
    },
    skeleton = {
        hp = 50, damage = 18, speed = 60, w = 12, h = 24,
        color = {220, 220, 200},
        drops = {
            { id = "iron_ore", count = 2, chance = 0.4 },
            { id = "arrow", count = 5, chance = 0.3 },
            { id = "gold_ore", count = 1, chance = 0.15 },
        },
    },
}

function Enemy.Spawn(shared, typeName, x, y)
    local def = Enemy.types[typeName]
    if not def then return end

    local e = {
        type = typeName,
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        w = def.w,
        h = def.h,
        hp = def.hp,
        maxHp = def.hp,
        damage = def.damage,
        speed = def.speed,
        color = def.color,
        drops = def.drops,
        alive = true,
        invTimer = 0,
        onGround = false,
        aiTimer = 0,
        jumpTimer = def.jumpTimer or 0,
        jumpCooldown = 0,
        facingRight = true,
    }
    table.insert(shared.enemies, e)
end

function Enemy.UpdateAll(shared, dt)
    local p = shared.player
    local toRemove = {}

    for i, e in ipairs(shared.enemies) do
        if not e.alive then
            table.insert(toRemove, i)
        else
            -- Invincibility
            if e.invTimer > 0 then
                e.invTimer = e.invTimer - dt
            end

            -- AI based on type
            if e.type == "slime" then
                Enemy.SlimeAI(e, p, dt)
            elseif e.type == "zombie" then
                Enemy.WalkAI(e, p, dt)
            elseif e.type == "skeleton" then
                Enemy.SkeletonAI(e, p, dt)
            end

            -- Physics
            Physics.ApplyGravity(e, dt)
            Physics.MoveAndCollide(e, dt)

            -- Despawn if too far
            local dx = math.abs(e.x - p.x)
            local dy = math.abs(e.y - p.y)
            if dx > Config.DESPAWN_RANGE or dy > Config.DESPAWN_RANGE then
                table.insert(toRemove, i)
            end
        end
    end

    -- Remove dead/despawned
    for i = #toRemove, 1, -1 do
        table.remove(shared.enemies, toRemove[i])
    end

    -- Check collisions with player
    Combat.CheckEnemyCollisions(shared)
end

function Enemy.SlimeAI(e, p, dt)
    e.aiTimer = e.aiTimer + dt

    -- Hop toward player periodically
    e.jumpCooldown = e.jumpCooldown - dt
    if e.jumpCooldown <= 0 and e.onGround then
        e.jumpCooldown = e.jumpTimer + math.random() * 0.5

        local dx = p.x - e.x
        e.facingRight = dx > 0
        e.vx = (dx > 0) and e.speed or -e.speed
        e.vy = -200
        e.onGround = false
    end

    -- Stop horizontal movement when on ground
    if e.onGround then
        e.vx = e.vx * 0.8
    end
end

function Enemy.WalkAI(e, p, dt)
    local dx = p.x - e.x
    e.facingRight = dx > 0

    if math.abs(dx) < 300 then
        e.vx = (dx > 0) and e.speed or -e.speed
    else
        e.vx = 0
    end
end

function Enemy.SkeletonAI(e, p, dt)
    local dx = p.x - e.x
    local dy = p.y - e.y
    e.facingRight = dx > 0

    if math.abs(dx) < 300 then
        e.vx = (dx > 0) and e.speed or -e.speed

        -- Jump if player is above and we're on ground
        e.jumpCooldown = e.jumpCooldown - dt
        if dy < -20 and e.onGround and e.jumpCooldown <= 0 then
            e.vy = -250
            e.onGround = false
            e.jumpCooldown = 2.0
        end
    else
        e.vx = 0
    end
end

function Enemy.DrawAll(shared)
    local camX = Camera.GetX()
    local camY = Camera.GetY()

    for _, e in ipairs(shared.enemies) do
        if e.alive then
            local sx = math.floor(e.x - camX)
            local sy = math.floor(e.y - camY)

            -- Blink when hit
            if e.invTimer > 0 and math.floor(e.invTimer * 10) % 2 == 0 then
                goto continue
            end

            if e.type == "slime" then
                -- Slime: rounded body
                UI.Rect(sx + 1, sy + 2, e.w - 2, e.h - 2, e.color)
                UI.Rect(sx, sy + 4, e.w, e.h - 6, e.color)
                -- Eyes
                local eyeOff = e.facingRight and 2 or -2
                UI.Rect(sx + 3 + eyeOff, sy + 3, 2, 2, {40, 40, 40})
                UI.Rect(sx + 7 + eyeOff, sy + 3, 2, 2, {40, 40, 40})
            elseif e.type == "zombie" then
                -- Zombie humanoid
                UI.Rect(sx + 3, sy, 6, 6, {80, 120, 60})       -- head
                UI.Rect(sx + 2, sy + 6, 8, 10, {50, 90, 40})   -- body
                UI.Rect(sx + 2, sy + 16, 3, 8, {40, 70, 30})   -- legs
                UI.Rect(sx + 7, sy + 16, 3, 8, {40, 70, 30})
                -- Arms reaching out
                local armX = e.facingRight and (sx + 10) or (sx - 2)
                UI.Rect(armX, sy + 7, 3, 6, {80, 120, 60})
                -- Eyes
                UI.Rect(sx + 4, sy + 2, 2, 2, {200, 50, 50})
                UI.Rect(sx + 7, sy + 2, 2, 2, {200, 50, 50})
            elseif e.type == "skeleton" then
                -- Skeleton humanoid
                UI.Rect(sx + 3, sy, 6, 6, e.color)             -- skull
                UI.Rect(sx + 3, sy + 6, 6, 10, {200, 200, 180})-- ribcage
                UI.Rect(sx + 3, sy + 16, 2, 8, e.color)        -- legs
                UI.Rect(sx + 7, sy + 16, 2, 8, e.color)
                -- Eye sockets
                UI.Rect(sx + 4, sy + 2, 2, 2, {40, 40, 40})
                UI.Rect(sx + 7, sy + 2, 2, 2, {40, 40, 40})
                -- Weapon
                local weapX = e.facingRight and (sx + 10) or (sx - 3)
                UI.Rect(weapX, sy + 4, 2, 14, {180, 180, 160})
            end

            -- HP bar above enemy
            if e.hp < e.maxHp then
                local barW = e.w
                local barH = 2
                UI.Rect(sx, sy - 5, barW, barH, {60, 0, 0})
                local fill = math.max(0, e.hp / e.maxHp)
                UI.Rect(sx, sy - 5, math.floor(barW * fill), barH, {220, 40, 40})
            end

            ::continue::
        end
    end
end

return Enemy
