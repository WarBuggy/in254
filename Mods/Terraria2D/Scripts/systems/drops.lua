-- ============================================
-- Terraria2D — Item Drops
-- Dropped items, pickup magnetism
-- ============================================

local Config = require("core/config")
local Camera = require("core/camera")
local Tiles = require("world/tiles")
local Physics = require("systems/physics")
local UI = require("core/ui")

local Drops = {}

function Drops.Spawn(shared, itemId, count, x, y)
    local drop = {
        x = x - 3,
        y = y,
        w = 6,
        h = 6,
        vx = math.random(-50, 50),
        vy = Config.DROP_VEL,
        itemId = itemId,
        count = count,
        lifetime = 0,
        onGround = false,
    }
    table.insert(shared.drops, drop)
end

function Drops.UpdateAll(shared, dt)
    local p = shared.player
    local inv = shared.inventory
    local Inventory = require("systems/inventory")
    local toRemove = {}

    for i, drop in ipairs(shared.drops) do
        drop.lifetime = drop.lifetime + dt

        -- Gravity and movement
        Physics.ApplyGravity(drop, dt)
        Physics.MoveAndCollide(drop, dt)

        -- Friction when on ground
        if drop.onGround then
            drop.vx = drop.vx * 0.9
        end

        -- Magnet toward player if close
        if p.alive then
            local dx = (p.x + p.w / 2) - (drop.x + drop.w / 2)
            local dy = (p.y + p.h / 2) - (drop.y + drop.h / 2)
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < Config.PICKUP_RANGE then
                -- Pick up
                local remaining = Inventory.Add(inv, drop.itemId, drop.count)
                if remaining < drop.count then
                    drop.count = remaining
                    if drop.count <= 0 then
                        table.insert(toRemove, i)
                    end
                end
            elseif dist < Config.PICKUP_MAGNET then
                -- Magnet pull
                local speed = 200
                drop.vx = (dx / dist) * speed
                drop.vy = (dy / dist) * speed
            end
        end

        -- Despawn after 60 seconds
        if drop.lifetime > 60 then
            table.insert(toRemove, i)
        end
    end

    -- Remove collected drops (reverse order)
    for i = #toRemove, 1, -1 do
        table.remove(shared.drops, toRemove[i])
    end
end

function Drops.DrawAll(shared)
    local camX = Camera.GetX()
    local camY = Camera.GetY()

    for _, drop in ipairs(shared.drops) do
        local sx = math.floor(drop.x - camX)
        local sy = math.floor(drop.y - camY)
        local color = Tiles.GetItemColor(drop.itemId)

        -- Floating bob
        sy = sy + math.floor(math.sin(drop.lifetime * 3) * 2)

        -- Item rectangle
        UI.Rect(sx, sy, drop.w, drop.h, color)
        -- Outline
        UI.Rect(sx - 1, sy - 1, drop.w + 2, 1, {255, 255, 255, 80})
    end
end

return Drops
