-- ============================================
-- ScorchridgeV2 — Bottom Bar Sub-Scene
-- Inmate dot-map, selected inmate info
-- ============================================

local Theme = require("core/theme")
local Config = require("core/config")
local UI = require("core/ui")

local modId = "ScorchridgeV2"
local C = Theme.Colors
local L = Theme.Layout

return SceneNode.new({
    name = "bottombar",

    onDraw = function(self, shared)
        local state = shared.state
        local inmates = shared.inmates
        local production = shared.production
        local W, H = shared.W, shared.H
        if not state or not inmates then return end

        local barY = H - L.BOT_H
        UI.Panel(0, barY, W, L.BOT_H, C.DARK_BG)

        local count = #inmates

        -- Dot map: 20 dots, 6 per row, 4 rows
        local dotSize = 10
        local dotGap = 3
        local dotsPerRow = 6
        local dotAreaW = dotsPerRow * (dotSize + dotGap)
        local dotStartX = 10
        local dotStartY = barY + 4

        for i = 1, count do
            local row = math.floor((i - 1) / dotsPerRow)
            local col = (i - 1) % dotsPerRow
            local dx = dotStartX + col * (dotSize + dotGap)
            local dy = dotStartY + row * (dotSize + dotGap + 1)

            local im = inmates[i]
            local dotColor = C.GREEN
            if im.exhausted then
                dotColor = C.RED
            elseif im.stamina < im.maxStamina * 0.3 then
                dotColor = C.ORANGE
            elseif im.morale < im.maxMorale * 0.3 then
                dotColor = {200, 100, 200}
            end

            -- Selected highlight
            if state.selectedInmate == i then
                UI.Rect(dx - 1, dy - 1, dotSize + 2, dotSize + 2, {255, 255, 100, 120})
            end

            UI.Rect(dx, dy, dotSize, dotSize, dotColor)

            -- Click to select
            if UI.IsClicked(dx, dy, dotSize, dotSize) then
                state.selectedInmate = i
                GameData:SetTo(modId, "colony.state", state)
            end

            -- Tier color indicator (tiny dot)
            local tc = C.TIER_COLORS[im.assignedTier or 1]
            if tc then
                UI.Rect(dx + dotSize - 3, dy, 3, 3, tc)
            end

            -- Addiction marker
            if im.addicted then
                UI.Rect(dx, dy, 3, 3, C.RED)
            end
        end

        -- Selected inmate detail strip
        local detailX = dotStartX + dotAreaW + 20
        local detailY = barY + 6
        local selected = inmates[state.selectedInmate]

        if selected then
            local nameColor = C.YELLOW
            Text.Draw(selected.name .. " (#" .. state.selectedInmate .. ")", detailX, detailY, 12, nameColor)
            detailY = detailY + 16

            -- Tier
            local tier = selected.assignedTier or 1
            local tierData = production and production.oreTiers[tier]
            local tierName = tierData and tierData.name or ("T" .. tier)
            local tc = C.TIER_COLORS[tier] or C.WHITE
            Text.Draw("Tier: " .. tierName, detailX, detailY, 10, tc)
            detailY = detailY + 13

            -- Stats bars
            local barW = 120
            local barH = 6
            local staColor = selected.stamina < (selected.maxStamina * 0.2) and C.RED or C.GREEN
            Text.Draw("S", detailX, detailY, 8, C.GRAY)
            UI.ProgressBar(detailX + 12, detailY + 1, barW, barH, selected.stamina, selected.maxStamina, staColor, {30, 30, 40, 160})
            Text.Draw(math.floor(selected.stamina) .. "", detailX + barW + 16, detailY, 8, C.GRAY)
            detailY = detailY + 10

            local morColor = selected.morale < (selected.maxMorale * 0.2) and C.RED or {100, 150, 255}
            Text.Draw("M", detailX, detailY, 8, C.GRAY)
            UI.ProgressBar(detailX + 12, detailY + 1, barW, barH, selected.morale, selected.maxMorale, morColor, {30, 30, 40, 160})
            Text.Draw(math.floor(selected.morale) .. "", detailX + barW + 16, detailY, 8, C.GRAY)
            detailY = detailY + 10

            -- Credits
            Text.Draw("Crd:" .. selected.credits, detailX, detailY, 9, C.GREEN)
            if selected.exhausted then
                Text.Draw("EXHAUSTED", detailX + 80, detailY, 8, C.RED)
            end
            if selected.addicted then
                Text.Draw("ADDICTED", detailX + 150, detailY, 8, C.RED)
            end
        end

        -- Level indicator dots (L1-L4)
        local levelX = W - 40
        local levelY = barY + 6
        for lvl = 1, Config.ROW_COUNT do
            local lColor = shared.player and shared.player.level == lvl and C.YELLOW or C.DIM
            Text.Draw("L" .. lvl, levelX, levelY + (lvl - 1) * 14, 9, lColor)
        end
    end
})
