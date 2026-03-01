-- ============================================
-- Terraria2D — World View
-- Tile rendering with viewport culling + lighting
-- ============================================

local Config = require("core/config")
local Tiles = require("world/tiles")
local WorldData = require("world/worlddata")
local Camera = require("core/camera")
local UI = require("core/ui")
local Theme = require("core/theme")

local floor = math.floor

local WorldView = {}

function WorldView.Draw(shared)
    local W = shared.W
    local H = shared.H
    local TS = Config.TILE_SIZE
    local camX = Camera.GetX()
    local camY = Camera.GetY()

    -- Sky background
    local skyColor = shared.skyColor or Theme.Colors.SKY_DAY
    UI.Rect(0, 0, W, H, skyColor)

    -- Batch all visible tiles in one Lua→C# call
    Drawing.TileMap(
        WorldData.GetTiles(), shared.colorCache,
        camX, camY, TS,
        Config.WORLD_W, Config.WORLD_H, W, H,
        Config.MAX_LIGHT, shared.lightMap, Config.SURFACE_Y,
        UI.GetPixelId(), Tiles.data
    )

    -- Mining indicator
    if shared.mineTarget and shared.mineProgress > 0 then
        local mx = shared.mineTarget.x
        local my = shared.mineTarget.y
        local sx = floor(mx * TS - camX)
        local sy = floor(my * TS - camY)
        local prog = shared.mineProgress
        UI.Rect(sx, sy, TS, TS, {255, 255, 255, floor(60 + 100 * prog)})
        UI.Rect(sx, sy + TS, TS, 2, {40, 40, 40, 200})
        UI.Rect(sx, sy + TS, floor(TS * prog), 2, {255, 255, 100})
    end
end

return WorldView
