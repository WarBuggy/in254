export default {
    modData: [
        {
            dataType: "biome",
            name: "forest.spawnRules.wolf",
            payload: {
                type: "number",
                data: {
                    default: 7,      // new spawn rate
                    min: 1,
                    max: 15,
                    step: 1
                },
                description: "Updated spawn rate for wolves",
                tooltip: "Adjust this value to control wolf spawn frequency more aggressively",
            },
        },
        {
            dataType: "biome",
            name: "forest.spawnRules.fox",
            payload: {
                type: "array",
                data: ["kit", "adult"],
                description: "Initial fox spawn stages",
                tooltip: "Controls which fox stages spawn in the forest",
            },
        },
    ],
}