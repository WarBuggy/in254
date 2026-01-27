print("This is scriptJ.lua from ModJ.")
Mods.SetRuntimeFor("ModI", "rooms", {})
local rooms = Mods.RuntimeFrom("ModI", "rooms")
local exists = Mods.HasRuntimeFrom("ModI", "rooms")
Mods.RemoveRuntimeFrom("ModI", "rooms")
Mods.ClearRuntimeFor("ModI")
-- GameData:AllPathHistoriesFor("Core")
local somePath, somePathExists = GameData:TryGetFrom("Core", "somePath")
print("Core mod, path somePath exists: ")
print(somePathExists)


-- player = RE('Core', 'player')
-- player:setModDataFor('Core', 'health', 80)
-- print("End of scriptJ.lua from ModJ. Nothing should be printed between these 2 messages.")

Events.OnDefinitionCreated.Add(function(modId, defName, defType)
    print("Definition created:")
    print("  Mod:", modId)
    print("  Name:", defName)
    print("  Type:", defType)

    -- Try reading some data
    local health = Definition:TryGet(defName, "health")
    local maxHealth = Definition:TryGet(defName, "maxHealth")

    print("  Health:", health)
    print("  MaxHealth:", maxHealth)
end)