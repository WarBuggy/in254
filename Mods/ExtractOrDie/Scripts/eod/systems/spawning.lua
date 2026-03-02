-- ============================================
-- ExtractOrDie — Spawning System
-- Enemy spawning, extraction swarm
-- ============================================

local Config = require("eod/core/config")
local Physics = require("eod/systems/physics")
local Tilemap = require("eod/world/tilemap")
local Enemy = require("eod/entities/enemy")

local Spawning = {}

local floor = math.floor
local random = math.random
local sqrt = math.sqrt
local TS = Config.TILE_SIZE

-- Find a valid floor tile near a position
local function findFloorNear(cx, cy, minDist, maxDist)
    for attempt = 1, 20 do
        local angle = random() * math.pi * 2
        local dist = minDist + random() * (maxDist - minDist)
        local px = cx + math.cos(angle) * dist
        local py = cy + math.sin(angle) * dist
        local tx = floor(px / TS)
        local ty = floor(py / TS)
        if Tilemap.InBounds(tx, ty) and Tilemap.Get(tx, ty) == Config.FLOOR then
            return tx * TS + TS / 2, ty * TS + TS / 2
        end
    end
    return nil, nil
end

function Spawning.Update(shared, dt)
    if #shared.enemies >= Config.MAX_ENEMIES then return end

    -- Use faster spawn rate during extraction
    local rate = shared.extracting and Config.SPAWN_RATE_EXTRACT or Config.SPAWN_RATE
    shared.spawnTimer = shared.spawnTimer + dt
    if shared.spawnTimer < rate then return end
    shared.spawnTimer = 0

    local p = shared.player
    local sx, sy = findFloorNear(p.x, p.y, Config.SPAWN_RANGE_MIN, Config.SPAWN_RANGE_MAX)
    if not sx then return end

    -- Pick enemy type (brute is rare — only spawns if no other brute alive)
    local roll = random()
    local typeName
    if roll < 0.05 then
        -- Check if a brute already exists
        local bruteExists = false
        for _, e in ipairs(shared.enemies) do
            if e.type == "brute" and e.alive then
                bruteExists = true
                break
            end
        end
        typeName = bruteExists and "grunt" or "brute"
    elseif roll < 0.50 then
        typeName = "grunt"
    elseif roll < 0.80 then
        typeName = "shooter"
    else
        typeName = "runner"
    end

    Enemy.Spawn(shared, typeName, sx, sy)
end

return Spawning
