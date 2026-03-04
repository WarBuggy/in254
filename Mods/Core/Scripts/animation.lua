local FRAME_SCHEMA = {
    index = { type = "number" },
    file = { type = "string"},
    folder = { type = "string"},
    layer = { type = "string"},
    width = { type = "number"},
    height = { type = "number"},
    spriteOffsetX= { type = "number"},
    spriteOffsetY = { type = "number"},
    offsetX = { type = "number"},
    offsetY = { type = "number"},
    posX = { type = "number"},
    posY = { type = "number"},
    flipX = { type = "boolean"},
    flipY = { type = "boolean"},
    textureId = { type = "null"},
}

local targetDefType = "animation"

local function tryGetBaseComponent(animation, modId)
    return Definition.TryGetPayload(targetDefType, animation, {"baseComponent"}, modId)
end

local function tryGetComponentList(animation, modId)
    return Definition.TryGetPayload(targetDefType, animation, {"componentList"}, modId)
end

local function tryGetFrameProperty(animation, comp, state, frame, property, modId)
    return Definition.TryGetPayload(targetDefType, animation, 
        {"components", comp, "states", state, "frames", frame, property}, modId)
end

local function setFrameProperty(animation, comp, state, frame, property, value, modId)
    Definition.SetPayload(targetDefType, animation,
        {"components", comp, "states", state, "frames", frame, property}, 
        value, modId)
end

local function tryGetStateProperty(animation, comp, state, property, modId)
    return Definition.TryGetPayload(targetDefType, animation, 
        {"components", comp, "states", state, property}, modId)
end

local function setStateProperty(animation, comp, state, property, value, modId)
    Definition.SetPayload(targetDefType, animation,
        {"components", comp, "states", state, property}, 
        value, modId)
end

local function tryGetCompProperty(animation, comp, property, modId)
    return Definition.TryGetPayload(targetDefType, animation, 
        {"components", comp, property}, modId)
end

local function setCurrentState(animation, comp, currentState, modId)
    Definition.SetPayload(targetDefType, animation, 
        {"components", comp, "currentState"}, 
        currentState, modId)
end

local function collectAnimationData(modId, defName, defPaths)
    local components = {}

    local frameIndexPattern =
        "definition%.animation%." .. defName ..
        "%.payload%.components%.([^%.]+)%.states%.([^%.]+)%.frames%.([^%.]+)%.index$"

    for _, path in ipairs(defPaths) do
        local comp, state, frameKey = string.match(path, frameIndexPattern)

        if comp then
            local indexValue, exists = tryGetFrameProperty(defName, comp, state, frameKey, "index", modId)
            
            if exists then
                components[comp] = components[comp] or {}
                components[comp][state] = components[comp][state] or {}
                components[comp][state][frameKey] = indexValue
            end
        end
    end

    return components
end

local function validateFrameProperties(modId, defName, comp, state, frameKey)
    local errors = {}
    local collected = {} 

    for propName, rule in pairs(FRAME_SCHEMA) do

        local value, exists = tryGetFrameProperty(defName, comp, state, frameKey, propName, modId)

        if not exists then
            table.insert(errors, Localize("animation.lua.frameMissingRequiredProperty", modId, defName, comp, state, frameKey, propName))
        else
            local ruleType = rule.type
            if ruleType ~= "null" then
                local valueType = type(value)
                if valueType ~= ruleType then
                    table.insert(errors, Localize("animation.lua.framePropertyWithInvalidValue", modId, defName, comp, state, frameKey, propName, ruleType, valueType))
                else
                    collected[propName] = value
                end
            end
        end
    end

    if #errors > 0 then
        return false, errors, nil, nil, nil
    end

    return true, nil,
           collected.index,
           collected.file,
           collected.folder
end

