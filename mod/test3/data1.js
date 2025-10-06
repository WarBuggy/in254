export default {
    modData: [
        {
            dataType: "biome",
            name: "forest.spawnRules.wolf",
            payload: {
                type: "number",
                data: {
                    default: 5,
                    min: 0,
                    max: 10,
                    step: 1,
                    color: ['white', 'gray'],
                },
                description: "Spawn rate for wolves in the forest biome",
                tooltip: "Adjust this value to control wolf spawn frequency",
            },
        },
    ],
}