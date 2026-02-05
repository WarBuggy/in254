-- Builds a final ordered draw queue for all gowi, ignoring frames with unknown layers
local function processGowi()
    -- Get gowi ledger
    local gowiLedger, exists = GameData:TryGetFrom("Core", "gowi.list")
    if not exists or not gowiLedger then
        print("[DrawQueue] No gowi ledger found")
        return
    end

    layerIndexMap, layerIndexMapExists  = GameData:TryGetFrom("Core", "drawLayers.layerIndexMap")
    if not layerIndexMapExists then
        print(Localize("drawQueue.lua.drawLayersNotReady"))
        return
    end

    -- print("[DrawQueue] Found " .. LedgerMap.Count(gowiLedger) .. " gowi")

    -- Iterate over all gowi
    for pair in LedgerMap.Iterator(gowiLedger) do
        if type(pair) == "table" then
            local animationName = pair.Key
            local modId = pair.Value
            -- print("[DrawQueue] Processing GOwI: animation=" .. tostring(animationName) .. ", mod=" .. tostring(modId))
            if type(animationName) == "string" and type(modId) == "string" then
                local components = Animation.ComponentsFrom(modId, animationName)

                -- if not components then
                --     print("[DrawQueue] No components found for animation: " .. animationName)
                -- else
                --     print("[DrawQueue] Found " .. LedgerArray.Count(components) .. " components")
                -- end

                for compName in LedgerArray.Iterator(components) do
                    -- print("  Component: " .. tostring(compName))
                    if type(compName) == "string" and compName ~= "" then
                        local state = Animation.CurrentStateFrom(modId, animationName, compName)
                        -- print("    State: " .. tostring(state))
                        local frameIndex = Animation.CurrentFrameFrom(modId, animationName, compName, state)
                        -- print("    FrameIndex: " .. tostring(frameIndex))

                        local textureId     = Animation.FrameTextureIdFrom(modId, animationName, compName, state, frameIndex)
                        local posX          = Animation.FramePosXFrom(modId, animationName, compName, state, frameIndex) or 0
                        local posY          = Animation.FramePosYFrom(modId, animationName, compName, state, frameIndex) or 0
                        local width         = Animation.FrameWidthFrom(modId, animationName, compName, state, frameIndex) or 0
                        local height        = Animation.FrameHeightFrom(modId, animationName, compName, state, frameIndex) or 0
                        local spriteOffsetX = Animation.FrameOffsetXFrom(modId, animationName, compName, state, frameIndex) or 0
                        local spriteOffsetY = Animation.FrameOffsetYFrom(modId, animationName, compName, state, frameIndex) or 0
                        local flipX         = Animation.FlipXFrom(modId, animationName, compName) or false  
                        local flipY         = Animation.FlipYFrom(modId, animationName, compName) or false  

                        -- print(string.format("Frame found: TextureId=%s PosX=%s PosY=%s", tostring(textureId), tostring(posX), tostring(posY)))
                        local layerName = Animation.FrameLayerFrom(modId, animationName, compName, state, frameIndex)
                        local layerOrder = layerName and layerIndexMap[layerName]
                        if not layerOrder then
                            print(Localize("drawQueue.lua.frameLayerMissing", layerName))
                        else
                            -- print("    Adding frame to draw queue, layer: " .. layerName .. " (" .. layerOrder .. ")")
                            Drawing.AddRequest(
                                textureId,
                                {posX, posY},
                                0,            -- rotation
                                {1, 1},       -- scale
                                nil,          -- color
                                0,            -- layerDepth
                                width, height,
                                spriteOffsetX, spriteOffsetY,
                                flipX, flipY
                            )
                        end
                    end
                end
            end
        end
    end
end

Events.OnDraw.Add(processGowi)
