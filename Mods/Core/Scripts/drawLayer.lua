local function onDrawLayerCreated(modId, defName, defType)
    if defType ~= "drawLayer" then
        return
    end

    -- Get declared index from Definition
    local index, exists = Definition:TryGetPayloadFrom(modId, defName, "index")
    if not exists or index == nil then
        error(Localize("drawLayer.lua.missingIndex", defName))
    end

    -- Get current layerIndexMap
    local layerIndexMap, mapExists = GameData:TryGetFrom("Core", "drawLayers.layerIndexMap")
    if not mapExists or not layerIndexMap then
        error(LocalizeWithEnding("", "drawLayer.lua.notInitialized"))
    end

    -- insert or redefine
    layerIndexMap[defName] = {
        position      = 0,       -- will compute below
        modId         = modId,
        declaredIndex = index
    }

    -- collect all layers, sort by declaredIndex, assign position
    local tempList = {}
    for name, info in pairs(layerIndexMap) do
        table.insert(tempList, { name = name, index = info.declaredIndex, modId = info.modId })
    end
    table.sort(tempList, function(a, b) return a.index < b.index end)

    for pos, entry in ipairs(tempList) do
        layerIndexMap[entry.name].position = pos
    end

    -- save back
    GameData:SetTo("Core", "drawLayers.layerIndexMap", layerIndexMap)
end

Events.OnDefinitionCreated.Add(onDrawLayerCreated)


-- DrawLayers read-only API
DrawLayers = DrawLayers or {}

function DrawLayers.PrintAllWithIndex()
    local layerIndexMap = GameData:TryGetFrom("Core", "drawLayers.layerIndexMap") or {}

    local entries = {}
    for layerName, info in pairs(layerIndexMap) do
        table.insert(entries, {
            layerName     = layerName,
            position      = info.position,
            declaredIndex = info.declaredIndex
        })
    end

    table.sort(entries, function(a, b) return a.position < b.position end)

    print("===== DrawLayers (sorted) =====")
    for i, entry in ipairs(entries) do
        print(string.format("%d. %s (declared index: %s)", i, entry.layerName, tostring(entry.declaredIndex)))
    end
    print("===============================")
end
