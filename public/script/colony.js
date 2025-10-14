export class Colony {
    constructor(input) {
        const { interiorData, levelData, } = input;
        this.allLevelData = {};
        this.levelListInOrder = [];
        this.width = 0;
        this.height = 0;
        this.firstLevelWithControlRoom = null;
        let nextCellNumber = interiorData.cellStartingNum;
        let levelCeiling = 0;
        for (const [levelName, data] of Object.entries(levelData.list)) {
            const bunkerList = data.bunkerList;
            const aLevelData =
                this.createALevelData({ interiorData, levelName, bunkerList, nextCellNumber, });
            aLevelData.groundY = levelCeiling + aLevelData.groundToCeilingHeight;
            this.allLevelData[aLevelData.name] = aLevelData;
            this.levelListInOrder.push(aLevelData);
            this.width = Math.max(this.width, aLevelData.width);
            this.height = this.height + aLevelData.height;
            if (aLevelData.hasControlRoom && !this.firstLevelWithControlRoom) {
                this.firstLevelWithControlRoom = aLevelData;
            }
            nextCellNumber = aLevelData.nextCellNumber;
            levelCeiling = levelCeiling + aLevelData.height;
        }
        this.topLevel = this.levelListInOrder[0];
        this.bottomLevel = this.levelListInOrder[this.levelListInOrder.length - 1];
    }

    createALevelData(input) {
        const { interiorData, levelName, bunkerList, } = input;
        let nextCellNumber = input.nextCellNumber;
        const levelHeight = interiorData.levelCeilingPaddingTop + interiorData.levelFloorPaddingBottom +
            interiorData.floorThickness + interiorData.bunkerHeight;
        const groundToCeilingHeight = levelHeight - interiorData.floorThickness;
        let levelWidth = interiorData.outerWallPaddingLeft + interiorData.outerWallPaddingRight;
        const cellList = [];
        let hasControlRoom = false;
        for (const bunker of bunkerList) {
            const cellData = {
                level: levelName,
                type: bunker,
            };
            if (bunker == Shared.BUNKER_TYPE.ELEVATOR) {
                levelWidth = levelWidth + interiorData.elevatorWidth +
                    interiorData.elevatorMarginLeft + interiorData.elevatorMarginRight;
                continue;
            }

            levelWidth = levelWidth + interiorData.bunkerMarginLeft +
                interiorData.bunkerMarginRight + interiorData.bunkerWidth;
            if (bunker == Shared.BUNKER_TYPE.CELL) {
                cellData.number = nextCellNumber;
                cellData.name = `${nextCellNumber}`.padStart(interiorData.cellPaddingTargetLength,
                    interiorData.cellPaddingCharacter);
                nextCellNumber++;
            } else if (bunker == Shared.BUNKER_TYPE.CONTROL_ROOM) {
                hasControlRoom = true;
            }
            cellList.push(cellData);
        }
        return {
            name: levelName,
            width: levelWidth,
            height: levelHeight,
            groundToCeilingHeight, cellList, nextCellNumber, hasControlRoom,
        };
    }
}