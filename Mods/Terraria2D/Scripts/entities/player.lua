-- ============================================
-- Terraria2D — Player
-- Input, physics, mining, placing, combat
-- ============================================

local Config = require("core/config")
local Physics = require("systems/physics")
local Tiles = require("world/tiles")
local WorldData = require("world/worlddata")
local Camera = require("core/camera")
local UI = require("core/ui")
local HUD = require("scenes/gameplay/hud")
local Lighting = require("world/lighting")
local Batch = require("core/batch")

local Player = {}

-- Batch state (lazy init)
local _batch = Batch.new()
local _ps -- pixel sprite id

-- Item color cache (keyed by item id)
local _itemColorCache = {}
local function GetItemPackedColor(itemId)
    local cached = _itemColorCache[itemId]
    if cached then return cached end
    local c = Tiles.GetItemColor(itemId)
    cached = Color.New(c[1], c[2], c[3], c[4] or 255)
    _itemColorCache[itemId] = cached
    return cached
end

function Player.new(spawnX, spawnY)
    local TS = Config.TILE_SIZE
    return {
        x = spawnX * TS,
        y = (spawnY - 3) * TS,
        vx = 0,
        vy = 0,
        w = Config.PLAYER_W,
        h = Config.PLAYER_H,
        onGround = false,
        facingRight = true,
        hp = Config.PLAYER_HP,
        maxHp = Config.PLAYER_HP,
        mana = Config.PLAYER_MANA,
        maxMana = Config.PLAYER_MANA,
        invTimer = 0,
        attackTimer = 0,
        alive = true,
        manaRegenTimer = 0,
    }
end

function Player.Update(p, dt, shared)
    if not p.alive then return end

    -- Invincibility timer
    if p.invTimer > 0 then
        p.invTimer = p.invTimer - dt
    end

    -- Attack cooldown
    if p.attackTimer > 0 then
        p.attackTimer = p.attackTimer - dt
    end

    -- Mana regen
    p.manaRegenTimer = p.manaRegenTimer + dt
    if p.manaRegenTimer >= 1.0 then
        p.manaRegenTimer = p.manaRegenTimer - 1.0
        if p.mana < p.maxMana then
            p.mana = math.min(p.mana + 2, p.maxMana)
        end
    end

    -- Horizontal movement
    p.vx = 0
    if Input.IsKeyDown("a") then
        p.vx = -Config.PLAYER_SPEED
        p.facingRight = false
    end
    if Input.IsKeyDown("d") then
        p.vx = Config.PLAYER_SPEED
        p.facingRight = true
    end

    -- Jump
    if Input.IsKeyPressed("space") and p.onGround then
        p.vy = Config.JUMP_VEL
        p.onGround = false
    end

    -- Gravity
    Physics.ApplyGravity(p, dt)

    -- Move and collide
    Physics.MoveAndCollide(p, dt)

    -- Mining (left click hold)
    Player.HandleMining(p, dt, shared)

    -- Placing (right click)
    Player.HandlePlacing(p, shared)

    -- Attack (left click, if holding weapon)
    Player.HandleAttack(p, dt, shared)

    -- Hotbar keys (wrapped by input.lua, zero crossings)
    local numKey = Input.GetNumberKeyPressed()
    if numKey >= 0 then
        shared.inventory.selected = numKey == 0 and 10 or numKey
    end

    -- Camera follow
    local cx = p.x + p.w / 2
    local cy = p.y + p.h / 2
    Camera.Follow(cx, cy, shared.W, shared.H)
    Camera.Update(dt)
end

