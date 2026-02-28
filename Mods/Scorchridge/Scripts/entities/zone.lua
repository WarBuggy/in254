-- ============================================
-- Scorchridge — ZoneClass
-- Drawable game zone (Barracks, Mine, Mess Hall)
-- ============================================

local UI = require("core/ui")

local ZoneClass = {}
ZoneClass.__index = ZoneClass

ZoneClass.WALL_COLOR = {65, 60, 55, 255}
ZoneClass.GRID_LINE  = {50, 45, 40, 80}
ZoneClass.LABEL_COLOR = {120, 120, 100, 180}
ZoneClass.DEFAULT_TILE = 28

function ZoneClass.new(opts)
    local self = setmetatable({}, ZoneClass)
    self.x = opts.x or 0
    self.y = opts.y or 0
    self.w = opts.w or 100
    self.h = opts.h or 100
    self.floorColor = opts.floorColor or {40, 35, 32, 255}
    self.label = opts.label
    self.wallThickness = opts.wallThickness or 4
    return self
end

function ZoneClass:drawFloor(tileSize)
    tileSize = tileSize or ZoneClass.DEFAULT_TILE
    UI.Rect(self.x, self.y, self.w, self.h, self.floorColor)
    for gx = self.x, self.x + self.w - 1, tileSize do
        UI.Rect(gx, self.y, 1, self.h, ZoneClass.GRID_LINE)
    end
    for gy = self.y, self.y + self.h - 1, tileSize do
        UI.Rect(self.x, gy, self.w, 1, ZoneClass.GRID_LINE)
    end
end

function ZoneClass:drawWalls()
    local t = self.wallThickness
    UI.Rect(self.x, self.y, self.w, t, ZoneClass.WALL_COLOR)
    UI.Rect(self.x, self.y + self.h - t, self.w, t, ZoneClass.WALL_COLOR)
    UI.Rect(self.x, self.y, t, self.h, ZoneClass.WALL_COLOR)
    UI.Rect(self.x + self.w - t, self.y, t, self.h, ZoneClass.WALL_COLOR)
end

function ZoneClass:draw(tileSize)
    self:drawFloor(tileSize)
    self:drawWalls()
    if self.label then
        Text.Draw(self.label, self.x + 8, self.y + 6, 10, ZoneClass.LABEL_COLOR)
    end
end

function ZoneClass:highlight(color)
    UI.Rect(self.x - 1, self.y - 1, self.w + 2, self.h + 2, color)
end

function ZoneClass:getInmateSlots(count)
    local slots = {}
    local spacing = math.floor(self.w / (count + 1))
    for i = 1, count do
        slots[i] = {
            x = self.x + spacing * i,
            y = self.y + math.floor(self.h / 2)
        }
    end
    return slots
end

function ZoneClass:wanderBounds(padding)
    padding = padding or 20
    return {
        x1 = self.x + padding,
        x2 = self.x + self.w - padding,
        y1 = self.y + padding,
        y2 = self.y + self.h - padding
    }
end

return ZoneClass
