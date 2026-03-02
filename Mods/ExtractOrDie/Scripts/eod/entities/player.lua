-- ============================================
-- ExtractOrDie — Player
-- WASD 8-directional movement, mouse aim, shooting
-- ============================================

local Config = require("eod/core/config")
local Physics = require("eod/systems/physics")
local Weapons = require("eod/systems/weapons")
local Camera = require("eod/core/camera")
local UI = require("eod/core/ui")

local Particles = require("eod/entities/particles")

local Player = {}

local _DR = Drawing.Rect
local _ps -- pixel sprite id
local DIAG = 0.7071

-- Cached colors (3/4 angled view)
local _cBody    = Color.New(60, 140, 80)
local _cBodyDk  = Color.New(45, 110, 60)
local _cSkin    = Color.New(230, 190, 150)
local _cHair    = Color.New(80, 50, 20)
local _cLegs    = Color.New(50, 80, 120)
local _cLegsDk  = Color.New(40, 65, 100)
local _cEyes    = Color.New(40, 40, 40)
local _cShadow  = Color.New(0, 0, 0, 40)
local _cDmgNum  = {255, 80, 80}

function Player.New(spawnX, spawnY, weaponId)
    return {
        x = spawnX,
        y = spawnY,
        vx = 0,
        vy = 0,
        w = Config.PLAYER_W,
        h = Config.PLAYER_H,
        hp = Config.PLAYER_HP,
        maxHp = Config.PLAYER_HP,
        alive = true,
        invTimer = 0,
        aimAngle = 0,
        weapon = Weapons.NewState(weaponId or "pistol"),
        -- Dodge roll
        dodging = false,
        dodgeTimer = 0,
        dodgeCooldown = 0,
        dodgeDirX = 0,
        dodgeDirY = 0,
    }
end

function Player.Update(p, dt, shared)
    if not p.alive then return end

    -- Invincibility
    if p.invTimer > 0 then
        p.invTimer = p.invTimer - dt
    end

    -- Dodge cooldown
    if p.dodgeCooldown > 0 then
        p.dodgeCooldown = p.dodgeCooldown - dt
    end

    -- WASD movement
    local mx, my = 0, 0
    if Input.IsKeyDown("w") then my = -1 end
    if Input.IsKeyDown("s") then my = 1 end
    if Input.IsKeyDown("a") then mx = -1 end
    if Input.IsKeyDown("d") then mx = 1 end

    -- Normalize diagonal
    if mx ~= 0 and my ~= 0 then
        mx = mx * DIAG
        my = my * DIAG
    end

    -- Dodge roll initiation (spacebar)
    if Input.IsKeyPressed("space") and not p.dodging and p.dodgeCooldown <= 0 then
        p.dodging = true
        p.dodgeTimer = Config.DODGE_DURATION
        p.invTimer = Config.DODGE_IFRAMES
        -- Dodge in movement direction, or aim direction if standing still
        if mx ~= 0 or my ~= 0 then
            p.dodgeDirX = mx
            p.dodgeDirY = my
        else
            p.dodgeDirX = math.cos(p.aimAngle)
            p.dodgeDirY = math.sin(p.aimAngle)
        end
        -- Normalize dodge direction
        local len = math.sqrt(p.dodgeDirX * p.dodgeDirX + p.dodgeDirY * p.dodgeDirY)
        if len > 0 then
            p.dodgeDirX = p.dodgeDirX / len
            p.dodgeDirY = p.dodgeDirY / len
        end
    end

    -- During dodge: override velocity
    if p.dodging then
        p.dodgeTimer = p.dodgeTimer - dt
        p.vx = p.dodgeDirX * Config.DODGE_SPEED
        p.vy = p.dodgeDirY * Config.DODGE_SPEED
        -- Ghost trail particle
        Particles.GhostTrail(shared, p.x + p.w / 2, p.y + p.h / 2)
        if p.dodgeTimer <= 0 then
            p.dodging = false
            p.dodgeCooldown = Config.DODGE_COOLDOWN
        end
    else
        p.vx = mx * Config.PLAYER_SPEED
        p.vy = my * Config.PLAYER_SPEED
    end

    -- Physics
    Physics.Update(p, dt)

    -- Mouse aim angle
    local pcx = p.x + p.w / 2
    local pcy = p.y + p.h / 2
    local worldMX = Camera.ScreenToWorldX(UI.MouseX())
    local worldMY = Camera.ScreenToWorldY(UI.MouseY())
    p.aimAngle = math.atan2(worldMY - pcy, worldMX - pcx)

    -- Weapon update
    Weapons.Update(p.weapon, dt)

    -- Skip weapon firing during dodge
    if not p.dodging then
        -- Reload
        if Input.IsKeyPressed("r") then
            Weapons.StartReload(p.weapon)
        end

        -- Shoot (left click hold for auto-fire)
        if UI.IsMouseDown() and Weapons.CanFire(p.weapon) then
            Player.Shoot(p, shared)
        end

        -- Auto-reload when empty and trying to fire
        if UI.IsMouseDown() and p.weapon.ammo <= 0 and not p.weapon.reloading then
            Weapons.StartReload(p.weapon)
        end
    end

    -- Pickup items (F key)
    if Input.IsKeyPressed("f") then
        Player.TryPickup(p, shared)
    end

    -- Camera follow
    Camera.Follow(pcx, pcy, shared.W, shared.H)
    Camera.Update(dt)
end

