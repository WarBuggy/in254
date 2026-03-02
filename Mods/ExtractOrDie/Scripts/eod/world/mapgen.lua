-- ============================================
-- ExtractOrDie — BSP Dungeon Generator
-- 100x100 tiles, recursive BSP split
-- ============================================

local Config = require("eod/core/config")
local Tilemap = require("eod/world/tilemap")

local MapGen = {}

local floor = math.floor
local random = math.random
local min = math.min
local max = math.max

-- BSP node
local function newNode(x, y, w, h)
    return { x = x, y = y, w = w, h = h, left = nil, right = nil, room = nil }
end

-- Recursively split BSP
local function splitNode(node, depth)
    if depth <= 0 then return end
    if node.w < Config.ROOM_MIN * 2 + 4 and node.h < Config.ROOM_MIN * 2 + 4 then return end

    local splitH = random() > 0.5
    -- Force horizontal split if too wide, vertical if too tall
    if node.w > node.h * 1.4 then splitH = false end
    if node.h > node.w * 1.4 then splitH = true end

    if splitH then
        if node.h < Config.ROOM_MIN * 2 + 4 then return end
        local splitAt = floor(node.h * (0.35 + random() * 0.3))
        splitAt = max(Config.ROOM_MIN + 2, min(splitAt, node.h - Config.ROOM_MIN - 2))
        node.left = newNode(node.x, node.y, node.w, splitAt)
        node.right = newNode(node.x, node.y + splitAt, node.w, node.h - splitAt)
    else
        if node.w < Config.ROOM_MIN * 2 + 4 then return end
        local splitAt = floor(node.w * (0.35 + random() * 0.3))
        splitAt = max(Config.ROOM_MIN + 2, min(splitAt, node.w - Config.ROOM_MIN - 2))
        node.left = newNode(node.x, node.y, splitAt, node.h)
        node.right = newNode(node.x + splitAt, node.y, node.w - splitAt, node.h)
    end

    splitNode(node.left, depth - 1)
    splitNode(node.right, depth - 1)
end

-- Carve a room inside a BSP leaf
local function carveRoom(node, rooms)
    if node.left or node.right then
        if node.left then carveRoom(node.left, rooms) end
        if node.right then carveRoom(node.right, rooms) end
        return
    end

    -- Leaf node: create a room
    local margin = 2
    local rw = random(Config.ROOM_MIN, min(Config.ROOM_MAX, node.w - margin * 2))
    local rh = random(Config.ROOM_MIN, min(Config.ROOM_MAX, node.h - margin * 2))
    local rx = node.x + random(margin, max(margin, node.w - rw - margin))
    local ry = node.y + random(margin, max(margin, node.h - rh - margin))

    -- Clamp to map bounds
    rx = max(1, min(rx, Config.MAP_W - rw - 1))
    ry = max(1, min(ry, Config.MAP_H - rh - 1))

    node.room = { x = rx, y = ry, w = rw, h = rh }
    table.insert(rooms, node.room)

    -- Carve floor tiles
    for y = ry, ry + rh - 1 do
        for x = rx, rx + rw - 1 do
            Tilemap.Set(x, y, Config.FLOOR)
        end
    end
end

-- Get center of a room or recurse to find one
local function getCenter(node)
    if node.room then
        return floor(node.room.x + node.room.w / 2),
               floor(node.room.y + node.room.h / 2)
    end
    if node.left then return getCenter(node.left) end
    if node.right then return getCenter(node.right) end
    return floor(node.x + node.w / 2), floor(node.y + node.h / 2)
end

-- Carve an L-shaped corridor between two points
local function carveCorridor(x1, y1, x2, y2)
    local cw = Config.CORRIDOR_W
    local half = floor(cw / 2)

    -- Horizontal segment
    local sx = min(x1, x2)
    local ex = max(x1, x2)
    for x = sx, ex do
        for dy = -half, half do
            local ty = y1 + dy
            if ty >= 1 and ty < Config.MAP_H - 1 then
                Tilemap.Set(x, ty, Config.FLOOR)
            end
        end
    end

    -- Vertical segment
    local sy = min(y1, y2)
    local ey = max(y1, y2)
    for y = sy, ey do
        for dx = -half, half do
            local tx = x2 + dx
            if tx >= 1 and tx < Config.MAP_W - 1 then
                Tilemap.Set(tx, y, Config.FLOOR)
            end
        end
    end
