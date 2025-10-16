export default {
    modData: [
        {
            dataType: Shared.MOD_STRING.MOD_DATA_TYPE.ANIMATION_DATA,
            name: 'elevator',
            payload: {
                baseComponent: 'base',
                componentList: [
                    {
                        name: 'base',
                        folder: 'asset/elevator/',
                        layer: 'outside',
                        default: 'idle',
                        animationList: {
                            idle: { frameList: ['idle.svg'], },
                            ready: { frameList: ['ready.svg'], },
                            up: { frameList: ['up.svg'], },
                            down: { frameList: ['down.svg'], offsetX: 0, offsetY: 0, },
                        },
                        width: 256, // duplicated in colonyData
                        height: 32,
                    },
                    {
                        name: 'railGuard',
                        folder: 'asset/elevator/',
                        layer: 'foreground',
                        offsetX: 0,
                        offsetY: -90,
                        default: 'ready',
                        animationList: {
                            ready: { frameList: ['guard.svg'], offsetX: 0, offsetY: -90, },
                        },
                        width: 256,
                        height: 90,
                        layer: 'foreground',
                    },
                ],
            },
        },
        {
            dataType: Shared.MOD_STRING.MOD_DATA_TYPE.ANIMATION_DATA,
            name: 'player',
            payload: {
                baseComponent: 'base',
                componentList: [
                    {
                        name: 'base',
                        folder: 'asset/in254/',
                        layer: 'middleOutside',
                        default: 'idle',
                        animationList: {
                            idle: { frameList: ['idle.svg'], },
                            move: { frameList: ['move_01.svg', 'move_02.svg', 'move_03.svg', 'move_04.svg', 'move_05.svg', 'move_06.svg', 'move_07.svg',], },
                        },
                        width: 256,
                        height: 256,
                    },
                ],
            },
        },
        {
            dataType: Shared.MOD_STRING.MOD_DATA_TYPE.ANIMATION_DATA,
            name: 'cell',
            payload: {
                baseComponent: 'base',
                componentList: [
                    {
                        name: 'base',
                        folder: 'asset/bunker/cell/',
                        layer: 'wall',
                        default: 'idle',
                        animationList: {
                            idle: { frameList: ['base.svg'], },
                        },
                        width: 800, // duplicated in colonyData
                        height: 256,
                    },
                    {
                        name: 'wallMountedLight',
                        folder: 'asset/bunker/cell/',
                        layer: 'wall',
                        default: 'off',
                        animationList: {
                            off: { frameList: ['wallMountedLightOff.svg'], },
                            on: { frameList: ['wallMountedLightOn.svg'], },
                        },
                        width: 800, // duplicated in colonyData
                        height: 256,
                    },
                    {
                        name: 'lighting',
                        folder: 'asset/bunker/cell/',
                        layer: 'outside',
                        default: 'off',
                        animationList: {
                            off: { frameList: ['lightingOff.svg'], },
                            on: { frameList: ['lightingOn.svg'], },
                        },
                        width: 800, // duplicated in colonyData
                        height: 256,
                    },
                ],
            },
        },
    ],
}