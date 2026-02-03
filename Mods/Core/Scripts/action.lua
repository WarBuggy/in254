local function createActionList(modId, defName, type)
    if type ~= "action" then
        return
    end

    local coreModId = "Core"
    local rootPath = "actions.list"
    
    -- Try to get the action table from Core
    local actionTable, exists = GameData.TryGetFrom(coreModId, rootPath)

    if not exists or actionTable == nil then
        actionTable = {}
        GameData.SetTo(coreModId, rootPath, actionTable)
    end

    actionTable[defName] = modId
end

Events.OnDefinitionCreated.Add(createActionList)