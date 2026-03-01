-- ============================================
-- ScorchridgeV2 — Colony Phase State Machine
-- Adapted from V1: cell-based, no zone assignment
-- ============================================

local InmateClass = require("entities/inmate")
local SFX = require("core/sound")
local Production = require("systems/production")
local GameEvents = require("systems/events")
local Drugs = require("systems/drugs")
local Merits = require("systems/merits")
local Resupply = require("systems/resupply")

local modId = "ScorchridgeV2"

local Colony = {}

local PHASES = {
    "preparation",
    "work",
    "preMeal",
    "meal",
    "postMeal",
    "downtime",
    "rest"
}

local PLAYER_PHASES = {
    preparation = true,
    preMeal = true,
    postMeal = true
}

local AUTO_PHASE_DURATION = {
    work = 4,
    meal = 3,
    downtime = 2,
    rest = 3
}

local autoPhaseExecuted = false

local function advanceToNextPhase()
    local state = GameData:TryGetFrom(modId, "colony.state")
    if not state or state.gameOver then return end

    state.phaseIndex = state.phaseIndex + 1

    if state.phaseIndex > #PHASES then
        state.phaseIndex = 1
        state.quadrant = state.quadrant + 1

        if state.quadrant > 4 then
            GameData:SetTo(modId, "colony.state", state)
            Production.AdvanceCycle()
            autoPhaseExecuted = false
            return
        end
    end

    state.phase = PHASES[state.phaseIndex]
    state.phaseTimer = 0
    autoPhaseExecuted = false

    SFX.Advance()

    if state.phaseIndex == 1 and state.quadrant > 1 then
        GameEvents.Roll(state, GameData:TryGetFrom(modId, "colony.inmates"),
            GameData:TryGetFrom(modId, "colony.resources"),
            GameData:TryGetFrom(modId, "colony.production"))
    end

    if state.phaseIndex == 1 then
        local inmates = GameData:TryGetFrom(modId, "colony.inmates")
        InmateClass.hydrateAll(inmates)
        local resources = GameData:TryGetFrom(modId, "colony.resources")

        if inmates and resources then
            -- Oxygen drain: 2 per living inmate per quadrant
            local livingCount = 0
            for i = 1, #inmates do
                if inmates[i].alive then livingCount = livingCount + 1 end
            end
            local o2Drain = livingCount * 2
            resources.oxygen = math.max(0, (resources.oxygen or 0) - o2Drain)

            -- Zero oxygen: kill 1 random living inmate
            if resources.oxygen <= 0 then
                local livingIndices = {}
                for i = 1, #inmates do
                    if inmates[i].alive then livingIndices[#livingIndices + 1] = i end
                end
                if #livingIndices > 0 then
                    local victim = livingIndices[math.random(#livingIndices)]
                    inmates[victim].alive = false
                    print("[ScorchridgeV2] Inmate " .. inmates[victim].name .. " died from oxygen deprivation!")
                end
            elseif resources.oxygen < 100 then
                -- Low oxygen penalty: -5 sta, -8 mor per inmate
                for i = 1, #inmates do
                    if inmates[i].alive then
                        inmates[i].stamina = math.max(0, inmates[i].stamina - 5)
                        inmates[i].morale = math.max(0, inmates[i].morale - 8)
                    end
                end
            end

            GameData:SetTo(modId, "colony.resources", resources)

            for i = 1, #inmates do
                Drugs.ProcessWithdrawal(inmates[i])
            end
            GameData:SetTo(modId, "colony.inmates", inmates)
        end
    end

    GameData:SetTo(modId, "colony.state", state)
end

local function executeAutoPhase(phase)
    if autoPhaseExecuted then return end
    autoPhaseExecuted = true

    if phase == "work" then
        Production.RunWorkShift()
        SFX.Pickaxe()
    elseif phase == "meal" then
        Production.RunMealPhase()
        SFX.Eat()
    elseif phase == "downtime" then
        -- nothing
    elseif phase == "rest" then
        Production.RunRestPhase()
        SFX.Rest()
    end
end

function Colony.Update(deltaTime, totalTime)
    local state = GameData:TryGetFrom(modId, "colony.state")
    if not state then return end

    if state.gameOver then
        return "gameover"
    end

    SFX.UpdateBGM(state.phase)

    if GameEvents.HasPending() then
        if Input.IsKeyPressed("enter") or Input.IsKeyPressed("space") then
            GameEvents.Dismiss()
        end
        return
    end

    if Resupply.IsOpen() then
        return
    end

    -- Auto-open resupply when pending
    if state.resupplyPending then
        Resupply.Open()
        return
    end

    if Merits.IsStoreOpen() then
        if Input.IsKeyPressed("escape") then
            Merits.ToggleStore()
        end
        return
    end

    local phase = state.phase

    -- Player phases: advance with Enter
    if PLAYER_PHASES[phase] then
        if Input.IsKeyPressed("enter") then
            advanceToNextPhase()
        end
    else
        -- Auto phases
        executeAutoPhase(phase)

        local duration = AUTO_PHASE_DURATION[phase] or 3
        state.phaseTimer = state.phaseTimer + deltaTime

        if state.phaseTimer >= duration then
            GameData:SetTo(modId, "colony.state", state)
            advanceToNextPhase()
        else
            GameData:SetTo(modId, "colony.state", state)
        end
    end
end

function Colony.GetPhases() return PHASES end
function Colony.IsPlayerPhase(phase) return PLAYER_PHASES[phase] == true end
function Colony.AdvancePhase() advanceToNextPhase() end

return Colony
