-- ============================================
-- ExtractOrDie — Stash
-- Persistent 20-slot stash between raids
-- ============================================

local Config = require("eod/core/config")
local Theme = require("eod/core/theme")

local Stash = {}

local MAX_STACK = Config.MAX_STACK
local STASH_SIZE = Config.STASH_SIZE

function Stash.Get()
    return Theme.GetStash()
end

function Stash.GetSize() return STASH_SIZE end

-- Add item to stash, returns amount that couldn't fit
function Stash.Add(itemId, count)
    if not itemId or count <= 0 then return count end
    local slots = Theme.GetStash()

    -- Stack with existing
    for i = 1, STASH_SIZE do
        if count <= 0 then break end
        local slot = slots[i]
        if slot and slot.id == itemId and slot.count < MAX_STACK then
            local space = MAX_STACK - slot.count
            local toAdd = math.min(count, space)
            slot.count = slot.count + toAdd
            count = count - toAdd
        end
    end

    -- Empty slots
    for i = 1, STASH_SIZE do
        if count <= 0 then break end
        if not slots[i] then
            local toAdd = math.min(count, MAX_STACK)
            slots[i] = { id = itemId, count = toAdd }
            count = count - toAdd
        end
    end

    return count
end

function Stash.Remove(slotIndex, count)
    local slots = Theme.GetStash()
    local slot = slots[slotIndex]
    if not slot then return end
    slot.count = slot.count - count
    if slot.count <= 0 then
        slots[slotIndex] = nil
    end
end

-- Transfer all backpack items to stash (on successful extraction)
function Stash.TransferFromBackpack(backpack)
    local saved = {}
    for i = 1, #backpack.slots do
        local slot = backpack.slots[i]
        if slot then
            local remaining = Stash.Add(slot.id, slot.count)
            local savedCount = slot.count - remaining
            if savedCount > 0 then
                table.insert(saved, { id = slot.id, count = savedCount })
            end
            -- Check if item is a weapon, unlock it
            local lootDef = Config.LOOT_ITEMS[slot.id]
            if lootDef and lootDef.isWeapon then
                Theme.UnlockWeapon(slot.id)
            end
        end
    end
    return saved
end

return Stash
