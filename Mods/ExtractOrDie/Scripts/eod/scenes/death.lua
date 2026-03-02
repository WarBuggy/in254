-- ============================================
-- ExtractOrDie — Death Screen
-- Shows loot lost
-- ============================================

local UI = require("eod/core/ui")
local Theme = require("eod/core/theme")
local Config = require("eod/core/config")
local C = Theme.Colors

local _cBg       = Color.New(15, 5, 5)
local _cPanel     = Color.New(30, 10, 10, 240)
local _cBtnBase   = Color.New(80, 40, 40, 230)
local _cBtnHover  = Color.New(110, 50, 50, 240)
local _cItemBg    = Color.New(40, 25, 25, 200)
local _cLost      = Color.New(200, 80, 80)

local deathNode = Node.new({
    name = "death",

    onEnter = function(self, shared)
        Drawing.RegisterLayer("ui", 30, { blend = "alpha" })
        print("[ExtractOrDie] Player died. All loot lost.")
    end,

    onExit = function(self, shared) end,

    onUpdate = function(self, dt, totalTime, shared)
        UI.UpdateInput()
        if Input.IsKeyPressed("enter") or Input.IsKeyPressed("escape") then
            Scene.Switch("eod_loadout")
        end
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end

        Drawing.SetLayer("ui")
        local W, H = Screen.Width(), Screen.Height()

        UI.Rect(0, 0, W, H, _cBg)

        local cx = math.floor(W / 2)
        UI.Panel(cx - 150, 60, 300, 40, _cPanel)
        Drawing.Text("YOU DIED", cx - 55, 70, 24, C.RED)

        Drawing.Text("All loot has been lost:", cx - 80, 120, 14, _cLost)

        -- Show lost items
        local _, loot = Theme.GetRaidResult()
        loot = loot or {}
        local iy = 145
        if #loot == 0 then
            Drawing.Text("No items were collected", cx - 70, iy, 12, C.GRAY)
        else
            for _, item in ipairs(loot) do
                local lootDef = Config.LOOT_ITEMS[item.id]
                if lootDef then
                    UI.Rect(cx - 100, iy, 200, 22, _cItemBg)
                    local c = lootDef.color
                    -- Dimmed/crossed-out appearance
                    UI.Rect(cx - 94, iy + 3, 16, 16, Color.New(c[1], c[2], c[3], 120))
                    Drawing.Text(lootDef.name .. " x" .. item.count, cx - 72, iy + 4, 12, C.DIM)
                    iy = iy + 26
                end
            end
        end

        -- Continue button
        if UI.Button(cx - 100, H - 80, 200, 40, "  TRY AGAIN", {
            color = _cBtnBase,
            hoverColor = _cBtnHover,
            textColor = C.WHITE,
            textSize = 16
        }) then
            Scene.Switch("eod_loadout")
        end

        UI.DrawTooltip()
        UI.Flush()
        Drawing.ResetLayer()
    end
})

deathNode:registerAsScene("eod_death")

return deathNode
