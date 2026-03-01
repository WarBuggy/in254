-- ============================================
-- Terraria2D — Lighting
-- Sunlight columns + torch BFS (optimized)
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

-- Pre-allocated BFS queue arrays (avoids per-node table allocation)
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

-- Direction offsets (pre-allocated, not per-iteration)
local DX = { 0, 0, -1, 1 }
local DY = { -1, 1, 0, 0 }

function Lighting.Calculate(shared)
    local W = Config.WORLD_W
    local H = Config.WORLD_H
    local maxLight = Config.MAX_LIGHT
    local tileData = Tiles.data
    local tiles = WorldData.GetTiles()

    -- Reuse or create light map
    local lightMap = shared.lightMap
    if not lightMap then
        lightMap = {}
        for i = 1, W * H do
            lightMap[i] = 0
        end
    else
        -- Clear only the viewport region (faster than full clear)
        local prevStartX = shared._lightStartX or 0
        local prevEndX = shared._lightEndX or (W - 1)
        local prevEndY = shared._lightEndY or (H - 1)
        for y = 0, prevEndY do
            local base = y * W
            for x = prevStartX, prevEndX do
                lightMap[base + x + 1] = 0
            end
        end
    end

    -- Only calculate around camera for performance
    local camTX = floor((shared.camX or 0) / Config.TILE_SIZE)
    local camTY = floor((shared.camY or 0) / Config.TILE_SIZE)
    local viewW = ceil(shared.W / Config.TILE_SIZE) + 2
    local viewH = ceil(shared.H / Config.TILE_SIZE) + 2
    local margin = 20

    local startX = max(0, camTX - margin)
    local endX = min(W - 1, camTX + viewW + margin)
    local startY = max(0, camTY - margin)
    local endY = min(H - 1, camTY + viewH + margin)

    -- Store bounds for next clear
    shared._lightStartX = startX
    shared._lightEndX = endX
    shared._lightEndY = endY

    -- Pass 1: Sunlight - scan columns from top (direct array access)
    local skyLight = shared.isNight and 7 or maxLight

    for x = startX, endX do
        local light = skyLight
        for y = 0, endY do
            local idx = y * W + x + 1
            local tileId = tiles[idx] or 0
            local data = tileData[tileId] or tileData[0]

            if tileId == 0 or (not data.solid) then
                local cur = lightMap[idx]
                if light > cur then lightMap[idx] = light end
            else
                local reduced = light - 1
                if reduced < 0 then reduced = 0 end
                local cur = lightMap[idx]
                if reduced > cur then lightMap[idx] = reduced end
                light = light - 2
                if light < 0 then light = 0 end
            end
        end
    end

    -- Pass 2: Collect light-emitting tiles into flat queue
    local head = 1
    local tail = 0

    for y = startY, endY do
        local base = y * W
        for x = startX, endX do
            local tileId = tiles[base + x + 1] or 0
            local data = tileData[tileId]
            if data and data.light > 0 then
                tail = tail + 1
                _queueX[tail] = x
                _queueY[tail] = y
                _queueL[tail] = data.light
            end
        end
    end

    -- Ensure queue arrays are large enough
    local estimatedSize = tail + (endX - startX + 1) * (endY - startY + 1)
    ensureQueueCapacity(estimatedSize)

    -- BFS flood fill with index-based circular queue (O(1) dequeue)
    while head <= tail do
        local x = _queueX[head]
        local y = _queueY[head]
        local light = _queueL[head]
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
                        _queueX[tail] = nx
                        _queueY[tail] = ny
                        _queueL[tail] = nextLight
                    end
                end
            end
        end
    end

    shared.lightMap = lightMap

    -- Pre-compute lit colors for the viewport (avoids per-tile math in draw)
    local colorCache = shared.colorCache
    if not colorCache then
        colorCache = {}
        shared.colorCache = colorCache
    end

    local invMax = 1 / maxLight
    for y = startY, endY do
        local base = y * W
        for x = startX, endX do
            local idx = base + x + 1
            local tileId = tiles[idx] or 0
            if tileId ~= 0 then
                local data = tileData[tileId] or tileData[0]
                local color = data.color
                local light = lightMap[idx] or 0
                local lf = light * invMax
                -- Store as packed r,g,b,a (reuse table if exists)
                local cached = colorCache[idx]
                if not cached then
                    cached = { 0, 0, 0, 255 }
                    colorCache[idx] = cached
                end
                cached[1] = floor(color[1] * lf)
                cached[2] = floor(color[2] * lf)
                cached[3] = floor(color[3] * lf)
                cached[4] = color[4] or 255
            else
                colorCache[idx] = nil
            end
        end
    end

    -- Store camera position for next calculation
    local Camera = require("core/camera")
    shared.camX = Camera.GetX()
    shared.camY = Camera.GetY()

    Drawing.RefreshTileMap()
end

return Lighting
