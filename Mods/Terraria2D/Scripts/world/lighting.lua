-- ============================================
-- Terraria2D — Lighting
-- Sunlight columns + torch BFS (incremental)
-- Color computation moved to C# DrawManager
-- ============================================

local Config = require("core/config")
local Tiles = require("world/tiles")
local WorldData = require("world/worlddata")

local Lighting = {}

-- Localize for hot-path performance
local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min

-- Pre-allocated BFS queue arrays
local _queueX = {}
local _queueY = {}
local _queueL = {}
local _queueCap = 0

local function ensureQueueCapacity(n)
    if _queueCap >= n then return end
    for i = _queueCap + 1, n do
        _queueX[i] = 0
        _queueY[i] = 0
        _queueL[i] = 0
    end
    _queueCap = n
end

-- Direction offsets
local DX = { 0, 0, -1, 1 }
local DY = { -1, 1, 0, 0 }

-- Pre-built flat lookups (indexed by tile ID, avoids field access per tile)
local _solidLookup = nil
local _lightLookup = nil

local function buildLookups()
    if _solidLookup then return end
    local tileData = Tiles.data
    _solidLookup = {}
    _lightLookup = {}
    for id, data in pairs(tileData) do
        _solidLookup[id] = data.solid or false
        _lightLookup[id] = data.light or 0
    end
end

-- ============================================
-- Sunlight column scan with culling
-- Splits into two phases:
--   1a) Above viewport: only track attenuation (no writes)
--   1b) In viewport: write lightMap + collect emitters
-- ============================================
local function sunlightPass(tiles, solid, emit, lightMap, W,
                            startX, endX, startY, endY, skyLight,
                            queueX, queueY, queueL, tail)
    for x = startX, endX do
        local light = skyLight

        -- Phase 1a: above viewport — just track sunlight attenuation
        for y = 0, startY - 1 do
            local tileId = tiles[y * W + x + 1] or 0
            if solid[tileId] then
                light = light - 2
                if light <= 0 then light = 0; break end
            end
        end

        -- Phase 1b: in viewport — write lightMap + collect emitters
        for y = startY, endY do
            local idx = y * W + x + 1
            local tileId = tiles[idx] or 0

            if tileId == 0 or not solid[tileId] then
                if light > lightMap[idx] then lightMap[idx] = light end
            else
                local reduced = light - 1
                if reduced < 0 then reduced = 0 end
                if reduced > lightMap[idx] then lightMap[idx] = reduced end
                light = light - 2
                if light < 0 then light = 0 end
            end

            -- Collect emitters
            if (emit[tileId] or 0) > 0 then
                tail = tail + 1
                queueX[tail] = x
                queueY[tail] = y
                queueL[tail] = emit[tileId]
            end
        end
    end
    return tail
end

-- ============================================
-- BFS flood fill (shared by Calculate + UpdateAt)
-- ============================================
local function bfsFloodFill(lightMap, W, H, queueX, queueY, queueL, head, tail)
    while head <= tail do
        local x = queueX[head]
        local y = queueY[head]
        local light = queueL[head]
        head = head + 1

        local idx = y * W + x + 1
        if light > lightMap[idx] then
            lightMap[idx] = light
        end

        local nextLight = light - 1
        if nextLight > 0 then
            for d = 1, 4 do
                local nx = x + DX[d]
                local ny = y + DY[d]
                if nx >= 0 and nx < W and ny >= 0 and ny < H then
                    local nidx = ny * W + nx + 1
                    if nextLight > (lightMap[nidx] or 0) then
                        tail = tail + 1
                        queueX[tail] = nx
                        queueY[tail] = ny
                        queueL[tail] = nextLight
                    end
                end
            end
        end
    end
end

-- ============================================
-- Full recalculation (initial + day/night)
-- ============================================
function Lighting.Calculate(shared)
    buildLookups()

    local W = Config.WORLD_W
    local H = Config.WORLD_H
    local maxLight = Config.MAX_LIGHT
    local tiles = WorldData.GetTiles()
    local solid = _solidLookup
    local emit = _lightLookup

    -- Reuse or create light map
    local lightMap = shared.lightMap
    if not lightMap then
        lightMap = {}
        for i = 1, W * H do
            lightMap[i] = 0
        end
    else
        -- Clear previous viewport region
        local prevStartX = shared._lightStartX or 0
        local prevStartY = shared._lightStartY or 0
        local prevEndX = shared._lightEndX or (W - 1)
        local prevEndY = shared._lightEndY or (H - 1)
        for y = prevStartY, prevEndY do
            local base = y * W
            for x = prevStartX, prevEndX do
                lightMap[base + x + 1] = 0
            end
        end
    end

    -- Viewport bounds
    local camTX = floor((shared.camX or 0) / Config.TILE_SIZE)
    local camTY = floor((shared.camY or 0) / Config.TILE_SIZE)
    local viewW = (shared.W or 0) > 0 and ceil(shared.W / Config.TILE_SIZE) + 2 or Config.WORLD_W
    local viewH = (shared.H or 0) > 0 and ceil(shared.H / Config.TILE_SIZE) + 2 or Config.WORLD_H
    local margin = 20

    local startX = max(0, camTX - margin)
    local endX = min(W - 1, camTX + viewW + margin)
    local startY = max(0, camTY - margin)
    local endY = min(H - 1, camTY + viewH + margin)

    shared._lightStartX = startX
    shared._lightStartY = startY
    shared._lightEndX = endX
    shared._lightEndY = endY

    -- Sunlight + emitter collection (culled)
    local skyLight = shared.isNight and 7 or maxLight
    local tail = sunlightPass(tiles, solid, emit, lightMap, W,
        startX, endX, startY, endY, skyLight,
        _queueX, _queueY, _queueL, 0)

    -- BFS flood fill
    ensureQueueCapacity(tail + (endX - startX + 1) * (endY - startY + 1))
    bfsFloodFill(lightMap, W, H, _queueX, _queueY, _queueL, 1, tail)

    shared.lightMap = lightMap

    -- Store camera position for next calculation
    local Camera = require("core/camera")
    shared.camX = Camera.GetX()
    shared.camY = Camera.GetY()

    Drawing.RefreshTileColors()
end

-- ============================================
-- Incremental update (tile mine/place)
-- Only recalculates a local region around the
-- changed tile instead of the full viewport.
-- ============================================
function Lighting.UpdateAt(shared, tx, ty)
    buildLookups()

    local W = Config.WORLD_W
    local H = Config.WORLD_H
    local tiles = WorldData.GetTiles()
    local solid = _solidLookup
    local emit = _lightLookup
    local lightMap = shared.lightMap
    if not lightMap then return end

    local radius = Config.MAX_LIGHT
    local x0 = max(0, tx - radius)
    local x1 = min(W - 1, tx + radius)
    local y0 = max(0, ty - radius)
    local y1 = min(H - 1, ty + radius)

    -- Clear local region
    for y = y0, y1 do
        local base = y * W
        for x = x0, x1 do
            lightMap[base + x + 1] = 0
        end
    end

    -- Sunlight + emitters (culled — only writes y0..y1)
    local skyLight = shared.isNight and 7 or Config.MAX_LIGHT
    local tail = sunlightPass(tiles, solid, emit, lightMap, W,
        x0, x1, y0, y1, skyLight,
        _queueX, _queueY, _queueL, 0)

    -- BFS flood fill
    ensureQueueCapacity(tail + (x1 - x0 + 1) * (y1 - y0 + 1))
    bfsFloodFill(lightMap, W, H, _queueX, _queueY, _queueL, 1, tail)

    Drawing.RefreshTileColors()
end

return Lighting
