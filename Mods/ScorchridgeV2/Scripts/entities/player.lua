-- ============================================
-- ScorchridgeV2 — Player Entity
-- Warden avatar: WASD movement, staircase interaction
-- ============================================

local Config = require("core/config")
local Camera = require("core/camera")

local Player = {}
Player.__index = Player

function Player.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Player)
    self.x = opts.x or Config.CONTROL_ROOM_W / 2
    self.level = opts.level or 1
    self.w = Config.PLAYER_W
    self.h = Config.PLAYER_H
    self.scale = Config.PLAYER_SCALE
    self.speed = Config.PLAYER_SPEED
    self.facing = 1  -- 1 = right, -1 = left
    self.walkTimer = 0
    self.walkFrame = 0
    return self
end

-- Get the screen Y for the player (centered in hallway)
function Player:getScreenY()
    local hallY = Camera.HallwayScreenY(self.level)
    return hallY + math.floor(Config.HALLWAY_H / 2) - math.floor(self.h * self.scale / 2)
end

-- Get the staircase X position
function Player:getStaircaseX()
    return Config.CONTROL_ROOM_W
end

-- Check if player is near the staircase
function Player:isNearStaircase()
    local stairX = self:getStaircaseX()
    return math.abs(self.x - stairX) < Config.STAIRCASE_W
end

-- Get which cell the player is near (1-based, or 0 if none)
function Player:getNearestCell()
    local cellStartX = Config.CONTROL_ROOM_W + Config.STAIRCASE_W
    local relX = self.x - cellStartX
    if relX < -Config.INTERACT_RANGE then return 0 end

    local cellIndex = math.floor(relX / Config.CELL_W) + 1
    -- How many cells on this row
    local cellsOnRow = math.min(Config.CELLS_PER_ROW, Config.TOTAL_CELLS - (self.level - 1) * Config.CELLS_PER_ROW)
    if cellIndex < 1 or cellIndex > cellsOnRow then return 0 end

    local cellCenterX = cellStartX + (cellIndex - 1) * Config.CELL_W + Config.CELL_W / 2
    if math.abs(self.x - cellCenterX) > Config.INTERACT_RANGE then return 0 end

    return cellIndex + (self.level - 1) * Config.CELLS_PER_ROW
end

function Player:update(dt)
    local moved = false

    -- Horizontal movement
    if Input.IsKeyDown("a") then
        self.x = self.x - self.speed * dt
        self.facing = -1
        moved = true
    end
    if Input.IsKeyDown("d") then
        self.x = self.x + self.speed * dt
        self.facing = 1
        moved = true
    end

    -- Clamp horizontal position
    self.x = math.max(0, math.min(self.x, Config.WORLD_W - self.w * self.scale))

    -- Staircase: W/S to change level
    if self:isNearStaircase() then
        if Input.IsKeyPressed("w") and self.level > 1 then
            self.level = self.level - 1
        end
        if Input.IsKeyPressed("s") and self.level < Config.ROW_COUNT then
            self.level = self.level + 1
        end
    end

    -- Walk animation
    if moved then
        self.walkTimer = self.walkTimer + dt
        if self.walkTimer > 0.15 then
            self.walkTimer = 0
            self.walkFrame = (self.walkFrame + 1) % 4
        end
    else
        self.walkTimer = 0
        self.walkFrame = 0
    end

    -- Camera follows player horizontally
    Camera.Follow(self.x, Screen.Width())
    Camera.Update(dt)
end

return Player
