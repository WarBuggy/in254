local function onDataInit()
    GameData:SetTo("Core", "actions.list", LedgerMap.Create());
    GameData:SetTo("Core", "drawLayers.layerIndexMap", {});
end


Events.OnDataInit.Add(onDataInit)