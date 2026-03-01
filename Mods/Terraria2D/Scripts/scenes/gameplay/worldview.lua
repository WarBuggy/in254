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
    local startTX = math.floor(camX / TS)
    local startTY = math.floor(camY / TS)
    local endTX = math.floor((camX + W) / TS) + 1
    local endTY = math.floor((camY + H) / TS) + 1

    startTX = math.max(0, startTX)
    startTY = math.max(0, startTY)
    endTX = math.min(Config.WORLD_W - 1, endTX)
    endTY = math.min(Config.WORLD_H - 1, endTY)

    local lightMap = shared.lightMap
    local maxLight = Config.MAX_LIGHT

    for y = startTY, endTY do
        for x = startTX, endTX do
            local tileId = WorldData.Get(x, y)
            if tileId ~= Tiles.AIR or (tileId == Tiles.AIR and y >= Config.SURFACE_Y) then
                if tileId ~= Tiles.AIR then
                    local data = Tiles.GetData(tileId)
                    local color = data.color
                    local sx = math.floor(x * TS - camX)
                    local sy = math.floor(y * TS - camY)

                    -- Apply lighting
                    local light = maxLight
                    if lightMap then
                        local idx = y * Config.WORLD_W + x + 1
                        light = lightMap[idx] or 0
                    end
                    local lf = light / maxLight
                    local r = math.floor(color[1] * lf)
                    local g = math.floor(color[2] * lf)
                    local b = math.floor(color[3] * lf)
                    local a = color[4] or 255

                    if lf > 0 or y < Config.SURFACE_Y + 3 then
                        UI.Rect(sx, sy, TS, TS, {r, g, b, a})
                    end
                end
            end
        end
    end

    -- Draw underground darkness for air tiles
    if lightMap then
        for y = startTY, endTY do
            if y > Config.SURFACE_Y + 3 then
                for x = startTX, endTX do
                    local tileId = WorldData.Get(x, y)
                    if tileId == Tiles.AIR then
                        local idx = y * Config.WORLD_W + x + 1
                        local light = lightMap[idx] or 0
                        if light > 0 then
                            -- Show dimly lit air as dark background
                            local lf = light / maxLight
                            local darkness = math.floor(255 * (1 - lf * 0.3))
                            -- Just skip - air is transparent, darkness comes from sky being blocked
                        end
                    end
                end
            end
        end
    end

    -- Mining indicator
    if shared.mineTarget and shared.mineProgress > 0 then
        local mx = shared.mineTarget.x
        local my = shared.mineTarget.y
        local sx = math.floor(mx * TS - camX)
        local sy = math.floor(my * TS - camY)
        -- Mining progress overlay
        local prog = shared.mineProgress
        UI.Rect(sx, sy, TS, TS, {255, 255, 255, math.floor(60 + 100 * prog)})
        -- Progress bar below tile
        UI.Rect(sx, sy + TS, TS, 2, {40, 40, 40, 200})
        UI.Rect(sx, sy + TS, math.floor(TS * prog), 2, {255, 255, 100})
    end
end

return WorldView
