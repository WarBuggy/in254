export default {
    modData: [
        {
            dataType: Shared.MOD_STRING.MOD_DATA_TYPE.ANIMATION_DATA,
            name: 'elevator',
            payload: {
                folder: 'asset/elevator/',
                default: 'idle',
                idle: ['idle.svg'],
                ready: ['ready.svg'],
                up: ['up.svg'],
                down: ['down.svg'],
            },
        },
        {
            dataType: Shared.MOD_STRING.MOD_DATA_TYPE.ANIMATION_DATA,
            name: 'player',
            payload: {
                folder: 'asset/in254/',
                default: 'idle',
                idle: ['idle.svg'],
                move: ['move_01.svg', 'move_02.svg', 'move_03.svg', 'move_04.svg', 'move_05.svg', 'move_06.svg', 'move_07.svg',],
            },
        },
    ],
}