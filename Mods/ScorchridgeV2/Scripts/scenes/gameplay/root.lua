-- ============================================
-- ScorchridgeV2 — Gameplay Root Node
-- Main scene tree root with player controller
-- ============================================

local Theme = require("core/theme")
local SFX = require("core/sound")
local UI = require("core/ui")
local Config = require("core/config")
local Camera = require("core/camera")

local Player = require("entities/player")
local InmateClass = require("entities/inmate")
local Cell = require("entities/cell")
local Colony = require("systems/colony")

local modId = "ScorchridgeV2"

local GameplayRoot = SceneNode.new({
    name   = "gameplay_root",
    shared = Theme.NewGameplayShared(),

    onEnter = function(self, shared)
        SFX.LoadGameplaySounds()

        -- Initialize player
        shared.player = Player.new({
            x = Config.CONTROL_ROOM_W / 2,
            level = 1
        })

        -- Initialize camera
        Camera.Init()

        -- Initialize cells
        shared.cells = {}
        for i = 1, Config.TOTAL_CELLS do
            shared.cells[i] = Cell.new(i)
        end

        shared.sidePanelOpen = false
        shared.selectedCell = 0
        shared.prevPhase = ""
        shared.lastDrawPhase = ""

        print("[ScorchridgeV2] Entered gameplay scene.")
    end,

    onExit = function(self, shared)
        SFX.StopBGM()
        shared.player = nil
        shared.cells = nil
    end,

    onUpdate = function(self, dt, totalTime, shared)
        shared.bobTimer = shared.bobTimer + dt
        UI.UpdateInput()

        -- Colony phase update
        local result = Colony.Update(dt, totalTime)
        if result == "gameover" then
            Scene.Switch("gameover")
            return
        end

        local state = GameData:TryGetFrom(modId, "colony.state")
        if not state then return end

        -- Phase transition effect
        if state.phase ~= shared.prevPhase then
            if shared.prevPhase ~= "" then
                shared.phaseTransText = Theme.PhaseName(state.phase)
                shared.phaseTransTimer = 1.2
            end
            shared.prevPhase = state.phase
            -- Close side panel on phase change
            shared.sidePanelOpen = false
        end
        if shared.phaseTransTimer > 0 then
            shared.phaseTransTimer = shared.phaseTransTimer - dt
        end

        -- Player update (only during player phases)
        local player = shared.player
        if player and Colony.IsPlayerPhase(state.phase) then
            player:update(dt)

            -- E to interact with nearest cell terminal
            if Input.IsKeyPressed("e") then
                local nearCell = player:getNearestCell()
                if nearCell > 0 then
                    state.selectedInmate = nearCell
                    shared.sidePanelOpen = true
                    shared.selectedCell = nearCell
                    GameData:SetTo(modId, "colony.state", state)
                    SFX.Click()
                end
            end

            -- Escape to close side panel
            if Input.IsKeyPressed("escape") then
                shared.sidePanelOpen = false
            end
        else
            -- During auto phases, camera still updates smoothly
            Camera.Update(dt)
        end

        -- Update inmate idle animations
        local inmates = GameData:TryGetFrom(modId, "colony.inmates")
        InmateClass.hydrateAll(inmates)
        if inmates then
            for i = 1, #inmates do
                inmates[i]:updateIdle(dt)
            end
        end
    end,

    onDraw = function(self, shared)
        if not UI.ResolvePixel() then return end

        local state = GameData:TryGetFrom(modId, "colony.state")
        if not state then return end

        shared.state      = state
        shared.W          = Screen.Width()
        shared.H          = Screen.Height()
        shared.resources  = GameData:TryGetFrom(modId, "colony.resources")
        shared.production = GameData:TryGetFrom(modId, "colony.production")
        shared.inmates    = GameData:TryGetFrom(modId, "colony.inmates")
        InmateClass.hydrateAll(shared.inmates)
    end
})

-- Add child scenes
GameplayRoot:addChild(require("scenes/gameplay/topbar"))
GameplayRoot:addChild(require("scenes/gameplay/world"))
GameplayRoot:addChild(require("scenes/gameplay/bottombar"))
GameplayRoot:addChild(require("scenes/gameplay/sidepanel"))
GameplayRoot:addChild(require("scenes/gameplay/transition"))
GameplayRoot:addChild(require("scenes/gameplay/overlays"))

GameplayRoot:registerAsScene("gameplay")

return GameplayRoot
