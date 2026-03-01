-- ============================================
-- Terraria2D — Pause Menu
-- ============================================

local UI = require("core/ui")
local Theme = require("core/theme")
local Boss = require("systems/boss")
local C = Theme.Colors

local PauseUI = {}

function PauseUI.Update(shared)
    -- Handled in draw for button clicks
end

function PauseUI.Draw(shared)
    local W = shared.W
    local H = shared.H

    -- Overlay
    UI.Rect(0, 0, W, H, {0, 0, 0, 180})

    local panelW = 220
    local panelH = 200
    local panelX = math.floor(W / 2 - panelW / 2)
    local panelY = math.floor(H / 2 - panelH / 2)

    UI.Panel(panelX, panelY, panelW, panelH, {25, 25, 40, 240})
    Drawing.Text("PAUSED", panelX + panelW / 2 - 30, panelY + 10, 18, C.YELLOW)

    local btnW = 180
    local btnH = 30
    local btnX = panelX + math.floor((panelW - btnW) / 2)
    local btnY = panelY + 45

    -- Resume
    if UI.Button(btnX, btnY, btnW, btnH, "  Resume", {
        color = {40, 60, 40, 230},
        hoverColor = {60, 80, 60, 240},
        textSize = 14,
    }) then
        shared.showPause = false
    end

    -- Spawn Boss (debug/fun feature)
    btnY = btnY + 40
    local bossLabel = (shared.boss and shared.boss.alive) and "  Boss Active!" or "  Summon Boss"
    local bossDisabled = shared.boss and shared.boss.alive
    if UI.Button(btnX, btnY, btnW, btnH, bossLabel, {
        color = {80, 30, 30, 230},
        hoverColor = {110, 40, 40, 240},
        textSize = 14,
        disabled = bossDisabled,
    }) then
        Boss.Spawn(shared)
        shared.showPause = false
    end

    -- Quit to title
    btnY = btnY + 40
    if UI.Button(btnX, btnY, btnW, btnH, "  Quit to Title", {
        color = {80, 40, 40, 230},
        hoverColor = {110, 50, 50, 240},
        textSize = 14,
    }) then
        Scene.Switch("title")
    end
end

return PauseUI
