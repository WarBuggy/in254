local function onDrawLayerCreated(modId, defType, defName, _) -- _ because defPaths is not used here
    local targetDefType = "drawLayer"
    
    if defType ~= targetDefType then
        return
    end

    -- Get declared index from Definition
    local index, exists = Definition.TryGetPayload(targetDefType, defName, {"index"}, modId)
    if not exists or index == nil then
        error(Localize("drawLayer.lua.missingIndex", defName))
    end

    -- Get current layerIndexMap
    local layerIndexMap, mapExists = GameData.TryGet("drawLayers.layerIndexMap", "Core")
    if not mapExists or not layerIndexMap then
        error(Localize("drawLayer.lua.notInitialized"))
    end

    -- Remove old entry if redefining
    LedgerMap.TryRemove(layerIndexMap, defName)

    -- Collect all current entries with their declared index and modId
    local tempList = {}
    for pair in LedgerMap.Iterator(layerIndexMap) do
        if type(pair) == "table" then
            local name = pair.Key
            local info = pair.Value
            local declared, _ = Definition.TryGetPayload(targetDefType, name, {"index"}, info.modId)
            table.insert(tempList, { name = name, index = declared or 0, modId = info.modId })
        end
    end

    -- Add the new layer
    table.insert(tempList, { name = defName, index = index, modId = modId })

    -- Sort by declared index ascending
    table.sort(tempList, function(a, b) return a.index < b.index end)

    -- Rebuild LedgerMap: key = layerName, value = { position, modId }
    local newMap = LedgerMap.Create()
    for i, entry in ipairs(tempList) do
        LedgerMap.Set(newMap, entry.name, { position = i, modId = entry.modId })
    end

    -- Save back to GameData
    GameData.Set("drawLayers.layerIndexMap", newMap, "Core")
end

Events.OnDefinitionCreated.Add(onDrawLayerCreated)


-- DrawLayers read-only API
DrawLayers = DrawLayers or {}

function DrawLayers.PrintAllWithIndex()
    local layerIndexMap, exists = GameData.TryGetFrom("drawLayers.layerIndexMap", "Core")
    if not exists or not layerIndexMap then
        print("[DrawLayers] layerIndexMap not ready")
        return
    end

    -- Collect entries
    local entries = {}
    for pair in LedgerMap.Iterator(layerIndexMap) do
        if type(pair) == "table" then
            local layerName = pair.Key
            local info      = pair.Value
            local position  = info.position
            local declaredIndex, idxExists = Definition.TryGetPayload("drawLayer", layerName, {"index"}, info.modId)
            declaredIndex = idxExists and declaredIndex or "nil"
            table.insert(entries, {
                layerName = layerName,
                position  = position,
                declaredIndex = declaredIndex
            })
        end
    end

    -- Sort by position (draw order)
    table.sort(entries, function(a, b) return a.position < b.position end)

    -- Print nicely
    print("===== DrawLayers (sorted) =====")
    for i, entry in ipairs(entries) do
        print(string.format("%d. %s (declared index: %s)", i, entry.layerName, tostring(entry.declaredIndex)))
    end
    print("===============================")
end
