print("This is scriptJ.lua from ModJ.")
-- GameData:AllPathHistoriesFor("Core")
local somePath, somePathExists = GameData:TryGetFrom("Core", "somePath")
print("Core mod, path somePath exists: ")
print(somePathExists)
print(Mods.Ids())

-- player = RE('Core', 'player')
-- player:setModDataFor('Core', 'health', 80)
-- print("End of scriptJ.lua from ModJ. Nothing should be printed between these 2 messages.")

Events.OnDefinitionCreated.Add(function(modId, defName, defType)
    print("Definition created:")
    print("  Mod:", modId)
    print("  Name:", defName)
    print("  Type:", defType)

    -- Try reading some data
    local typeName, exist = Definition:TryGetType(defName);
    local health = Definition:TryGetPayload(defName, "health")
    local maxHealth = Definition:TryGetPayload(defName, "maxHealth")
    if exist then
        print("  Type:", typeName)
    end
    print("  Health:", health)
    print("  MaxHealth:", maxHealth)

    if (defName ~= "drawLayers") then
        if DrawLayers.Has("foreground") then
            print("Foreground index:", DrawLayers.GetIndex("foreground"))
        end

        print("Layer 3 is:", DrawLayers.GetName(3))
    end
end)

-- Hook into DrawLayers ready event
DrawLayers.Events.OnReady:Add(function()
    print("[ModJ] DrawLayers are ready!")

    DrawLayers.AddFirst("ModJ 1st layer");

    -- You can now safely query or manipulate DrawLayers
    local allLayers = DrawLayers.GetAll()
    for i, name in ipairs(allLayers) do
        print(i, name)
    end
end)

