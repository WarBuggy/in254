export class Colony {
    constructor(input) {
        const { interiorData, levelData, } = input;
        this.allLevelData = {};
        this.width = 0;
        this.height = 0;
        this.firstLevelWithControlRoom = null;
        let nextCellNumber = interiorData.cellStartingNum;
        let levelCeiling = 0;
        for (const [levelName, data] of Object.entries(levelData.list)) {
            const aLevelData =
                this.createALevelData({ interiorData, levelName, data, nextCellNumber, });
            aLevelData.groundY = levelCeiling + aLevelData.groundToCeilingHeight;
            this.allLevelData[aLevelData.name] = aLevelData;
            this.width = Math.max(this.width, aLevelData.width);
            this.height = this.height + aLevelData.height;
            if (aLevelData.lastControlRoom && !this.firstLevelWithControlRoom) {
                this.firstLevelWithControlRoom = aLevelData;
            }
            nextCellNumber = aLevelData.nextCellNumber;
            levelCeiling = levelCeiling + aLevelData.height;
        }
        this.levelListInOrder = Object.values(this.allLevelData);
        this.levelListInOrder.sort((a, b) => a.index - b.index);
        this.topLevel = this.levelListInOrder[0];
        this.bottomLevel = this.levelListInOrder[this.levelListInOrder.length - 1];
        this.elevatorX = this.calculateElevatorX({ interiorData, allLevelData: this.allLevelData, }).x;
    }

    createALevelData(input) {
        const { interiorData, levelName, data, } = input;

        let nextCellNumber = input.nextCellNumber;
        const levelHeight = interiorData.levelCeilingPaddingTop + interiorData.levelFloorPaddingBottom +
            interiorData.floorThickness + interiorData.bunkerHeight;
        const groundToCeilingHeight = levelHeight - interiorData.floorThickness;
        let levelWidth = interiorData.outerWallPaddingLeft + interiorData.outerWallPaddingRight;
        const bunkerList = [];
        let lastControlRoom = null;
        let currentX = interiorData.outerWallPaddingLeft;
        for (let i = 0; i < data.bunkerList.length; i++) {
            const bunker = data.bunkerList[i];
            const cellData = {
                level: levelName,
                type: bunker,
            };
            let marginLeft = 0;
            let bunkerWidth = 0;
            let marginRight = 0;
            bunkerList.push(cellData);
            switch (bunker) {
                case Shared.BUNKER_TYPE.ELEVATOR:
                    marginLeft = interiorData.elevatorMarginLeft;
                    bunkerWidth = interiorData.elevatorWidth;
                    marginRight = interiorData.elevatorMarginRight;
                    break;
                case Shared.BUNKER_TYPE.CONTROL_ROOM:
                    marginLeft = interiorData.bunkerMarginLeft;
                    bunkerWidth = interiorData.bunkerWidth;
                    marginRight = interiorData.bunkerMarginRight;
                    lastControlRoom = cellData;
                    break;
                case Shared.BUNKER_TYPE.CELL:
                default:
                    marginLeft = interiorData.bunkerMarginLeft;
                    bunkerWidth = interiorData.bunkerWidth;
                    marginRight = interiorData.bunkerMarginRight;
                    cellData.number = nextCellNumber;
                    cellData.name = `${nextCellNumber}`.padStart(interiorData.cellPaddingTargetLength,
                        interiorData.cellPaddingCharacter);
                    nextCellNumber++;
                    break;
            }
            currentX += marginLeft;
            cellData.x = currentX;
            cellData.width = bunkerWidth;
            currentX += bunkerWidth + marginRight;
            levelWidth += marginLeft + bunkerWidth + marginRight;
            continue;
        }

        return {
            name: levelName,
            width: levelWidth,
            height: levelHeight,
            groundToCeilingHeight, bunkerList, nextCellNumber, lastControlRoom,
            index: data.index,
        };
    }

    calculateElevatorX(input) {
        const { interiorData, allLevelData, } = input;

        const computedList = [];

        for (const [levelName, level] of Object.entries(allLevelData)) {
            let x = interiorData.outerWallPaddingLeft;
            const bunkerList = level.bunkerList || [];
            let foundElevator = false;

            for (const bunker of bunkerList) {
                if (bunker && bunker.type === Shared.BUNKER_TYPE.ELEVATOR) {
                    x += interiorData.elevatorMarginLeft;
                    foundElevator = true;
                    break;
                } else {
                    // non-elevator bunker: add margins + bunker width
                    x += interiorData.bunkerMarginLeft + interiorData.bunkerWidth + interiorData.bunkerMarginRight;
                }
            }

            if (!foundElevator) {
                // no explicit elevator entry in this level's list — log error
                console.error(`[Colony] ${taggedString.colonyNoElevatorFound(levelName)}`);
                // Assume elevator right in the middle
                x = (level.width - interiorData.elevatorWidth) / 2;
            }

            computedList.push({ level: levelName, x });
        }

        const xValues = computedList.map(e => e.x);
        const uniqueX = Array.from(new Set(xValues));

        if (uniqueX.length === 1) {
            return { x: uniqueX[0], };
        }

        // mismatch across levels — log details and return the smallest x
        const minX = Math.min(...xValues);
        console.error(`[Colony] ${taggedString.colonyElevatorXMismatch(JSON.stringify(computedList), String(minX))}`);
        return { x: minX, };
    }
}