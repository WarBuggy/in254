-- ============================================
-- Scorchridge — World Sub-Scene
-- Zone rendering, inmates per phase, ore/furniture
-- ============================================

local Theme = require("core/theme")
local UI = require("core/ui")

local Colony = require("systems/colony")
local ZoneClass = require("entities/zone")
local InmateClass = require("entities/inmate")

local C = Theme.Colors
local L = Theme.Layout
local spr = Theme.Spr

local FLOOR_DARK = {35, 30, 28, 255}
local FLOOR_CELL = {40, 35, 32, 255}
local FLOOR_MINE = {50, 40, 30, 255}
local FLOOR_MESS = {38, 38, 35, 255}
local WALL_INNER = {55, 50, 45, 255}
local SELECT_RING = {255, 255, 100, 120}

local function drawInmateTopDown(inmTex, x, y, scale, selected, tierColor)
    scale = scale or 2
    UI.Rect(x + 2, y + scale * 20, scale * 14, 6, {0, 0, 0, 60})
    spr(inmTex, x, y, 16, 24, scale, scale)
    if selected then
        UI.Rect(x - 3, y - 3, scale * 16 + 6, scale * 24 + 6, SELECT_RING)
    end
    if tierColor then
        UI.Rect(x + scale * 16 - 6, y - 2, 8, 8, tierColor)
    end
end

