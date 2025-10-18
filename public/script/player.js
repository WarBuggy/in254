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
        this.facingRight = false;
        this.isMoving = false;

        this.interactionOffsetX = generalData.interactionOffsetX;
        this.interactionX = this.x + this.interactionOffsetX;
        this.interactWith = null;
    }

    updatePosition(input) {
        const { deltaTime, inputManager, mapLimit, } = input;

        if (this.interactWith) {
            return;
        }

        // Horizontal movement
        const movingLeft = inputManager.isPressed({ key: 'a', });
        const movingRight = inputManager.isPressed({ key: 'd', });

        const moveDistance = this.speed * deltaTime;
        if (movingLeft) {
            this.x -= moveDistance;
            this.x = Math.max(mapLimit.left, this.x);
            this.isMoving = true;
            this.facingRight = false;
        }
        else if (movingRight) {
            this.x += moveDistance;
            this.x = Math.min(mapLimit.right - this.width, this.x);
            this.isMoving = true;
            this.facingRight = true;
        } else {
            this.isMoving = false;
        }
        this.interactionX = this.x + this.interactionOffsetX;
    }

    postUpdate(input) {
        const { deltaTime, gowaInstanceList, } = input;
        // If on a moving elevator, just follow it and idle
        if (this.interactWith == 'elevator') {
            const elevator = gowaInstanceList[this.interactWith];
            this.y = elevator.y - this.height;
            this.setState({ name: 'base', state: 'idle', });
            super.update({ deltaTime, x: this.x, y: this.y, isFlipped: !this.facingRight, });
            return;
        }

        // Set animation state based on movement
        if (this.isMoving) this.setState({ name: 'base', state: 'move', });
        else this.setState({ name: 'base', state: 'idle', });

        super.update({ deltaTime, x: this.x, y: this.y, isFlipped: !this.facingRight, });
    }

    checkVisibility(input) {
        return true;
    }
}
