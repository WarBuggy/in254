-- ============================================
-- Terraria2D — Boss: The Watcher
-- Phase 1: dash + mini-eyes, Phase 2: faster + spin
-- ============================================

local Config = require("core/config")
local Physics = require("systems/physics")
local Camera = require("core/camera")
local UI = require("core/ui")
local Enemy = require("entities/enemy")

local Boss = {}

function Boss.Spawn(shared)
    local p = shared.player
    shared.boss = {
        name = "The Watcher",
        x = p.x + 200,
        y = p.y - 100,
        vx = 0,
        vy = 0,
        w = Config.BOSS_SIZE,
        h = Config.BOSS_SIZE,
        hp = Config.BOSS_HP,
        maxHp = Config.BOSS_HP,
        alive = true,
        invTimer = 0,
        phase = 1,
        dashTimer = 3,
        spawnTimer = 5,
        spinAngle = 0,
        spinning = false,
        spinTimer = 0,
        pupilX = 0,
        pupilY = 0,
        onGround = false,
    }
end

function Boss.Update(shared, dt)
    local boss = shared.boss
    if not boss or not boss.alive then return end

    local p = shared.player

    -- Invincibility
    if boss.invTimer > 0 then
        boss.invTimer = boss.invTimer - dt
    end

    -- Phase check
    if boss.hp <= boss.maxHp / 2 then
        boss.phase = 2
    end

    -- Track pupil toward player
    local dx = (p.x + p.w / 2) - (boss.x + boss.w / 2)
    local dy = (p.y + p.h / 2) - (boss.y + boss.h / 2)
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
        boss.pupilX = (dx / dist) * 6
        boss.pupilY = (dy / dist) * 6
    end

    -- Float toward player (gentle)
    local targetY = p.y - 60
    local floatSpeed = boss.phase == 2 and 80 or 50
    boss.vy = (targetY - boss.y) * 0.5
    if math.abs(boss.vy) > floatSpeed then
        boss.vy = floatSpeed * (boss.vy > 0 and 1 or -1)
    end

    local targetX = p.x + (dx > 0 and -80 or 80)
    boss.vx = (targetX - boss.x) * 0.3
    if math.abs(boss.vx) > floatSpeed then
        boss.vx = floatSpeed * (boss.vx > 0 and 1 or -1)
    end

    -- Dash attack
    boss.dashTimer = boss.dashTimer - dt
    local dashInterval = boss.phase == 2 and 2 or 3
    if boss.dashTimer <= 0 then
        boss.dashTimer = dashInterval
        -- Dash toward player
        if dist > 0 then
            local speed = boss.phase == 2 and 400 or 300
            boss.vx = (dx / dist) * speed
            boss.vy = (dy / dist) * speed
        end
    end

    -- Phase 1: Spawn mini-eyes
    if boss.phase == 1 then
        boss.spawnTimer = boss.spawnTimer - dt
        if boss.spawnTimer <= 0 then
            boss.spawnTimer = 5
            -- Spawn 2 mini slimes as "eyes"
            Enemy.Spawn(shared, "slime", boss.x, boss.y + boss.h)
            Enemy.Spawn(shared, "slime", boss.x + boss.w, boss.y + boss.h)
        end
    end

    -- Phase 2: Spin attack
    if boss.phase == 2 then
        boss.spinTimer = boss.spinTimer - dt
        if boss.spinTimer <= 0 and not boss.spinning then
            boss.spinning = true
            boss.spinTimer = 3
            boss.spinAngle = 0
        end
        if boss.spinning then
            boss.spinAngle = boss.spinAngle + dt * 720
            if boss.spinAngle >= 360 then
                boss.spinning = false
                boss.spinAngle = 0
            end
        end
    end

    -- Move boss
    boss.x = boss.x + boss.vx * dt
    boss.y = boss.y + boss.vy * dt

    -- Clamp to world
    boss.x = math.max(0, math.min(boss.x, Config.WORLD_PX_W - boss.w))
    boss.y = math.max(0, math.min(boss.y, Config.WORLD_PX_H - boss.h))

    -- Collision with player
    local Combat = require("systems/combat")
    Combat.CheckEnemyCollisions(shared)
end

function Boss.Draw(shared)
    local boss = shared.boss
    if not boss or not boss.alive then return end

    local sx = math.floor(boss.x)
    local sy = math.floor(boss.y)

    -- Viewport culling (world-space, 40px margin for spin orbs)
    local margin = 40
    local b = shared.camBounds
    if boss.x + boss.w + margin < b.x or boss.x - margin > b.x + b.w or
       boss.y + boss.h + margin < b.y or boss.y - margin > b.y + b.h then
        return
    end

    -- Blink
    if boss.invTimer > 0 and math.floor(boss.invTimer * 10) % 2 == 0 then
        return
    end

    -- Main body (large red rectangle)
    local bodyColor = boss.phase == 2 and {180, 20, 20} or {200, 40, 40}
    UI.Rect(sx, sy, boss.w, boss.h, bodyColor)

    -- Eye white
    local eyeSize = 16
    local eyeX = sx + boss.w / 2 - eyeSize / 2
    local eyeY = sy + boss.h / 2 - eyeSize / 2
    UI.Rect(eyeX, eyeY, eyeSize, eyeSize, {240, 240, 240})

    -- Pupil
    local pupilSize = 6
    local px = eyeX + eyeSize / 2 - pupilSize / 2 + boss.pupilX
    local py = eyeY + eyeSize / 2 - pupilSize / 2 + boss.pupilY
    UI.Rect(px, py, pupilSize, pupilSize, {20, 20, 20})

    -- Phase 2: red glow border
    if boss.phase == 2 then
        UI.Rect(sx - 2, sy - 2, boss.w + 4, 2, {255, 60, 60, 150})
        UI.Rect(sx - 2, sy + boss.h, boss.w + 4, 2, {255, 60, 60, 150})
        UI.Rect(sx - 2, sy, 2, boss.h, {255, 60, 60, 150})
        UI.Rect(sx + boss.w, sy, 2, boss.h, {255, 60, 60, 150})
    end

    -- Spin effect (rotating indicators)
    if boss.spinning then
        local angle = math.rad(boss.spinAngle)
        local radius = boss.w * 0.8
        for i = 0, 3 do
            local a = angle + i * math.pi / 2
            local ox = math.cos(a) * radius
            local oy = math.sin(a) * radius
            UI.Rect(sx + boss.w / 2 + ox - 3, sy + boss.h / 2 + oy - 3, 6, 6, {255, 100, 100, 200})
        end
    end
end

return Boss
