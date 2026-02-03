-- Called every time an animation is created
local function addAnimationToList(owningModId, animationName)
    local coreModId = "Core"
    local rootPath = "animations.list"

    -- Try to get the global animations table from Core
    local animationsTable, exists = GameData.TryGetFrom(coreModId, rootPath)

    if not exists or animationsTable == nil then
        -- Create the global table if it does not exist
        animationsTable = {}
        GameData.SetTo(coreModId, rootPath, animationsTable)
    end

    -- Get or create the ledger for this mod
    local ledger = animationsTable[owningModId]
    if ledger == nil then
        ledger = LedgerArray.Create()
        animationsTable[owningModId] = ledger
    end

    -- Add the animation to the ledger
    LedgerArray.InsertLast(ledger, animationName)
end

-- Hook into animation creation event
Events.OnAnimationCreated.Add(addAnimationToList)
