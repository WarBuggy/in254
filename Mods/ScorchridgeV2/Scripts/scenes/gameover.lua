-- ============================================
-- ScorchridgeV2 — Game Over Scene
-- ============================================

local Theme = require("core/theme")
local SFX = require("core/sound")
local UI = require("core/ui")

local modId = "ScorchridgeV2"
local C = Theme.Colors

local gameoverNode = Node.new({
    name = "gameover",

    onEnter = function(self, shared)
        SFX.StopBGM()
        print("[ScorchridgeV2] Game Over.")
    end,

    onUpdate = function(self, dt, totalTime, shared)
        UI.UpdateInput()
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end

        local W, H = Screen.Width(), Screen.Height()

        UI.Rect(0, 0, W, H, {10, 5, 5, 255})

        local cx = math.floor(W / 2)
        local cy = math.floor(H / 2)
        UI.Rect(cx - 252, cy - 82, 504, 164, {180, 40, 40, 200})
        UI.Panel(cx - 250, cy - 80, 500, 160, {30, 10, 10, 240})
        Text.Draw("GAME OVER", cx - 80, cy - 60, 28, C.RED)
        Text.Draw("OvAI has deemed the colony non-viable.", cx - 160, cy - 20, 14, C.GRAY)
        Text.Draw("Supply deliveries have been suspended.", cx - 155, cy, 14, C.GRAY)
        Text.Draw("Press Esc to quit", cx - 70, cy + 40, 14, C.DIM)

        UI.DrawTooltip()
    end
})

gameoverNode:registerAsScene("gameover")

return gameoverNode
