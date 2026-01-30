-- Initialize ordered LedgerArray for drawLayers
local function createDrawLayerOrderedList(modId, defName, type)
    if defName ~= "drawLayers" then
        return
    end

    -- Collect all layer paths under "list"
    local listPaths = Definition:PayloadPaths(defName, "list")
    local layers = {}

    for _, path in ipairs(listPaths) do
        local index, exists = Definition:TryGetPayload(defName, path)
        if exists and index ~= nil then
            local layerName = path:match("^list%.([^%.]+)%.index$")
            if layerName then
                layers[layerName] = index
            end
        end
    end

    -- Sort layers by their index value
    local sortable = {}
    for name, idx in pairs(layers) do
        table.insert(sortable, { name = name, index = idx })
    end
    table.sort(sortable, function(a, b) return a.index < b.index end)

    -- Build LedgerArray + reverse lookup map
    local ordered = LedgerArray.Create()
    local indexMap = {}

    for _, entry in ipairs(sortable) do
        -- Insert at the end, LedgerArray will record the insertion
        LedgerArray.InsertLast(ordered, entry.name)
        -- 1-based map for Lua
        indexMap[entry.name] = LedgerArray.Count(ordered)
    end

    -- Store into Definition payloads
    Definition:SetPayload(defName, "orderedList", ordered)
    Definition:SetPayload(defName, "layerIndexMap", indexMap)
    Definition:SetPayload(defName, "orderedListReady", true)

    -- Fire the ready event
    DrawLayers.Events.OnReady:Fire()
end

Events.OnDefinitionCreated.Add(createDrawLayerOrderedList)

-- Setup DrawLayers namespace
DrawLayers = DrawLayers or {}
DrawLayers.Events = DrawLayers.Events or {}
DrawLayers.Events.OnReady = DrawLayers.Events.OnReady or CreateEvent()

-- Ensure drawLayers is ready
local function ensureReady()
    local ready, exists = Definition:TryGetPayloadFrom("Core", "drawLayers", "orderedListReady")
    if not exists or not ready then
        print("[DrawLayers] Warning: DrawLayers not ready. Hook into DrawLayers.Events.OnReady.")
        return false
    end
    return true
end

-- Rebuild the index map from LedgerArray
local function rebuildIndexMap(ordered)
    local map = {}
    for i = 1, LedgerArray.Count(ordered) do
        local val = LedgerArray.TryGetAt(ordered, i)
        if val ~= nil then
            map[val] = i
        end
    end
    return map
end

-- Get ordered LedgerArray and its index map
local function getLayerData()
    if not ensureReady() then return nil, nil end
    local ordered, ok1 = Definition:TryGetPayloadFrom("Core", "drawLayers", "orderedList")
    local map, ok2 = Definition:TryGetPayloadFrom("Core", "drawLayers", "layerIndexMap")
    if not ok1 or not ok2 then return nil, nil end
    return ordered, map
end

-- Layer existence
function DrawLayers.Has(layerName)
    local _, map = getLayerData()
    return map and map[layerName] ~= nil
end

-- Get index of a layer (1-based)
function DrawLayers.GetIndex(layerName)
    local _, map = getLayerData()
    return map and map[layerName] or nil
end

-- Get layer name by index
function DrawLayers.GetName(index)
    local ordered, _ = getLayerData()
    if not ordered then return nil end
    return LedgerArray.TryGetAt(ordered, index)
end

-- Get full ordered list (read-only copy)
function DrawLayers.GetAll()
    local ordered, _ = getLayerData()
    if not ordered then return {} end
    local result = {}
    for i = 1, LedgerArray.Count(ordered) do
        result[i] = LedgerArray.TryGetAt(ordered, i)
    end
    return result
end

-- Add new layer at start
function DrawLayers.AddFirst(layerName)
    local ordered, _ = getLayerData()
    if not ordered then return end
    if LedgerArray.IndexOf(ordered, layerName) ~= 0 then
        print("[DrawLayers] Layer already exists:", layerName)
        return
    end
    LedgerArray.InsertFirst(ordered, layerName)
    Definition:SetPayloadTo("Core", "drawLayers", "layerIndexMap", rebuildIndexMap(ordered))
end

-- Add new layer at end
function DrawLayers.AddLast(layerName)
    local ordered, _ = getLayerData()
    if not ordered then return end
    if LedgerArray.IndexOf(ordered, layerName) ~= 0 then
        print("[DrawLayers] Layer already exists:", layerName)
        return
    end
    LedgerArray.InsertLast(ordered, layerName)
    Definition:SetPayloadTo("Core", "drawLayers", "layerIndexMap", rebuildIndexMap(ordered))
end

-- Add new layer before existing layer
function DrawLayers.AddBefore(targetLayer, newLayer)
    local ordered, _ = getLayerData()
    if not ordered then return end
    if LedgerArray.IndexOf(ordered, newLayer) ~= 0 then
        print("[DrawLayers] Layer already exists:", newLayer)
        return
    end
    local success = LedgerArray.TryInsertBeforeValue(ordered, targetLayer, newLayer) ~= nil
    if not success then
        print("[DrawLayers] Target layer not found:", targetLayer)
        return
    end
    Definition:SetPayloadTo("Core", "drawLayers", "layerIndexMap", rebuildIndexMap(ordered))
end

-- Add new layer after existing layer
function DrawLayers.AddAfter(targetLayer, newLayer)
    local ordered, _ = getLayerData()
    if not ordered then return end
    if LedgerArray.IndexOf(ordered, newLayer) ~= 0 then
        print("[DrawLayers] Layer already exists:", newLayer)
        return
    end
    local success = LedgerArray.TryInsertAfterValue(ordered, targetLayer, newLayer) ~= nil
    if not success then
        print("[DrawLayers] Target layer not found:", targetLayer)
        return
    end
    Definition:SetPayloadTo("Core", "drawLayers", "layerIndexMap", rebuildIndexMap(ordered))
end

-- Remove layer by name
function DrawLayers.Remove(layerName)
    local ordered, _ = getLayerData()
    if not ordered then return end
    local index = LedgerArray.IndexOf(ordered, layerName)
    if index == 0 then
        print("[DrawLayers] Layer not found:", layerName)
        return
    end
    LedgerArray.TryRemoveAt(ordered, index)
    Definition:SetPayloadTo("Core", "drawLayers", "layerIndexMap", rebuildIndexMap(ordered))
end
