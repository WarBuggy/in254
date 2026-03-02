-- ============================================
-- ExtractOrDie — Extraction System
-- Zone timer, swarm trigger
-- ============================================

local Config = require("eod/core/config")

local Extraction = {}

local TS = Config.TILE_SIZE

-- Check if player is inside any extraction zone
function Extraction.IsPlayerInZone(shared)
    local p = shared.player
    if not p.alive then return false end

    local pcx = p.x + p.w / 2
    local pcy = p.y + p.h / 2

    for _, zone in ipairs(shared.extractZones) do
        local zx = zone.x * TS
        local zy = zone.y * TS
        local zw = zone.w * TS
        local zh = zone.h * TS
        if pcx >= zx and pcx < zx + zw and pcy >= zy and pcy < zy + zh then
            return true
        end
    end
    return false
end

function Extraction.Update(shared, dt)
    if shared.raidOver then return end

    local inZone = Extraction.IsPlayerInZone(shared)

    if inZone then
        if not shared.extracting then
            shared.extracting = true
            shared.extractTimer = 0
        end
        shared.extractTimer = shared.extractTimer + dt
        if shared.extractTimer >= Config.EXTRACT_TIME then
            -- Extraction successful!
            shared.raidOver = true
            shared.raidResult = "extracted"
        end
    else
        if shared.extracting then
            shared.extracting = false
            shared.extractTimer = 0
        end
    end
end

return Extraction
