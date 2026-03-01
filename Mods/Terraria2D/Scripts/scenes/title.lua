-- ============================================
-- Terraria2D — Title Screen
-- ============================================

local UI = require("core/ui")
local Theme = require("core/theme")
local C = Theme.Colors

local titleNode = Node.new({
    name = "title",

    onEnter = function(self, shared)
        print("[Terraria2D] Title screen entered.")
    end,

    onExit = function(self, shared) end,

    onUpdate = function(self, dt, totalTime, shared)
        UI.UpdateInput()
        if Input.IsKeyPressed("enter") then
            Scene.Switch("gameplay")
        end
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end

        local W, H = Screen.Width(), Screen.Height()

        -- Sky gradient background
        UI.Rect(0, 0, W, H * 0.6, {100, 180, 230, 255})
        UI.Rect(0, math.floor(H * 0.6), W, math.floor(H * 0.4), {76, 153, 0, 255})

        -- Ground details
        UI.Rect(0, math.floor(H * 0.62), W, 4, {60, 130, 0, 255})

        -- Simple trees on title
        for i = 0, 5 do
            local tx = 80 + i * 130
            local ty = math.floor(H * 0.6) - 40
            -- Trunk
            UI.Rect(tx, ty + 10, 8, 30, {140, 90, 40})
            -- Canopy
            UI.Rect(tx - 12, ty, 32, 16, {30, 130, 30})
            UI.Rect(tx - 8, ty - 8, 24, 12, {40, 150, 40})
        end

        -- Title
        local titleY = math.floor(H * 0.15)
        UI.Rect(W / 2 - 170, titleY - 10, 340, 60, {0, 0, 0, 120})
        Drawing.Text("TERRARIA 2D", math.floor(W / 2) - 100, titleY, 32, C.WHITE)

        -- Subtitle
        Drawing.Text("A 2D Sandbox Adventure", math.floor(W / 2) - 90, titleY + 40, 14, C.YELLOW)

        -- Buttons
        local btnW, btnH = 200, 40
        local btnX = math.floor(W / 2) - 100
        local btnY = math.floor(H * 0.55)

        if UI.Button(btnX, btnY, btnW, btnH, "  New Game", {
            color = {40, 80, 40, 230},
            hoverColor = {60, 110, 60, 240},
            textColor = C.WHITE,
            textSize = 18
        }) then
            Scene.Switch("gameplay")
        end

        -- Controls info
        local infoY = math.floor(H * 0.75)
        Drawing.Text("Controls:", 30, infoY, 14, C.WHITE)
        Drawing.Text("A/D: Move   Space: Jump   LClick: Mine/Attack", 30, infoY + 18, 12, C.GRAY)
        Drawing.Text("RClick: Place   E: Inventory   C: Crafting", 30, infoY + 34, 12, C.GRAY)
        Drawing.Text("1-0: Hotbar   Esc: Pause", 30, infoY + 50, 12, C.GRAY)

        UI.DrawTooltip()
    end
})

titleNode:registerAsScene("title")

return titleNode