function Player.HandleMining(p, dt, shared)
    if not UI.IsMouseDown() then
        shared.mineTarget = nil
        shared.mineProgress = 0
        return
    end

    -- Don't mine if UI overlay is open
    if shared.showInventory or shared.showCrafting or shared.showPause then
        return
    end

    -- Check if holding a weapon (don't mine with weapons)
    local inv = shared.inventory
    local slot = inv.slots[inv.selected]
    if slot and Tiles.IsWeapon(slot.id) then
        return
    end

    local TS = Config.TILE_SIZE
    local mx = Camera.ScreenToWorldX(UI.MouseX())
    local my = Camera.ScreenToWorldY(UI.MouseY())
    local tx = math.floor(mx / TS)
    local ty = math.floor(my / TS)

    -- Check reach distance (squared to avoid sqrt)
    local pcx = p.x + p.w * 0.5
    local pcy = p.y + p.h * 0.5
    local tcx = tx * TS + TS * 0.5
    local tcy = ty * TS + TS * 0.5
    local dx = pcx - tcx
    local dy = pcy - tcy
    local reachPx = Config.REACH_DIST * TS
    if dx * dx + dy * dy > reachPx * reachPx then
        shared.mineTarget = nil
        shared.mineProgress = 0
        return
    end

    local tileId = WorldData.Get(tx, ty)
    if tileId == Tiles.AIR then
        shared.mineTarget = nil
        shared.mineProgress = 0
        return
    end

    local data = Tiles.GetData(tileId)
    if data.hardness <= 0 and tileId ~= Tiles.TORCH then
        shared.mineTarget = nil
        shared.mineProgress = 0
        return
    end

    -- Same target?
    if shared.mineTarget and shared.mineTarget.x == tx and shared.mineTarget.y == ty then
        shared.mineProgress = shared.mineProgress + dt * Config.MINE_RATE / math.max(data.hardness, 0.1)
        if shared.mineProgress >= 1.0 then
            -- Block mined!
            WorldData.Set(tx, ty, Tiles.AIR)
            Lighting.UpdateAt(shared, tx, ty)
            Drawing.RefreshTileMap()
            HUD.RefreshMinimap()
            -- Drop item
            if data.drop then
                local Drops = require("systems/drops")
                Drops.Spawn(shared, data.drop, 1, tx * TS + TS / 2, ty * TS)
            end
            -- Particles
            local Particles = require("entities/particles")
            Particles.BlockBreak(shared, tx * TS + TS / 2, ty * TS + TS / 2, data.color)
            shared.mineTarget = nil
            shared.mineProgress = 0
        end
    else
        shared.mineTarget = { x = tx, y = ty }
        shared.mineProgress = 0
    end
end

function Player.HandlePlacing(p, shared)
    if not UI.IsRightPressed() then return end
    if shared.showInventory or shared.showCrafting or shared.showPause then return end

    local inv = shared.inventory
    local slot = inv.slots[inv.selected]
    if not slot or not Tiles.IsPlaceable(slot.id) then return end

    local TS = Config.TILE_SIZE
    local mx = Camera.ScreenToWorldX(UI.MouseX())
    local my = Camera.ScreenToWorldY(UI.MouseY())
    local tx = math.floor(mx / TS)
    local ty = math.floor(my / TS)

    -- Check reach (squared to avoid sqrt)
    local pcx = p.x + p.w * 0.5
    local pcy = p.y + p.h * 0.5
    local tcx = tx * TS + TS * 0.5
    local tcy = ty * TS + TS * 0.5
    local dx = pcx - tcx
    local dy = pcy - tcy
    local reachPx = Config.REACH_DIST * TS
    if dx * dx + dy * dy > reachPx * reachPx then return end

    -- Must be air
    if WorldData.Get(tx, ty) ~= Tiles.AIR then return end

    -- Don't place inside player
    local tileLeft = tx * TS
    local tileTop = ty * TS
    if p.x < tileLeft + TS and p.x + p.w > tileLeft and
       p.y < tileTop + TS and p.y + p.h > tileTop then
        return
    end

    -- Place tile
    local tileId = Tiles.itemToTile[slot.id]
    WorldData.Set(tx, ty, tileId)
    Lighting.UpdateAt(shared, tx, ty)
    Drawing.RefreshTileMap()
    HUD.RefreshMinimap()

    -- Consume from inventory
    local Inventory = require("systems/inventory")
    Inventory.Remove(inv, inv.selected, 1)
end

function Player.HandleAttack(p, dt, shared)
    if not UI.IsMousePressed() then return end
    if shared.showInventory or shared.showCrafting or shared.showPause then return end
    if p.attackTimer > 0 then return end

    local inv = shared.inventory
    local slot = inv.slots[inv.selected]
    if not slot or not Tiles.IsWeapon(slot.id) then return end

    local weapon = Tiles.weapons[slot.id]
    p.attackTimer = weapon.speed

    if weapon.type == "melee" then
        -- Melee attack: hit enemies in front of player
        local Combat = require("systems/combat")
        local attackBox = {
            x = p.facingRight and (p.x + p.w) or (p.x - 20),
            y = p.y - 4,
            w = 20,
            h = p.h + 8
        }
        Combat.MeleeSwing(shared, attackBox, weapon.damage, weapon.knockback, p.facingRight)
    elseif weapon.type == "ranged" then
        -- Need arrows
        local Inventory = require("systems/inventory")
        local arrowSlot = Inventory.FindItem(inv, "arrow")
        if arrowSlot then
            Inventory.Remove(inv, arrowSlot, 1)
            local Projectile = require("entities/projectile")
            local dir = p.facingRight and 1 or -1
            Projectile.Spawn(shared, p.x + p.w / 2, p.y + p.h / 3, dir * 300, 0, weapon.damage, "arrow", true)
        end
    elseif weapon.type == "magic" then
        if p.mana >= weapon.manaCost then
            p.mana = p.mana - weapon.manaCost
            local Projectile = require("entities/projectile")
            local dir = p.facingRight and 1 or -1
            Projectile.Spawn(shared, p.x + p.w / 2, p.y + p.h / 3, dir * 250, 0, weapon.damage, "magic", true)
        end
    end
end

function Player.Draw(p, shared)
    if not p.alive then return end

    -- Lazy init pixel sprite
    if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

    local camX = Camera.GetX()
    local camY = Camera.GetY()
    local sx = math.floor(p.x - camX)
    local sy = math.floor(p.y - camY)

    -- Blink when invincible
    if p.invTimer > 0 and math.floor(p.invTimer * 10) % 2 == 0 then
        return
    end

    local b = _batch
    local R = Batch.rect
    Batch.clear(b)

    -- Body (torso)
    R(b, _ps, sx + 2, sy + 6, 8, 10, Color.New(60, 120, 200))
    -- Head
    R(b, _ps, sx + 3, sy, 6, 6, Color.New(230, 190, 150))
    -- Hair
    R(b, _ps, sx + 3, sy, 6, 2, Color.New(100, 60, 20))
    -- Legs
    R(b, _ps, sx + 2, sy + 16, 3, 8, Color.New(50, 50, 150))
    R(b, _ps, sx + 7, sy + 16, 3, 8, Color.New(50, 50, 150))
    -- Arms
    if p.facingRight then
        R(b, _ps, sx + 10, sy + 7, 2, 8, Color.New(230, 190, 150))
    else
        R(b, _ps, sx, sy + 7, 2, 8, Color.New(230, 190, 150))
    end
    -- Eyes
    local eyeX = p.facingRight and (sx + 7) or (sx + 4)
    R(b, _ps, eyeX, sy + 2, 1, 2, Color.New(40, 40, 40))

    -- Draw held item
    local inv = shared.inventory
    if inv then
        local slot = inv.slots[inv.selected]
        if slot then
            local packedColor = GetItemPackedColor(slot.id)
            local ix, iy
            if Tiles.IsWeapon(slot.id) then
                if p.facingRight then ix = sx + 11 else ix = sx - 4 end
                iy = sy + 5
                R(b, _ps, ix, iy, 3, 12, packedColor)
            else
                if p.facingRight then ix = sx + 11 else ix = sx - 3 end
                iy = sy + 8
                R(b, _ps, ix, iy, 4, 4, packedColor)
            end
        end
    end

    Batch.flush(b)
end

function Player.TakeDamage(p, damage, shared, knockDir)
    if p.invTimer > 0 or not p.alive then return end

    p.hp = p.hp - damage
    p.invTimer = Config.INVINCIBILITY_TIME

    -- Knockback
    if knockDir then
        p.vx = knockDir * Config.KNOCKBACK
        p.vy = -150
    end

    -- Damage number
    local Particles = require("entities/particles")
    Particles.DamageNumber(shared, p.x + p.w / 2, p.y, damage, {255, 80, 80})

    if p.hp <= 0 then
        p.hp = 0
        p.alive = false
        shared.respawnTimer = Config.RESPAWN_TIME
    end
end

function Player.Respawn(p, shared)
    local TS = Config.TILE_SIZE
    p.x = shared.spawnX * TS
    p.y = (shared.spawnY - 3) * TS
    p.vx = 0
    p.vy = 0
    p.hp = p.maxHp
    p.mana = p.maxMana
    p.alive = true
    p.invTimer = 2.0
end

return Player
