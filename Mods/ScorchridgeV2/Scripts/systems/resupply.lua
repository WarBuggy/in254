-- ============================================
-- ScorchridgeV2 — Resupply Shop System
-- Cycle-start purchasing with credits
-- ============================================

local Inventory = require("systems/inventory")

local modId = "ScorchridgeV2"

local Resupply = {}

local SHOP_ITEMS = {
    {
        id = "buy_oxygen",
        name = "Oxygen Tanks",
        desc = "+100 O2",
        amount = 100,
        cost = 80,
        target = "resource",
        resourceKey = "oxygen"
    },
    {
        id = "buy_food",
        name = "Food Crates",
        desc = "+100 food",
        amount = 100,
        cost = 60,
        target = "resource",
        resourceKey = "food"
    },
    {
        id = "buy_pcho",
        name = "PCHO Supplements",
        desc = "+20 PCHO",
        amount = 20,
        cost = 20,
        target = "inventory",
        inventoryItem = "pcho_ration"
    },
    {
        id = "buy_drug",
        name = "Stimulant Doses",
        desc = "+5 drugs",
        amount = 5,
        cost = 50,
        target = "inventory",
        inventoryItem = "drug_dose"
    }
}

local open = false

function Resupply.IsOpen()
    return open
end

function Resupply.Open()
    open = true
end

function Resupply.Close()
    open = false
    local state = GameData:TryGetFrom(modId, "colony.state")
    if state then
        state.resupplyPending = false
        GameData:SetTo(modId, "colony.state", state)
    end
end

function Resupply.GetShopItems()
    return SHOP_ITEMS
end

function Resupply.Purchase(itemId, resources)
    if not resources then return false end

    for _, item in ipairs(SHOP_ITEMS) do
        if item.id == itemId then
            if (resources.colonyCredits or 0) < item.cost then
                return false
            end

            resources.colonyCredits = resources.colonyCredits - item.cost

            if item.target == "resource" then
                resources[item.resourceKey] = (resources[item.resourceKey] or 0) + item.amount
            elseif item.target == "inventory" then
                Inventory.Add(item.inventoryItem, item.amount)
            end

            GameData:SetTo(modId, "colony.resources", resources)
            return true
        end
    end
    return false
end

return Resupply
