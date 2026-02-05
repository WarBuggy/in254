-- Local constant: seconds per frame
local FRAME_DURATION = 0.12

-- Store accumulated time for the player animation
local frameTimer = 0

local function updateAnimationPlayer(deltaTime, totalTime)
    local activeActionList, exists = GameData:TryGetFrom("Core", "actions.activeList")
    if not exists or not activeActionList then return end

    local animationName = "player"
    local baseCompName = "base"

    -- Determine new state
    local compBaseNewState = "idle"
    local flipX = Animation.FlipX(animationName, baseCompName) or false
    if LedgerMap.TryGet(activeActionList, "moveLeft") then
        compBaseNewState = "moving"
        flipX = true
    elseif LedgerMap.TryGet(activeActionList, "moveRight") then
        compBaseNewState = "moving"
        flipX = false
    end

    local compBasePrevState = Animation.CurrentState(animationName, baseCompName)

    -- Handle state change
    if compBaseNewState ~= compBasePrevState then
        Animation.SetCurrentState(animationName, baseCompName, compBaseNewState)
        Animation.SetCurrentFrame(animationName, baseCompName, compBaseNewState, 1)
        frameTimer = 0  -- reset timer on state change
    else
        -- Advance frame based on timer
        frameTimer = frameTimer + deltaTime
        local frameCount = Animation.FrameCount(animationName, baseCompName, compBaseNewState)
        if frameCount > 0 and frameTimer >= FRAME_DURATION then
            local currentFrame = Animation.CurrentFrame(animationName, baseCompName, compBaseNewState)
            local nextFrame = currentFrame % frameCount + 1
            Animation.SetCurrentFrame(animationName, baseCompName, compBaseNewState, nextFrame)
            frameTimer = frameTimer - FRAME_DURATION  -- subtract frame duration, keep leftover time
        end
    end

    -- Update flipX
    Animation.SetFlipX(animationName, baseCompName, flipX)

    -- Center and position
    local currentFrame = Animation.CurrentFrame(animationName, baseCompName, compBaseNewState)
    AnimationUtils.CenterCurrentFrameOnScreen(animationName, baseCompName, compBaseNewState, currentFrame)
    AnimationUtils.PositionAnimationComponents(animationName)

    -- Update gowi ledger
    local gowiLedger, exists = GameData:TryGetFrom("Core", "gowi.list")
    LedgerMap.Set(gowiLedger, animationName, "Core")
end

Events.OnUpdate.Add(updateAnimationPlayer)
