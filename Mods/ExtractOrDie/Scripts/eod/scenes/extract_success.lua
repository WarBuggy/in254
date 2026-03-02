-- ============================================
-- ExtractOrDie — Extraction Success Screen
-- Shows loot saved to stash
-- ============================================

local UI = require("eod/core/ui")
local Theme = require("eod/core/theme")
local Config = require("eod/core/config")
local C = Theme.Colors

local _cBg       = Color.New(5, 15, 5)
local _cPanel     = Color.New(15, 30, 15, 240)
local _cBtnBase   = Color.New(40, 80, 40, 230)
local _cBtnHover  = Color.New(60, 110, 60, 240)
local _cItemBg    = Color.New(30, 45, 30, 200)

-- We store loot from the last raid in a module-level var set before switching
local _savedLoot = {}

local extractNode = Node.new({
    name = "extract_success",

    onEnter = function(self, shared)
        Drawing.RegisterLayer("ui", 30, { blend = "alpha" })
        -- Grab loot from the raid scene's shared (passed via scene system)
        -- The raid scene sets shared.raidLoot before switching
        print("[ExtractOrDie] Extraction successful!")
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
        UI.Panel(cx - 180, 60, 360, 40, _cPanel)
        Drawing.Text("EXTRACTION SUCCESSFUL", cx - 130, 70, 22, C.GREEN)

        Drawing.Text("Loot saved to stash:", cx - 80, 120, 14, C.WHITE)

        -- Show saved items
        local _, loot = Theme.GetRaidResult()
        loot = loot or {}
        local iy = 145
        if #loot == 0 then
            Drawing.Text("No items collected", cx - 60, iy, 12, C.GRAY)
        else
            for _, item in ipairs(loot) do
                local lootDef = Config.LOOT_ITEMS[item.id]
                if lootDef then
                    UI.Rect(cx - 100, iy, 200, 22, _cItemBg)
                    local c = lootDef.color
                    UI.Rect(cx - 94, iy + 3, 16, 16, Color.New(c[1], c[2], c[3]))
                    Drawing.Text(lootDef.name .. " x" .. item.count, cx - 72, iy + 4, 12, C.WHITE)
                    iy = iy + 26
                end
            end
        end

        -- Continue button
        if UI.Button(cx - 100, H - 80, 200, 40, "  CONTINUE", {
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

extractNode:registerAsScene("eod_extract_success")

return extractNode
