-- ============================================
-- Terraria2D — Enemies
-- Slime, Zombie, Skeleton AI + physics
-- ============================================

local Config = require("core/config")
local Physics = require("systems/physics")
local Camera = require("core/camera")
local UI = require("core/ui")
local Combat = require("systems/combat")
local Batch = require("core/batch")

local Enemy = {}

-- Batch state (lazy init)
local _batch = Batch.new()
local _ps -- pixel sprite id

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

    local c = def.color
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
        packedColor = Color.New(c[1], c[2], c[3]),
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
    local enemies = shared.enemies
    local n = #enemies
    local i = 1

    while i <= n do
        local e = enemies[i]
        local remove = false

        if not e.alive then
            remove = true
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

            -- Despawn if too far (avoid math.abs)
            local dx = e.x - p.x
            local dy = e.y - p.y
            local despawn = Config.DESPAWN_RANGE
            if dx > despawn or dx < -despawn or dy > despawn or dy < -despawn then
                remove = true
            end
        end

        if remove then
            enemies[i] = enemies[n]
            enemies[n] = nil
            n = n - 1
        else
            i = i + 1
        end
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

    if dx > -300 and dx < 300 then
        e.vx = (dx > 0) and e.speed or -e.speed
    else
        e.vx = 0
    end
end

function Enemy.SkeletonAI(e, p, dt)
    local dx = p.x - e.x
    local dy = p.y - e.y
    e.facingRight = dx > 0

    if dx > -300 and dx < 300 then
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

-- Pre-packed colors for enemy parts
local _cEye = Color.New(40, 40, 40)
local _cZombieHead = Color.New(80, 120, 60)
local _cZombieBody = Color.New(50, 90, 40)
local _cZombieLeg = Color.New(40, 70, 30)
local _cZombieEye = Color.New(200, 50, 50)
local _cSkelRib = Color.New(200, 200, 180)
local _cSkelWeap = Color.New(180, 180, 160)
local _cHpBg = Color.New(60, 0, 0)
local _cHpFg = Color.New(220, 40, 40)

function Enemy.DrawAll(shared)
    -- Lazy init pixel sprite
    if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

    local camX = Camera.GetX()
    local camY = Camera.GetY()
    local screenW = shared.W
    local screenH = shared.H
    local b = _batch
    local R = Batch.rect
    Batch.clear(b)

    for _, e in ipairs(shared.enemies) do
        if e.alive then
            local sx = math.floor(e.x - camX)
            local sy = math.floor(e.y - camY)
            local pc = e.packedColor

            -- Viewport culling
            if sx + e.w < 0 or sx > screenW or sy + e.h < 0 or sy > screenH then
                goto continue
            end

            -- Blink when hit
            if e.invTimer > 0 and math.floor(e.invTimer * 10) % 2 == 0 then
                goto continue
            end

            if e.type == "slime" then
                R(b, _ps, sx + 1, sy + 2, e.w - 2, e.h - 2, pc)
                R(b, _ps, sx, sy + 4, e.w, e.h - 6, pc)
                local eyeOff = e.facingRight and 2 or -2
                R(b, _ps, sx + 3 + eyeOff, sy + 3, 2, 2, _cEye)
                R(b, _ps, sx + 7 + eyeOff, sy + 3, 2, 2, _cEye)
            elseif e.type == "zombie" then
                R(b, _ps, sx + 3, sy, 6, 6, _cZombieHead)
                R(b, _ps, sx + 2, sy + 6, 8, 10, _cZombieBody)
                R(b, _ps, sx + 2, sy + 16, 3, 8, _cZombieLeg)
                R(b, _ps, sx + 7, sy + 16, 3, 8, _cZombieLeg)
                local armX = e.facingRight and (sx + 10) or (sx - 2)
                R(b, _ps, armX, sy + 7, 3, 6, _cZombieHead)
                R(b, _ps, sx + 4, sy + 2, 2, 2, _cZombieEye)
                R(b, _ps, sx + 7, sy + 2, 2, 2, _cZombieEye)
            elseif e.type == "skeleton" then
                R(b, _ps, sx + 3, sy, 6, 6, pc)
                R(b, _ps, sx + 3, sy + 6, 6, 10, _cSkelRib)
                R(b, _ps, sx + 3, sy + 16, 2, 8, pc)
                R(b, _ps, sx + 7, sy + 16, 2, 8, pc)
                R(b, _ps, sx + 4, sy + 2, 2, 2, _cEye)
                R(b, _ps, sx + 7, sy + 2, 2, 2, _cEye)
                local weapX = e.facingRight and (sx + 10) or (sx - 3)
                R(b, _ps, weapX, sy + 4, 2, 14, _cSkelWeap)
            end

            -- HP bar above enemy
            if e.hp < e.maxHp then
                local barW = e.w
                R(b, _ps, sx, sy - 5, barW, 2, _cHpBg)
                local fill = math.max(0, e.hp / e.maxHp)
                R(b, _ps, sx, sy - 5, math.floor(barW * fill), 2, _cHpFg)
            end

            ::continue::
        end
    end

    Batch.flush(b)
end

return Enemy