function tryRegisterTexture(defName, comp, state, frameKey, folder, file, modId)
    local sourceModId, exists = tryGetFrameProperty(defName, comp, state, frameKey, "sourceMod", modId)
    if not exists or type(sourceModId) ~= "string" or sourceModId == "" then
        sourceModId = modId
    end

    local ok, texId = Texture.TryRegister(folder, file, sourceModId, modId)
    if ok and texId then
        setFrameProperty(defName, comp, state, frameKey, "textureId", texId, modId)
        return true
    else
        return false
    end
end

local function processFrame(modId, defName, comp, state, frameKey)
    local isValid, errors, index, file, folder = validateFrameProperties(modId, defName, comp, state, frameKey)

    if not isValid then
        for _, err in ipairs(errors) do
            print(err)
        end
        return false, nil
    end

    local registered = tryRegisterTexture(defName, comp, state, frameKey, folder, file, modId)
    if not registered then 
        return false, nil
    end

    return true, index
end

local function processState(modId, defName, comp, state, frames)
    local _, cfExists = tryGetStateProperty(defName, comp, state, "currentFrame", modId)
    if not cfExists then
        print(Localize("animation.lua.stateMissingProperty", modId, defName, comp, state, "currentFrame"))
        return false, 0
    end
    local _, flExists = tryGetStateProperty(defName, comp, state, "frameList", modId)
    if not flExists then
        print(Localize("animation.lua.stateMissingProperty", modId, defName, comp, state, "frameList"))
        return false, 0
    end
    
    local validFrames = {}
    for frameKey, _ in pairs(frames) do
        local ok, index = processFrame(modId, defName, comp, state, frameKey)
        if ok then
            validFrames[frameKey] = index
        end
    end

    if next(validFrames) == nil then
        print(Localize("animation.lua.stateNoValidFrames", modId, defName, comp, state))
        return false, 0
    end

    local orderedFrames = {}
    for frameKey, index in pairs(validFrames) do
        table.insert(orderedFrames, { key = frameKey, index = index })
    end
    table.sort(orderedFrames, function(a, b) return a.index < b.index end)

    local frameList = LedgerArray.Create()
    for i, f in ipairs(orderedFrames) do
        LedgerArray.InsertLast(frameList, f.key)
    end
    setStateProperty(defName, comp, state, "frameList", frameList, modId)
    
    local frameCount = LedgerArray.Count(frameList)
    setStateProperty(defName, comp, state, "currentFrame", frameCount, modId)
    
    return true, frameCount
end

local function processComponent(modId, defName, comp, states)
    local _, csExists = tryGetCompProperty(defName, comp, "currentState", modId)
    if not csExists then
        print(Localize("animation.lua.compMissingProperty", modId, defName, comp, "currentState"))
        return false, 0, 0
    end

    local defaultState, dsExists = tryGetCompProperty(defName, comp, "defaultState", modId)
    if not dsExists then
        print(Localize("animation.lua.compMissingProperty", modId, defName, comp, "defaultState"))
        return false, 0, 0
    end

    if type(defaultState) ~= "string" then
        print(Localize("animation.lua.compInvalidDefaultStateType", modId, defName, comp))
        return false, 0, 0
    end

    local totalFrameCount = 0
    local validStateCount = 0
    local validStates = {}
    for stateName, frameData in pairs(states) do
        local ok, frameCount = processState(modId, defName, comp, stateName, frameData)
        if ok then
            validStates[stateName] = true
            totalFrameCount = totalFrameCount + frameCount
            validStateCount = validStateCount + 1
        end
    end

    if next(validStates) == nil then
        print(Localize("animation.lua.compNoValidStates", modId, defName, comp))
        return false, 0, 0
    end

    if not validStates[defaultState] then
        print(Localize("animation.lua.compInvalidDefaultState", modId, defName, comp, defaultState))
        return false, 0, 0
    end

    setCurrentState(defName, comp, defaultState, modId)

    return true, validStateCount, totalFrameCount
end

