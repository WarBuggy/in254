-- ============================================
-- Terraria2D Mod — Initialization
-- 2D sandbox adventure
-- ============================================

-- Require scenes (side effect: registers with engine)
require("scenes/title")
require("scenes/gameover")
require("scenes/gameplay/root")

local function onDataInit()
    print("[Terraria2D] Initializing Terraria 2D mod...")
    Scene.Switch("title")
    print("[Terraria2D] Ready.")
end

Events.OnDataInit.Add(onDataInit)
