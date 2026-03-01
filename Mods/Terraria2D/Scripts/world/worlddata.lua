-- ============================================
-- Terraria2D — World Data
-- Flat array storage for tile data
-- ============================================

local Config = require("core/config")

local WorldData = {}

local tiles = nil
local W = Config.WORLD_W
local H = Config.WORLD_H

function WorldData.Init()
    tiles = {}
    for i = 1, W * H do
        tiles[i] = 0
    end
end

function WorldData.GetTiles()
    return tiles
end

function WorldData.SetTiles(t)
    tiles = t
end

function WorldData.InBounds(x, y)
    return x >= 0 and x < W and y >= 0 and y < H
end

function WorldData.GetIndex(x, y)
    return y * W + x + 1
end

function WorldData.Get(x, y)
    if not WorldData.InBounds(x, y) then return 0 end
    return tiles[y * W + x + 1] or 0
end

function WorldData.Set(x, y, id)
    if not WorldData.InBounds(x, y) then return end
    tiles[y * W + x + 1] = id
end

-- Cache tile data table for IsSolid (avoid require() per call)
local _tileData = nil
local function getTileData()
    if not _tileData then
        _tileData = require("world/tiles").data
    end
    return _tileData
end

function WorldData.IsSolid(x, y)
    if not WorldData.InBounds(x, y) then
        return y >= H
    end
    local id = tiles[y * W + x + 1] or 0
    local d = getTileData()[id]
    return d and d.solid
end

function WorldData.GetWidth() return W end
function WorldData.GetHeight() return H end

return WorldData
