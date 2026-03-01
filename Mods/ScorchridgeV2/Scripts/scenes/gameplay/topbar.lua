-- ============================================
-- ScorchridgeV2 — Top Bar Sub-Scene
-- HUD: cycle, phase, resources, quota
-- ============================================

local Theme = require("core/theme")
local UI = require("core/ui")
local Colony = require("systems/colony")

local C = Theme.Colors
local L = Theme.Layout

return Node.new({
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

        -- Phase dots
        local dotX = math.floor(W / 2) - 56
        local PHASES = Colony.GetPhases()
        for i = 1, #PHASES do
            local filled = (i <= state.phaseIndex)
            local dotColor = filled and C.GREEN or {60, 60, 70, 200}
            if i == state.phaseIndex then dotColor = C.YELLOW end
            UI.Rect(dotX + (i - 1) * 18, 18, 12, 12, dotColor)
        end

        -- Player phase indicator
        if Colony.IsPlayerPhase(state.phase) then
            Text.Draw("[ENTER] Advance", math.floor(W / 2) - 50, 34, 10, C.YELLOW)
        end

        -- Resources
        local rx = W - 10
        if resources then
            local mStr = "M:" .. (resources.colonyMerits or 0)
            rx = rx - #mStr * 8 - 8
            Text.Draw(mStr, rx, 6, 14, C.CYAN)

            local cStr = "$" .. (resources.colonyCredits or 0)
            rx = rx - #cStr * 8 - 8
            Text.Draw(cStr, rx, 6, 14, C.GREEN)

            local fVal = resources.food or 0
            local fStr = "Food:" .. fVal
            rx = rx - #fStr * 8 - 8
            local fc = fVal < 80 and C.RED or C.WHITE
            Text.Draw(fStr, rx, 6, 14, fc)

            local o2Val = resources.oxygen or 0
            local o2Str = "O2:" .. o2Val
            rx = rx - #o2Str * 8 - 8
            local o2c = o2Val < 100 and C.RED or (o2Val < 200 and C.ORANGE or C.WHITE)
            Text.Draw(o2Str, rx, 6, 14, o2c)
        end

        -- Quota progress
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
