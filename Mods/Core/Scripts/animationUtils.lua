local function centerFrameOnScreen(animationName, componentName, stateName, frameName, modId)
    local owningModId = modId or Mods.CurrentId()

    local frameWidth, widthExists  = Animation.TryGetFrameProperty(animationName, componentName, stateName, frameName, "width", owningModId)
    local frameHeight, heightExists = Animation.TryGetFrameProperty(animationName, componentName, stateName, frameName, "height", owningModId)
    if not widthExists or not heightExists then return end

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
    Animation.SetFrameProperty(animationName, componentName, stateName, frameName, "posX", posX, owningModId)
    Animation.SetFrameProperty(animationName, componentName, stateName, frameName, "posY", posY, owningModId)
end

-- Positions all non-base components relative to base component
local function positionAnimationComponents(animationName, modId)
    local owningModId = modId or Mods.CurrentId()
    
    -- Get base component
    local baseCompName, baseComponentExists = Animation.TryGetBaseComponent(animationName, owningModId)
    
    if not baseComponentExists or type(baseCompName) ~= "string" or baseCompName == "" then
        print(Localize("animationUtils.lua.baseComponentMissing" , animationName)) -- give me localize key here
        return
    end

    -- Get base component's current state and frame
    local baseState = Animation.TryGetCompProperty(animationName, baseCompName, "currentState", owningModId)
    local baseFrameIndex, baseFrameKey, _ = Animation.TryGetCurrentFrameInfo(animationName, baseCompName, baseState, owningModId)
    local basePosX, _     = Animation.TryGetFrameProperty(animationName, baseCompName, baseState, baseFrameKey, "posX", owningModId) or 0
    local basePosY, _     = Animation.TryGetFrameProperty(animationName, baseCompName, baseState, baseFrameKey, "posY", owningModId) or 0
    local baseOffsetX, _  = Animation.TryGetFrameProperty(animationName, baseCompName, baseState, baseFrameKey, "offsetX", owningModId) or 0
    local baseOffsetY, _  = Animation.TryGetFrameProperty(animationName, baseCompName, baseState, baseFrameKey, "offsetY", owningModId) or 0

    -- Get all components
    local components, componentsExist = Animation.TryGetComponentList(animationName, owningModId)
    if not componentsExist or not components then 
        print(Localize("animationUtils.lua.componentsMissing")) -- give me localize key here
        return
    end

    for compName in LedgerArray.Iterator(components) do
        if type(compName) == "string" and compName ~= "" and compName ~= baseCompName then
            local state, _ = Animation.TryGetCompProperty(animationName, compName, "currentState", owningModId)
            local frameIndex, frameKey, _ = Animation.TryGetCurrentFrameInfo(animationName, compName, state, owningModId)
            local frameOffsetX, _ = Animation.TryGetFrameProperty(animationName, compName, state, frameKey, "offsetX", owningModId) or 0
            local frameOffsetY, _ = Animation.TryGetFrameProperty(animationName, compName, state, frameKey, "offsetY", owningModId) or 0
            local posX = basePosX + frameOffsetX - baseOffsetX
            local posY = basePosY + frameOffsetY - baseOffsetY
            Animation.SetFrameProperty(animationName, compName, state, frameKey, "posX", posX, owningModId)
            Animation.SetFrameProperty(animationName, compName, state, frameKey, "posY", posY, owningModId)
        end
    end
end

local function goToNextFrame(animation, comp, state, modId)
    local owningModId = modId or Mods.CurrentId()

    local currentFrame, exists = Animation.TryGetStateProperty(animation, comp, state, "currentFrame", owningModId)
    if not exists then 
        return nil, nil, false 
    end

    local frameList, flExists = Animation.TryGetStateProperty(animation, comp, state, "frameList", owningModId)
    if not flExists or LedgerArray.Count(frameList) == 0 then
        return nil, nil, false
    end

    local frameCount = LedgerArray.Count(frameList)
    local nextFrame = currentFrame + 1
    if nextFrame > frameCount then
        nextFrame = 1
    end

    Animation.SetStateProperty(animation, comp, state, "currentFrame", nextFrame, owningModId)

    local nextFrameKey, nextFrameKeyExists = LedgerArray.TryGet(frameList, nextFrame)
   if not nextFrameKeyExists then
        return nil, nil, false
    end

    return nextFrame, nextFrameKey, true
end

AnimationUtils = AnimationUtils or {}
AnimationUtils.CenterFrameOnScreen = centerFrameOnScreen
AnimationUtils.PositionAnimationComponents = positionAnimationComponents
AnimationUtils.GoToNextFrame = goToNextFrame
