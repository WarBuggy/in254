-- ============================================
-- Terraria2D — Inventory System
-- 10 hotbar + 40 bag slots, stacking
-- ============================================

local Inventory = {}

local MAX_STACK = 99
local HOTBAR_SIZE = 10
local BAG_SIZE = 40
local TOTAL_SLOTS = HOTBAR_SIZE + BAG_SIZE

function Inventory.New()
    local inv = {
        slots = {},
        selected = 1,
    }
    for i = 1, TOTAL_SLOTS do
        inv.slots[i] = nil
    end
    return inv
end

function Inventory.GetHotbarSize() return HOTBAR_SIZE end
function Inventory.GetBagSize() return BAG_SIZE end
function Inventory.GetTotalSlots() return TOTAL_SLOTS end

-- Add item to inventory, returns amount that couldn't fit
function Inventory.Add(inv, itemId, count)
    if not itemId or count <= 0 then return count end

    -- First try to stack with existing items
    for i = 1, TOTAL_SLOTS do
        if count <= 0 then break end
        local slot = inv.slots[i]
        if slot and slot.id == itemId and slot.count < MAX_STACK then
            local space = MAX_STACK - slot.count
            local toAdd = math.min(count, space)
            slot.count = slot.count + toAdd
            count = count - toAdd
        end
    end

    -- Then try empty slots
    for i = 1, TOTAL_SLOTS do
        if count <= 0 then break end
        if not inv.slots[i] then
            local toAdd = math.min(count, MAX_STACK)
            inv.slots[i] = { id = itemId, count = toAdd }
            count = count - toAdd
        end
    end

    return count
end

-- Remove count from specific slot
function Inventory.Remove(inv, slotIndex, count)
    local slot = inv.slots[slotIndex]
    if not slot then return end
    slot.count = slot.count - count
    if slot.count <= 0 then
        inv.slots[slotIndex] = nil
    end
end

-- Remove item by id from anywhere
function Inventory.RemoveItem(inv, itemId, count)
    for i = 1, TOTAL_SLOTS do
        if count <= 0 then break end
        local slot = inv.slots[i]
        if slot and slot.id == itemId then
            local toRemove = math.min(count, slot.count)
            slot.count = slot.count - toRemove
            count = count - toRemove
            if slot.count <= 0 then
                inv.slots[i] = nil
            end
        end
    end
    return count
end

-- Check if inventory has enough of an item
function Inventory.HasItem(inv, itemId, count)
    count = count or 1
    local total = 0
    for i = 1, TOTAL_SLOTS do
        local slot = inv.slots[i]
        if slot and slot.id == itemId then
            total = total + slot.count
        end
    end
    return total >= count
end

-- Count total of an item
function Inventory.CountItem(inv, itemId)
    local total = 0
    for i = 1, TOTAL_SLOTS do
        local slot = inv.slots[i]
        if slot and slot.id == itemId then
            total = total + slot.count
        end
    end
    return total
end

-- Find first slot containing item, returns index or nil
function Inventory.FindItem(inv, itemId)
    for i = 1, TOTAL_SLOTS do
        local slot = inv.slots[i]
        if slot and slot.id == itemId then
            return i
        end
    end
    return nil
end

-- Swap two slots
function Inventory.Swap(inv, a, b)
    inv.slots[a], inv.slots[b] = inv.slots[b], inv.slots[a]
end

-- Get selected hotbar item
function Inventory.GetSelected(inv)
    return inv.slots[inv.selected]
end

return Inventory
