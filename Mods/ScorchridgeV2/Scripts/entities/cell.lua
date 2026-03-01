-- ============================================
-- ScorchridgeV2 — Cell Entity
-- Cell room: furniture layout, header bar, rendering
-- ============================================

local Config = require("core/config")
local Camera = require("core/camera")
local Theme = require("core/theme")
local UI = require("core/ui")

local C = Theme.Colors
local spr = Theme.Spr
local FURN = Config.FURNITURE

local Cell = {}
Cell.__index = Cell

-- Create a cell given its global index (1-20)
function Cell.new(index)
    local self = setmetatable({}, Cell)
    self.index = index
    self.level = math.ceil(index / Config.CELLS_PER_ROW)
    self.localIndex = ((index - 1) % Config.CELLS_PER_ROW) + 1
    self.inmateIndex = index
    return self
end

-- Get the world X position of this cell
function Cell:worldX()
    return Config.CONTROL_ROOM_W + Config.STAIRCASE_W + (self.localIndex - 1) * Config.CELL_W
end

-- Get screen position (cell body, below header)
function Cell:screenPos()
    local sx = Camera.WorldToScreenX(self:worldX())
    local sy = Camera.CellScreenY(self.level)
    return sx, sy
end

-- Draw the header bar above the cell body
function Cell:drawHeader(shared, inmate)
    local sx = Camera.WorldToScreenX(self:worldX())
    local sy = Camera.LevelScreenY(self.level)

    -- Dark header background
    UI.Rect(sx, sy, Config.CELL_W, Config.HEADER_H, {20, 20, 30, 240})
    -- Bottom border
    UI.Rect(sx, sy + Config.HEADER_H - 1, Config.CELL_W, 1, {50, 48, 52, 200})

    -- Cell number
    Text.Draw("#" .. self.index, sx + 2, sy + 3, 8, C.DIM)

    if not inmate or not inmate.alive then return end

    -- Stamina mini-bar
    local barW = 28
    local barH = 4
    local barX = sx + 24
    local barY = sy + 3
    local staRatio = math.min(inmate.stamina / inmate.maxStamina, 1)
    local staColor = staRatio < 0.2 and C.RED or C.GREEN
    UI.Rect(barX, barY, barW, barH, {30, 30, 40, 160})
    UI.Rect(barX, barY, math.floor(barW * staRatio), barH, staColor)

    -- Morale mini-bar
    local morBarY = barY + barH + 2
    local morRatio = math.min(inmate.morale / inmate.maxMorale, 1)
    local morColor = morRatio < 0.2 and C.RED or {100, 150, 255}
    UI.Rect(barX, morBarY, barW, barH, {30, 30, 40, 160})
    UI.Rect(barX, morBarY, math.floor(barW * morRatio), barH, morColor)

    -- Buff/debuff icons area (right side of header)
    local iconX = sx + 56

    -- Exhausted indicator
    if inmate.exhausted then
        Text.Draw("!", iconX, sy + 2, 9, C.RED)
        iconX = iconX + 10
    end

    -- Addicted indicator
    if inmate.addicted then
        Text.Draw("A", iconX, sy + 2, 9, C.ORANGE)
        iconX = iconX + 10
    end

    -- Tier color dot
    local tc = C.TIER_COLORS[inmate.assignedTier or 1]
    if tc then
        UI.Rect(sx + Config.CELL_W - 14, sy + 4, 8, 8, tc)
        Text.Draw("T" .. (inmate.assignedTier or 1), sx + Config.CELL_W - 28, sy + 3, 8, C.DIM)
    end
end

