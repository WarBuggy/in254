-- ============================================
-- Terraria2D — World Generation
-- Procedural terrain, caves, ores, trees, biomes
-- ============================================

local Config = require("core/config")
local Tiles = require("world/tiles")
local WorldData = require("world/worlddata")

local WorldGen = {}

-- Simple noise-like height variation
local function heightAt(x)
    local base = Config.SURFACE_Y
    -- Layered sine waves for terrain variation
    local h = base
    h = h + math.sin(x * 0.05) * 6
    h = h + math.sin(x * 0.12 + 3) * 3
    h = h + math.sin(x * 0.02 + 7) * 8

    -- Biome adjustments
    if x >= Config.BIOME_DESERT and x < Config.BIOME_DESERT + 100 then
        -- Desert: flatter, slightly lower
        h = base + math.sin(x * 0.03) * 2
    elseif x >= 300 then
        -- Mountain: higher terrain
        h = h - 10 - math.sin(x * 0.04) * 5
    end

    return math.floor(h)
end

-- Get biome at x position
local function biomeAt(x)
    if x < Config.BIOME_FOREST then return "forest"
    elseif x < Config.BIOME_PLAINS then return "plains"
    elseif x < Config.BIOME_DESERT then return "desert"
    else return "mountain" end
end

-- Place a tree at position
local function placeTree(x, surfaceY)
    local W = Config.WORLD_W
    local trunkH = 4 + math.random(0, 3)

    -- Trunk
    for ty = surfaceY - trunkH, surfaceY - 1 do
        if WorldData.InBounds(x, ty) then
            WorldData.Set(x, ty, Tiles.WOOD)
        end
    end

    -- Canopy (leaves)
    local topY = surfaceY - trunkH
    for ly = topY - 3, topY do
        local radius = 3 - (topY - ly)
        if radius < 1 then radius = 1 end
        for lx = x - radius, x + radius do
            if WorldData.InBounds(lx, ly) then
                local existing = WorldData.Get(lx, ly)
                if existing == Tiles.AIR then
                    WorldData.Set(lx, ly, Tiles.LEAVES)
                end
            end
        end
    end
end

-- Generate cave via random walk
local function carveCave(startX, startY, length)
    local cx, cy = startX, startY
    for i = 1, length do
        local radius = math.random(1, 3)
        for dy = -radius, radius do
            for dx = -radius, radius do
                if dx * dx + dy * dy <= radius * radius then
                    local tx, ty = cx + dx, cy + dy
                    if WorldData.InBounds(tx, ty) and ty > Config.SURFACE_Y + 5 then
                        local existing = WorldData.Get(tx, ty)
                        if existing ~= Tiles.OBSIDIAN then
                            WorldData.Set(tx, ty, Tiles.AIR)
                        end
                    end
                end
            end
        end
        -- Random walk
        cx = cx + math.random(-2, 2)
        cy = cy + math.random(-1, 2)
        cx = math.max(1, math.min(cx, Config.WORLD_W - 2))
        cy = math.max(Config.SURFACE_Y + 5, math.min(cy, Config.WORLD_H - 5))
    end
end

-- Place ore vein
local function placeOre(centerX, centerY, oreId, size)
    for i = 1, size do
        local ox = centerX + math.random(-2, 2)
        local oy = centerY + math.random(-2, 2)
        if WorldData.InBounds(ox, oy) then
            local existing = WorldData.Get(ox, oy)
            if existing == Tiles.STONE or existing == Tiles.DIRT then
                WorldData.Set(ox, oy, oreId)
            end
        end
    end
end

function WorldGen.Generate()
    WorldData.Init()

    local W = Config.WORLD_W
    local H = Config.WORLD_H
    local surfaceMap = {}

    -- Pass 1: Fill terrain
    for x = 0, W - 1 do
        local surfY = heightAt(x)
        surfaceMap[x] = surfY
        local biome = biomeAt(x)

        for y = 0, H - 1 do
            if y < surfY then
                -- Sky
                WorldData.Set(x, y, Tiles.AIR)
            elseif y == surfY then
                -- Surface block
                if biome == "desert" then
                    WorldData.Set(x, y, Tiles.SAND)
                else
                    WorldData.Set(x, y, Tiles.GRASS)
                end
            elseif y < surfY + Config.DIRT_DEPTH then
                -- Dirt layer
                if biome == "desert" then
                    WorldData.Set(x, y, Tiles.SAND)
                else
                    WorldData.Set(x, y, Tiles.DIRT)
                end
            elseif y >= Config.OBSIDIAN_Y then
                -- Obsidian bottom
                WorldData.Set(x, y, Tiles.OBSIDIAN)
            else
                -- Stone
                WorldData.Set(x, y, Tiles.STONE)
            end
        end
    end

    -- Pass 2: Caves
    local numCaves = 40
    for i = 1, numCaves do
        local cx = math.random(10, W - 10)
        local cy = math.random(Config.SURFACE_Y + 10, H - 20)
        local length = math.random(30, 80)
        carveCave(cx, cy, length)
    end

    -- Pass 3: Ores
    -- Coal (shallow)
    for i = 1, 60 do
        local ox = math.random(0, W - 1)
        local oy = math.random(Config.SURFACE_Y + 5, Config.SURFACE_Y + 60)
        placeOre(ox, oy, Tiles.COAL, math.random(3, 8))
    end

    -- Copper (shallow-mid)
    for i = 1, 50 do
        local ox = math.random(0, W - 1)
        local oy = math.random(Config.SURFACE_Y + 10, Config.SURFACE_Y + 80)
        placeOre(ox, oy, Tiles.COPPER_ORE, math.random(3, 7))
    end

    -- Iron (mid)
    for i = 1, 40 do
        local ox = math.random(0, W - 1)
        local oy = math.random(Config.SURFACE_Y + 30, H - 30)
        placeOre(ox, oy, Tiles.IRON_ORE, math.random(3, 6))
    end

    -- Gold (deep)
    for i = 1, 25 do
        local ox = math.random(0, W - 1)
        local oy = math.random(Config.SURFACE_Y + 60, H - 20)
        placeOre(ox, oy, Tiles.GOLD_ORE, math.random(2, 5))
    end

    -- Diamond (very deep)
    for i = 1, 15 do
        local ox = math.random(0, W - 1)
        local oy = math.random(H - 40, H - 10)
        placeOre(ox, oy, Tiles.DIAMOND, math.random(1, 3))
    end

    -- Pass 4: Trees (forest & plains only)
    for x = 5, W - 5 do
        local biome = biomeAt(x)
        local surfY = surfaceMap[x]
        if (biome == "forest" or biome == "plains") and surfY and surfY > 5 then
            local chance = 0
            if biome == "forest" then chance = 0.12
            elseif biome == "plains" then chance = 0.04
            end
            if math.random() < chance then
                -- Check flat ground
                local leftY = surfaceMap[x - 1]
                local rightY = surfaceMap[x + 1]
                if leftY and rightY and math.abs(leftY - surfY) <= 1 and math.abs(rightY - surfY) <= 1 then
                    placeTree(x, surfY)
                end
            end
        end
    end

    -- Find spawn point (middle of world, on surface)
    local spawnX = math.floor(W / 2)
    local spawnY = surfaceMap[spawnX] or Config.SURFACE_Y

    -- Clear a small area around spawn
    for dx = -2, 2 do
        for dy = -4, -1 do
            local sx = spawnX + dx
            local sy = spawnY + dy
            if WorldData.InBounds(sx, sy) then
                WorldData.Set(sx, sy, Tiles.AIR)
            end
        end
    end

    return spawnX, spawnY
end

return WorldGen
