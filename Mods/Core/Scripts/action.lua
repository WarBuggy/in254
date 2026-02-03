local function createActionList(modId, defName, type)
    if type ~= "action" then
        return
    end

    local coreModId = "Core"
    local rootPath = "actions.list"
    
    -- Try to get the action LedgerMap from Core
    local ledger, exists = GameData:TryGetFrom(coreModId, rootPath)

    if not exists or ledger == nil then
        -- Create a new LedgerMap if it doesn't exist
        ledger = LedgerMap.Create()
        GameData.SetTo(coreModId, rootPath, ledger)
    end

    -- Set the definition name with modId as value, actorId = Core
    LedgerMap.Set(ledger, defName, modId)
end

Events.OnDefinitionCreated.Add(createActionList)