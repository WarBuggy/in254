-- ============================================
-- ScorchridgeV2 — Drug / Addiction System (wrappers)
-- ============================================

local InmateClass = require("entities/inmate")
local Inventory = require("systems/inventory")

local Drugs = {}

function Drugs.Administer(inmate)
    InmateClass.hydrate(inmate)
    return inmate:administerDrug()
end

function Drugs.ProcessWithdrawal(inmate)
    InmateClass.hydrate(inmate)
    inmate:processWithdrawal()
end

return Drugs
