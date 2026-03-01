-- ============================================
-- ScorchridgeV2 Mod — Initialization
-- Side-scrolling prison colony with 20 inmates
-- ============================================

local InmateClass = require("entities/inmate")
local Inventory = require("systems/inventory")

-- Require scenes (side effect: registers with engine)
require("scenes/help")
require("scenes/gameover")
require("scenes/gameplay/root")

local modId = "ScorchridgeV2"

-- Inmate name pool
local INMATE_NAMES = {
    "Inmate-7A", "Inmate-3K", "Inmate-9R", "Inmate-2D",
    "Inmate-5F", "Inmate-8B", "Inmate-1G", "Inmate-4E",
    "Inmate-6C", "Inmate-0H", "Inmate-7J", "Inmate-2L",
    "Inmate-9M", "Inmate-3N", "Inmate-5P", "Inmate-8Q",
    "Inmate-1S", "Inmate-4T", "Inmate-6U", "Inmate-0V"
}

local function createInmate(index)
    -- Randomize stats slightly for variety
    local baseStamina = 130 + math.random(0, 40)
    local baseMorale = 100 + math.random(0, 40)
    return {
        name = INMATE_NAMES[index] or ("Inmate-" .. index),
        stamina = baseStamina,
        maxStamina = 150,
        morale = baseMorale,
        maxMorale = 150,
        credits = 0,
        alive = true,
        exhausted = false,
        assignedTier = 1,
        drugEffectiveness = 100,
        addicted = false,
        quadrantsClean = 0,
        dosedThisQuadrant = false,
        cellIndex = index
    }
end

local function onDataInit()
    print("[ScorchridgeV2] Initializing side-scrolling colony...")

    -- Colony state
    local state = {
        cycle = 1,
        quadrant = 1,
        phase = "preparation",
        phaseIndex = 1,
        phaseTimer = 0,
        gameOver = false,
        consecutiveQuotaSuccesses = 0,
        selectedInmate = 1,
        portionSize = 2,
        usePcho = false,
        resupplyPending = false,
    }
    GameData:SetTo(modId, "colony.state", state)

    -- Spawn 20 inmates
    local inmates = {}
    for i = 1, 20 do
        inmates[i] = createInmate(i)
    end
    InmateClass.hydrateAll(inmates)
    GameData:SetTo(modId, "colony.inmates", inmates)

    -- Resources (scaled for 20 inmates)
    local resources = {
        oxygen = 400,
        food = 300,
        colonyCredits = 0,
        colonyMerits = 0
    }
    GameData:SetTo(modId, "colony.resources", resources)

    -- Inventory (drugs + PCHO as items)
    Inventory.Init({ drug_dose = 10, pcho_ration = 600 })

    -- Production config
    local production = {
        oreTiers = {
            { mult = 1.0, staCost = 18, name = "Copper" },
            { mult = 1.8, staCost = 33, name = "Silver" },
            { mult = 3.0, staCost = 52, name = "Gold" }
        },
        portionSizes = {
            { food = 2, staRec = 15, morRec = 2, name = "Small" },
            { food = 4, staRec = 30, morRec = 5, name = "Normal" },
            { food = 6, staRec = 50, morRec = 10, name = "Large" }
        },
        baseOutput = 10,
        quotaPerCycle = 500,
        cycleCreditsEarned = 0,
        totalCreditsEarned = 0,
        lastShiftOutput = 0,
        lastShiftDetails = {}
    }
    GameData:SetTo(modId, "colony.production", production)

    -- Start in help scene
    Scene.Switch("help")

    print("[ScorchridgeV2] Colony initialized: 20 inmates, O2/food/inventory system active")
end

Events.OnDataInit.Add(onDataInit)
