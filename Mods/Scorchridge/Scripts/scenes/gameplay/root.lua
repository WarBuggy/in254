-- ============================================
-- Scorchridge — Gameplay Root Node
-- ============================================

local Theme = require("core/theme")
local SFX = require("core/sound")
local UI = require("core/ui")

local Character = require("entities/character")
local InmateClass = require("entities/inmate")
local Colony = require("systems/colony")

local modId = "Scorchridge"

local GameplayRoot = Node.new({
    name   = "gameplay_root",
    shared = Theme.NewGameplayShared(),

    onEnter = function(self, shared)
        SFX.LoadGameplaySounds()

        local inmates = GameData:TryGetFrom(modId, "colony.inmates")
        InmateClass.hydrateAll(inmates)
        shared.characters = {}
        if inmates then
            for i = 1, #inmates do
                local idx = i
                local char = Character.new({
                    data = inmates[i],
                    w = 16, h = 24, scale = 2,
                    tag = inmates[i].name
                })
                char:on("onClick", function(self)
                    local state = GameData:TryGetFrom(modId, "colony.state")
                    state.selectedInmate = idx
                    GameData:SetTo(modId, "colony.state", state)
                end)
                char:on("onHover", function(self)
                    local im = self.data
                    if im then
                        UI.Tooltip(im.name .. " | STA:" .. math.floor(im.stamina) .. "/" .. im.maxStamina ..
                            " MOR:" .. math.floor(im.morale) .. "/" .. im.maxMorale ..
                            " CRD:" .. im.credits ..
                            (im.exhausted and " [EXHAUSTED]" or "") ..
                            (im.addicted and " [ADDICTED]" or ""))
                    end
                end)
                shared.characters[idx] = char
            end
        end

        shared.prevPhase = ""
        shared.lastDrawPhase = ""
        print("[Scorchridge] Entered gameplay scene.")
    end,

    onExit = function(self, shared)
        SFX.StopBGM()
        shared.characters = {}
    end,

    onUpdate = function(self, dt, totalTime, shared)
        shared.bobTimer = shared.bobTimer + dt
        UI.UpdateInput()

        local result = Colony.Update(dt, totalTime)
        if result == "gameover" then
            Scene.Switch("gameover")
            return
        end

        local state = GameData:TryGetFrom(modId, "colony.state")
        if state and state.phase ~= shared.prevPhase then
            if shared.prevPhase ~= "" then
                shared.phaseTransText = Theme.PhaseName(state.phase)
                shared.phaseTransTimer = 1.2
            end
            shared.prevPhase = state.phase
        end
        if shared.phaseTransTimer > 0 then
            shared.phaseTransTimer = shared.phaseTransTimer - dt
        end

        local inmates = GameData:TryGetFrom(modId, "colony.inmates")
        InmateClass.hydrateAll(inmates)
        if inmates then
            for i = 1, #inmates do
                inmates[i]:updateWander(dt)
                if shared.characters[i] then
                    shared.characters[i].data = inmates[i]
                    local ws = inmates[i]:wander()
                    shared.characters[i]:setPosition(ws.x, ws.y)
                    shared.characters[i]:update(dt)
                end
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
