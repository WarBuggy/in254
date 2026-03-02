-- ============================================
-- ExtractOrDie — Title Screen
-- ============================================

local UI = require("eod/core/ui")
local Theme = require("eod/core/theme")
local C = Theme.Colors

local _cBg       = Color.New(8, 8, 12)
local _cPanel     = Color.New(15, 15, 22, 240)
local _cBtnBase   = Color.New(40, 80, 40, 230)
local _cBtnHover  = Color.New(60, 110, 60, 240)
local _cAccent    = Color.New(200, 50, 50)
local _cSubtitle  = Color.New(180, 160, 140)

local titleNode = Node.new({
    name = "title",

    onEnter = function(self, shared)
        Drawing.RegisterLayer("ui", 30, { blend = "alpha" })
        print("[ExtractOrDie] Title screen entered.")
    end,

    onExit = function(self, shared) end,

    onUpdate = function(self, dt, totalTime, shared)
        UI.UpdateInput()
        if Input.IsKeyPressed("enter") then
            Scene.Switch("eod_loadout")
        end
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end

        Drawing.SetLayer("ui")
        local W, H = Screen.Width(), Screen.Height()

        -- Dark background
        UI.Rect(0, 0, W, H, _cBg)

        -- Decorative grid lines
        for i = 0, 20 do
            local x = i * 40
            UI.Rect(x, 0, 1, H, Color.New(20, 20, 28, 60))
        end
        for i = 0, 15 do
            local y = i * 40
            UI.Rect(0, y, W, 1, Color.New(20, 20, 28, 60))
        end

        -- Title panel
        local cx = math.floor(W / 2)
        local titleY = math.floor(H * 0.2)
        UI.Panel(cx - 200, titleY - 10, 400, 80, _cPanel)
        -- Red accent bar
        UI.Rect(cx - 200, titleY - 10, 400, 3, _cAccent)

        Drawing.Text("EXTRACT OR DIE", cx - 120, titleY + 5, 28, C.WHITE)
        Drawing.Text("Top-Down Extraction Shooter", cx - 105, titleY + 40, 12, _cSubtitle)

        -- START button
        local btnW, btnH = 220, 45
        local btnX = cx - 110
        local btnY = math.floor(H * 0.55)

        if UI.Button(btnX, btnY, btnW, btnH, "  START RAID", {
            color = _cBtnBase,
            hoverColor = _cBtnHover,
            textColor = C.WHITE,
            textSize = 18
        }) then
            Scene.Switch("eod_loadout")
        end

        -- Controls info
        local infoY = math.floor(H * 0.75)
        Drawing.Text("Controls:", 30, infoY, 14, C.WHITE)
        Drawing.Text("WASD: Move   Mouse: Aim   LClick: Shoot", 30, infoY + 18, 12, C.GRAY)
        Drawing.Text("R: Reload   F: Pickup   Tab: Backpack", 30, infoY + 34, 12, C.GRAY)
        Drawing.Text("Reach extraction zone and hold 5s to escape", 30, infoY + 54, 12, C.GREEN)

        UI.DrawTooltip()
        UI.Flush()
        Drawing.ResetLayer()
    end
})

titleNode:registerAsScene("eod_title")

return titleNode
