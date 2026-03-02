-- ============================================
-- ExtractOrDie — Loadout Screen
-- Weapon select, stash view, DEPLOY button
-- ============================================

local UI = require("eod/core/ui")
local Theme = require("eod/core/theme")
local Config = require("eod/core/config")
local Stash = require("eod/systems/stash")
local C = Theme.Colors

local _cBg       = Color.New(12, 12, 18)
local _cPanel     = Color.New(20, 20, 30, 240)
local _cSlotBg    = Color.New(35, 35, 50, 200)
local _cSlotSel   = Color.New(60, 80, 60, 230)
local _cBtnDeploy = Color.New(40, 100, 40, 230)
local _cBtnHover  = Color.New(60, 130, 60, 240)
local _cBtnBack   = Color.New(80, 40, 40, 230)
local _cBtnBackH  = Color.New(110, 50, 50, 240)
local _cMapSlot   = Color.New(35, 35, 50, 200)
local _cMapSel    = Color.New(50, 70, 90, 230)
local _cDungeonIco = Color.New(80, 75, 68)
local _cForestIco  = Color.New(50, 120, 50)
local _cRarityCommon   = Color.New(180, 180, 180)
local _cRarityUncommon = Color.New(80, 200, 80)
local _cRarityRare     = Color.New(100, 150, 255)

local function getRarityColor(rarity)
    if rarity == "uncommon" then return _cRarityUncommon end
    if rarity == "rare" then return _cRarityRare end
    return _cRarityCommon
end

local loadoutNode = Node.new({
    name = "loadout",

    onEnter = function(self, shared)
        Drawing.RegisterLayer("ui", 30, { blend = "alpha" })
        print("[ExtractOrDie] Loadout screen.")
    end,

    onExit = function(self, shared) end,

    onUpdate = function(self, dt, totalTime, shared)
        UI.UpdateInput()
        if Input.IsKeyPressed("escape") then
            Scene.Switch("eod_title")
        end
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end

        Drawing.SetLayer("ui")
        local W, H = Screen.Width(), Screen.Height()

        UI.Rect(0, 0, W, H, _cBg)

        local cx = math.floor(W / 2)

        -- Title
        Drawing.Text("LOADOUT", cx - 50, 20, 22, C.WHITE)

        -- Weapon selection
        Drawing.Text("Select Weapon:", 30, 60, 14, C.GRAY)
        local weaponList = { "pistol", "smg", "shotgun", "rifle" }
        local selectedWeapon = Theme.GetSelectedWeapon()
        local unlocked = Theme.GetUnlockedWeapons()

        local wy = 85
        for _, wepId in ipairs(weaponList) do
            local def = Config.WEAPONS[wepId]
            local isUnlocked = unlocked[wepId]
            local isSelected = (selectedWeapon == wepId)

            local slotColor = isSelected and _cSlotSel or _cSlotBg
            UI.Rect(30, wy, 340, 36, slotColor)

            if isUnlocked then
                local c = def.color
                UI.Rect(38, wy + 8, 20, 20, Color.New(c[1], c[2], c[3]))
                Drawing.Text(def.name, 66, wy + 4, 14, C.WHITE)
                Drawing.Text("DMG:" .. def.damage .. " MAG:" .. def.magSize .. " RPM:" .. math.floor(60 / def.fireRate), 66, wy + 20, 10, C.GRAY)

                if UI.IsClicked(30, wy, 340, 36) then
                    Theme.SetSelectedWeapon(wepId)
                end
            else
                Drawing.Text(def.name .. " [LOCKED]", 66, wy + 10, 14, C.DIM)
            end

            wy = wy + 42
        end

        -- Map type selector
        Drawing.Text("Select Map:", 30, wy + 10, 14, C.GRAY)
        local mapY = wy + 35
        local selectedMap = Theme.GetSelectedMap()
        local mapTypes = {
            { id = "dungeon", name = "Dungeon", icoColor = _cDungeonIco },
            { id = "forest",  name = "Forest",  icoColor = _cForestIco },
        }
        for _, mt in ipairs(mapTypes) do
            local isSel = (selectedMap == mt.id)
            local slotColor = isSel and _cMapSel or _cMapSlot
            UI.Rect(30, mapY, 160, 32, slotColor)
            UI.Rect(38, mapY + 6, 20, 20, mt.icoColor)
            Drawing.Text(mt.name, 66, mapY + 8, 14, C.WHITE)
            if UI.IsClicked(30, mapY, 160, 32) then
                Theme.SetSelectedMap(mt.id)
            end
            mapY = mapY + 38
        end

        -- Stash
        Drawing.Text("Stash:", 400, 60, 14, C.GRAY)
        local stashSlots = Stash.Get()
        local sx, sy = 400, 85
        local slotSize = 36
        local cols = 5
        for i = 1, Config.STASH_SIZE do
            local col = ((i - 1) % cols)
            local row = math.floor((i - 1) / cols)
            local slotX = sx + col * (slotSize + 4)
            local slotY = sy + row * (slotSize + 4)

            UI.Rect(slotX, slotY, slotSize, slotSize, _cSlotBg)

            local slot = stashSlots[i]
            if slot then
                local lootDef = Config.LOOT_ITEMS[slot.id]
                if lootDef then
                    local c = lootDef.color
                    UI.Rect(slotX + 6, slotY + 6, slotSize - 12, slotSize - 12, Color.New(c[1], c[2], c[3]))
                    if slot.count > 1 then
                        Drawing.Text(tostring(slot.count), slotX + 2, slotY + slotSize - 12, 10, C.WHITE)
                    end
                end
                if UI.IsHovered(slotX, slotY, slotSize, slotSize) then
                    local name = lootDef and lootDef.name or slot.id
                    UI.Tooltip(name .. " x" .. slot.count)
                end
            end
        end

        -- DEPLOY button
        local btnW, btnH = 200, 45
        if UI.Button(cx - 100, H - 80, btnW, btnH, "  DEPLOY", {
            color = _cBtnDeploy,
            hoverColor = _cBtnHover,
            textColor = C.WHITE,
            textSize = 20
        }) then
            Scene.Switch("eod_raid")
        end

        -- Back button
        if UI.Button(30, H - 50, 100, 30, "  Back", {
            color = _cBtnBack,
            hoverColor = _cBtnBackH,
            textSize = 12,
        }) then
            Scene.Switch("eod_title")
        end

        UI.DrawTooltip()
        UI.Flush()
        Drawing.ResetLayer()
    end
})

loadoutNode:registerAsScene("eod_loadout")

return loadoutNode