-- Draw the cell background and furniture
function Cell:draw(shared)
    local sx, sy = self:screenPos()
    local tex = shared.tex

    -- Cell background
    UI.Rect(sx, sy, Config.CELL_W, Config.CELL_H, C.CELL_FLOOR)

    -- Cell walls (top, left, right)
    UI.Rect(sx, sy, Config.CELL_W, 3, C.CELL_WALL)
    UI.Rect(sx, sy, 3, Config.CELL_H, C.CELL_WALL)
    UI.Rect(sx + Config.CELL_W - 3, sy, 3, Config.CELL_H, C.CELL_WALL)

    -- Bottom wall (with door gap in center)
    local doorW = 28
    local doorX = sx + math.floor(Config.CELL_W / 2) - math.floor(doorW / 2)
    UI.Rect(sx, sy + Config.CELL_H - 3, doorX - sx, 3, C.CELL_WALL)
    UI.Rect(doorX + doorW, sy + Config.CELL_H - 3, sx + Config.CELL_W - doorX - doorW, 3, C.CELL_WALL)

    -- Furniture
    if tex.terminal then
        spr(tex.terminal, sx + FURN.terminal.x, sy + FURN.terminal.y, FURN.terminal.w, FURN.terminal.h, 1.5, 1.5, {100, 200, 255, 255})
    end
    if tex.table then
        spr(tex.table, sx + FURN.table.x, sy + FURN.table.y, FURN.table.w, FURN.table.h, 1.5, 1.5)
    end
    if tex.bed then
        spr(tex.bed, sx + FURN.bed.x, sy + FURN.bed.y, FURN.bed.w, FURN.bed.h, 1.5, 1.5)
    end
    if tex.toilet then
        spr(tex.toilet, sx + FURN.toilet.x, sy + FURN.toilet.y, FURN.toilet.w, FURN.toilet.h, 1, 1, {200, 200, 220, 255})
    end
end

-- Draw the inmate inside this cell based on current phase
function Cell:drawInmate(shared, inmate, phase, bobTimer)
    if not inmate or not inmate.alive then return end

    local sx, sy = self:screenPos()
    local tex = shared.tex

    local bob = inmate:idleBob(0.6)

    if phase == "work" then
        local imX = sx + FURN.terminal.x + 20
        local imY = sy + FURN.terminal.y + 2
        if inmate.exhausted then
            spr(tex.inmate, imX, imY + 8, 16, 24, 1.5, 1.5, {180, 100, 100, 255})
            Text.Draw("TIRED", imX - 4, imY + 36, 8, C.RED)
        else
            local swing = math.sin((bobTimer or 0) * 4 + self.index * 1.3) * 2
            spr(tex.inmateWork, imX, imY + swing, 16, 24, 1.5, 1.5)
            local glow = math.floor(150 + math.sin((bobTimer or 0) * 3 + self.index) * 50)
            UI.Rect(sx + FURN.terminal.x + 2, sy + FURN.terminal.y + 2, 20, 14, {60, glow, 255, 80})
        end

    elseif phase == "meal" or phase == "preMeal" then
        local imX = sx + FURN.table.x - 10
        local imY = sy + FURN.table.y + 16
        local eatBob = math.sin((bobTimer or 0) * 3 + self.index * 1.5) * 2
        if phase == "meal" then
            spr(tex.inmateEat, imX, imY + eatBob, 16, 24, 1.5, 1.5)
            Text.Draw("+STA", imX + 2, imY - 8, 8, C.GREEN)
        else
            spr(tex.inmate, imX, imY + bob, 16, 24, 1.5, 1.5)
        end

    elseif phase == "rest" then
        local imX = sx + FURN.bed.x + 4
        local imY = sy + FURN.bed.y - 8
        local breath = math.sin((bobTimer or 0) * 1.2 + self.index * 0.9) * 1.5
        spr(tex.inmateRest, imX, imY + breath, 24, 12, 1.5, 1.5)
        local zPhase = (bobTimer or 0) * 0.8 + self.index
        local zAlpha = math.floor(180 + math.sin(zPhase * 1.3) * 60)
        Text.Draw("z", imX + 38, imY - 4 - math.abs(math.sin(zPhase * 0.5)) * 5, 9, {140, 140, 160, zAlpha})
        Text.Draw("Z", imX + 48, imY - 10, 12, {140, 140, 160, zAlpha})

    else
        -- Idle: preparation, postMeal, downtime
        local imX = sx + FURN.inmate.x
        local imY = sy + FURN.inmate.y
        spr(tex.inmate, imX, imY + bob, 16, 24, 1.5, 1.5)

        if phase == "downtime" or phase == "postMeal" then
            local thoughtPhase = math.sin((bobTimer or 0) * 0.3 + self.index * 2)
            if thoughtPhase > 0.7 then
                local thought = inmate.morale > 100 and ".." or (inmate.morale > 50 and "..." or "!?")
                local tColor = inmate.morale > 100 and C.GRAY or (inmate.morale > 50 and C.DIM or C.RED)
                Text.Draw(thought, imX + 20, imY - 8, 8, tColor)
            end
        end
    end
end

-- Highlight this cell (selected)
function Cell:highlight(color)
    local sx, sy = self:screenPos()
    color = color or {255, 255, 100, 40}
    UI.Rect(sx - 1, sy - 1, Config.CELL_W + 2, Config.CELL_H + 2, color)
end

return Cell
