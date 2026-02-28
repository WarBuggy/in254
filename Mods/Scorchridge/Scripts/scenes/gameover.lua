-- ============================================
-- Scorchridge — Game Over Scene
-- ============================================

local Theme = require("core/theme")
local SFX = require("core/sound")
local UI = require("core/ui")


local modId = "Scorchridge"
local C = Theme.Colors
local spr = Theme.Spr

local tex = {}
local texturesReady = false

local function resolveTextures()
    if texturesReady then return true end
    tex.sky = Animation.FrameTextureIdFrom(modId, "scrSky", "base", "idle", 1)
    if not tex.sky then return false end
    texturesReady = true
    return true
end

local gameoverNode = SceneNode.new({
    name = "gameover",

    onEnter = function(self, shared)
        SFX.StopBGM()
        print("[Scorchridge] Game Over.")
    end,

    onUpdate = function(self, dt, totalTime, shared)
        UI.UpdateInput()
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end

        local W, H = Screen.Width(), Screen.Height()

        if resolveTextures() then
            for x = 0, W, 64 do
                for y = 0, H, 64 do spr(tex.sky, x, y, 64, 64) end
            end
        end

        UI.Rect(0, 0, W, H, {0, 0, 0, 140})

        local cx = math.floor(W / 2)
        local cy = math.floor(H / 2)
        UI.Panel(cx - 250, cy - 80, 500, 160, {30, 10, 10, 240})
        UI.Rect(cx - 252, cy - 82, 504, 164, {180, 40, 40, 200})
        Text.Draw("GAME OVER", cx - 80, cy - 60, 28, C.RED)
        Text.Draw("The colony has been shut down.", cx - 130, cy - 20, 14, C.GRAY)
        Text.Draw("Press Esc to quit", cx - 70, cy + 30, 14, C.DIM)

        UI.DrawTooltip()
    end
})

gameoverNode:registerAsScene("gameover")

return gameoverNode
