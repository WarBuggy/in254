-- ============================================
-- Scorchridge Mod — Initialization
-- Single entry point: requires all modules, sets up game data.
-- ============================================

local InmateClass = require("entities/inmate")

-- Require scenes (side effect: registers with engine)
require("scenes/help")
require("scenes/gameover")
require("scenes/gameplay/root")

local modId = "Scorchridge"

local function onDataInit()
    print(Localize("scorchridge.welcome"))

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
    }
    GameData:SetTo(modId, "colony.state", state)

    -- Spawn 3 inmates
    local inmates = {
        {
            name = "Inmate-7A",
            stamina = 150, maxStamina = 150,
            morale = 120, maxMorale = 150,
            credits = 0, alive = true, exhausted = false,
            assignedTier = 1,
            drugEffectiveness = 100, addicted = false, quadrantsClean = 0,
            dosedThisQuadrant = false
        },
        {
            name = "Inmate-3K",
            stamina = 150, maxStamina = 150,
            morale = 120, maxMorale = 150,
            credits = 0, alive = true, exhausted = false,
            assignedTier = 1,
            drugEffectiveness = 100, addicted = false, quadrantsClean = 0,
            dosedThisQuadrant = false
        },
        {
            name = "Inmate-9R",
            stamina = 150, maxStamina = 150,
            morale = 120, maxMorale = 150,
            credits = 0, alive = true, exhausted = false,
            assignedTier = 1,
            drugEffectiveness = 100, addicted = false, quadrantsClean = 0,
            dosedThisQuadrant = false
        }
    }
    InmateClass.hydrateAll(inmates)
    GameData:SetTo(modId, "colony.inmates", inmates)

    -- Resources
    local resources = {
        pcho = 180,
        colonyCredits = 0,
        colonyMerits = 0,
        drugSupply = 6
    }
    GameData:SetTo(modId, "colony.resources", resources)

    -- Production config
    local production = {
        oreTiers = {
            { mult = 1.0, staCost = 18, name = "Copper" },
            { mult = 1.8, staCost = 33, name = "Silver" },
            { mult = 3.0, staCost = 52, name = "Gold" }
        },
        portionSizes = {
            { pcho = 3, staRec = 22, morRec = 3, name = "Small" },
            { pcho = 5, staRec = 45, morRec = 8, name = "Normal" },
            { pcho = 8, staRec = 75, morRec = 15, name = "Large" }
        },
        baseOutput = 10,
        quotaPerCycle = 80,
        cycleCreditsEarned = 0,
        totalCreditsEarned = 0,
        lastShiftOutput = 0,
        lastShiftDetails = {}
    }
    GameData:SetTo(modId, "colony.production", production)

    -- Start in help scene
    Scene.Switch("help")

    print(Localize("scorchridge.initialized", "1", "1"))
end

Events.OnDataInit.Add(onDataInit)
