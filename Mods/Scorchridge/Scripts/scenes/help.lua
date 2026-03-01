-- ============================================
-- Scorchridge — Help Scene
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
    tex.inmate = Animation.FrameTextureIdFrom(modId, "scrInmate", "base", "idle", 1)
    tex.ore    = Animation.FrameTextureIdFrom(modId, "scrOre", "base", "idle", 1)
    tex.pcho   = Animation.FrameTextureIdFrom(modId, "scrPcho", "base", "idle", 1)
    tex.sky    = Animation.FrameTextureIdFrom(modId, "scrSky", "base", "idle", 1)
    for _, v in pairs(tex) do
        if not v then return false end
    end
    texturesReady = true
    return true
end

local helpNode = Node.new({
    name = "help",

    onEnter = function(self, shared)
        SFX.LoadMenuSounds()
        print("[Scorchridge] Entered help scene.")
    end,

    onExit = function(self, shared)
    end,

    onUpdate = function(self, dt, totalTime, shared)
        UI.UpdateInput()
        if Input.IsKeyPressed("enter") then
            Scene.Switch("gameplay")
        end
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end

        local W, H = Screen.Width(), Screen.Height()

        if resolveTextures() then
            for x = 0, W, 64 do
                for y = 0, H, 64 do spr(tex.sky, x, y, 64, 64) end
            end
        end

        UI.Panel(20, 10, W - 40, H - 20, {10, 10, 20, 220})

        local L = 40
        local y = 20

        Text.Draw("SCORCHRIDGE PENAL COLONY", L, y, 28, C.YELLOW); y = y + 38
        Text.Draw("Manage 3 inmates mining ore to meet credit quotas.", L, y, 16, C.WHITE); y = y + 30

        Text.Draw("YOUR DECISIONS", L, y, 20, C.CYAN); y = y + 24
        Text.Draw("PREPARATION: assign each inmate an ore tier (click or 1/2/3).", L + 10, y, 14, C.GREEN); y = y + 18
        Text.Draw("  Copper (safe, low)  Silver (medium)  Gold (risky, high)", L + 10, y, 12, C.GRAY); y = y + 18
        Text.Draw("PRE-MEAL: choose portion size for all inmates.", L + 10, y, 14, C.GREEN); y = y + 18
        Text.Draw("  Small (save food) / Normal / Large (full recovery)", L + 10, y, 12, C.GRAY); y = y + 24

        Text.Draw("GAME FLOW", L, y, 20, C.CYAN); y = y + 24
        Text.Draw("1 Cycle = 4 Quadrants.  Each quadrant: 7 phases.", L + 10, y, 14, C.WHITE); y = y + 18
        Text.Draw("Prep > Work > PreMeal > Meal > PostMeal > Down > Rest", L + 10, y, 12, C.GRAY); y = y + 18
        Text.Draw("After 4 quadrants: quota check. 2/3 inmates fail = GAME OVER.", L + 10, y, 14, C.RED); y = y + 24

        Text.Draw("CONTROLS", L, y, 20, C.CYAN); y = y + 24
        Text.Draw("Mouse: click inmates, buttons, panels.  Keyboard: 1/2/3, Enter, E/C, Esc", L + 10, y, 14, C.WHITE); y = y + 30

        local btnW, btnH = 200, 40
        local btnX = math.floor(W / 2) - 100
        if UI.Button(btnX, y, btnW, btnH, ">>> Begin <<<", {
            color = {50, 70, 50, 230},
            hoverColor = {70, 100, 70, 240},
            textColor = C.YELLOW,
            textSize = 18
        }) then
            Scene.Switch("gameplay")
        end

        if resolveTextures() then
            local px = W - 180
            spr(tex.inmate, px, 80, 16, 24, 4, 4)
            Text.Draw("Inmate", px + 70, 100, 12, C.ORANGE)
            spr(tex.ore, px, 200, 20, 16, 4, 4)
            Text.Draw("Ore", px + 90, 215, 12, C.GOLD)
            spr(tex.pcho, px, 300, 16, 16, 4, 4)
            Text.Draw("PCHO", px + 70, 315, 12, C.GREEN)
        end

        UI.DrawTooltip()
    end
})

helpNode:registerAsScene("help")

return helpNode
