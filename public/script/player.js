export class Player extends GameClasses.GameObjectWithAnimation {
    constructor(input) {
        super(input);
        const { colony } = input;

        this.width = 256;
        this.height = 256;
        this.x = (colony.width - this.width) / 2;
        this.y = colony.firstLevelWithControlRoom.groundY - this.height;
        this.speed = 16;
        this.level = colony.firstLevelWithControlRoom;

        this.facingRight = false;
    }

    update(input) {
        const { elevator, keyList, deltaTime, colony, mapLimit, } = input;

        // If on a moving elevator, just follow it and idle
        if (elevator.playerIsOn) {
            this.y = elevator.y - this.height;
            if (elevator.movingVertically) {
                this.setState({ state: 'idle' });
                super.update({ deltaTime, name: 'player', });
                return;
            }
            this.level = colony.levelListInOrder[elevator.currentLevelIndex];
        }

        // Horizontal movement
        const movingLeft = !!keyList['a'];
        const movingRight = !!keyList['d'];

        if (movingLeft) {
            this.x -= this.speed;
            this.x = Math.max(mapLimit.left, this.x);
        }
        if (movingRight) {
            this.x += this.speed;
            this.x = Math.min(mapLimit.right - this.width, this.x);
        }

        // Facing direction
        if (movingLeft) this.facingRight = false;
        else if (movingRight) this.facingRight = true;

        // Set animation state based on movement
        if (movingLeft || movingRight) this.setState({ state: 'move', });
        else this.setState({ state: 'idle', });

        // Update animation frame
        super.update({ deltaTime, name: 'player', });
    }

    draw(input) {
        const { ctx, camera } = input;
        const x = this.x - camera.x;
        const y = this.y - camera.y;

        // flipX = false when facing right, true when facing left
        super.draw({ ctx, x, y, flipX: !this.facingRight });
    }
}
