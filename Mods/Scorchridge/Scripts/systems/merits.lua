-- ============================================
-- Scorchridge — Colony Merits Store
-- ============================================

local InmateClass = require("entities/inmate")

local modId = "Scorchridge"

local Merits = {}

local storeOpen = false

local STORE_ITEMS = {
    {
        id = "buy_pcho",
        name = "Buy PCHO Rations",
        desc = "+20 PCHO supply",
        cost = 10,
        apply = function(resources, inmates)
            resources.pcho = resources.pcho + 20
        end
    },
    {
        id = "buy_drug",
        name = "Buy Drug Dose",
        desc = "+1 drug supply",
        cost = 15,
        apply = function(resources, inmates)
            resources.drugSupply = (resources.drugSupply or 0) + 1
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