return SceneNode.new({
    name = "world",

    onDraw = function(self, shared)
        if not Theme.ResolveTextures(shared) then return end

        local state = shared.state
        local inmates = shared.inmates
        local resources = shared.resources
        local production = shared.production
        local W, H = shared.W, shared.H
        local tex = shared.tex
        local bobTimer = shared.bobTimer
        if not state then return end

        local phase = state.phase
        local count = inmates and #inmates or 3

        local sceneTop = L.TOP_H
        local sceneBot = H - L.BOT_H
        local sceneH = sceneBot - sceneTop
        local sceneW = W
        if Colony.IsPlayerPhase(phase) then
            sceneW = W - L.SIDE_W
        end

        UI.Rect(0, sceneTop, sceneW, sceneH, FLOOR_DARK)

        local barX = 16
        local barY = sceneTop + 16
        local barW = math.floor(sceneW * 0.25)
        local barH = sceneH - 32
        local cellH = math.floor((barH - 16) / count)

        local mineX = barX + barW + 16
        local mineY = sceneTop + 16
        local mineW = sceneW - mineX - 16
        local mineH = math.floor(sceneH * 0.45)

        local messX = mineX
        local messY = mineY + mineH + 12
        local messW = mineW
        local messH = sceneBot - messY - 16

        local barracks = ZoneClass.new({x=barX, y=barY, w=barW, h=barH, floorColor=FLOOR_CELL, label="BARRACKS"})
        local mine = ZoneClass.new({x=mineX, y=mineY, w=mineW, h=mineH, floorColor=FLOOR_MINE, label="MINE SHAFT"})
        local mess = ZoneClass.new({x=messX, y=messY, w=messW, h=messH, floorColor=FLOOR_MESS, label="MESS HALL"})

        barracks:draw()
        mine:draw()
        mess:draw()

        for i = 1, count do
            local cellY = barY + 8 + (i - 1) * cellH
            local cellW = barW - 16
            UI.Rect(barX + 8, cellY, cellW, cellH - 8, {45, 40, 36, 200})
            UI.Rect(barX + 8, cellY, cellW, 2, WALL_INNER)
            spr(tex.bed, barX + 14, cellY + cellH - 44, 32, 12, 1.8, 1.8)
            if inmates and inmates[i] then
                Text.Draw(inmates[i].name, barX + 12, cellY + 4, 9, C.GRAY)
            end
        end

        local mineInmSpacing = math.floor(mineW / (count + 1))
        local oreCY = mineY + math.floor(mineH / 2) - 20
        for oi = 1, count do
            local ox = mineX + mineInmSpacing * oi - 20
            spr(tex.ore, ox - 16, oreCY - 10, 20, 16, 2, 2)
            spr(tex.ore, ox + 14, oreCY + 16, 20, 16, 1.5, 1.5)
        end

        local tableDrawX = messX + math.floor(messW / 2) - 60
        local tableDrawY = messY + math.floor(messH / 2) - 16
        spr(tex.table, tableDrawX, tableDrawY, 40, 16, 3, 2)

        if resources then
            local crateCount = math.min(math.floor(resources.pcho / 20), 6)
            for ci = 1, crateCount do
                local row = math.floor((ci - 1) / 3)
                local col = (ci - 1) % 3
                spr(tex.pcho, messX + messW - 60 + col * 18, messY + messH - 50 + row * 18, 16, 16, 1, 1)
            end
        end

        local inmScale = 2
        local phaseChanged = (shared.lastDrawPhase ~= phase)
        local TC = C.TIER_COLORS

        if phase == "preparation" or phase == "postMeal" then
            if phaseChanged then
                for i = 1, count do
                    if inmates and inmates[i] then
                        local cellY2 = barY + 8 + (i - 1) * cellH
                        inmates[i]:setWanderTarget(barX + barW - 50, cellY2 + 10)
                    end
                end
                shared.lastDrawPhase = phase
            end

            for i = 1, count do
                if inmates and inmates[i] then
                    local cellY2 = barY + 8 + (i - 1) * cellH
                    inmates[i]:wander().bounds = {
                        x1 = barX + 40, x2 = barX + barW - 44,
                        y1 = cellY2 + 6, y2 = cellY2 + cellH - 56
                    }

                    local im = inmates[i]
                    local ws = im:wander()
                    local bob = im:idleBob()
                    local sel = (state.selectedInmate == i)
                    local tc = TC[im.assignedTier or 1]
                    drawInmateTopDown(tex.inmate, ws.x, ws.y + bob, inmScale, sel, tc)

                    local tier = im.assignedTier or 1
                    local tierData = production and production.oreTiers[tier]
                    local tierName = tierData and tierData.name or ("T" .. tier)
                    Text.Draw(tierName, ws.x - 2, ws.y + inmScale * 24 + 4, 10, TC[tier] or C.WHITE)
                end
            end

        elseif phase == "work" then
            if phaseChanged then
                for i = 1, count do
                    if inmates and inmates[i] then
                        inmates[i]:setWanderTarget(mineX + mineInmSpacing * i - 12, oreCY + 10)
                    end
                end
                shared.lastDrawPhase = phase
            end

            for i = 1, count do
                if inmates and inmates[i] then
                    local bx = mineX + mineInmSpacing * i - 16
                    inmates[i]:wander().bounds = {x1 = bx - 6, x2 = bx + 12, y1 = oreCY + 4, y2 = oreCY + 18}

                    local im = inmates[i]
                    local ws = im:wander()
                    local sel = (state.selectedInmate == i)
                    local tc = TC[im.assignedTier or 1]

                    if im.exhausted then
                        local slump = math.sin(ws.idleAnim * 0.5) * 0.5
                        drawInmateTopDown(tex.inmate, ws.x + 4, ws.y + 20 + slump, inmScale, sel, tc)
                        Text.Draw("EXHAUSTED", ws.x - 6, ws.y + inmScale * 24 + 24, 9, C.RED)
                    else
                        local swing = math.sin(bobTimer * 5 + i * 2) * 3
                        drawInmateTopDown(tex.inmateWork, ws.x + 4, ws.y + swing, inmScale, sel, tc)
                        local pSwing = math.sin(bobTimer * 6 + i * 2) * 5
                        spr(tex.pickaxe, ws.x - 14, ws.y - 8 + pSwing, 12, 12, 1.5, 1.5)
                        if math.sin(bobTimer * 8 + i * 3) > 0.6 then
                            local sparkOff = math.sin(bobTimer * 12 + i) * 6
                            Text.Draw("*", ws.x - 22 + sparkOff, ws.y - 16 + pSwing, 12, C.GOLD)
                            Text.Draw(".", ws.x - 10 - sparkOff, ws.y - 20 + pSwing, 10, C.ORANGE)
                        end
                    end

                    local detail = production and production.lastShiftDetails and production.lastShiftDetails[i]
                    if detail and detail.credits > 0 then
                        local floatY = ws.y - 14 - math.sin(bobTimer * 2) * 4
                        Text.Draw("+" .. detail.credits, ws.x + 8, floatY, 11, C.GREEN)
                    end
                end
            end

        elseif phase == "preMeal" then
            if phaseChanged then
                local messInmSpacing2 = math.floor(messW / (count + 1))
                for i = 1, count do
                    if inmates and inmates[i] then
                        inmates[i]:setWanderTarget(messX + messInmSpacing2 * i - 16, tableDrawY + 40)
                    end
                end
                shared.lastDrawPhase = phase
            end

            for i = 1, count do
                if inmates and inmates[i] then
                    local im = inmates[i]
                    im:wander().bounds = {
                        x1 = messX + 20, x2 = messX + messW - 50,
                        y1 = tableDrawY + 20, y2 = messY + messH - 60
                    }
                    local ws = im:wander()
                    local bob = im:idleBob(0.6)
                    local sel = (state.selectedInmate == i)
                    local tc = TC[im.assignedTier or 1]
                    drawInmateTopDown(tex.inmate, ws.x, ws.y + bob, inmScale, sel, tc)
                end
            end

        elseif phase == "meal" then
            if phaseChanged then
                local messInmSpacing2 = math.floor(messW / (count + 1))
                for i = 1, count do
                    if inmates and inmates[i] then
                        inmates[i]:setWanderTarget(messX + messInmSpacing2 * i - 16, tableDrawY - inmScale * 24 - 8)
                    end
                end
                shared.lastDrawPhase = phase
            end

            for i = 1, count do
                if inmates and inmates[i] then
                    local im = inmates[i]
                    local ws = im:wander()
                    local sel = (state.selectedInmate == i)
                    local tc = TC[im.assignedTier or 1]
                    local eatBob = math.sin(bobTimer * 3 + i * 1.5) * 2
                    local leanX = math.sin(bobTimer * 2 + i) * 1.5
                    drawInmateTopDown(tex.inmateEat, ws.x + leanX, ws.y + eatBob, inmScale, sel, tc)
                    spr(tex.foodBowl, ws.x + 6, tableDrawY + 4, 12, 8, 1.5, 1.5)
                    local recY = ws.y - 10 - math.abs(math.sin(bobTimer * 1.5 + i)) * 6
                    Text.Draw("+STA", ws.x + 2, recY, 9, C.GREEN)
                end
            end

        elseif phase == "downtime" then
            local yardCX = math.floor(sceneW / 2)
            local yardCY = sceneTop + math.floor(sceneH / 2)

            if phaseChanged then
                for i = 1, count do
                    if inmates and inmates[i] then
                        inmates[i]:setWanderTarget(yardCX - 20 + i * 30, yardCY - 10)
                    end
                end
                shared.lastDrawPhase = phase
            end

            for i = 1, count do
                if inmates and inmates[i] then
                    local im = inmates[i]
                    im:wander().bounds = {
                        x1 = barX + barW + 24, x2 = sceneW - 60,
                        y1 = sceneTop + 30, y2 = sceneBot - 50
                    }
                    local ws = im:wander()
                    local bob = im:idleBob(0.8)
                    local sel = (state.selectedInmate == i)
                    local tc = TC[im.assignedTier or 1]
                    drawInmateTopDown(tex.inmate, ws.x, ws.y + bob, inmScale, sel, tc)

                    local thoughtPhase = math.sin(ws.idleAnim * 0.3 + i * 2)
                    if thoughtPhase > 0.7 then
                        local thought = im.morale > 100 and ".." or (im.morale > 50 and "..." or "!?")
                        local tColor = im.morale > 100 and C.GRAY or (im.morale > 50 and C.DIM or C.RED)
                        Text.Draw(thought, ws.x + 20, ws.y - 14 + math.sin(ws.idleAnim) * 2, 9, tColor)
                    end
                end
            end

        elseif phase == "rest" then
            if phaseChanged then
                shared.lastDrawPhase = phase
            end

            for i = 1, count do
                if inmates and inmates[i] then
                    local im = inmates[i]
                    local ws = im:wander()
                    local cellY2 = barY + 8 + (i - 1) * cellH
                    local bedDrawX = barX + 14
                    local bedDrawY = cellY2 + cellH - 44
                    local breath = math.sin(ws.idleAnim * 1.2 + i * 0.9) * 1.5
                    spr(tex.inmateRest, bedDrawX + 6, bedDrawY - 14 + breath, 24, 12, 1.8, 1.8)
                    local zPhase = ws.idleAnim * 0.8 + i
                    local zX = 70 + math.sin(zPhase) * 8
                    local zY = -20 - math.abs(math.sin(zPhase * 0.5)) * 10
                    local zAlpha = math.floor(180 + math.sin(zPhase * 1.3) * 60)
                    Text.Draw("z", bedDrawX + zX, bedDrawY + zY, 11, {140, 140, 160, zAlpha})
                    Text.Draw("Z", bedDrawX + zX + 14, bedDrawY + zY - 8, 14, {140, 140, 160, zAlpha})
                    Text.Draw("z", bedDrawX + zX + 30, bedDrawY + zY - 4, 9, {140, 140, 160, zAlpha})
                end
            end
        end

        local HIGHLIGHT = {255, 200, 60, 40}
        if phase == "work" then
            mine:highlight(HIGHLIGHT)
        elseif phase == "meal" or phase == "preMeal" then
            mess:highlight(HIGHLIGHT)
        elseif phase == "preparation" or phase == "postMeal" or phase == "rest" then
            barracks:highlight(HIGHLIGHT)
        end
    end
})
