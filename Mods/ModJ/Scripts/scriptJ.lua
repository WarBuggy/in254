print("This is scriptJ.lua from ModJ.")
-- GameData:AllPathHistoriesFor("Core")
local somePath, somePathExists = GameData:TryGetFrom("Core", "somePath")
print("Core mod, path somePath exists: ")
print(somePathExists)
print(Mods.Ids())

-- player = RE('Core', 'player')
-- player:setModDataFor('Core', 'health', 80)
-- Hook into DrawLayers ready event
DrawLayers.Events.OnReady:Add(function()
    print("[ModJ] DrawLayers are ready!")

    DrawLayers.AddFirst("ModJ 1st layer");

    -- You can now safely query or manipulate DrawLayers
    local allLayers = DrawLayers.All()
    for i, name in ipairs(allLayers) do
        print(i, name)
    end
end)

