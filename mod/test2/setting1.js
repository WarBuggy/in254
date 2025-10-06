export default {
    modData: [
        {
            dataType: "setting",
            name: "testSetting1",
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
    ],
}