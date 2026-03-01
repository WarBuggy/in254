-- ============================================
-- ScorchridgeV2 — Colony Merits Store
-- ============================================

local InmateClass = require("entities/inmate")
local Inventory = require("systems/inventory")

local modId = "ScorchridgeV2"

local Merits = {}

local storeOpen = false

local STORE_ITEMS = {
    {
        id = "buy_pcho",
        name = "Buy PCHO Rations",
        desc = "+40 PCHO (inventory)",
        cost = 10,
        apply = function(resources, inmates)
            Inventory.Add("pcho_ration", 40)
        end
    },
    {
        id = "buy_drug",
        name = "Buy Drug Dose",
        desc = "+2 drug supply (inventory)",
        cost = 15,
        apply = function(resources, inmates)
            Inventory.Add("drug_dose", 2)
        end
    },
    {
        id = "morale_boost",
        name = "Morale Boost",
        desc = "+10 morale to all inmates",
        cost = 5,
        apply = function(resources, inmates)
            if inmates then
                for i = 1, #inmates do
                    inmates[i].morale = math.min(inmates[i].morale + 10, inmates[i].maxMorale)
                end
                GameData:SetTo(modId, "colony.inmates", inmates)
            end
        end
    },
    {
        id = "stamina_boost",
        name = "Energy Rations",
        desc = "+15 stamina to all inmates",
        cost = 8,
        apply = function(resources, inmates)
            if inmates then
                for i = 1, #inmates do
                    inmates[i].stamina = math.min(inmates[i].stamina + 15, inmates[i].maxStamina)
                end
                GameData:SetTo(modId, "colony.inmates", inmates)
            end
        end
    }
}

function Merits.IsStoreOpen()
    return storeOpen
end

function Merits.ToggleStore()
    storeOpen = not storeOpen
end

function Merits.GetStoreItems()
    return STORE_ITEMS
end

function Merits.Purchase(itemId, resources)
    if not resources then return false end

    local inmates = GameData:TryGetFrom(modId, "colony.inmates")
    InmateClass.hydrateAll(inmates)

    for _, item in ipairs(STORE_ITEMS) do
        if item.id == itemId then
            if (resources.colonyMerits or 0) >= item.cost then
                resources.colonyMerits = resources.colonyMerits - item.cost
                item.apply(resources, inmates)
                return true
            end
            return false
        end
    end
    return false
end

return Merits
