-- ============================================
-- Scorchridge — Drug / Addiction System (wrappers)
-- ============================================

local InmateClass = require("entities/inmate")

local Drugs = {}

function Drugs.Administer(inmate, resources)
    InmateClass.hydrate(inmate)
    return inmate:administerDrug(resources)
end

function Drugs.ProcessWithdrawal(inmate)
    InmateClass.hydrate(inmate)
    inmate:processWithdrawal()
end

return Drugs
