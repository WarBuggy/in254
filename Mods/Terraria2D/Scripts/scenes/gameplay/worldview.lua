-- ============================================
-- Terraria2D — World View
-- Tile rendering with viewport culling + lighting
-- ============================================

local Config = require("core/config")
local Camera = require("core/camera")
local UI = require("core/ui")
local Theme = require("core/theme")

local floor = math.floor

-- Cached colors
local _cMineBg  = Color.New(40, 40, 40, 200)
local _cMineFg  = Color.New(255, 255, 100)

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

    -- Per-frame tile draw (config already set in root.lua)
    Drawing.DrawTileMap(camX, camY, W, H, shared.lightMap)

    -- Mining indicator
    if shared.mineTarget and shared.mineProgress > 0 then
        local mx = shared.mineTarget.x
        local my = shared.mineTarget.y
        local sx = floor(mx * TS - camX)
        local sy = floor(my * TS - camY)
        local prog = shared.mineProgress
        UI.Rect(sx, sy, TS, TS, Color.New(255, 255, 255, floor(60 + 100 * prog)))
        UI.Rect(sx, sy + TS, TS, 2, _cMineBg)
        UI.Rect(sx, sy + TS, floor(TS * prog), 2, _cMineFg)
    end
end

return WorldView
