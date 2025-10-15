export default {
    modData: [
        {
            dataType: Shared.MOD_STRING.MOD_DATA_TYPE.DRAW_LAYER_DATA,
            name: 'layer',
            payload: {
                defaultLayer: 'wall',
                list: {
                    'wall': { index: 0, },
                    'nearWall': { index: 1, },
                    'bunkerMiddle': { index: 2, },
                    'nearOutside': { index: 3, },
                    'outside': { index: 4, },
                    'middleOutside': { index: 5, },
                    'foreground': { index: 6, },
                },
            }
        },
    ],
}