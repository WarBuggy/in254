-- ============================================
-- ExtractOrDie — Enemies
-- Grunt/Shooter/Runner with top-down AI
-- ============================================

local Config = require("eod/core/config")
local Physics = require("eod/systems/physics")
local UI = require("eod/core/ui")
local Combat = require("eod/systems/combat")

local Enemy = {}

local _DR = Drawing.Rect
local _ps -- pixel sprite id
local TS = Config.TILE_SIZE
local floor = math.floor
local sqrt = math.sqrt
local random = math.random

-- Cached colors
local _cHpBg = Color.New(60, 0, 0)
local _cHpFg = Color.New(220, 40, 40)
local _cEyeColor = Color.New(40, 40, 40)
local _cShadow = Color.New(0, 0, 0, 40)
local _cBruteHorn = Color.New(180, 160, 120)
local _cBruteEnrage = Color.New(200, 60, 20)
local _cSlamTelegraph = Color.New(255, 80, 30, 60)

function Enemy.Spawn(shared, typeName, x, y)
    local def = Config.ENEMIES[typeName]
    if not def then return end

    local c = def.color
    local e = {
        type = typeName,
        x = x - def.w / 2,
        y = y - def.h / 2,
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
        aiTimer = 0,
        fireTimer = 0,
        strafeDir = (random() > 0.5) and 1 or -1,
        strafeTimer = 0,
    }
    -- Brute-specific state
    if typeName == "brute" then
        e.slamTimer = 0
        e.slamWindupTimer = 0
        e.slamming = false
        e.chargeTimer = 0
        e.charging = false
        e.chargeDirX = 0
        e.chargeDirY = 0
        e.chargeTimeLeft = 0
        e.enraged = false
    end

    table.insert(shared.enemies, e)
end

-- Grunt AI: walk straight at player
local function gruntAI(e, p, dt)
    local dx = (p.x + p.w / 2) - (e.x + e.w / 2)
    local dy = (p.y + p.h / 2) - (e.y + e.h / 2)
    local len = sqrt(dx * dx + dy * dy)
    if len > 1 then
        e.vx = (dx / len) * e.speed
        e.vy = (dy / len) * e.speed
    else
        e.vx = 0
        e.vy = 0
    end
end

-- Shooter AI: keep distance, strafe, fire with LOS
local function shooterAI(e, p, dt, shared)
    local def = Config.ENEMIES.shooter
    local dx = (p.x + p.w / 2) - (e.x + e.w / 2)
    local dy = (p.y + p.h / 2) - (e.y + e.h / 2)
    local len = sqrt(dx * dx + dy * dy)

    -- Movement: approach/retreat to preferred range
    local preferred = def.preferredRange
    if len > 1 then
        local nx, ny = dx / len, dy / len
        if len > preferred + 30 then
            -- Move closer
            e.vx = nx * e.speed
            e.vy = ny * e.speed
        elseif len < preferred - 30 then
            -- Retreat
            e.vx = -nx * e.speed
            e.vy = -ny * e.speed
        else
            -- Strafe perpendicular
            e.strafeTimer = e.strafeTimer + dt
            if e.strafeTimer > 2.0 then
                e.strafeDir = -e.strafeDir
                e.strafeTimer = 0
            end
            e.vx = -ny * e.speed * 0.6 * e.strafeDir
            e.vy = nx * e.speed * 0.6 * e.strafeDir
        end
    end

    -- Fire at player
    e.fireTimer = e.fireTimer - dt
    if e.fireTimer <= 0 and len < 350 then
        -- Check line of sight
        local ecx = e.x + e.w / 2
        local ecy = e.y + e.h / 2
        if Physics.HasLineOfSight(ecx, ecy, p.x + p.w / 2, p.y + p.h / 2) then
            local Projectile = require("eod/entities/projectile")
            local speed = 250
            if len > 1 then
                local vx = (dx / len) * speed
                local vy = (dy / len) * speed
                Projectile.Spawn(shared, ecx, ecy, vx, vy, def.damage, false)
            end
            e.fireTimer = def.fireRate
        end
    end
end

-- Runner AI: fast rush at player
local function runnerAI(e, p, dt)
    local dx = (p.x + p.w / 2) - (e.x + e.w / 2)
    local dy = (p.y + p.h / 2) - (e.y + e.h / 2)
    local len = sqrt(dx * dx + dy * dy)
    if len > 1 then
        e.vx = (dx / len) * e.speed
        e.vy = (dy / len) * e.speed
    else
        e.vx = 0
        e.vy = 0
    end
