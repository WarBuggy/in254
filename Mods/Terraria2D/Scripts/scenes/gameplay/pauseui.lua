-- ============================================
-- Terraria2D — Pause Menu
-- ============================================

local UI = require("core/ui")
local Theme = require("core/theme")
local Boss = require("systems/boss")
local C = Theme.Colors

local PauseUI = {}

-- Cached colors
local _cOverlay     = Color.New(0, 0, 0, 180)
local _cPanelBg     = Color.New(25, 25, 40, 240)
local _cResumeBtn   = Color.New(40, 60, 40, 230)
local _cResumeHov   = Color.New(60, 80, 60, 240)
local _cBossBtn     = Color.New(80, 30, 30, 230)
local _cBossHov     = Color.New(110, 40, 40, 240)
local _cQuitBtn     = Color.New(80, 40, 40, 230)
local _cQuitHov     = Color.New(110, 50, 50, 240)

function PauseUI.Update(shared)
    -- Handled in draw for button clicks
end

function PauseUI.Draw(shared)
    local W = shared.W
    local H = shared.H

    -- Overlay
    UI.Rect(0, 0, W, H, _cOverlay)

    local panelW = 220
    local panelH = 200
    local panelX = math.floor(W / 2 - panelW / 2)
    local panelY = math.floor(H / 2 - panelH / 2)

    UI.Panel(panelX, panelY, panelW, panelH, _cPanelBg)
    Drawing.Text("PAUSED", panelX + panelW / 2 - 30, panelY + 10, 18, C.YELLOW)

    local btnW = 180
    local btnH = 30
    local btnX = panelX + math.floor((panelW - btnW) / 2)
    local btnY = panelY + 45

    -- Resume
    if UI.Button(btnX, btnY, btnW, btnH, "  Resume", {
        color = _cResumeBtn,
        hoverColor = _cResumeHov,
        textSize = 14,
    }) then
        shared.showPause = false
    end

    -- Spawn Boss (debug/fun feature)
    btnY = btnY + 40
    local bossLabel = (shared.boss and shared.boss.alive) and "  Boss Active!" or "  Summon Boss"
    local bossDisabled = shared.boss and shared.boss.alive
    if UI.Button(btnX, btnY, btnW, btnH, bossLabel, {
        color = _cBossBtn,
        hoverColor = _cBossHov,
        textSize = 14,
        disabled = bossDisabled,
    }) then
        Boss.Spawn(shared)
        shared.showPause = false
    end

    -- Quit to title
    btnY = btnY + 40
    if UI.Button(btnX, btnY, btnW, btnH, "  Quit to Title", {
        color = _cQuitBtn,
        hoverColor = _cQuitHov,
        textSize = 14,
    }) then
        Scene.Switch("title")
    end
end

return PauseUI
