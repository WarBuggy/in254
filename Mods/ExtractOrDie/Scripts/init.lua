-- ============================================
-- ExtractOrDie Mod — Initialization
-- Top-down extraction shooter
-- ============================================

-- Require scenes (side effect: registers with engine)
require("eod/scenes/title")
require("eod/scenes/loadout")
require("eod/scenes/raid")
require("eod/scenes/extract_success")
require("eod/scenes/death")

local function onDataInit()
    print("[ExtractOrDie] Initializing Extract Or Die mod...")
    Scene.Switch("eod_title")
    print("[ExtractOrDie] Ready.")
end

Events.OnDataInit.Add(onDataInit)
