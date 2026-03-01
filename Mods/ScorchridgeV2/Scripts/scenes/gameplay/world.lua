-- ============================================
-- ScorchridgeV2 — World Sub-Scene
-- Bunker rendering: 4 rows visible, cells, hallway, player
-- ============================================

local Theme = require("core/theme")
local Config = require("core/config")
local Camera = require("core/camera")
local UI = require("core/ui")
local Colony = require("systems/colony")
local Cell = require("entities/cell")
local InmateClass = require("entities/inmate")

local C = Theme.Colors
local L = Theme.Layout
local spr = Theme.Spr

local function drawLevel(level, shared, phase, bobTimer)
    local tex = shared.tex
    local inmates = shared.inmates
    local state = shared.state

    local levelY = Camera.LevelScreenY(level)
    local cellY = Camera.CellScreenY(level)
    local hallY = Camera.HallwayScreenY(level)

    -- How many cells on this row
    local cellStart = (level - 1) * Config.CELLS_PER_ROW + 1
    local cellCount = math.min(Config.CELLS_PER_ROW, Config.TOTAL_CELLS - cellStart + 1)
    if cellCount < 1 then return end

    -- Control room (only on row 1)
    if level == 1 then
        local crX = Camera.WorldToScreenX(0)
        UI.Rect(crX, cellY, Config.CONTROL_ROOM_W, Config.CELL_H, C.CTRL_ROOM)
        UI.Rect(crX, cellY, Config.CONTROL_ROOM_W, 3, C.CELL_WALL)
        UI.Rect(crX, cellY, 3, Config.CELL_H, C.CELL_WALL)
        UI.Rect(crX, cellY + Config.CELL_H - 3, Config.CONTROL_ROOM_W, 3, C.CELL_WALL)
        Text.Draw("CONTROL", crX + 10, cellY + 8, 11, C.CYAN)
        Text.Draw("ROOM", crX + 10, cellY + 20, 11, C.CYAN)
        -- Processor banks
        for pi = 1, 3 do
            UI.Rect(crX + 16 + (pi - 1) * 28, cellY + 38, 18, 30, {50, 55, 65, 255})
            local glow = math.floor(120 + math.sin(bobTimer * 2 + pi) * 40)
            UI.Rect(crX + 19 + (pi - 1) * 28, cellY + 41, 12, 8, {40, glow, 180, 200})
        end
        -- Hallway under control room
        UI.Rect(crX, hallY, Config.CONTROL_ROOM_W, Config.HALLWAY_H, C.HALLWAY_BG)
    end

    -- Staircase
    local stairX = Camera.WorldToScreenX(Config.CONTROL_ROOM_W)
    local stairH = Config.CELL_H + Config.HALLWAY_H
    UI.Rect(stairX, cellY, Config.STAIRCASE_W, stairH, C.STAIR_BG)
    -- Stair lines
    for si = 0, 6 do
        local stepY = cellY + si * math.floor(stairH / 7)
        UI.Rect(stairX + 4, stepY, Config.STAIRCASE_W - 8, 2, {70, 65, 60, 200})
    end
    -- Staircase labels
    if level > 1 then
        Text.Draw("^ L" .. (level - 1), stairX + 6, cellY + 4, 8, C.DIM)
    end
    if level < Config.ROW_COUNT then
        Text.Draw("v L" .. (level + 1), stairX + 6, cellY + Config.CELL_H + 4, 8, C.DIM)
    end

    -- Hallway
    local hallStartX = Config.CONTROL_ROOM_W + Config.STAIRCASE_W
    local hallSX = Camera.WorldToScreenX(hallStartX)
    local hallLen = cellCount * Config.CELL_W
    UI.Rect(hallSX, hallY, hallLen, Config.HALLWAY_H, C.HALLWAY_BG)
    UI.Rect(hallSX, hallY, hallLen, 2, {50, 48, 52, 200})
    UI.Rect(hallSX, hallY + Config.HALLWAY_H - 2, hallLen, 2, {50, 48, 52, 200})
    -- Ceiling lights
    for li = 0, cellCount - 1 do
        local lightX = hallSX + li * Config.CELL_W + Config.CELL_W / 2 - 6
        UI.Rect(lightX, hallY + 2, 12, 3, {120, 110, 90, 150})
    end

    -- Cells
    local cellEnd = cellStart + cellCount - 1

    for ci = cellStart, cellEnd do
        local cell = shared.cells[ci]
        if cell then
            if state.selectedInmate == ci then
                cell:highlight({255, 255, 100, 40})
            end
            -- Draw header bar
            local inmate = inmates and inmates[ci]
            cell:drawHeader(shared, inmate)
            -- Draw cell body
            cell:draw(shared)
            -- Draw inmate
            if inmate then
                cell:drawInmate(shared, inmate, phase, bobTimer)
            end
        end
    end
end

return Node.new({
    name = "world",

    onDraw = function(self, shared)
        if not Theme.ResolveTextures(shared) then return end

        local state = shared.state
        local W, H = shared.W, shared.H
        local tex = shared.tex
        local bobTimer = shared.bobTimer
        if not state then return end

        local phase = state.phase

        -- Background
        UI.Rect(0, Config.TOP_H, W, Config.PLAY_H, {15, 14, 18, 255})

        -- Initialize cells if needed
        if not shared.cells then
            shared.cells = {}
            for ci = 1, Config.TOTAL_CELLS do
                shared.cells[ci] = Cell.new(ci)
            end
        end

        -- Draw all 4 rows
        for level = 1, Config.ROW_COUNT do
            drawLevel(level, shared, phase, bobTimer)
        end

        -- Draw player
        local player = shared.player
        if player then
            local px = Camera.WorldToScreenX(player.x)
            local py = player:getScreenY()
            local flipX = player.facing < 0

            -- Player shadow
            UI.Rect(px + 4, py + player.h * player.scale - 4, player.w * player.scale - 8, 5, {0, 0, 0, 60})

            -- Walk bob
            local walkBob = 0
            if player.walkFrame > 0 then
                walkBob = math.sin(player.walkTimer * 20) * 2
            end

            -- Player sprite (green tint to distinguish from inmates)
            spr(tex.player, px, py + walkBob, player.w, player.h, player.scale, player.scale, {80, 255, 80, 255}, flipX)

            -- Label
            Text.Draw("IN-254", px - 4, py - 12, 8, {80, 255, 80, 200})

            -- Interaction prompt when near a cell
            local nearCell = player:getNearestCell()
            if nearCell > 0 and Colony.IsPlayerPhase(phase) then
                Text.Draw("[E] Interact", px - 20, py - 22, 10, C.YELLOW)
            end

            -- Staircase prompt
            if player:isNearStaircase() then
                local prompts = {}
                if player.level > 1 then prompts[#prompts + 1] = "[W] Up" end
                if player.level < Config.ROW_COUNT then prompts[#prompts + 1] = "[S] Down" end
                if #prompts > 0 then
                    Text.Draw(table.concat(prompts, "  "), px - 16, py - 22, 10, C.CYAN)
                end
            end
        end

        -- Row labels
        for level = 1, Config.ROW_COUNT do
            Text.Draw("L" .. level, 4, Camera.LevelScreenY(level) + 2, 9, C.DIM)
        end
    end
})
