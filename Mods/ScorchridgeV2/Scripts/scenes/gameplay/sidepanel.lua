-- ============================================
-- ScorchridgeV2 — Side Panel Sub-Scene
-- Management overlay opened with E near terminal
-- ============================================

local Theme = require("core/theme")
local UI = require("core/ui")
local Colony = require("systems/colony")
local Inmates = require("systems/inmates")
local Drugs = require("systems/drugs")
local Merits = require("systems/merits")
local Inventory = require("systems/inventory")

local modId = "ScorchridgeV2"
local C = Theme.Colors
local L = Theme.Layout
local TIER_ICONS = {"Cu", "Ag", "Au"}
local PORTION_ICONS = {"S", "M", "L"}

return SceneNode.new({
    name = "sidepanel",

    onDraw = function(self, shared)
        local state = shared.state
        local inmates = shared.inmates
        local resources = shared.resources
        local production = shared.production
        local W, H = shared.W, shared.H
        if not state then return end

        local phase = state.phase
        if not shared.sidePanelOpen then return end
        if not Colony.IsPlayerPhase(phase) then
            shared.sidePanelOpen = false
            return
        end

        local px = W - L.SIDE_W
        local py = L.TOP_H
        local pw = L.SIDE_W
        local ph = H - L.TOP_H - L.BOT_H
        UI.Panel(px, py, pw, ph, C.SIDE_BG)

        local y = py + 10
        local x = px + 10
        local bw = pw - 20

        Text.Draw(Theme.PhaseName(phase), x, y, 14, C.YELLOW)
        y = y + 20

        local selIdx = state.selectedInmate
        local selected = inmates and inmates[selIdx]

        if phase == "preparation" and production then
            if selected then
                Text.Draw(selected.name .. " (#" .. selIdx .. ")", x, y, 12, C.WHITE)
                y = y + 18
            end

            Text.Draw("Ore Tier:", x, y, 10, C.GRAY)
            y = y + 14

            local iconSize = 44
            local iconGap = 6
            local rowX = x
            for ti = 1, 3 do
                local td = production.oreTiers[ti]
                if td then
                    local tc = C.TIER_COLORS[ti] or C.WHITE
                    local isActive = selected and (selected.assignedTier == ti)
                    local clicked = UI.IconButton(rowX, y, iconSize, TIER_ICONS[ti], {
                        color = {45, 42, 38, 220},
                        hoverColor = {tc[1], tc[2], tc[3], 80},
                        iconColor = tc,
                        iconSize = 18,
                        selected = isActive,
                        label = td.name
                    })
                    if clicked and selected and inmates then
                        selected.assignedTier = ti
                        GameData:SetTo(modId, "colony.inmates", inmates)
                    end
                    rowX = rowX + iconSize + iconGap
                end
            end
            y = y + iconSize + 16

            if selected and production then
                local tier = selected.assignedTier or 1
                local td = production.oreTiers[tier]
                if td then
                    local tc = C.TIER_COLORS[tier] or C.WHITE
                    Text.Draw(td.name .. " Ore", x, y, 11, tc)
                    y = y + 14
                    Text.Draw("-" .. td.staCost .. " stamina", x, y, 10, C.ORANGE)
                    local credits, cost, canWork = Inmates.PreviewWorkOutput(selected, production, tier)
                    if canWork then
                        Text.Draw("+" .. credits .. " crd", x + 90, y, 10, C.GREEN)
                    else
                        Text.Draw("Can't work", x + 90, y, 10, C.RED)
                    end
                    y = y + 16
                end
            end

            -- Drug administration
            if selected then
                y = y + 6
                local drugCount = Inventory.GetCount("drug_dose")
                local canDose = drugCount > 0 and not selected.dosedThisQuadrant
                local eff = selected.drugEffectiveness or 100
                local clicked = UI.IconButton(x, y, 36, "Rx", {
                    color = {70, 35, 35, 220},
                    hoverColor = {100, 50, 50, 230},
                    iconColor = canDose and C.ORANGE or C.DIM,
                    iconSize = 16,
                    disabled = not canDose,
                    label = "Drug"
                })
                Text.Draw(eff .. "% eff", x + 44, y + 6, 10, C.GRAY)
                if selected.addicted then
                    Text.Draw("ADDICTED", x + 44, y + 18, 9, C.RED)
                end
                Text.Draw("x" .. drugCount, x + 110, y + 6, 10, C.DIM)

                if clicked then
                    local ok, msg = Drugs.Administer(selected)
                    if ok then
                        GameData:SetTo(modId, "colony.inmates", inmates)
                    end
                end
                y = y + 44
            end

        elseif phase == "preMeal" and production then
            Text.Draw("Portion Size:", x, y, 10, C.GRAY)
            y = y + 14

            local inmateCount = inmates and #inmates or 20
            local iconSize = 44
            local iconGap = 6
            local rowX = x
            for pi = 1, 3 do
                local pd = production.portionSizes[pi]
                if pd then
                    local isSel = (state.portionSize == pi)
                    local clicked = UI.IconButton(rowX, y, iconSize, PORTION_ICONS[pi], {
                        color = {38, 45, 38, 220},
                        hoverColor = {60, 80, 60, 230},
                        iconColor = isSel and C.YELLOW or C.WHITE,
                        iconSize = 20,
                        selected = isSel,
                        label = pd.name
                    })
                    if clicked then
                        state.portionSize = pi
                        GameData:SetTo(modId, "colony.state", state)
                    end
                    rowX = rowX + iconSize + iconGap
                end
            end
            y = y + iconSize + 16

            local ps = state.portionSize or 2
            local pd = production.portionSizes[ps]
            if pd then
                local totalFood = pd.food * inmateCount
                Text.Draw(pd.name .. " Portions", x, y, 11, C.WHITE)
                y = y + 14
                Text.Draw("+" .. pd.staRec .. " sta  +" .. pd.morRec .. " mor", x, y, 10, C.GREEN)
                y = y + 12
                Text.Draw("-" .. totalFood .. " food (total)", x, y, 10, C.ORANGE)
                y = y + 16
            end

            -- PCHO toggle
            local pchoCount = Inventory.GetCount("pcho_ration")
            local pchoLabel = state.usePcho and "PCHO: ON" or "PCHO: OFF"
            local pchoClicked = UI.Button(x, y, 90, 28, pchoLabel, {
                color = state.usePcho and {40, 65, 40, 230} or {50, 50, 50, 220},
                hoverColor = state.usePcho and {55, 85, 55, 240} or {70, 70, 70, 230},
                textColor = state.usePcho and C.GREEN or C.GRAY,
                textSize = 11
            })
            if pchoClicked then
                state.usePcho = not state.usePcho
                GameData:SetTo(modId, "colony.state", state)
            end
            Text.Draw("x" .. pchoCount, x + 98, y + 8, 10, C.DIM)
            if state.usePcho then
                Text.Draw("+15 sta +5 mor bonus", x, y + 30, 9, C.GREEN)
            end
            y = y + 46

        elseif phase == "postMeal" and selected then
            Text.Draw(selected.name .. " (#" .. selIdx .. ")", x, y, 12, C.WHITE)
            y = y + 16
            Text.Draw("STA: " .. math.floor(selected.stamina) .. "/" .. selected.maxStamina, x, y, 10, C.GREEN)
            y = y + 12
            Text.Draw("MOR: " .. math.floor(selected.morale) .. "/" .. selected.maxMorale, x, y, 10, {100, 150, 255})
            y = y + 12
            Text.Draw("CRD: " .. selected.credits, x, y, 10, C.CYAN)
            y = y + 16
            if selected.addicted then
                Text.Draw("ADDICTED (eff: " .. (selected.drugEffectiveness or 0) .. "%)", x, y, 9, C.RED)
                y = y + 14
            end

            -- Drug administration in postMeal too
            y = y + 6
            local drugCount = Inventory.GetCount("drug_dose")
            local canDose = drugCount > 0 and not selected.dosedThisQuadrant
            local clicked = UI.IconButton(x, y, 36, "Rx", {
                color = {70, 35, 35, 220},
                hoverColor = {100, 50, 50, 230},
                iconColor = canDose and C.ORANGE or C.DIM,
                iconSize = 16,
                disabled = not canDose,
                label = "Drug"
            })
            Text.Draw("x" .. drugCount, x + 44, y + 6, 10, C.DIM)
            if clicked then
                local ok, msg = Drugs.Administer(selected)
                if ok then
                    GameData:SetTo(modId, "colony.inmates", inmates)
                end
            end
            y = y + 44
        end

        -- Bottom buttons
        local btnY = py + ph - 40
        local btnX = x

        -- Store button
        if UI.IconButton(btnX, btnY, 34, "$", {
            color = {35, 50, 65, 220},
            hoverColor = {50, 70, 90, 230},
            iconColor = C.CYAN,
            iconSize = 18,
            label = "Store"
        }) then
            Merits.ToggleStore()
        end
        btnX = btnX + 42

        -- Close panel button
        if UI.Button(btnX, btnY, 60, 34, "Close", {
            color = {65, 45, 45, 230},
            hoverColor = {90, 65, 65, 240},
            textColor = C.WHITE,
            textSize = 12
        }) then
            shared.sidePanelOpen = false
        end
        btnX = btnX + 68

        -- Advance button
        local advW = bw - (btnX - x)
        local advClicked = UI.Button(btnX, btnY, advW, 34, ">> Advance", {
            color = {45, 60, 45, 230},
            hoverColor = {65, 90, 65, 240},
            textColor = C.YELLOW,
            textSize = 13
        })
        if advClicked then
            Colony.AdvancePhase()
        end
    end
})
