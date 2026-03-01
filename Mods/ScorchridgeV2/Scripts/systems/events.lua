-- ============================================
-- ScorchridgeV2 — Events System
-- Random events at quadrant boundaries
-- ============================================

local SFX = require("core/sound")

local modId = "ScorchridgeV2"

local GameEvents = {}

local pendingEvent = nil

local EVENT_POOL = {
    {
        id = "contaminated_food",
        name = "Contaminated Food",
        desc = "A batch of food rations has been found contaminated. Food supply reduced by 20%.",
        type = "negative",
        chance = 0.12,
        effect = function(state, inmates, resources, production)
            if resources then
                resources.food = math.floor((resources.food or 0) * 0.8)
            end
        end
    },
    {
        id = "oxygen_leak",
        name = "Oxygen Leak",
        desc = "A seal breach has caused an oxygen leak! -50 O2.",
        type = "negative",
        chance = 0.10,
        effect = function(state, inmates, resources, production)
            if resources then
                resources.oxygen = math.max(0, (resources.oxygen or 0) - 50)
            end
        end
    },
    {
        id = "solar_flare",
        name = "Solar Flare",
        desc = "Intense radiation from a solar flare. All inmates lose 20 stamina.",
        type = "negative",
        chance = 0.10,
        effect = function(state, inmates, resources, production)
            if inmates then
                for i = 1, #inmates do
                    inmates[i].stamina = math.max(0, inmates[i].stamina - 20)
                end
            end
        end
    },
    {
        id = "market_fluctuation",
        name = "Market Fluctuation",
        desc = "Ore prices have shifted. Quota increased by 15%.",
        type = "negative",
        chance = 0.10,
        effect = function(state, inmates, resources, production)
            if production then
                production.quotaPerCycle = math.floor(production.quotaPerCycle * 1.15)
            end
        end
    },
    {
        id = "hunger_strike",
        name = "Hunger Strike",
        desc = "Inmates are protesting conditions. All morale drops by 15.",
        type = "negative",
        chance = 0.10,
        effect = function(state, inmates, resources, production)
            if inmates then
                for i = 1, #inmates do
                    inmates[i].morale = math.max(0, inmates[i].morale - 15)
                end
            end
        end
    },
    {
        id = "mother_lode",
        name = "Mother Lode",
        desc = "A rich vein has been discovered! Colony earns 100 bonus credits.",
        type = "positive",
        chance = 0.08,
        effect = function(state, inmates, resources, production)
            if resources then
                resources.colonyCredits = (resources.colonyCredits or 0) + 100
            end
            if production then
                production.cycleCreditsEarned = (production.cycleCreditsEarned or 0) + 100
            end
        end
    },
    {
        id = "experimental_supplement",
        name = "Experimental Supplement",
        desc = "A new supplement has been tested. All inmates gain 30 stamina.",
        type = "positive",
        chance = 0.10,
        effect = function(state, inmates, resources, production)
            if inmates then
                for i = 1, #inmates do
                    inmates[i].stamina = math.min(inmates[i].stamina + 30, inmates[i].maxStamina)
                end
            end
        end
    },
    {
        id = "ads_campaign",
        name = "Ads Campaign",
        desc = "Corporate propaganda boosts colony reputation. +20 merits.",
        type = "positive",
        chance = 0.10,
        effect = function(state, inmates, resources, production)
            if resources then
                resources.colonyMerits = (resources.colonyMerits or 0) + 20
            end
        end
    },
    {
        id = "supply_cache",
        name = "Supply Cache Found",
        desc = "Scavengers found a hidden cache! +50 food, +30 oxygen.",
        type = "positive",
        chance = 0.08,
        effect = function(state, inmates, resources, production)
            if resources then
                resources.food = (resources.food or 0) + 50
                resources.oxygen = (resources.oxygen or 0) + 30
            end
        end
    }
}

function GameEvents.Roll(state, inmates, resources, production)
    if pendingEvent then return end

    local triggered = {}
    for _, evt in ipairs(EVENT_POOL) do
        if math.random() < evt.chance then
            triggered[#triggered + 1] = evt
        end
    end

    if #triggered > 0 then
        SFX.Event()
        local chosen = triggered[math.random(#triggered)]
        pendingEvent = {
            name = chosen.name,
            desc = chosen.desc,
            type = chosen.type,
            effect = chosen.effect,
            _state = state,
            _inmates = inmates,
            _resources = resources,
            _production = production
        }
    end
end

function GameEvents.HasPending()
    return pendingEvent ~= nil
end

function GameEvents.GetPending()
    return pendingEvent
end

function GameEvents.Dismiss()
    if not pendingEvent then return end

    local evt = pendingEvent
    pendingEvent = nil

    if evt.effect then
        evt.effect(evt._state, evt._inmates, evt._resources, evt._production)
    end

    if evt._state then GameData:SetTo(modId, "colony.state", evt._state) end
    if evt._inmates then GameData:SetTo(modId, "colony.inmates", evt._inmates) end
    if evt._resources then GameData:SetTo(modId, "colony.resources", evt._resources) end
    if evt._production then GameData:SetTo(modId, "colony.production", evt._production) end
end

return GameEvents
