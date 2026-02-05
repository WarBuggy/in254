-- Builds a final ordered draw queue for all gowi, ignoring frames with unknown layers
local function processGowiFrames()
    -- Get gowi ledger
    local gowiLedger, exists = GameData:TryGet("Core", "gowi.list")
    if not exists or not gowiLedger then
        return
    end

    -- Get ordered layers
    local orderedLayers, layerIndexMap = DrawLayers.All(), nil
    if not orderedLayers then
        print(Localize("drawQueue.lua.drawLayersNotReady"))
        return
    end
    _, layerIndexMap = GameData:TryGetFrom("Core", "drawLayers.layerIndexMap")
    if not layerIndexMap then
        print(Localize("drawQueue.lua.drawLayersNotReady"))
        return
    end

    -- Iterate over all gowi
    for animationName, modId in LedgerMap.Iterator(gowiLedger) do
        if type(animationName) == "string" and type(modId) == "string" then
            local components = Animation.ComponentsFrom(modId, animationName)
            if components then
                for compName in LedgerArray.Iterator(components) do
                    if type(compName) == "string" and compName ~= "" then
                        local state = Animation.CurrentStateFrom(modId, animationName, compName)
                        local frameIndex = Animation.CurrentFrameFrom(modId, animationName, compName, state)
                        local frame = Animation.FrameFrom(modId, animationName, compName, state, frameIndex)
                        if type(frame) == "table" then
                            local layerName = Animation.FrameLayerFrom(modId, animationName, compName, state, frameIndex)
                            local layerOrder = layerName and layerIndexMap[layerName]
                            if not layerOrder then
                                print(Localize("drawQueue.lua.frameLayerMissing", layerName))
                            else
                                Drawing.AddRequest(
                                    frame.TextureId,
                                    {frame.PosX, frame.PosY},
                                    0,            -- rotation
                                    {1, 1},       -- scale
                                    nil,          -- color
                                    layerOrder,   -- layerDepth
                                    frame.Width,
                                    frame.Height,
                                    frame.SpriteOffsetX,
                                    frame.SpriteOffsetY
                                )
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.OnDraw.Add(processGowiFrames)
