-- ============================================
-- Terraria2D — Lighting
-- Sunlight columns + torch BFS
-- ============================================

local Config = require("core/config")
local Tiles = require("world/tiles")
local WorldData = require("world/worlddata")

local Lighting = {}

function Lighting.Calculate(shared)
    local W = Config.WORLD_W
    local H = Config.WORLD_H
    local maxLight = Config.MAX_LIGHT

    -- Initialize light map
    local lightMap = {}
    for i = 1, W * H do
        lightMap[i] = 0
    end

    -- Only calculate around camera for performance
    local camTX = math.floor((shared.camX or 0) / Config.TILE_SIZE)
    local camTY = math.floor((shared.camY or 0) / Config.TILE_SIZE)
    local viewW = math.ceil(shared.W / Config.TILE_SIZE) + 2
    local viewH = math.ceil(shared.H / Config.TILE_SIZE) + 2
    local margin = 20 -- extra tiles for light spread

    local startX = math.max(0, camTX - margin)
    local endX = math.min(W - 1, camTX + viewW + margin)
    local startY = math.max(0, camTY - margin)
    local endY = math.min(H - 1, camTY + viewH + margin)

    -- Pass 1: Sunlight - scan columns from top
    local isNight = shared.isNight
    local skyLight = isNight and 7 or maxLight

    for x = startX, endX do
        local light = skyLight
        for y = 0, endY do
            local idx = y * W + x + 1
            local tileId = WorldData.Get(x, y)
            local data = Tiles.GetData(tileId)

            if tileId == Tiles.AIR or (not data.solid) then
                lightMap[idx] = math.max(lightMap[idx], light)
            else
                -- Solid tile blocks light
                lightMap[idx] = math.max(lightMap[idx], math.max(light - 1, 0))
                light = light - 2
                if light < 0 then light = 0 end
            end
        end
    end

    -- Pass 2: Light-emitting tiles (torches, furnaces) - simple BFS
    local queue = {}
    for y = startY, endY do
        for x = startX, endX do
            local tileId = WorldData.Get(x, y)
            local data = Tiles.GetData(tileId)
            if data.light > 0 then
                table.insert(queue, { x = x, y = y, light = data.light })
            end
        end
    end

    -- BFS flood fill
    local visited = {}
    while #queue > 0 do
        local node = table.remove(queue, 1)
        local x, y, light = node.x, node.y, node.light

        if x >= 0 and x < W and y >= 0 and y < H and light > 0 then
            local idx = y * W + x + 1
            local key = y * W + x

            if not visited[key] or lightMap[idx] < light then
                visited[key] = true
                if light > lightMap[idx] then
                    lightMap[idx] = light
                end

                local nextLight = light - 1
                if nextLight > 0 then
                    -- Check if we'd improve neighbors
                    local dirs = {{0,-1},{0,1},{-1,0},{1,0}}
                    for _, d in ipairs(dirs) do
                        local nx, ny = x + d[1], y + d[2]
                        if nx >= 0 and nx < W and ny >= 0 and ny < H then
                            local nidx = ny * W + nx + 1
                            if nextLight > (lightMap[nidx] or 0) then
                                table.insert(queue, { x = nx, y = ny, light = nextLight })
                            end
                        end
                    end
                end
            end
        end
    end

    shared.lightMap = lightMap
    -- Store camera tile position for next calculation
    local camX = require("core/camera").GetX()
    local camY = require("core/camera").GetY()
    shared.camX = camX
    shared.camY = camY
end

return Lighting
