export class Player extends GameClasses.GameObjectWithAnimation {
    constructor(input) {
        super(input);
        const { colony, generalData, } = input;

        this.width = this.baseComponent.width;
        this.height = this.baseComponent.height;
        const controlRoom = colony.firstLevelWithControlRoom.lastControlRoom;
        this.x = controlRoom.x + (controlRoom.width / 2) - (this.width / 2);
        this.y = colony.firstLevelWithControlRoom.groundY - this.height;
        this.speed = generalData.speed; // per 1 ms
        this.level = colony.firstLevelWithControlRoom;

        this.facingRight = false;
    }

    preUpdate(input) {
        const { deltaTime, inputManager, mapLimit, } = input;

        // Horizontal movement
        const movingLeft = !!inputManager.isPressed({ key: 'a', });
        const movingRight = !!inputManager.isPressed({ key: 'd', });

        const moveDistance = this.speed * deltaTime;
        if (movingLeft) {
            this.x -= moveDistance;
            this.x = Math.max(mapLimit.left, this.x);
        }
        if (movingRight) {
            this.x += moveDistance;
            this.x = Math.min(mapLimit.right - this.width, this.x);
        }

        // Facing direction
        if (movingLeft) this.facingRight = false;
        else if (movingRight) this.facingRight = true;

        // Set animation state based on movement
        if (movingLeft || movingRight) this.setState({ name: 'base', state: 'move', });
        else this.setState({ name: 'base', state: 'idle', });

        // Update animation frame
    }

    postUpdate(input) {
        const { elevator, deltaTime, colony, } = input;
        // If on a moving elevator, just follow it and idle
        if (elevator.playerIsOn) {
            this.y = elevator.y - this.height;
            if (elevator.movingVertically) {
                this.setState({ name: 'base', state: 'idle', });
                super.update({ deltaTime, x: this.x, y: this.y, isFlipped: !this.facingRight, });
                return;
            }
            this.level = colony.levelListInOrder[elevator.currentLevelIndex];
        }
        super.update({ deltaTime, x: this.x, y: this.y, isFlipped: !this.facingRight, });
    }

    checkVisibility(input) {
        return true;
    }
}
