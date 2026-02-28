-- ============================================
-- Scorchridge — Inmate Logic (wrappers)
-- ============================================

local InmateClass = require("entities/inmate")

local Inmates = {}

function Inmates.CalculateWorkOutput(inmate, production)
    InmateClass.hydrate(inmate)
    return inmate:calculateWork(production)
end

function Inmates.ProcessMeal(inmate, portionConfig)
    InmateClass.hydrate(inmate)
    return inmate:processMeal(portionConfig)
end

function Inmates.ApplyMoraleDecay(inmate)
    InmateClass.hydrate(inmate)
    inmate:applyMoraleDecay()
end

function Inmates.GetStatus(inmate)
    InmateClass.hydrate(inmate)
    return inmate:getStatus()
end

function Inmates.PreviewWorkOutput(inmate, production, tierIndex)
    InmateClass.hydrate(inmate)
    return inmate:previewWork(production, tierIndex)
end

return Inmates
