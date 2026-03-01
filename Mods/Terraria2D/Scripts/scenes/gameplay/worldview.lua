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
    local zoom = Camera.zoom
    local TS = Config.TILE_SIZE
    local camX = Camera.GetX()
    local camY = Camera.GetY()

    -- Sky background (positioned at camera origin in world-space; camera transform offsets it)
    local viewW = math.ceil(W / zoom)
    local viewH = math.ceil(H / zoom)
    UI.Rect(floor(camX), floor(camY), viewW, viewH, shared.skyColor or Theme.Colors.SKY_DAY)

    -- Per-frame tile draw (3 params — camera read from CameraManager in C#)
    Drawing.DrawTileMap(viewW, viewH, shared.lightMap)

    -- Mining indicator (world-space positions)
    if shared.mineTarget and shared.mineProgress > 0 then
        local mx = shared.mineTarget.x
        local my = shared.mineTarget.y
        local sx = mx * TS
        local sy = my * TS
        local prog = shared.mineProgress
        UI.Rect(sx, sy, TS, TS, Color.New(255, 255, 255, floor(60 + 100 * prog)))
        UI.Rect(sx, sy + TS, TS, 2, _cMineBg)
        UI.Rect(sx, sy + TS, floor(TS * prog), 2, _cMineFg)
    end
end

return WorldView
