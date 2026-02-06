-- Collect frames for a single animation
local function collectFramesForAnimation(modId, animationName, layerIndexMap)
    local frames = {}
    local components = Animation.ComponentsFrom(modId, animationName)
    if not components then return frames end

    for compName in LedgerArray.Iterator(components) do
        if type(compName) == "string" and compName ~= "" then
            local state = Animation.CurrentStateFrom(modId, animationName, compName)
            local frameIndex = Animation.CurrentFrameFrom(modId, animationName, compName, state)

            local textureId     = Animation.FrameTextureIdFrom(modId, animationName, compName, state, frameIndex)
            local posX          = Animation.FramePosXFrom(modId, animationName, compName, state, frameIndex) or 0
            local posY          = Animation.FramePosYFrom(modId, animationName, compName, state, frameIndex) or 0
            local width         = Animation.FrameWidthFrom(modId, animationName, compName, state, frameIndex) or 0
            local height        = Animation.FrameHeightFrom(modId, animationName, compName, state, frameIndex) or 0
            local offsetX       = Animation.FrameOffsetXFrom(modId, animationName, compName, state, frameIndex) or 0
            local offsetY       = Animation.FrameOffsetYFrom(modId, animationName, compName, state, frameIndex) or 0
            local flipX         = Animation.FlipXFrom(modId, animationName, compName) or false
            local flipY         = Animation.FlipYFrom(modId, animationName, compName) or false

            local layerName     = Animation.FrameLayerFrom(modId, animationName, compName, state, frameIndex)
            local layerInfo  = layerName and layerIndexMap[layerName]
            local layerOrder = layerInfo and layerInfo.position

            if layerOrder then
                table.insert(frames, {
                    layerOrder = layerOrder,
                    textureId  = textureId,
                    posX       = posX,
                    posY       = posY,
                    width      = width,
                    height     = height,
                    offsetX    = offsetX,
                    offsetY    = offsetY,
                    flipX      = flipX,
                    flipY      = flipY
                })
            else
                print(Localize("drawQueue.lua.frameLayerMissing", layerName))
            end
        end
    end

    return frames
end

-- Collect all frames from all GOWI
local function collectAllFrames()
    local drawQueue = {}

    local gowiLedger, exists = GameData:TryGetFrom("Core", "gowi.list")
    if not exists or not gowiLedger then
        print(Localize("drawQueue.lua.noGowiLedgerFound"))
        return drawQueue
    end

    local layerIndexMap, layerIndexMapExists = GameData:TryGetFrom("Core", "drawLayers.layerIndexMap")
    if not layerIndexMapExists then
        print(Localize("drawQueue.lua.drawLayersNotReady"))
        return drawQueue
    end

    for pair in LedgerMap.Iterator(gowiLedger) do
        if type(pair) == "table" then
            local animationName = pair.Key
            local modId = pair.Value
            if type(animationName) == "string" and type(modId) == "string" then
                local frames = collectFramesForAnimation(modId, animationName, layerIndexMap)
                for _, frame in ipairs(frames) do
                    table.insert(drawQueue, frame)
                end
            end
        end
    end

    return drawQueue
end

-- Sort draw queue by layerOrder
local function sortDrawQueue(drawQueue)
    table.sort(drawQueue, function(a, b)
        return a.layerOrder < b.layerOrder
    end)
end

-- Submit frames to Drawing
local function submitDrawQueue(drawQueue)
    for _, frame in ipairs(drawQueue) do
        Drawing.AddRequest(
            frame.textureId,
            {frame.posX, frame.posY},
            0,             -- rotation
            {1, 1},        -- scale
            nil,           -- color
            0,             -- layerDepth
            frame.width, frame.height,
            frame.offsetX, frame.offsetY,
            frame.flipX, frame.flipY
        )
    end
end

-- Main draw queue processing
local function processGowi()
    local drawQueue = collectAllFrames()
    if #drawQueue == 0 then return end

    sortDrawQueue(drawQueue)
    submitDrawQueue(drawQueue)
end

Events.OnDraw.Add(processGowi)
