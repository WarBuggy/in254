-- ============================================
-- ExtractOrDie — Loot Crates
-- Breakable containers that drop items
-- ============================================

local Config = require("eod/core/config")
local UI = require("eod/core/ui")

local LootCrate = {}

local _DR = Drawing.Rect
local _ps -- pixel sprite id
local TS = Config.TILE_SIZE

-- Cached colors
local _cCrate  = Color.New(160, 120, 50)
local _cBand   = Color.New(120, 90, 30)
local _cDamaged = Color.New(180, 100, 40)
local _cHpBg   = Color.New(60, 40, 0)
local _cHpFg   = Color.New(200, 160, 50)

function LootCrate.New(tileX, tileY)
    return {
        x = tileX * TS + 1,
        y = tileY * TS + 1,
        w = TS - 2,
        h = TS - 2,
        hp = Config.CRATE_HP,
        maxHp = Config.CRATE_HP,
        alive = true,
    }
end

function LootCrate.SpawnAll(shared, positions)
    shared.crates = {}
    for _, pos in ipairs(positions) do
        table.insert(shared.crates, LootCrate.New(pos.x, pos.y))
    end
end

-- Roll loot from crate loot table
local function rollLoot()
    local table_ = Config.CRATE_LOOT
    local totalWeight = 0
    for _, entry in ipairs(table_) do
        totalWeight = totalWeight + entry.weight
    end

    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, entry in ipairs(table_) do
        cumulative = cumulative + entry.weight
        if roll <= cumulative then
            return entry.id, 1
        end
    end
    return table_[1].id, 1
end

function LootCrate.Damage(crate, damage, shared)
    if not crate.alive then return end
    crate.hp = crate.hp - damage
    if crate.hp <= 0 then
        crate.alive = false
        -- Drop loot
        local itemId, count = rollLoot()
        table.insert(shared.drops, {
            x = crate.x + crate.w / 2 - 3,
            y = crate.y + crate.h / 2 - 3,
            w = 6, h = 6,
            vx = 0, vy = 0,
            itemId = itemId,
            count = count,
            lifetime = 0,
        })
        -- Maybe a second drop
        if math.random() < 0.3 then
            local itemId2, count2 = rollLoot()
            table.insert(shared.drops, {
                x = crate.x + crate.w / 2 - 3 + math.random(-8, 8),
                y = crate.y + crate.h / 2 - 3 + math.random(-8, 8),
                w = 6, h = 6,
                vx = 0, vy = 0,
                itemId = itemId2,
                count = count2,
                lifetime = 0,
            })
        end
        -- Break particles
        local Particles = require("eod/entities/particles")
        Particles.DeathBurst(shared, crate.x + crate.w / 2, crate.y + crate.h / 2, {160, 120, 50})
    end
end

function LootCrate.DrawAll(shared)
    if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

    local b = shared.camBounds
    if not b then return end
    local R = _DR

    for _, crate in ipairs(shared.crates) do
        if crate.alive then
            -- Viewport culling
            local inView = not (crate.x + crate.w < b.x or crate.x > b.x + b.w
                or crate.y + crate.h < b.y or crate.y > b.y + b.h)

            if inView then
                local sx = math.floor(crate.x)
                local sy = math.floor(crate.y)
                local color = crate.hp < crate.maxHp and _cDamaged or _cCrate

                R(_ps, sx, sy, crate.w, crate.h, color)
                -- Metal band
                R(_ps, sx, sy + math.floor(crate.h / 2) - 1, crate.w, 2, _cBand)

                -- HP bar if damaged
                if crate.hp < crate.maxHp then
                    R(_ps, sx, sy - 4, crate.w, 2, _cHpBg)
                    local fill = math.max(0, crate.hp / crate.maxHp)
                    R(_ps, sx, sy - 4, math.floor(crate.w * fill), 2, _cHpFg)
                end
            end
        end
    end
end

return LootCrate
