-- ============================================
-- Terraria2D — Game Over Scene
-- ============================================

local UI = require("core/ui")
local Theme = require("core/theme")
local C = Theme.Colors

local gameoverNode = SceneNode.new({
    name = "gameover",

    onEnter = function(self, shared)
        print("[Terraria2D] Game Over.")
    end,

    onUpdate = function(self, dt, totalTime, shared)
        UI.UpdateInput()
        if Input.IsKeyPressed("enter") then
            Scene.Switch("title")
        end
        if Input.IsKeyPressed("escape") then
            Scene.Switch("title")
        end
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end

        local W, H = Screen.Width(), Screen.Height()

        UI.Rect(0, 0, W, H, {10, 5, 5, 255})

        local cx = math.floor(W / 2)
        local cy = math.floor(H / 2)

        UI.Panel(cx - 150, cy - 60, 300, 120, {30, 10, 10, 240})
        Text.Draw("GAME OVER", cx - 70, cy - 45, 24, C.RED)
        Text.Draw("Your adventure has ended.", cx - 90, cy - 10, 12, C.GRAY)

        if UI.Button(cx - 80, cy + 20, 160, 30, "  Return to Title", {
            color = {60, 30, 30, 230},
            hoverColor = {80, 40, 40, 240},
            textSize = 12,
        }) then
            Scene.Switch("title")
        end

        UI.DrawTooltip()
    end
})

gameoverNode:registerAsScene("gameover")

return gameoverNode
