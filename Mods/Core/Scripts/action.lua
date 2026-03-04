local function createActionList(modId, defType, defName, _)
    
    if defType ~= "action" then
        return
    end
    
    local coreModId = "Core"
    local rootPath = "actions.list"
    -- Try to get the action LedgerMap from Core
    local ledger, exists = GameData.TryGet(rootPath, coreModId)
    -- Set the definition name with modId as value, actorId = Core
    LedgerMap.Set(ledger, defName, modId)
end

Events.OnDefinitionCreated.Add(createActionList)