end

-- Brute AI: slow tank with ground slam, charge, and enrage
local function bruteAI(e, p, dt, shared)
    local def = Config.ENEMIES.brute
    local dx = (p.x + p.w / 2) - (e.x + e.w / 2)
    local dy = (p.y + p.h / 2) - (e.y + e.h / 2)
    local len = sqrt(dx * dx + dy * dy)

    -- Enrage check
    if not e.enraged and e.hp <= e.maxHp * 0.5 then
        e.enraged = true
        -- Visual feedback: burst particles
        local Particles = require("eod/entities/particles")
        Particles.DeathBurst(shared, e.x + e.w / 2, e.y + e.h / 2, {255, 100, 30})
    end

    local speedMult = e.enraged and def.enrageSpeedMult or 1.0
    local cdMult = e.enraged and def.enrageCooldownMult or 1.0

    -- Tick cooldowns
    if e.slamTimer > 0 then e.slamTimer = e.slamTimer - dt end
    if e.chargeTimer > 0 then e.chargeTimer = e.chargeTimer - dt end

    -- Currently charging: override movement
    if e.charging then
        e.chargeTimeLeft = e.chargeTimeLeft - dt
        e.vx = e.chargeDirX * def.chargeSpeed
        e.vy = e.chargeDirY * def.chargeSpeed
        if e.chargeTimeLeft <= 0 then
            e.charging = false
            e.chargeTimer = def.chargeCooldown * cdMult
        end
        return
    end

    -- Currently slamming (windup): stand still
    if e.slamming then
        e.vx = 0
        e.vy = 0
        e.slamWindupTimer = e.slamWindupTimer - dt
        if e.slamWindupTimer <= 0 then
            e.slamming = false
            e.slamTimer = def.slamCooldown * cdMult
            -- Deal AoE damage
            local pdx = (p.x + p.w / 2) - (e.x + e.w / 2)
            local pdy = (p.y + p.h / 2) - (e.y + e.h / 2)
            local pDist = sqrt(pdx * pdx + pdy * pdy)
            if pDist < def.slamRadius then
                local Player = require("eod/entities/player")
                Player.TakeDamage(p, def.slamDamage, shared, pdx, pdy)
            end
            -- Shockwave visual
            local Particles = require("eod/entities/particles")
            Particles.Shockwave(shared, e.x + e.w / 2, e.y + e.h / 2, def.slamRadius)
        end
        return
    end

    -- Try ground slam if player is close
    if e.slamTimer <= 0 and len < def.slamRange then
        e.slamming = true
        e.slamWindupTimer = def.slamWindup
        e.vx = 0
        e.vy = 0
        return
    end

    -- Try charge if player is at medium range
    if e.chargeTimer <= 0 and len > def.slamRange and len < def.chargeRange then
        if len > 1 then
            e.charging = true
            e.chargeDirX = dx / len
            e.chargeDirY = dy / len
            e.chargeTimeLeft = def.chargeDuration
        end
        return
    end

    -- Default: walk toward player
    if len > 1 then
        e.vx = (dx / len) * def.speed * speedMult
        e.vy = (dy / len) * def.speed * speedMult
    else
        e.vx = 0
        e.vy = 0
    end
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
            if e.invTimer > 0 then
                e.invTimer = e.invTimer - dt
            end

            -- AI
            if e.type == "grunt" then
                gruntAI(e, p, dt)
            elseif e.type == "shooter" then
                shooterAI(e, p, dt, shared)
            elseif e.type == "runner" then
                runnerAI(e, p, dt)
            elseif e.type == "brute" then
                bruteAI(e, p, dt, shared)
            end

            Physics.Update(e, dt)

            -- Despawn if too far (brutes get larger leash)
            local despawnDist = (e.type == "brute") and 900 or 600
            local dx = e.x - p.x
            local dy = e.y - p.y
            if dx > despawnDist or dx < -despawnDist or dy > despawnDist or dy < -despawnDist then
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

    Combat.CheckEnemyCollisions(shared)
end

