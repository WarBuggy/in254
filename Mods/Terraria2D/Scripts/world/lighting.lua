-- ============================================
-- Terraria2D — Lighting (Native Buffer)
-- Sunlight columns + emitters + 4-dir sweep
-- All heavy compute runs in C# via NativeBuffer
-- ============================================

local Config = require("core/config")
local Tiles = require("world/tiles")
local WorldData = require("world/worlddata")

local Lighting = {}

local floor = math.floor
local ceil = math.ceil
local max = math.max
local min = math.min

-- Native buffer handles
local _lightH   -- lightMap buffer (W*H ints, 0-indexed: buf[y*W+x])
local _tileH    -- mirror of Lua tiles array
local _solidH   -- lookup by tile ID → 1=solid, 0=not
local _emitH    -- lookup by tile ID → emission level
local _inited = false

local function initNative()
    if _inited then return end
    _inited = true

    local W = Config.WORLD_W
    local H = Config.WORLD_H

    -- Create buffers
    _lightH = NativeBuffer.Create(W * H)
    _tileH  = NativeBuffer.Create(W * H)

    -- Sync tiles from Lua to C# (one-time)
    local tiles = WorldData.GetTiles()
    NativeBuffer.SyncFromTable(_tileH, tiles, W * H)

    -- Build solid/emit lookup buffers from tile definitions
    local maxId = 0
    for id, _ in pairs(Tiles.data) do
        if id > maxId then maxId = id end
    end

    _solidH = NativeBuffer.Create(maxId + 1)
    _emitH  = NativeBuffer.Create(maxId + 1)
    for id, data in pairs(Tiles.data) do
        NativeBuffer.Set(_solidH, id, (data.solid and 1 or 0))
        NativeBuffer.Set(_emitH, id, (data.light or 0))
    end

    -- Tell tile renderer to read overlay from native buffer
    Drawing.SetNativeOverlayBuffer(_lightH)
end

-- ============================================
-- Notify tile change (call after WorldData.Set)
-- Keeps native tile buffer in sync
-- ============================================
function Lighting.NotifyTileChanged(x, y, newId)
    if not _inited then return end
    NativeBuffer.Set(_tileH, y * Config.WORLD_W + x, newId)
end

-- ============================================
-- Full recalculation (initial + day/night)
-- ============================================
function Lighting.Calculate(shared)
    initNative()

    local Camera = require("core/camera")
    local W = Config.WORLD_W
    local H = Config.WORLD_H
    local maxLight = Config.MAX_LIGHT

    -- Mirror the tile renderer's alignment logic so lighting covers
    -- every tile the renderer could display, plus maxLight propagation
    local TS = Config.TILE_SIZE
    local tileMargin = 20  -- must match TileRendererManager._tileMargin
    local camTX = floor(Camera.GetX() / TS)
    local camTY = floor(Camera.GetY() / TS)
    local alignedTX = floor(camTX / tileMargin) * tileMargin
    local alignedTY = floor(camTY / tileMargin) * tileMargin
    local viewW = (shared.W or 0) > 0 and ceil(shared.W / TS) + 2 or W
    local viewH = (shared.H or 0) > 0 and ceil(shared.H / TS) + 2 or H

    local startX = max(0, alignedTX - tileMargin - maxLight)
    local endX = min(W - 1, alignedTX + viewW + tileMargin + maxLight + 2)
    local startY = max(0, alignedTY - tileMargin - maxLight)
    local endY = min(H - 1, alignedTY + viewH + tileMargin + maxLight + 2)

    -- Clear previous viewport region
    local prevSX = shared._lightStartX or startX
    local prevSY = shared._lightStartY or startY
    local prevEX = shared._lightEndX or endX
    local prevEY = shared._lightEndY or endY
    NativeBuffer.FillRect(_lightH, W, prevSX, prevSY, prevEX, prevEY, 0)

    -- Also clear new region (in case it extends beyond previous)
    NativeBuffer.FillRect(_lightH, W, startX, startY, endX, endY, 0)

    shared._lightStartX = startX
    shared._lightStartY = startY
    shared._lightEndX = endX
    shared._lightEndY = endY

    -- Column decay: propagate sky light downward, decay=2 through solids, write reduced=val-1 at solid
    local skyLight = shared.isNight and 7 or maxLight
    NativeBuffer.ColumnDecay(_lightH, _tileH, _solidH, W, H, startX, endX, startY, endY, skyLight, 2, 1)

    -- Scatter emitter values from tile ID lookup
    NativeBuffer.ScatterLookup(_lightH, _tileH, _emitH, W, startX, endX, startY, endY)

    -- 4-directional SIMD sweep relaxation
    -- Need maxLight passes for full propagation (each pass spreads light 1 tile per direction)
    NativeBuffer.SweepMax(_lightH, W, H, startX, endX, startY, endY, 1, maxLight)

    Drawing.RefreshTileColors()
end

-- ============================================
-- Incremental update (tile mine/place)
-- Only recalculates a local region around the
-- changed tile instead of the full viewport.
-- ============================================
function Lighting.UpdateAt(shared, tx, ty)
    if not _inited then return end

    local W = Config.WORLD_W
    local H = Config.WORLD_H
    local maxLight = Config.MAX_LIGHT
    local radius = maxLight

    local x0 = max(0, tx - radius)
    local x1 = min(W - 1, tx + radius)
    local y0 = max(0, ty - radius)
    local y1 = min(H - 1, ty + radius)

    -- Clear local region
    NativeBuffer.FillRect(_lightH, W, x0, y0, x1, y1, 0)

    -- Column decay + scatter emitters
    local skyLight = shared.isNight and 7 or maxLight
    NativeBuffer.ColumnDecay(_lightH, _tileH, _solidH, W, H, x0, x1, y0, y1, skyLight, 2, 1)
    NativeBuffer.ScatterLookup(_lightH, _tileH, _emitH, W, x0, x1, y0, y1)

    -- Sweep relaxation — need maxLight passes for full propagation
    NativeBuffer.SweepMax(_lightH, W, H, x0, x1, y0, y1, 1, maxLight)

    Drawing.RefreshTileColors()
end

return Lighting
