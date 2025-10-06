export default {
    modData: [
        {
            dataType: "biome",
            name: "forest.spawnRules.fox",
            payload: {
                type: "array",
                data: ["elder"],
            },
            addPayloadToArray: true,
        },
        {
            dataType: "biome",
            name: "forest.spawnRules",
            payload: {
                type: "object",
                data: {
                    description: "Updated spawn rules container for forest biome",
                },
            },
        },
    ],
}