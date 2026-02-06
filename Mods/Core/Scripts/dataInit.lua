local function onDataInit()
    GameData:SetTo("Core", "actions.list", LedgerMap.Create());
    GameData:SetTo("Core", "drawLayers.layerIndexMap", LedgerMap.Create());
end


Events.OnDataInit.Add(onDataInit)