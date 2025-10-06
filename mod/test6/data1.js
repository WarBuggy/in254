export default {
    modData: [
        {
            dataType: "biome",
            name: "forest.spawnRules.data",
            payload: {
                description: "Overwrite last description",
            },
        },
        {
            dataType: "biome",
            name: "forest.spawnRules",
            payload: {
                tooltip: "Overwrite last tooltip",
            },
        },
        {
            dataType: "biome",
            name: "forest.spawnRules.wolf",
            payload: {
                data: {
                    color: ['black',],
                },
            },
        },
        {
            dataType: "biome",
            name: "forest.spawnRules.wolf",
            payload: {
                data: {
                    color: ['red',],
                },
            },
            addPayloadToArray: true,
        },
    ],
}