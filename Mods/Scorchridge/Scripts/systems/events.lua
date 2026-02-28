-- ============================================
-- Scorchridge — Events System
-- Random events at quadrant boundaries
-- ============================================

local SFX = require("core/sound")

local modId = "Scorchridge"

local GameEvents = {}

local pendingEvent = nil

local EVENT_POOL = {
    {
        id = "contaminated_pcho",
        name = "Contaminated PCHO",
        desc = "A batch of PCHO rations has been found contaminated. Supply reduced by 20%.",
        type = "negative",
        chance = 0.12,
        effect = function(state, inmates, resources, production)
            if resources then
                resources.pcho = math.floor(resources.pcho * 0.8)
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
        desc = "A rich vein has been discovered! Next shift output will be doubled.",
        type = "positive",
        chance = 0.08,
        effect = function(state, inmates, resources, production)
            if production then
                production.baseOutput = (production.baseOutput or 10) * 2
                production._motherLodeActive = true
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
