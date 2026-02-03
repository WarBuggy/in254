local function updatePlayer(deltaTime, totalTime)
    local activeActionList, exists = GameData:TryGetFrom("Core", "actions.activeList")
end

Events.OnUpdate.Add(updatePlayer)
