-- ============================================
-- Scorchridge — Colony Phase State Machine
-- ============================================

local InmateClass = require("entities/inmate")
local SFX = require("core/sound")
local Production = require("systems/production")
local GameEvents = require("systems/events")
local Drugs = require("systems/drugs")
local Merits = require("systems/merits")

local modId = "Scorchridge"

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
        if inmates then
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

    if Merits.IsStoreOpen() then
        if Input.IsKeyPressed("escape") then
            Merits.ToggleStore()
        end
        return
    end

    local phase = state.phase

    if phase == "preparation" then
        local inmates = GameData:TryGetFrom(modId, "colony.inmates")
        InmateClass.hydrateAll(inmates)
        if not inmates then return end

        local selected = inmates[state.selectedInmate]
        if selected then
            if Input.IsKeyPressed("d1") or Input.IsKeyPressed("numpad1") then
                selected.assignedTier = 1
                GameData:SetTo(modId, "colony.inmates", inmates)
            elseif Input.IsKeyPressed("d2") or Input.IsKeyPressed("numpad2") then
                selected.assignedTier = 2
                GameData:SetTo(modId, "colony.inmates", inmates)
            elseif Input.IsKeyPressed("d3") or Input.IsKeyPressed("numpad3") then
                selected.assignedTier = 3
                GameData:SetTo(modId, "colony.inmates", inmates)
            end
        end

        if Input.IsKeyPressed("enter") then
            advanceToNextPhase()
        end

    elseif phase == "preMeal" then
        if Input.IsKeyPressed("d1") or Input.IsKeyPressed("numpad1") then
            state.portionSize = 1
            GameData:SetTo(modId, "colony.state", state)
        elseif Input.IsKeyPressed("d2") or Input.IsKeyPressed("numpad2") then
            state.portionSize = 2
            GameData:SetTo(modId, "colony.state", state)
        elseif Input.IsKeyPressed("d3") or Input.IsKeyPressed("numpad3") then
            state.portionSize = 3
            GameData:SetTo(modId, "colony.state", state)
        end

        if Input.IsKeyPressed("enter") then
            advanceToNextPhase()
        end

    elseif PLAYER_PHASES[phase] then
        if Input.IsKeyPressed("enter") then
            advanceToNextPhase()
        end

    else
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
