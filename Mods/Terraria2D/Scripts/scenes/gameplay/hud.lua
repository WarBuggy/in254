-- ============================================
-- Terraria2D — HUD
-- HP/mana bars, hotbar, minimap
-- ============================================

local Config = require("core/config")
local UI = require("core/ui")
local Theme = require("core/theme")
local Tiles = require("world/tiles")
local Inventory = require("systems/inventory")
local DayNight = require("systems/daynight")
local C = Theme.Colors

local HUD = {}

-- Cached colors for inline literals
local _cBarOutline = Color.New(0, 0, 0, 150)
local _cSlotKey    = Color.New(150, 150, 150)
local _cBossBarBg  = Color.New(0, 0, 0, 180)
local _cBossBarFg  = Color.New(200, 40, 40)
local _cBossBarBg2 = Color.New(60, 10, 10, 200)
local _cMinimapBg  = Color.New(0, 0, 0, 200)
local _cPlayerDot  = Color.New(255, 255, 255)

-- Item color cache (keyed by item id, avoids per-frame Color.New in hotbar)
local _itemColorCache = {}

local function GetItemPackedColor(itemId)
    local cached = _itemColorCache[itemId]
    if cached then return cached end
    local c = Tiles.GetItemColor(itemId)
    cached = Color.New(c[1], c[2], c[3])
    _itemColorCache[itemId] = cached
    return cached
end

function HUD.Draw(shared)
    local W = shared.W
    local p = shared.player

    -- HP bar
    UI.Rect(8, 8, 104, 14, _cBarOutline)
    UI.ProgressBar(9, 9, 102, 12, p.hp, p.maxHp, C.HP_FG, C.HP_BG)
    Drawing.Text("HP " .. p.hp .. "/" .. p.maxHp, 14, 10, 10, C.WHITE)

    -- Mana bar
    UI.Rect(8, 24, 104, 14, _cBarOutline)
    UI.ProgressBar(9, 25, 102, 12, p.mana, p.maxMana, C.MANA_FG, C.MANA_BG)
    Drawing.Text("MP " .. p.mana .. "/" .. p.maxMana, 14, 26, 10, C.WHITE)

    -- Hotbar
    local hotbarSize = Inventory.GetHotbarSize()
    local slotSize = 28
    local slotGap = 2
    local hotbarW = hotbarSize * (slotSize + slotGap) - slotGap
    local hotbarX = math.floor(W / 2 - hotbarW / 2)
    local hotbarY = shared.H - slotSize - 6

    -- Hotbar background
    UI.Rect(hotbarX - 4, hotbarY - 4, hotbarW + 8, slotSize + 8, _cBarOutline)

    local inv = shared.inventory
    for i = 1, hotbarSize do
        local sx = hotbarX + (i - 1) * (slotSize + slotGap)
        local selected = (inv.selected == i)
        local bg = selected and C.SLOT_SEL or C.SLOT_BG
        UI.Rect(sx, hotbarY, slotSize, slotSize, bg)

        -- Item in slot
        local slot = inv.slots[i]
        if slot then
            local color = GetItemPackedColor(slot.id)
            local itemSize = Tiles.IsWeapon(slot.id) and 14 or 10
            local ox = math.floor((slotSize - itemSize) / 2)
            local oy = math.floor((slotSize - itemSize) / 2)

            if Tiles.IsWeapon(slot.id) then
                -- Draw weapon icon (tall rectangle)
                UI.Rect(sx + slotSize/2 - 2, hotbarY + 4, 4, 18, color)
            else
                UI.Rect(sx + ox, hotbarY + oy, itemSize, itemSize, color)
            end

            -- Stack count
            if slot.count > 1 then
                Drawing.Text(tostring(slot.count), sx + 2, hotbarY + slotSize - 10, 8, C.WHITE)
            end
        end

        -- Slot number
        local keyLabel = i == 10 and "0" or tostring(i)
        Drawing.Text(keyLabel, sx + slotSize - 8, hotbarY + 1, 7, _cSlotKey)

        -- Tooltip on hover
        if slot and UI.IsHovered(sx, hotbarY, slotSize, slotSize) then
            UI.Tooltip(Tiles.GetName(slot.id) .. " x" .. slot.count)
        end
    end

    -- Day/Night indicator
    local timeStr = DayNight.GetTimeString()
    local dayIcon = shared.isNight and "Night" or "Day"
    Drawing.Text(dayIcon .. " " .. timeStr, W - 90, 10, 10, C.WHITE)

    -- Minimap
    HUD.DrawMinimap(shared)

    -- Boss HP bar
    if shared.boss and shared.boss.alive then
        local bossW = 200
        local bossX = math.floor(W / 2 - bossW / 2)
        UI.Rect(bossX - 2, 6, bossW + 4, 18, _cBossBarBg)
        UI.ProgressBar(bossX, 8, bossW, 14, shared.boss.hp, shared.boss.maxHp, _cBossBarFg, _cBossBarBg2)
        Drawing.Text(shared.boss.name, bossX + 4, 9, 10, C.WHITE)
    end
end

-- Cached minimap batch data (rebuilt only when tiles change)
local _minimapBatch = nil
local _minimapCount = 0
local _minimapDirty = true

function HUD.RefreshMinimap()
    _minimapDirty = true
end

function HUD.DrawMinimap(shared)
    local W = shared.W
    local mapW = 80
    local mapH = 40
    local mapX = W - mapW - 8
    local mapY = 24

    UI.Rect(mapX - 1, mapY - 1, mapW + 2, mapH + 2, _cMinimapBg)

    local WorldData = require("world/worlddata")
    local TS = Config.TILE_SIZE
    local scaleX = Config.WORLD_W / mapW
    local scaleY = Config.WORLD_H / mapH
    local floor = math.floor

    -- Rebuild batch data only when dirty
    if _minimapDirty then
        _minimapDirty = false
        local tiles = WorldData.GetTiles()
        local tileData = Tiles.data
        local batch = {}
        local count = 0

        for my = 0, mapH - 1 do
            local ty = floor(my * scaleY)
            local base = ty * Config.WORLD_W
            for mx = 0, mapW - 1 do
                local tx = floor(mx * scaleX)
                local tileId = tiles[base + tx + 1] or 0
                if tileId ~= 0 then
                    local data = tileData[tileId] or tileData[0]
                    local c = data.color
                    local i = count * 8
                    batch[i + 1] = mapX + mx
                    batch[i + 2] = mapY + my
                    batch[i + 3] = 1
                    batch[i + 4] = 1
                    batch[i + 5] = c[1]
                    batch[i + 6] = c[2]
                    batch[i + 7] = c[3]
                    batch[i + 8] = 200
                    count = count + 1
                end
            end
        end

        _minimapBatch = batch
        _minimapCount = count
    end

    -- One interop call for all minimap pixels
    if _minimapCount > 0 then
        Drawing.RectBatch(UI.GetPixelId(), _minimapBatch, _minimapCount)
    end

    -- Player position on minimap (always fresh)
    local p = shared.player
    local px = floor(p.x / TS / scaleX)
    local py = floor(p.y / TS / scaleY)
    UI.Rect(mapX + px - 1, mapY + py - 1, 3, 3, _cPlayerDot)
end

return HUD
