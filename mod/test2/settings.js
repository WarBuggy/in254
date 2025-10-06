export default {
    modData: [
        {
            dataType: "setting",
            name: "testSetting",
            payload: {
                type: "number",
                data: {
                    default: 5,   // default value
                    min: 0,       // minimum value
                    max: 10,      // maximum value
                    step: 1       // step increment for UI
                },
                description: "A test numeric setting for demonstration purposes.",
                tooltip: "Adjust this value to test the numeric setting functionality.",
            },
        },
        {
            dataType: "setting",
            name: "enableFeatureX",
            payload: {
                type: "boolean",
                data: {
                    default: true
                },
                description: "Enable or disable feature X.",
                tooltip: "Toggle feature X on or off.",
            },
        },
        {
            dataType: "setting",
            // test bad data (no name and payload property)
            key: "username",
            type: "string",
            data: {
                default: "Player"
            },
            description: "The name of the player.",
            tooltip: "Enter a custom player name."
        },
    ],
}