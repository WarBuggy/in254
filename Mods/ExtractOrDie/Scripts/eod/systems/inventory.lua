-- ============================================
-- ExtractOrDie — Inventory (Raid Backpack)
-- 6-slot raid backpack
-- ============================================

local Config = require("eod/core/config")

local Inventory = {}

local MAX_STACK = Config.MAX_STACK
local BACKPACK_SIZE = Config.BACKPACK_SIZE

function Inventory.New()
    local inv = { slots = {} }
    for i = 1, BACKPACK_SIZE do
        inv.slots[i] = nil
    end
    return inv
end

function Inventory.GetSize() return BACKPACK_SIZE end

-- Add item, returns amount that couldn't fit
function Inventory.Add(inv, itemId, count)
    if not itemId or count <= 0 then return count end

    -- Stack with existing
    for i = 1, BACKPACK_SIZE do
        if count <= 0 then break end
        local slot = inv.slots[i]
        if slot and slot.id == itemId and slot.count < MAX_STACK then
            local space = MAX_STACK - slot.count
            local toAdd = math.min(count, space)
            slot.count = slot.count + toAdd
            count = count - toAdd
        end
    end

    -- Empty slots
    for i = 1, BACKPACK_SIZE do
        if count <= 0 then break end
        if not inv.slots[i] then
            local toAdd = math.min(count, MAX_STACK)
            inv.slots[i] = { id = itemId, count = toAdd }
            count = count - toAdd
        end
    end

    return count
end

function Inventory.Remove(inv, slotIndex, count)
    local slot = inv.slots[slotIndex]
    if not slot then return end
    slot.count = slot.count - count
    if slot.count <= 0 then
        inv.slots[slotIndex] = nil
    end
end

function Inventory.IsFull(inv)
    for i = 1, BACKPACK_SIZE do
        if not inv.slots[i] then return false end
    end
    return true
end

function Inventory.GetContents(inv)
    local items = {}
    for i = 1, BACKPACK_SIZE do
        local slot = inv.slots[i]
        if slot then
            table.insert(items, { id = slot.id, count = slot.count })
        end
    end
    return items
end

function Inventory.Clear(inv)
    for i = 1, BACKPACK_SIZE do
        inv.slots[i] = nil
    end
end

return Inventory