function Enemy.DrawAll(shared)
    if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

    local b = shared.camBounds
    if not b then return end
    local R = _DR

    for _, e in ipairs(shared.enemies) do
        if e.alive then
            local sx = floor(e.x)
            local sy = floor(e.y)

            -- Viewport culling + blink skip
            local visible = true
            if e.x + e.w < b.x or e.x > b.x + b.w or e.y + e.h < b.y or e.y > b.y + b.h then
                visible = false
            elseif e.invTimer > 0 and floor(e.invTimer * 10) % 2 == 0 then
                visible = false
            end

            if visible then
                -- Drop shadow
                R(_ps, sx + 1, sy + e.h - 2, e.w - 2, 2, _cShadow)

                -- 3/4 angled view
                local c = e.color
                local darkColor = Color.New(
                    floor(c[1] * 0.7), floor(c[2] * 0.7), floor(c[3] * 0.7))

                if e.type == "grunt" then
                    -- Legs
                    R(_ps, sx + 1, sy + 8, 3, 4, darkColor)
                    R(_ps, sx + 6, sy + 8, 3, 4, darkColor)
                    -- Body (bulky)
                    R(_ps, sx, sy + 3, e.w, 5, e.packedColor)
                    -- Head
                    R(_ps, sx + 2, sy, 6, 4, e.packedColor)
                    -- Eyes
                    R(_ps, sx + 3, sy + 1, 1, 2, _cEyeColor)
                    R(_ps, sx + 6, sy + 1, 1, 2, _cEyeColor)
                elseif e.type == "shooter" then
                    -- Legs
                    R(_ps, sx + 2, sy + 8, 2, 4, darkColor)
                    R(_ps, sx + 6, sy + 8, 2, 4, darkColor)
                    -- Body (slim)
                    R(_ps, sx + 1, sy + 3, 8, 5, e.packedColor)
                    -- Head
                    R(_ps, sx + 2, sy, 6, 4, e.packedColor)
                    -- Visor/eyes
                    R(_ps, sx + 3, sy + 1, 4, 1, _cEyeColor)
                elseif e.type == "runner" then
                    -- Legs (small, fast)
                    R(_ps, sx + 1, sy + 7, 2, 3, darkColor)
                    R(_ps, sx + 5, sy + 7, 2, 3, darkColor)
                    -- Body (lean)
                    R(_ps, sx + 1, sy + 3, 6, 4, e.packedColor)
                    -- Head (small)
                    R(_ps, sx + 2, sy, 4, 3, e.packedColor)
                    -- Eyes
                    R(_ps, sx + 2, sy + 1, 1, 1, _cEyeColor)
                    R(_ps, sx + 5, sy + 1, 1, 1, _cEyeColor)
                elseif e.type == "brute" then
                    local bodyColor = e.enraged and _cBruteEnrage or e.packedColor
                    -- Slam telegraph: pulsing circle on ground
                    if e.slamming then
                        local def = Config.ENEMIES.brute
                        local progress = 1 - (e.slamWindupTimer / def.slamWindup)
                        local radius = floor(def.slamRadius * progress * 0.4)
                        R(_ps, sx + e.w / 2 - radius, sy + e.h / 2 - radius,
                          radius * 2, radius * 2, _cSlamTelegraph)
                    end
                    -- Large shadow
                    R(_ps, sx + 2, sy + e.h - 3, e.w - 4, 4, _cShadow)
                    -- Legs (thick, wide-set)
                    R(_ps, sx + 1, sy + 14, 4, 6, darkColor)
                    R(_ps, sx + 11, sy + 14, 4, 6, darkColor)
                    -- Body (massive torso)
                    R(_ps, sx + 1, sy + 6, 14, 8, bodyColor)
                    R(_ps, sx + 1, sy + 12, 14, 3, darkColor)
                    -- Head (wide, flat)
                    R(_ps, sx + 3, sy + 1, 10, 6, bodyColor)
                    -- Horns
                    R(_ps, sx + 1, sy, 3, 2, _cBruteHorn)
                    R(_ps, sx + 12, sy, 3, 2, _cBruteHorn)
                    -- Angry eyes (wider during charge/slam)
                    local eyeH = (e.charging or e.slamming) and 3 or 2
                    R(_ps, sx + 5, sy + 3, 2, eyeH, _cEyeColor)
                    R(_ps, sx + 9, sy + 3, 2, eyeH, _cEyeColor)
                else
                    -- Fallback
                    R(_ps, sx, sy, e.w, e.h, e.packedColor)
                end

                -- HP bar
                if e.hp < e.maxHp then
                    local barW = e.w
                    R(_ps, sx, sy - 4, barW, 2, _cHpBg)
                    local fill = math.max(0, e.hp / e.maxHp)
                    R(_ps, sx, sy - 4, floor(barW * fill), 2, _cHpFg)
                end
            end
        end
    end
end

return Enemy
