-- ============================================
-- Scorchridge — Top Bar Sub-Scene
-- ============================================

local Theme = require("core/theme")
local UI = require("core/ui")

local Colony = require("systems/colony")

local C = Theme.Colors
local L = Theme.Layout

return SceneNode.new({
    name = "topbar",

    onDraw = function(self, shared)
        local state = shared.state
        local resources = shared.resources
        local production = shared.production
        local W = shared.W
        if not state then return end

        UI.Panel(0, 0, W, L.TOP_H, C.DARK_BG)

        local x = 10
        Text.Draw("Cycle " .. state.cycle, x, 6, 18, C.WHITE)
        x = x + 90
        Text.Draw("Q " .. state.quadrant .. "/4", x, 6, 18, C.WHITE)
        x = x + 70
        Text.Draw(Theme.PhaseName(state.phase), x, 6, 18, C.YELLOW)

        local dotX = math.floor(W / 2) - 56
        local PHASES = Colony.GetPhases()
        for i = 1, #PHASES do
            local filled = (i <= state.phaseIndex)
            local dotColor = filled and C.GREEN or {60, 60, 70, 200}
            if i == state.phaseIndex then dotColor = C.YELLOW end
            UI.Rect(dotX + (i - 1) * 18, 18, 12, 12, dotColor)
        end

        local rx = W - 10
        if resources then
            local mStr = "M:" .. (resources.colonyMerits or 0)
            rx = rx - #mStr * 8 - 8
            Text.Draw(mStr, rx, 6, 14, C.CYAN)

            local cStr = "Crd:" .. (resources.colonyCredits or 0)
            rx = rx - #cStr * 8 - 8
            Text.Draw(cStr, rx, 6, 14, C.GREEN)

            local pStr = "PCHO:" .. (resources.pcho or 0)
            rx = rx - #pStr * 8 - 8
            local pc = (resources.pcho or 0) < 30 and C.RED or C.WHITE
            Text.Draw(pStr, rx, 6, 14, pc)

            if resources.drugSupply then
                local dStr = "Drug:" .. resources.drugSupply
                rx = rx - #dStr * 8 - 8
                Text.Draw(dStr, rx, 6, 14, C.ORANGE)
            end
        end

        if production then
            local e = production.cycleCreditsEarned or 0
            local q = production.quotaPerCycle or 80
            local pct = q > 0 and math.floor((e / q) * 100) or 0
            local qc = e >= q and C.GREEN or (pct > 50 and C.YELLOW or C.RED)
            Text.Draw("Quota: " .. e .. "/" .. q .. " (" .. pct .. "%)", 10, 28, 12, qc)
            UI.ProgressBar(160, 30, 200, 10, e, q, qc, {40, 40, 50, 180})
        end
    end
})
