export default {
    modData: [
        {
            dataType: Shared.MOD_STRING.MOD_DATA_TYPE.INTERACTION_DATA,
            name: 'elevator',
            payload: {
                componentList: [
                    {
                        name: 'base',
                        interaction: ['w', 's',],
                    },
                ],
            },
        },
        {
            dataType: Shared.MOD_STRING.MOD_DATA_TYPE.INTERACTION_DATA,
            name: 'cell',
            payload: {
                componentList: [
                    {
                        name: 'controlPanel',
                        interaction: ['e',],
                    },
                ],
            },
        },
    ],
}