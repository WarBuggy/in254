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

-- Localize hot-path functions
local floor = math.floor
local max = math.max
local min = math.min

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

    -- Calculate visible tile range
    local startTX = max(0, floor(camX / TS))
    local startTY = max(0, floor(camY / TS))
    local endTX = min(Config.WORLD_W - 1, floor((camX + W) / TS) + 1)
    local endTY = min(Config.WORLD_H - 1, floor((camY + H) / TS) + 1)

    local colorCache = shared.colorCache
    local lightMap = shared.lightMap
    local maxLight = Config.MAX_LIGHT
    local surfaceY = Config.SURFACE_Y
    local worldW = Config.WORLD_W
    local tileData = Tiles.data

    for y = startTY, endTY do
        local base = y * worldW
        local sy = floor(y * TS - camY)
        for x = startTX, endTX do
            local idx = base + x + 1
            local tileId = WorldData.Get(x, y)

            if tileId ~= 0 then
                -- Use pre-computed lit color from lighting pass
                if colorCache then
                    local c = colorCache[idx]
                    if c then
                        local lf = lightMap and (lightMap[idx] or 0) or maxLight
                        if lf > 0 or y < surfaceY + 3 then
                            UI.Rect(floor(x * TS - camX), sy, TS, TS, c)
                        end
                    else
                        -- Fallback: no cached color, compute inline
                        local data = tileData[tileId] or tileData[0]
                        local color = data.color
                        local sx = floor(x * TS - camX)
                        UI.Rect(sx, sy, TS, TS, color)
                    end
                else
                    -- No color cache yet (first frame before lighting calc)
                    local data = tileData[tileId] or tileData[0]
                    local color = data.color
                    UI.Rect(floor(x * TS - camX), sy, TS, TS, color)
                end
            end
        end
    end

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
