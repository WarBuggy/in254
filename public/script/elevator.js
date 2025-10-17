export class Elevator extends GameClasses.GameObjectWithAnimation {
    constructor(input) {
        super(input);

        const { x, speed, delayDuration, colony, } = input;
        this.x = x;
        this.y = colony.firstLevelWithControlRoom.groundY;
        this.currentLevelIndex = colony.firstLevelWithControlRoom.index;
        this.width = this.baseComponent.width;
        this.height = this.baseComponent.height;
        this.speed = speed;
        this.delayDuration = delayDuration;
        this.delayTimer = 0; // counts down when elevator reaches a level

        this.targetY = this.y;
        this.movingVertically = false;
        this.playerIsOn = false; // added initialization
    }

    startDelay() {
        this.delayTimer = this.delayDuration;
    }

    update(input) {
        const { deltaTime, camera, player, inputManager, colony, } = input;

        // Update delay timer
        if (this.delayTimer > 0) {
            this.delayTimer -= deltaTime;
            if (this.delayTimer < 0) this.delayTimer = 0;
        }

        // Determine if player is on elevator
        this.playerIsOn = this.isPlayerOn({ player });

        // Handle vertical input only if player is on and delay expired
        if (this.playerIsOn && this.delayTimer <= 0 && !this.movingVertically) {
            if (inputManager.isPressed({ key: 'w', }) && this.currentLevelIndex > 0) {
                this.currentLevelIndex = this.currentLevelIndex - 1;
                const nextLevel = colony.levelListInOrder[this.currentLevelIndex];
                this.targetY = nextLevel.groundY;
                this.movingVertically = true;
            }
            else if (inputManager.isPressed({ key: 's', }) && this.currentLevelIndex < colony.levelListInOrder.length - 1) {
                this.currentLevelIndex = this.currentLevelIndex + 1;
                const nextLevel = colony.levelListInOrder[this.currentLevelIndex];
                this.targetY = nextLevel.groundY;
                this.movingVertically = true;
            }
        }

        // Move elevator vertically toward target
        if (this.movingVertically) {
            const direction = this.targetY > this.y ? 1 : -1;
            this.y += direction * this.speed * deltaTime;

            // Stop when reached target level
            if ((direction === 1 && this.y >= this.targetY) ||
                (direction === -1 && this.y <= this.targetY)) {
                this.y = this.targetY;
                this.movingVertically = false;
                this.startDelay();
            }
        }

        // Update animation state
        if (!this.playerIsOn) this.setState({ name: 'base', state: 'idle' });
        else if (this.playerIsOn && !this.movingVertically) this.setState({ name: 'base', state: 'ready' });
        else if (this.movingVertically && this.targetY < this.y) this.setState({ name: 'base', state: 'up' });
        else if (this.movingVertically && this.targetY > this.y) this.setState({ name: 'base', state: 'down' });

        // Update animation frames
        super.update({ deltaTime, x: this.x, y: this.y, camera, });
    }

    isPlayerOn(input) {
        const { player } = input;
        return player.x + (player.width / 2) >= this.x && player.x + (player.width / 2) < this.x + this.width;
    }

    checkVisibility(input) {
        const { camera, } = input;
        const y = this.componentList.railGuard.y;
        const bottom = this.baseComponent.y + this.baseComponent.height;
        return !(
            this.baseComponent.x + this.baseComponent.width < camera.x ||
            this.baseComponent.x > camera.right ||
            bottom < camera.y ||
            y > camera.bottom
        );
    }
}