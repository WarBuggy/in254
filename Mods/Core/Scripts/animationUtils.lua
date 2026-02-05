local function centerCurrentFrameOnScreen(animationName, componentName, stateName, frameIndex, modId)
    local owningModId = modId or Mods.Current()

    local frameWidth  = Animation.FrameWidthFrom(owningModId, animationName, componentName, stateName, frameIndex)
    local frameHeight = Animation.FrameHeightFrom(owningModId, animationName, componentName, stateName, frameIndex)
    if not frameWidth or not frameHeight then return end

    local screenWidth = Screen.Width()
    local screenHeight = Screen.Height()
    if not screenWidth or not screenHeight then return end

    -- Screen center
    local centerX = screenWidth * 0.5
    local centerY = screenHeight * 0.5

    -- Convert to top-left position, respecting frame size
    local posX = centerX - (frameWidth * 0.5)
    local posY = centerY - (frameHeight * 0.5)

    -- Apply per-frame position
    Animation.SetFramePosXTo(owningModId, animationName, componentName, stateName, frameIndex, posX)
    Animation.SetFramePosYTo(owningModId, animationName, componentName, stateName, frameIndex, posY)
end

-- Positions all non-base components relative to base component
local function positionAnimationComponents(animationName, modId)
    local owningModId = modId or Mods.Current()
    
    -- Get base component
    local baseCompName = Animation.BaseComponentFrom(owningModId, animationName)
    
    if type(baseCompName) ~= "string" or baseCompName == "" then
        print(Localize("animationUtils.lua.baseComponentMissing" , animationName)) -- give me localize key here
        return
    end

    -- Get base component's current state and frame
    local baseState = Animation.CurrentStateFrom(owningModId, animationName, baseCompName)
    local baseFrameIndex = Animation.CurrentFrameFrom(owningModId, animationName, baseCompName, baseState)
    local basePosX     = Animation.FramePosXFrom(owningModId, animationName, baseCompName, baseState, baseFrameIndex) or 0
    local basePosY     = Animation.FramePosYFrom(owningModId, animationName, baseCompName, baseState, baseFrameIndex) or 0
    local baseOffsetX  = Animation.FrameOffsetXFrom(owningModId, animationName, baseCompName, baseState, baseFrameIndex) or 0
    local baseOffsetY  = Animation.FrameOffsetYFrom(owningModId, animationName, baseCompName, baseState, baseFrameIndex) or 0

    -- Get all components
    local components = Animation.ComponentsFrom(owningModId, animationName)
    if not components then 
        print(Localize("animationUtils.lua.componentsMissing")) -- give me localize key here
        return
    end

    for compName in LedgerArray.Iterator(components) do
        if type(compName) == "string" and compName ~= "" and compName ~= baseCompName then
            local state = Animation.CurrentStateFrom(owningModId, animationName, compName)
            local frameIndex = Animation.CurrentFrameFrom(owningModId, animationName, compName, state)
            local frameOffsetX = Animation.FrameOffsetXFrom(owningModId, animationName, compName, state, frameIndex) or 0
            local frameOffsetY = Animation.FrameOffsetYFrom(owningModId, animationName, compName, state, frameIndex) or 0
            local posX = basePosX + frameOffsetX - baseOffsetX
            local posY = basePosY + frameOffsetY - baseOffsetY
            Animation.SetFramePosXTo(owningModId, animationName, compName, state, frameIndex, posX)
            Animation.SetFramePosYTo(owningModId, animationName, compName, state, frameIndex, posY)
        end
    end
end

-- Export functions globally
AnimationUtils = AnimationUtils or {}
AnimationUtils.CenterCurrentFrameOnScreen = centerCurrentFrameOnScreen
AnimationUtils.PositionAnimationComponents = positionAnimationComponents
