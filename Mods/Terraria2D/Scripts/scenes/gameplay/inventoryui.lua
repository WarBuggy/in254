-- ============================================
-- Terraria2D — Inventory UI
-- Full inventory overlay
-- ============================================

local UI = require("core/ui")
local Theme = require("core/theme")
local Tiles = require("world/tiles")
local Inventory = require("systems/inventory")
local C = Theme.Colors

local InventoryUI = {}

local heldItem = nil -- { id, count } for click-to-move

function InventoryUI.Update(shared)
    -- Click handling is done in Draw (since we need positions)
end

function InventoryUI.Draw(shared)
    local W = shared.W
    local H = shared.H
    local inv = shared.inventory

    -- Overlay background
    UI.Rect(0, 0, W, H, {0, 0, 0, 150})

    local panelW = 340
    local panelH = 360
    local panelX = math.floor(W / 2 - panelW / 2)
    local panelY = math.floor(H / 2 - panelH / 2)

    UI.Panel(panelX, panelY, panelW, panelH, {25, 25, 40, 240})
    Drawing.Text("Inventory", panelX + 10, panelY + 8, 16, C.YELLOW)
    Drawing.Text("[E] Close", panelX + panelW - 70, panelY + 10, 10, C.GRAY)

    local slotSize = 28
    local slotGap = 4
    local cols = 10
    local startX = panelX + 10
    local startY = panelY + 34

    -- Hotbar slots
    Drawing.Text("Hotbar", startX, startY - 2, 9, C.DIM)
    startY = startY + 10
    for i = 1, Inventory.GetHotbarSize() do
        local col = (i - 1) % cols
        local sx = startX + col * (slotSize + slotGap)
        local sy = startY
        local selected = (inv.selected == i)
        local bg = selected and C.SLOT_SEL or C.SLOT_BG
        UI.Rect(sx, sy, slotSize, slotSize, bg)

        local slot = inv.slots[i]
        if slot then
            InventoryUI.DrawSlotItem(sx, sy, slotSize, slot)
        end

        -- Click to swap
        if UI.IsClicked(sx, sy, slotSize, slotSize) then
            InventoryUI.HandleSlotClick(inv, i)
        end

        if slot and UI.IsHovered(sx, sy, slotSize, slotSize) then
            UI.Tooltip(Tiles.GetName(slot.id) .. " x" .. slot.count)
        end
    end

    -- Bag slots
    startY = startY + slotSize + 12
    Drawing.Text("Bag", startX, startY - 2, 9, C.DIM)
    startY = startY + 10

    local hotbarSize = Inventory.GetHotbarSize()
    local bagSize = Inventory.GetBagSize()
    for i = 1, bagSize do
        local idx = hotbarSize + i
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local sx = startX + col * (slotSize + slotGap)
        local sy = startY + row * (slotSize + slotGap)
        UI.Rect(sx, sy, slotSize, slotSize, C.SLOT_BG)

        local slot = inv.slots[idx]
        if slot then
            InventoryUI.DrawSlotItem(sx, sy, slotSize, slot)
        end

        -- Click to swap
        if UI.IsClicked(sx, sy, slotSize, slotSize) then
            InventoryUI.HandleSlotClick(inv, idx)
        end

        if slot and UI.IsHovered(sx, sy, slotSize, slotSize) then
            UI.Tooltip(Tiles.GetName(slot.id) .. " x" .. slot.count)
        end
    end

    -- Draw held item at cursor
    if heldItem then
        local mx = UI.MouseX()
        local my = UI.MouseY()
        local color = Tiles.GetItemColor(heldItem.id)
        UI.Rect(mx - 5, my - 5, 10, 10, color)
        Drawing.Text(tostring(heldItem.count), mx + 6, my + 2, 8, C.WHITE)
    end
end

function InventoryUI.DrawSlotItem(sx, sy, size, slot)
    local color = Tiles.GetItemColor(slot.id)
    if Tiles.IsWeapon(slot.id) then
        UI.Rect(sx + size/2 - 2, sy + 4, 4, size - 8, color)
    else
        local itemSize = 10
        local ox = math.floor((size - itemSize) / 2)
        UI.Rect(sx + ox, sy + ox, itemSize, itemSize, color)
    end
    if slot.count > 1 then
        Drawing.Text(tostring(slot.count), sx + 2, sy + size - 10, 8, C.WHITE)
    end
end

function InventoryUI.HandleSlotClick(inv, slotIndex)
    if heldItem then
        -- Place held item
        local existing = inv.slots[slotIndex]
        if existing and existing.id == heldItem.id then
            -- Stack
            local space = 99 - existing.count
            local toAdd = math.min(heldItem.count, space)
            existing.count = existing.count + toAdd
            heldItem.count = heldItem.count - toAdd
            if heldItem.count <= 0 then
                heldItem = nil
            end
        else
            -- Swap
            inv.slots[slotIndex] = { id = heldItem.id, count = heldItem.count }
            heldItem = existing
        end
    else
        -- Pick up from slot
        local slot = inv.slots[slotIndex]
        if slot then
            heldItem = { id = slot.id, count = slot.count }
            inv.slots[slotIndex] = nil
        end
    end
end

return InventoryUI