function Player.Shoot(p, shared)
    local def = Config.WEAPONS[p.weapon.id]
    Weapons.Fire(p.weapon)

    local Projectile = require("eod/entities/projectile")
    local pcx = p.x + p.w / 2
    local pcy = p.y + p.h / 2

    for i = 1, def.pellets do
        local spread = (math.random() - 0.5) * def.spread * 2
        local angle = p.aimAngle + spread
        local vx = math.cos(angle) * def.speed
        local vy = math.sin(angle) * def.speed
        Projectile.Spawn(shared, pcx, pcy, vx, vy, def.damage, true)
    end
end

function Player.TryPickup(p, shared)
    local Inventory = require("eod/systems/inventory")
    local drops = shared.drops
    local n = #drops

    for i = n, 1, -1 do
        local drop = drops[i]
        local dx = (p.x + p.w / 2) - (drop.x + drop.w / 2)
        local dy = (p.y + p.h / 2) - (drop.y + drop.h / 2)
        local distSq = dx * dx + dy * dy
        local range = Config.PICKUP_RANGE

        if distSq < range * range then
            -- Check if medkit — use immediately
            local lootDef = Config.LOOT_ITEMS[drop.itemId]
            if lootDef and lootDef.healAmount and p.hp < p.maxHp then
                p.hp = math.min(p.maxHp, p.hp + lootDef.healAmount)
                Particles.DamageNumber(shared, p.x + p.w / 2, p.y, "+" .. lootDef.healAmount, {80, 255, 80})
                drops[i] = drops[n]
                drops[n] = nil
                n = n - 1
            else
                local remaining = Inventory.Add(shared.backpack, drop.itemId, drop.count)
                if remaining < drop.count then
                    drop.count = remaining
                    if drop.count <= 0 then
                        drops[i] = drops[n]
                        drops[n] = nil
                        n = n - 1
                    end
                end
            end
        end
    end
end

function Player.TakeDamage(p, damage, shared, knockDirX, knockDirY)
    if p.invTimer > 0 or not p.alive then return end

    p.hp = p.hp - damage
    p.invTimer = Config.INVINCIBILITY_TIME

    -- Knockback
    if knockDirX and knockDirY then
        local len = math.sqrt(knockDirX * knockDirX + knockDirY * knockDirY)
        if len > 0 then
            p.vx = (knockDirX / len) * Config.KNOCKBACK
            p.vy = (knockDirY / len) * Config.KNOCKBACK
        end
    end

    Particles.DamageNumber(shared, p.x + p.w / 2, p.y, damage, _cDmgNum)

    if p.hp <= 0 then
        p.hp = 0
        p.alive = false
        shared.raidOver = true
        shared.raidResult = "died"
        Particles.DeathBurst(shared, p.x + p.w / 2, p.y + p.h / 2, {60, 140, 80})
    end
end

function Player.Draw(p, shared)
    if not p.alive then return end
    if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

    local sx = math.floor(p.x)
    local sy = math.floor(p.y)

    -- Blink when invincible (but not during dodge — dodge uses transparency instead)
    if p.invTimer > 0 and not p.dodging and math.floor(p.invTimer * 10) % 2 == 0 then
        return
    end

    local R = _DR

    -- Drop shadow (oval on ground)
    R(_ps, sx + 1, sy + p.h - 2, p.w - 2, 3, _cShadow)

    -- 3/4 angled view: head on top, body middle, legs bottom
    -- Legs (bottom 4px)
    R(_ps, sx + 1, sy + 10, 3, 4, _cLegs)
    R(_ps, sx + 6, sy + 10, 3, 4, _cLegs)
    -- Leg shading
    R(_ps, sx + 1, sy + 12, 3, 2, _cLegsDk)
    R(_ps, sx + 6, sy + 12, 3, 2, _cLegsDk)

    -- Body/torso (middle 6px)
    R(_ps, sx + 1, sy + 4, 8, 6, _cBody)
    R(_ps, sx + 1, sy + 8, 8, 2, _cBodyDk)

    -- Head (top 4px, skin colored)
    R(_ps, sx + 2, sy, 6, 4, _cSkin)
    -- Hair on top
    R(_ps, sx + 2, sy, 6, 1, _cHair)

    -- Eyes (direction-aware: show on the side we're facing)
    local facingRight = math.cos(p.aimAngle) >= 0
    local facingDown = math.sin(p.aimAngle) > 0.3
    if facingDown then
        -- Facing toward camera: show both eyes
        R(_ps, sx + 3, sy + 2, 1, 1, _cEyes)
        R(_ps, sx + 6, sy + 2, 1, 1, _cEyes)
    else
        -- Side/up: show one eye
        local eyeX = facingRight and (sx + 6) or (sx + 3)
        R(_ps, eyeX, sy + 2, 1, 1, _cEyes)
    end

    -- Arms extending toward aim with weapon
    if p.weapon then
        local wepDef = Config.WEAPONS[p.weapon.id]
        if wepDef then
            local c = wepDef.color
            local wepColor = Color.New(c[1], c[2], c[3])
            -- Arm position
            local armX = sx + p.w / 2 + math.cos(p.aimAngle) * 5
            local armY = sy + 5 + math.sin(p.aimAngle) * 4
            R(_ps, math.floor(armX) - 1, math.floor(armY), 2, 2, _cSkin)
            -- Weapon at arm end
            local wx = sx + p.w / 2 + math.cos(p.aimAngle) * 8
            local wy = sy + 5 + math.sin(p.aimAngle) * 5
            R(_ps, math.floor(wx) - 1, math.floor(wy) - 1, 3, 3, wepColor)
        end
    end
end

return Player
