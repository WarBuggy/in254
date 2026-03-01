-- ============================================
-- ScorchridgeV2 — Categorized Inventory System
-- Items: drugs, PCHO rations, etc.
-- ============================================

local modId = "ScorchridgeV2"

local Inventory = {}

local ITEM_CATALOG = {
    drug_dose = {
        id = "drug_dose",
        name = "Stimulant Dose",
        desc = "Combat drug — boosts stamina/morale, risk of addiction",
        category = "Medical",
        maxStack = 99
    },
    pcho_ration = {
        id = "pcho_ration",
        name = "PCHO Supplement",
        desc = "Premium supplement — bonus stamina/morale during meals",
        category = "Supplies",
        maxStack = 999
    }
}

function Inventory.Init(initialStock)
    local inv = {
        Medical   = {},
        Supplies  = {},
        Equipment = {}
    }

    initialStock = initialStock or { drug_dose = 10, pcho_ration = 600 }

    for itemId, count in pairs(initialStock) do
        local def = ITEM_CATALOG[itemId]
        if def then
            local cat = inv[def.category]
            if cat then
                cat[#cat + 1] = { id = itemId, count = count }
            end
        end
    end

    GameData:SetTo(modId, "colony.inventory", inv)
    return inv
end

local function findEntry(inv, itemId)
    local def = ITEM_CATALOG[itemId]
    if not def then return nil, nil end
    local cat = inv[def.category]
    if not cat then return nil, nil end
    for i = 1, #cat do
        if cat[i].id == itemId then
            return cat[i], cat
        end
    end
    return nil, cat
end

local function getInv()
    return GameData:TryGetFrom(modId, "colony.inventory")
end

local function saveInv(inv)
    GameData:SetTo(modId, "colony.inventory", inv)
end

function Inventory.GetCount(itemId)
    local inv = getInv()
    if not inv then return 0 end
    local entry = findEntry(inv, itemId)
    return entry and entry.count or 0
end

function Inventory.Add(itemId, amount)
    local inv = getInv()
    if not inv then return false end
    local def = ITEM_CATALOG[itemId]
    if not def then return false end

    local entry, cat = findEntry(inv, itemId)
    if entry then
        entry.count = entry.count + amount
    else
        cat = inv[def.category]
        if not cat then
            inv[def.category] = {}
            cat = inv[def.category]
        end
        cat[#cat + 1] = { id = itemId, count = amount }
    end

    saveInv(inv)
    return true
end

function Inventory.Consume(itemId, amount)
    local inv = getInv()
    if not inv then return false end

    local entry = findEntry(inv, itemId)
    if not entry or entry.count < amount then return false end

    entry.count = entry.count - amount
    saveInv(inv)
    return true
end

function Inventory.HasStock(itemId, amount)
    amount = amount or 1
    return Inventory.GetCount(itemId) >= amount
end

function Inventory.GetDef(itemId)
    return ITEM_CATALOG[itemId]
end

function Inventory.GetCatalog()
    return ITEM_CATALOG
end

return Inventory
