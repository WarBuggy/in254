-- ============================================
-- ScorchridgeV2 — Production & Mining
-- Virtual mining via neural-link terminals in cells
-- ============================================

local InmateClass = require("entities/inmate")
local Inmates = require("systems/inmates")
local Inventory = require("systems/inventory")
local SFX = require("core/sound")

local modId = "ScorchridgeV2"

local Production = {}

function Production.RunWorkShift()
    local inmates = GameData:TryGetFrom(modId, "colony.inmates")
    InmateClass.hydrateAll(inmates)
    local production = GameData:TryGetFrom(modId, "colony.production")
    local resources = GameData:TryGetFrom(modId, "colony.resources")

    if not inmates or not production or not resources then return end

    local totalOutput = 0
    production.lastShiftDetails = {}

    for i = 1, #inmates do
        local credits, usedTier = Inmates.CalculateWorkOutput(inmates[i], production)
        totalOutput = totalOutput + credits

        production.lastShiftDetails[i] = {
            name = inmates[i].name,
            credits = credits,
            tier = usedTier,
            stamina = math.floor(inmates[i].stamina),
            exhausted = inmates[i].exhausted
        }
    end

    production.cycleCreditsEarned = production.cycleCreditsEarned + totalOutput
    production.totalCreditsEarned = production.totalCreditsEarned + totalOutput
    production.lastShiftOutput = totalOutput
    resources.colonyCredits = resources.colonyCredits + totalOutput

    GameData:SetTo(modId, "colony.inmates", inmates)
    GameData:SetTo(modId, "colony.production", production)
    GameData:SetTo(modId, "colony.resources", resources)

    print("[ScorchridgeV2] Work shift complete: +" .. totalOutput .. " credits")
end

function Production.RunMealPhase()
    local inmates = GameData:TryGetFrom(modId, "colony.inmates")
    InmateClass.hydrateAll(inmates)
    local state = GameData:TryGetFrom(modId, "colony.state")
    local production = GameData:TryGetFrom(modId, "colony.production")
    local resources = GameData:TryGetFrom(modId, "colony.resources")

    if not inmates or not state or not production or not resources then return end

    local portionIndex = state.portionSize or 2
    local portionConfig = production.portionSizes[portionIndex]
    if not portionConfig then
        portionConfig = production.portionSizes[2]
    end

    -- Count living inmates for PCHO consumption
    local livingCount = 0
    for i = 1, #inmates do
        if inmates[i].alive then livingCount = livingCount + 1 end
    end

    -- PCHO bonus: if toggled on and enough stock
    local usePcho = state.usePcho and Inventory.HasStock("pcho_ration", livingCount)
    if usePcho then
        Inventory.Consume("pcho_ration", livingCount)
    end

    local totalFoodConsumed = 0
    for i = 1, #inmates do
        if inmates[i].alive then
            local hasPcho = usePcho
            local consumed = Inmates.ProcessMeal(inmates[i], portionConfig, hasPcho)
            totalFoodConsumed = totalFoodConsumed + consumed
        end
    end

    -- Consume food from resources; if not enough, no recovery already happened
    resources.food = math.max(resources.food - totalFoodConsumed, 0)

    for i = 1, #inmates do
        inmates[i].dosedThisQuadrant = false
    end

    GameData:SetTo(modId, "colony.inmates", inmates)
    GameData:SetTo(modId, "colony.resources", resources)

    print("[ScorchridgeV2] Meal phase: -" .. totalFoodConsumed .. " food consumed" ..
        (usePcho and " (+PCHO bonus)" or ""))
end

function Production.RunRestPhase()
    local inmates = GameData:TryGetFrom(modId, "colony.inmates")
    InmateClass.hydrateAll(inmates)
    if not inmates then return end

    for i = 1, #inmates do
        Inmates.ApplyMoraleDecay(inmates[i])
    end

    GameData:SetTo(modId, "colony.inmates", inmates)
    print("[ScorchridgeV2] Rest phase complete")
end

function Production.CheckQuota()
    local production = GameData:TryGetFrom(modId, "colony.production")
    local state = GameData:TryGetFrom(modId, "colony.state")
    local inmates = GameData:TryGetFrom(modId, "colony.inmates")
    InmateClass.hydrateAll(inmates)
    local resources = GameData:TryGetFrom(modId, "colony.resources")
    if not production or not state or not inmates then return false end

    local perInmateQuota = math.floor(production.quotaPerCycle / #inmates)
    local failCount = 0
    local passCount = 0

    for i = 1, #inmates do
        if inmates[i].credits >= perInmateQuota then
            passCount = passCount + 1
            if resources then
                resources.colonyMerits = (resources.colonyMerits or 0) + 10
            end
        else
            failCount = failCount + 1
            if resources then
                resources.colonyMerits = math.max(0, (resources.colonyMerits or 0) - 10)
            end
        end
    end

    if resources then
        GameData:SetTo(modId, "colony.resources", resources)
    end

    return production.cycleCreditsEarned >= production.quotaPerCycle, failCount
end

function Production.AdvanceCycle()
    local state = GameData:TryGetFrom(modId, "colony.state")
    local production = GameData:TryGetFrom(modId, "colony.production")
    local inmates = GameData:TryGetFrom(modId, "colony.inmates")
    InmateClass.hydrateAll(inmates)
    if not state or not production then return false end

    local met, failCount = Production.CheckQuota()

    if met then
        SFX.QuotaMet()
        state.consecutiveQuotaSuccesses = (state.consecutiveQuotaSuccesses or 0) + 1
        print("[ScorchridgeV2] Cycle " .. state.cycle .. " quota MET: " ..
            production.cycleCreditsEarned .. "/" .. production.quotaPerCycle)
    else
        SFX.QuotaFail()
        state.consecutiveQuotaSuccesses = 0
        print("[ScorchridgeV2] Cycle " .. state.cycle .. " quota FAILED: " ..
            production.cycleCreditsEarned .. "/" .. production.quotaPerCycle)
    end

    -- Game over: 2/3 of inmates fail (rounded: if failCount >= ceil(2/3 * total))
    failCount = failCount or 0
    local totalInmates = inmates and #inmates or 20
    local failThreshold = math.ceil(totalInmates * 2 / 3)
    if failCount >= failThreshold then
        state.gameOver = true
        GameData:SetTo(modId, "colony.state", state)
        print("[ScorchridgeV2] GAME OVER - too many inmates failed quota")
        return false
    end

    state.cycle = state.cycle + 1
    state.quadrant = 1
    state.phase = "preparation"
    state.phaseIndex = 1
    state.selectedInmate = 1
    state.portionSize = 2

    if inmates then
        for i = 1, #inmates do
            inmates[i].credits = 0
            inmates[i].exhausted = false
        end
        GameData:SetTo(modId, "colony.inmates", inmates)
    end

    production.cycleCreditsEarned = 0
    production.lastShiftOutput = 0
    production.lastShiftDetails = {}

    if (state.consecutiveQuotaSuccesses or 0) >= 3 then
        production.quotaPerCycle = math.floor(production.quotaPerCycle * 1.1)
        state.consecutiveQuotaSuccesses = 0
    end

    -- Trigger resupply screen at cycle start
    state.resupplyPending = true
    state.usePcho = false

    GameData:SetTo(modId, "colony.state", state)
    GameData:SetTo(modId, "colony.production", production)

    return true
end

return Production
