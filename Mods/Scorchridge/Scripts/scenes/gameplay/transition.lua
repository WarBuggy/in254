-- ============================================
-- Scorchridge — Transition Sub-Scene
-- ============================================

local UI = require("core/ui")


return SceneNode.new({
    name = "transition",

    onDraw = function(self, shared)
        if shared.phaseTransTimer <= 0 then return end
        local W, H = shared.W, shared.H
        local alpha = math.min(math.floor(shared.phaseTransTimer / 1.2 * 255), 255)
        UI.Rect(0, math.floor(H / 2) - 24, W, 48, {0, 0, 0, math.floor(alpha * 0.6)})
        Text.Draw(shared.phaseTransText, math.floor(W / 2) - #shared.phaseTransText * 7, math.floor(H / 2) - 14, 28, {255, 255, 100, alpha})
    end
})
