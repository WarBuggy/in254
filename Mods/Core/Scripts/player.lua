-- Local constant: seconds per frame
local FRAME_DURATION = 0.12

-- Store accumulated time for the player animation
local frameTimer = 0

local function updateAnimationPlayer(deltaTime, totalTime)

    local activeActionList, exists = GameData.TryGet("actions.activeList", "Core")
    if not exists or not activeActionList then return end

    local animationName = "player"
    local baseCompName, _ = Animation.TryGetBaseComponent(animationName)

    -- Determine new state
    local compBaseNewState, _ = Animation.TryGetCompProperty(animationName, baseCompName, "defaultState")
    local flipX = false
    if LedgerMap.TryGet(activeActionList, "moveLeft") then
        compBaseNewState = "moving"
        flipX = true
    elseif LedgerMap.TryGet(activeActionList, "moveRight") then
        compBaseNewState = "moving"
    end

    local compBasePrevState = Animation.TryGetCompProperty(animationName, baseCompName, "currentState")

    -- Handle state change
    if compBaseNewState ~= compBasePrevState then
        Animation.SetCurrentState(animationName, baseCompName, compBaseNewState)
        Animation.SetCurrentFrame(animationName, baseCompName, compBaseNewState, 1)
        frameTimer = 0  -- reset timer on state change
    else
        -- Advance frame based on timer
        frameTimer = frameTimer + deltaTime
        if frameTimer >= FRAME_DURATION then
            frameTimer = frameTimer - FRAME_DURATION
            AnimationUtils.GoToNextFrame(animationName, baseCompName, compBaseNewState)
        end
    end

    local frameIndex, frameKey, frameExists = Animation.TryGetCurrentFrameInfo(animationName, baseCompName, compBaseNewState)

    -- Update flipX
    Animation.SetFrameProperty(animationName, baseCompName, compBaseNewState, frameKey, "flipX", flipX)
    
    -- Center and position
    AnimationUtils.CenterFrameOnScreen(animationName, baseCompName, compBaseNewState, frameKey)
    AnimationUtils.PositionAnimationComponents(animationName)

    -- Update gowi ledger
    local gowiLedger, exists = GameData.TryGet("gowi.list", "Core")
    LedgerMap.Set(gowiLedger, animationName, "Core")
end

Events.OnUpdate.Add(updateAnimationPlayer)