local function processAnimation(modId, defName, components)
    local baseComp, baseExists = tryGetBaseComponent(defName, modId)
    if not baseExists or type(baseComp) ~= "string" or baseComp == "" then
        print(Localize("animation.lua.animationMissingBaseComponent", modId, defName))
        return false, 0, 0, 0
    end

    local _, listExist = tryGetComponentList(defName, modId)
    if not listExist then
        print(Localize("animation.lua.animationMissingComponentList", modId, defName))
        return false, 0, 0, 0
    end

    local validCompCount = 0
    local totalStateCount = 0
    local totalFrameCount = 0
    local validComponents = {}
    local componentLedger = LedgerArray.Create()

    for compName, states in pairs(components) do
        local ok, stateCount, frameCount = processComponent(modId, defName, compName, states)
        if ok then
            validComponents[compName] = true
            validCompCount = validCompCount + 1
            totalStateCount = totalStateCount + stateCount
            totalFrameCount = totalFrameCount + frameCount
            LedgerArray.InsertLast(componentLedger, compName)
        end
    end

    if next(validComponents) == nil then
        print(Localize("animation.lua.animationNoValidComponents", modId, defName))
        return false, 0, 0, 0
    end

    if not validComponents[baseComp] then
        print(Localize("animation.lua.animationInvalidBaseComponent", modId, defName,  baseComp))
        return false, 0, 0, 0
    end

    Definition.SetPayload(targetDefType, defName, {"componentList"}, componentLedger, modId)

    return true, validCompCount, totalStateCount, totalFrameCount
end

local function onAnimationCreated(modId, defType, defName, defPaths)
    if defType ~= targetDefType then
        return
    end
    
    local componentsData = collectAnimationData(modId, defName, defPaths)

    local ok, compCount, stateCount, frameCount = processAnimation(modId, defName, componentsData)

    if not ok then return end

    print(Localize("animation.lua.animationPassValidation", modId, defName, compCount, stateCount, frameCount))
end

Events.OnDefinitionCreated.Add(onAnimationCreated)

-- Animation API
Animation = Animation or {}

Animation.TryGetBaseComponent = tryGetBaseComponent
Animation.TryGetComponentList = tryGetComponentList
Animation.TryGetFrameProperty = tryGetFrameProperty
Animation.SetFrameProperty = setFrameProperty
Animation.TryGetStateProperty = tryGetStateProperty
Animation.SetStateProperty = setStateProperty
Animation.SetCurrentFrame = function(animation, comp, state, value, modId)
    setStateProperty(animation, comp, state, "currentFrame", value, modId)
end
Animation.TryGetCompProperty = tryGetCompProperty
Animation.SetCurrentState = setCurrentState

local function setCurrentFrameKey(animation, comp, state, frameKey, modId)
    local frameList, exists = tryGetStateProperty(animation, comp, state, "frameList", modId)
    if not exists or LedgerArray.Count(frameList) == 0 then
        return nil, false
    end

    local frameIndex = LedgerArray.IndexOf(frameList, frameKey)
    if  frameIndex == 0 then
        return nil, false
    end

    -- Set the currentFrame index
    setStateProperty(animation, comp, state, "currentFrame", frameIndex, modId)
    return frameIndex, true
end
Animation.SetCurrentFrameKey = setCurrentFrameKey

local function tryGetCurrentFrameInfo(animation, comp, state, modId)
    local currentFrame, exists = tryGetStateProperty(animation, comp, state, "currentFrame", modId)
    if not exists then 
        return nil, nil, false
    end

    local frameList, flExists = tryGetStateProperty(animation, comp, state, "frameList", modId)
    if not flExists or LedgerArray.Count(frameList) == 0 then
        return nil, nil, false
    end

    local frameKey, keyExists = LedgerArray.TryGet(frameList, currentFrame)
    if not keyExists then
        return nil, nil, false
    end

    return currentFrame, frameKey, true
end
Animation.TryGetCurrentFrameInfo = tryGetCurrentFrameInfo

