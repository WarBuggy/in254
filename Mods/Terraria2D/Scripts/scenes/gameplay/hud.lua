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

function HUD.Draw(shared)
    local W = shared.W
    local p = shared.player

    -- HP bar
    UI.Rect(8, 8, 104, 14, {0, 0, 0, 150})
    UI.ProgressBar(9, 9, 102, 12, p.hp, p.maxHp, C.HP_FG, C.HP_BG)
    Text.Draw("HP " .. p.hp .. "/" .. p.maxHp, 14, 10, 10, C.WHITE)

    -- Mana bar
    UI.Rect(8, 24, 104, 14, {0, 0, 0, 150})
    UI.ProgressBar(9, 25, 102, 12, p.mana, p.maxMana, C.MANA_FG, C.MANA_BG)
    Text.Draw("MP " .. p.mana .. "/" .. p.maxMana, 14, 26, 10, C.WHITE)

    -- Hotbar
    local hotbarSize = Inventory.GetHotbarSize()
    local slotSize = 28
    local slotGap = 2
    local hotbarW = hotbarSize * (slotSize + slotGap) - slotGap
    local hotbarX = math.floor(W / 2 - hotbarW / 2)
    local hotbarY = shared.H - slotSize - 6

    -- Hotbar background
    UI.Rect(hotbarX - 4, hotbarY - 4, hotbarW + 8, slotSize + 8, {0, 0, 0, 150})

    local inv = shared.inventory
    for i = 1, hotbarSize do
        local sx = hotbarX + (i - 1) * (slotSize + slotGap)
        local selected = (inv.selected == i)
        local bg = selected and C.SLOT_SEL or C.SLOT_BG
        UI.Rect(sx, hotbarY, slotSize, slotSize, bg)

        -- Item in slot
        local slot = inv.slots[i]
        if slot then
            local color = Tiles.GetItemColor(slot.id)
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
                Text.Draw(tostring(slot.count), sx + 2, hotbarY + slotSize - 10, 8, C.WHITE)
            end
        end

        -- Slot number
        local keyLabel = i == 10 and "0" or tostring(i)
        Text.Draw(keyLabel, sx + slotSize - 8, hotbarY + 1, 7, {150, 150, 150})

        -- Tooltip on hover
        if slot and UI.IsHovered(sx, hotbarY, slotSize, slotSize) then
            UI.Tooltip(Tiles.GetName(slot.id) .. " x" .. slot.count)
        end
    end

    -- Day/Night indicator
    local timeStr = DayNight.GetTimeString()
    local dayIcon = shared.isNight and "Night" or "Day"
    Text.Draw(dayIcon .. " " .. timeStr, W - 90, 10, 10, C.WHITE)

    -- Minimap
    HUD.DrawMinimap(shared)

    -- Boss HP bar
    if shared.boss and shared.boss.alive then
        local bossW = 200
        local bossX = math.floor(W / 2 - bossW / 2)
        UI.Rect(bossX - 2, 6, bossW + 4, 18, {0, 0, 0, 180})
        UI.ProgressBar(bossX, 8, bossW, 14, shared.boss.hp, shared.boss.maxHp, {200, 40, 40}, {60, 10, 10, 200})
        Text.Draw(shared.boss.name, bossX + 4, 9, 10, C.WHITE)
    end
end

function HUD.DrawMinimap(shared)
    local W = shared.W
    local mapW = 80
    local mapH = 40
    local mapX = W - mapW - 8
    local mapY = 24

    UI.Rect(mapX - 1, mapY - 1, mapW + 2, mapH + 2, {0, 0, 0, 200})

    -- Draw minimap (sample every N tiles)
    local WorldData = require("world/worlddata")
    local scaleX = Config.WORLD_W / mapW
    local scaleY = Config.WORLD_H / mapH

    for my = 0, mapH - 1 do
        for mx = 0, mapW - 1 do
            local tx = math.floor(mx * scaleX)
            local ty = math.floor(my * scaleY)
            local tileId = WorldData.Get(tx, ty)
            if tileId ~= 0 then
                local data = Tiles.GetData(tileId)
                local c = data.color
                UI.Rect(mapX + mx, mapY + my, 1, 1, {c[1], c[2], c[3], 200})
            end
        end
    end

    -- Player position on minimap
    local p = shared.player
    local TS = Config.TILE_SIZE
    local px = math.floor(p.x / TS / scaleX)
    local py = math.floor(p.y / TS / scaleY)
    UI.Rect(mapX + px - 1, mapY + py - 1, 3, 3, {255, 255, 255})
end

return HUD
