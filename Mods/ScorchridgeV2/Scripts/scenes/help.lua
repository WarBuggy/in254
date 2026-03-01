-- ============================================
-- ScorchridgeV2 — Help Scene
-- ============================================

local Theme = require("core/theme")
local SFX = require("core/sound")
local UI = require("core/ui")

local modId = "ScorchridgeV2"
local C = Theme.Colors

local helpNode = SceneNode.new({
    name = "help",

    onEnter = function(self, shared)
        SFX.LoadMenuSounds()
        print("[ScorchridgeV2] Entered help scene.")
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

        -- Dark background
        UI.Rect(0, 0, W, H, {10, 10, 18, 255})
        UI.Panel(20, 10, W - 40, H - 20, {15, 15, 25, 230})

        local L = 40
        local y = 20

        Text.Draw("SCORCHRIDGE V2 - SIDE SCROLLING", L, y, 24, C.YELLOW); y = y + 34
        Text.Draw("Manage 20 inmates in a two-level underground bunker.", L, y, 14, C.WHITE); y = y + 22
        Text.Draw("Inmates never leave their cells - they mine via neural-link terminals.", L, y, 12, C.GRAY); y = y + 24

        Text.Draw("CONTROLS", L, y, 18, C.CYAN); y = y + 22
        Text.Draw("W/A/S/D: Move warden through hallways", L + 10, y, 12, C.GREEN); y = y + 16
        Text.Draw("W/S at staircase: Switch between levels", L + 10, y, 12, C.GREEN); y = y + 16
        Text.Draw("E near cell: Open inmate management panel", L + 10, y, 12, C.GREEN); y = y + 16
        Text.Draw("ENTER: Advance to next phase", L + 10, y, 12, C.GREEN); y = y + 16
        Text.Draw("ESC: Close panel", L + 10, y, 12, C.GREEN); y = y + 24

        Text.Draw("GAME FLOW", L, y, 18, C.CYAN); y = y + 22
        Text.Draw("1 Cycle = 4 Quadrants. Each quadrant: 7 phases.", L + 10, y, 12, C.WHITE); y = y + 16
        Text.Draw("Prep > Work > PreMeal > Meal > PostMeal > Down > Rest", L + 10, y, 12, C.GRAY); y = y + 16
        Text.Draw("During PREP: walk to cells, press E, assign ore tiers", L + 10, y, 12, C.WHITE); y = y + 16
        Text.Draw("During PRE-MEAL: choose portion sizes, toggle PCHO bonus", L + 10, y, 12, C.WHITE); y = y + 16
        Text.Draw("After 4 quadrants: quota check, then RESUPPLY screen", L + 10, y, 12, C.WHITE); y = y + 16
        Text.Draw("2/3 inmates fail quota = GAME OVER", L + 10, y, 14, C.RED); y = y + 24

        Text.Draw("RESOURCES", L, y, 18, C.CYAN); y = y + 22
        Text.Draw("Oxygen: drains 2/inmate/quadrant. <100 = penalties. 0 = death!", L + 10, y, 12, C.WHITE); y = y + 16
        Text.Draw("Food: consumed during meals based on portion size (S=2, M=4, L=6)", L + 10, y, 12, C.WHITE); y = y + 16
        Text.Draw("Credits ($): earned from mining, spent at resupply shop", L + 10, y, 12, C.WHITE); y = y + 16
        Text.Draw("PCHO: premium supplement (inventory). Toggle ON for +15 sta/+5 mor", L + 10, y, 12, C.WHITE); y = y + 16
        Text.Draw("Drugs: combat stims (inventory). Boost stats but risk addiction", L + 10, y, 12, C.WHITE); y = y + 24

        Text.Draw("WORLD LAYOUT", L, y, 18, C.CYAN); y = y + 22
        Text.Draw("Level 1: [Control Room] [Stairs] [Cell 1-10]", L + 10, y, 12, C.WHITE); y = y + 16
        Text.Draw("Level 2: [Stairs] [Cell 11-20]", L + 10, y, 12, C.WHITE); y = y + 28

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

        UI.DrawTooltip()
    end
})

helpNode:registerAsScene("help")

return helpNode