end

-- Connect siblings in BSP
local function connectNodes(node)
    if not node.left or not node.right then return end
    local x1, y1 = getCenter(node.left)
    local x2, y2 = getCenter(node.right)
    carveCorridor(x1, y1, x2, y2)
    connectNodes(node.left)
    connectNodes(node.right)
end

-- Place walls around floor tiles
local function placeWalls()
    local W = Config.MAP_W
    local H = Config.MAP_H
    -- Scan for floor tiles and add walls to adjacent void tiles
    for y = 0, H - 1 do
        for x = 0, W - 1 do
            if Tilemap.Get(x, y) == Config.FLOOR then
                for dy = -1, 1 do
                    for dx = -1, 1 do
                        if dx ~= 0 or dy ~= 0 then
                            local nx, ny = x + dx, y + dy
                            if Tilemap.InBounds(nx, ny) and Tilemap.Get(nx, ny) == Config.VOID then
                                Tilemap.Set(nx, ny, Config.WALL)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Find the two rooms farthest from spawn room
local function findFarthestRooms(rooms, spawnRoom)
    local scx = spawnRoom.x + spawnRoom.w / 2
    local scy = spawnRoom.y + spawnRoom.h / 2

    -- Sort by distance from spawn
    local sorted = {}
    for _, r in ipairs(rooms) do
        if r ~= spawnRoom then
            local cx = r.x + r.w / 2
            local cy = r.y + r.h / 2
            local dx = cx - scx
            local dy = cy - scy
            table.insert(sorted, { room = r, dist = dx * dx + dy * dy })
        end
    end
    table.sort(sorted, function(a, b) return a.dist > b.dist end)

    local result = {}
    for i = 1, min(2, #sorted) do
        table.insert(result, sorted[i].room)
    end
    return result
end

-- Pick crate positions scattered across rooms
local function pickCratePositions(rooms, spawnRoom, numCrates)
    local positions = {}
    local tries = 0
    while #positions < numCrates and tries < 200 do
        tries = tries + 1
        local room = rooms[random(1, #rooms)]
        if room ~= spawnRoom then
            local cx = room.x + random(1, room.w - 2)
            local cy = room.y + random(1, room.h - 2)
            -- Check no overlap with existing
            local ok = true
            for _, p in ipairs(positions) do
                if p.x == cx and p.y == cy then ok = false; break end
            end
            if ok then
                table.insert(positions, { x = cx, y = cy })
            end
        end
    end
    return positions
end

-- ============================================
-- Forest Generation
-- Open floor with tree clusters, clearings, paths
-- ============================================

local function generateForest()
    Tilemap.Init()

    local W = Config.MAP_W
    local H = Config.MAP_H

    -- Start with all floor
    for y = 0, H - 1 do
        for x = 0, W - 1 do
            Tilemap.Set(x, y, Config.FLOOR)
        end
    end

    -- Dense border of trees (3 tiles thick)
    for y = 0, H - 1 do
        for x = 0, W - 1 do
            if x < 3 or x >= W - 3 or y < 3 or y >= H - 3 then
                Tilemap.Set(x, y, Config.WALL)
            end
        end
    end

    -- Place clearings (guaranteed open areas)
    local clearings = {}
    local numClearings = 8 + random(0, 4)
    local tries = 0
    while #clearings < numClearings and tries < 200 do
        tries = tries + 1
        local cw = random(8, 14)
        local ch = random(8, 14)
        local cx = random(6, W - cw - 6)
        local cy = random(6, H - ch - 6)
        -- Check no overlap with existing clearings
        local ok = true
        for _, cl in ipairs(clearings) do
            if cx < cl.x + cl.w + 4 and cx + cw + 4 > cl.x and
               cy < cl.y + cl.h + 4 and cy + ch + 4 > cl.y then
                ok = false
                break
            end
        end
        if ok then
            table.insert(clearings, { x = cx, y = cy, w = cw, h = ch })
        end
    end

    -- Scatter tree clusters (organic blobs of WALL)
    local numClusters = 40 + random(0, 20)
    for i = 1, numClusters do
        local tx = random(5, W - 6)
        local ty = random(5, H - 6)
        local clusterSize = random(3, 7)
        for j = 1, clusterSize do
            local ox = tx + random(-2, 2)
            local oy = ty + random(-2, 2)
            if ox >= 4 and ox < W - 4 and oy >= 4 and oy < H - 4 then
                Tilemap.Set(ox, oy, Config.WALL)
            end
        end
    end

    -- Carve clearings open (ensure they are floor)
    for _, cl in ipairs(clearings) do
        for y = cl.y, cl.y + cl.h - 1 do
            for x = cl.x, cl.x + cl.w - 1 do
                Tilemap.Set(x, y, Config.FLOOR)
            end
        end
    end

    -- Carve dirt paths between clearings (wider corridors)
    for i = 1, #clearings - 1 do
        local a = clearings[i]
        local b = clearings[i + 1]
        local ax = floor(a.x + a.w / 2)
        local ay = floor(a.y + a.h / 2)
        local bx = floor(b.x + b.w / 2)
        local by = floor(b.y + b.h / 2)
        carveCorridor(ax, ay, bx, by)
    end
    -- Connect last to first for loop connectivity
    if #clearings >= 2 then
        local a = clearings[#clearings]
        local b = clearings[1]
        carveCorridor(floor(a.x + a.w / 2), floor(a.y + a.h / 2),
                       floor(b.x + b.w / 2), floor(b.y + b.h / 2))
    end

    -- Convert clearings to rooms for spawn/extract/crate logic
    local rooms = {}
    for _, cl in ipairs(clearings) do
        table.insert(rooms, { x = cl.x, y = cl.y, w = cl.w, h = cl.h })
    end

    -- Pick spawn room (closest to center)
    local mapCX = W / 2
    local mapCY = H / 2
    local spawnRoom = rooms[1]
    local bestDist = math.huge
    for _, r in ipairs(rooms) do
        local rcx = r.x + r.w / 2
        local rcy = r.y + r.h / 2
        local dx = rcx - mapCX
        local dy = rcy - mapCY
        local d = dx * dx + dy * dy
        if d < bestDist then
            bestDist = d
            spawnRoom = r
        end
    end

    -- Find extraction zone rooms (farthest from spawn)
    local extractRooms = findFarthestRooms(rooms, spawnRoom)
    local extractZones = {}
    for _, r in ipairs(extractRooms) do
        local zs = Config.EXTRACT_ZONE_SIZE
        table.insert(extractZones, {
            x = r.x + floor((r.w - zs) / 2),
            y = r.y + floor((r.h - zs) / 2),
            w = zs,
            h = zs,
        })
    end

    -- Pick loot crate positions
    local cratePositions = pickCratePositions(rooms, spawnRoom, Config.NUM_CRATES)

    return {
        rooms = rooms,
        spawnRoom = spawnRoom,
        extractZones = extractZones,
        cratePositions = cratePositions,
    }
end

function MapGen.Generate(mapType)
    if mapType == "forest" then
        return generateForest()
    end

    -- Initialize tilemap
    Tilemap.Init()

    -- Build BSP tree
    local root = newNode(0, 0, Config.MAP_W, Config.MAP_H)
    splitNode(root, Config.BSP_SPLITS)

    -- Carve rooms
    local rooms = {}
    carveRoom(root, rooms)

    -- Connect rooms with corridors
    connectNodes(root)

    -- Place walls around carved areas
    placeWalls()

    -- Pick spawn room (closest to center)
    local mapCX = Config.MAP_W / 2
    local mapCY = Config.MAP_H / 2
    local spawnRoom = rooms[1]
    local bestDist = math.huge
    for _, r in ipairs(rooms) do
        local cx = r.x + r.w / 2
        local cy = r.y + r.h / 2
        local dx = cx - mapCX
        local dy = cy - mapCY
        local d = dx * dx + dy * dy
        if d < bestDist then
            bestDist = d
            spawnRoom = r
        end
    end

    -- Find extraction zone rooms
    local extractRooms = findFarthestRooms(rooms, spawnRoom)
    local extractZones = {}
    for _, r in ipairs(extractRooms) do
        local zs = Config.EXTRACT_ZONE_SIZE
        table.insert(extractZones, {
            x = r.x + floor((r.w - zs) / 2),
            y = r.y + floor((r.h - zs) / 2),
            w = zs,
            h = zs,
        })
    end

    -- Pick loot crate positions
    local cratePositions = pickCratePositions(rooms, spawnRoom, Config.NUM_CRATES)

    return {
        rooms = rooms,
        spawnRoom = spawnRoom,
        extractZones = extractZones,
        cratePositions = cratePositions,
    }
end

return MapGen
