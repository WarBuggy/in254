export default {
    modData: [
        {
            dataType: Shared.MOD_STRING.MOD_DATA_TYPE.COLONY_DATA,
            name: 'interiorData',
            payload: {
                outerWallPaddingLeft: 32,
                outerWallPaddingRight: 32,
                levelCeilingPaddingTop: 64,
                levelFloorPaddingBottom: 0,
                floorThickness: 64,
                bunkerMarginLeft: 32,
                bunkerMarginRight: 32,
                bunkerWidth: 800,
                bunkerHeight: 250,
                cellStartingNum: 1,
                cellPaddingTargetLength: 3,
                cellPaddingCharacter: '0',
                elevatorWidth: 256, // duplicated in elevator animation data
                elevatorMarginLeft: 32,
                elevatorMarginRight: 32,
                elevatorSpeed: 1, // per 1 ms
                elevatorDelayDuration: 200,
            },
        },
        {
            dataType: Shared.MOD_STRING.MOD_DATA_TYPE.COLONY_DATA,
            name: 'levelData',
            payload: {
                list: {
                    one: {
                        bunkerList: [Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.ELEVATOR, Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.CELL,],
                        index: 0,
                    },
                    two: {
                        bunkerList: [Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.ELEVATOR, Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.CELL,],
                        index: 1,
                    },
                    three: {
                        bunkerList: [Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.CONTROL_ROOM, Shared.BUNKER_TYPE.ELEVATOR, Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.CELL,],
                        index: 2,
                    },
                    four: {
                        bunkerList: [Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.ELEVATOR, Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.CELL,],
                        index: 3,
                    },
                    five: {
                        bunkerList: [Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.ELEVATOR, Shared.BUNKER_TYPE.CELL, Shared.BUNKER_TYPE.CELL,],
                        index: 4,
                    }
                },
            },
        },
    ],
}