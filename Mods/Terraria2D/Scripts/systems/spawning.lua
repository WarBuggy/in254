-- ============================================
-- Terraria2D — Spawning System
-- Enemy spawn by depth/time-of-day
-- ============================================

local Config = require("core/config")
local WorldData = require("world/worlddata")
local Enemy = require("entities/enemy")

local Spawning = {}

local spawnTimer = 0

function Spawning.Update(shared, dt)
    if #shared.enemies >= Config.MAX_ENEMIES then return end

    spawnTimer = spawnTimer + dt
    if spawnTimer < Config.SPAWN_RATE then return end
    spawnTimer = 0

    local p = shared.player
    local TS = Config.TILE_SIZE
    local playerTX = math.floor(p.x / TS)
    local playerTY = math.floor(p.y / TS)

    -- Pick random position around player
    local side = math.random() > 0.5 and 1 or -1
    local dist = math.random(20, 40)
    local spawnTX = playerTX + side * dist
    local spawnTY = playerTY + math.random(-10, 10)

    -- Clamp
    spawnTX = math.max(2, math.min(spawnTX, Config.WORLD_W - 2))
    spawnTY = math.max(2, math.min(spawnTY, Config.WORLD_H - 2))

    -- Find surface (scan down to find air above solid)
    local foundY = nil
    for y = math.max(0, spawnTY - 20), math.min(Config.WORLD_H - 1, spawnTY + 20) do
        if WorldData.Get(spawnTX, y) == 0 and WorldData.IsSolid(spawnTX, y + 1) then
            foundY = y
            break
        end
    end
    if not foundY then return end

    -- Determine what to spawn based on depth and time
    local isUnderground = foundY > Config.SURFACE_Y + 10
    local typeName

    if isUnderground then
        -- Underground: skeletons
        typeName = "skeleton"
    elseif shared.isNight then
        -- Surface night: zombies
        typeName = math.random() > 0.4 and "zombie" or "slime"
    else
        -- Surface day: slimes (less frequent)
        if math.random() > 0.6 then
            typeName = "slime"
        else
            return -- No spawn
        end
    end

    Enemy.Spawn(shared, typeName, spawnTX * TS, foundY * TS - 24)
end

return Spawning
