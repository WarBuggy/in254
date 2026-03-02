-- ============================================
-- ExtractOrDie — Tilemap
-- VOID/FLOOR/WALL flat array storage
-- ============================================

local Config = require("eod/core/config")

local Tilemap = {}

local tiles = nil
local W = Config.MAP_W
local H = Config.MAP_H

function Tilemap.Init()
    tiles = {}
    for i = 1, W * H do
        tiles[i] = Config.VOID
    end
    return tiles
end

function Tilemap.GetTiles() return tiles end
function Tilemap.SetTiles(t) tiles = t end

function Tilemap.InBounds(x, y)
    return x >= 0 and x < W and y >= 0 and y < H
end

function Tilemap.Get(x, y)
    if not Tilemap.InBounds(x, y) then return Config.VOID end
    return tiles[y * W + x + 1] or Config.VOID
end

function Tilemap.Set(x, y, id)
    if not Tilemap.InBounds(x, y) then return end
    tiles[y * W + x + 1] = id
end

function Tilemap.IsSolid(x, y)
    if not Tilemap.InBounds(x, y) then return true end
    local id = tiles[y * W + x + 1] or Config.VOID
    return id ~= Config.FLOOR
end

function Tilemap.GetWidth() return W end
function Tilemap.GetHeight() return H end

return Tilemap
