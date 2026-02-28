-- ============================================
-- Scorchridge — Bottom Bar Sub-Scene
-- ============================================

local Theme = require("core/theme")
local UI = require("core/ui")


local modId = "Scorchridge"
local C = Theme.Colors
local L = Theme.Layout
local spr = Theme.Spr

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
        local gap = 8
        local cardW = math.floor((W - (count + 1) * gap) / count)
        local cardH = L.BOT_H - 12

        for i = 1, count do
            local im = inmates[i]
            if im then
                local cx = gap + (i - 1) * (cardW + gap)
                local cy = barY + 6
                local selected = (state.selectedInmate == i)
                local hovered = UI.IsHovered(cx, cy, cardW, cardH)

                if selected then
                    UI.Rect(cx - 2, cy, 3, cardH, {255, 220, 80, 200})
                end

                local bg = selected and C.CARD_SEL or (hovered and C.CARD_HOVER or C.CARD_BG)
                UI.Rect(cx, cy, cardW, cardH, bg)

                if UI.IsClicked(cx, cy, cardW, cardH) then
                    state.selectedInmate = i
                    GameData:SetTo(modId, "colony.state", state)
                end

                if shared.texturesReady then
                    spr(shared.tex.inmate, cx + 4, cy + 6, 16, 24, 2, 2)
                end

                local tx = cx + 40
                local rightEdge = cx + cardW - 6
                local tier = im.assignedTier or 1
                local tierData = production and production.oreTiers[tier]
                local tierName = tierData and tierData.name or ("T" .. tier)
                local tc = C.TIER_COLORS[tier] or C.WHITE
                local nameColor = selected and C.YELLOW or C.WHITE
                Text.Draw(im.name, tx, cy + 3, 11, nameColor)
                Text.Draw(tierName, rightEdge - #tierName * 6, cy + 3, 9, tc)

                if im.addicted then
                    Text.Draw("!", rightEdge - #tierName * 6 - 14, cy + 3, 11, C.RED)
                end

                local barX2 = tx
                local barMaxW = rightEdge - tx - 4
                local barH2 = 6

                local staColor = im.stamina < (im.maxStamina * 0.2) and C.RED or C.GREEN
                Text.Draw("S", barX2, cy + 17, 8, C.GRAY)
                UI.ProgressBar(barX2 + 10, cy + 18, barMaxW - 10, barH2, im.stamina, im.maxStamina, staColor, {30, 30, 40, 160})

                local morColor = im.morale < (im.maxMorale * 0.2) and C.RED or {100, 150, 255}
                Text.Draw("M", barX2, cy + 27, 8, C.GRAY)
                UI.ProgressBar(barX2 + 10, cy + 27, barMaxW - 10, barH2, im.morale, im.maxMorale, morColor, {30, 30, 40, 160})

                Text.Draw("Crd:" .. im.credits, tx, cy + 38, 9, C.GREEN)
                if im.exhausted then
                    Text.Draw("TIRED", rightEdge - 30, cy + 38, 8, C.RED)
                end

                if hovered then
                    UI.Tooltip(im.name .. " | STA:" .. math.floor(im.stamina) .. "/" .. im.maxStamina ..
                        " MOR:" .. math.floor(im.morale) .. "/" .. im.maxMorale ..
                        " CRD:" .. im.credits ..
                        (im.exhausted and " [EXHAUSTED]" or "") ..
                        (im.addicted and " [ADDICTED eff:" .. (im.drugEffectiveness or 0) .. "%]" or ""))
                end
            end
        end
    end
})
