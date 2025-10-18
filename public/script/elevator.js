export class Elevator extends GameClasses.GameObjectWithInteraction {
    constructor(input) {
        super(input);

        const { speed, delayDuration, colony, } = input;
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
        const { deltaTime, player, } = input;

        // Update delay timer
        if (this.delayTimer > 0) {
            this.delayTimer -= deltaTime;
            if (this.delayTimer < 0) this.delayTimer = 0;
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
                player.interactWith = null;
                this.startDelay();
            }
        }

        // Update animation state
        this.playerIsOn = this.isPlayerOn({ player, });
        const name = 'base';
        if (this.movingVertically && this.targetY < this.y) this.setState({ name, state: 'up' });
        else if (this.movingVertically && this.targetY > this.y) this.setState({ name, state: 'down' });
        else if (this.playerIsOn && !this.movingVertically) this.setState({ name, state: 'ready' });
        else if (!this.playerIsOn) this.setState({ name, state: 'idle' });

        // Update animation frames
        super.update({ deltaTime, x: this.x, y: this.y, player, });
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

    calculateInteractionBound(input) {
        const x = this.baseComponent.x;
        const right = x + this.baseComponent.width;
        const top = this.componentList.railGuard.y
        const bottom = this.baseComponent.y + this.baseComponent.height;
        const y = top + ((bottom - top) / 2);
        return { x, right, y, };
    }

    getInteractableList(input) {
        this.interactableList = [];
        if (this.movingVertically) {
            return;
        }
        super.getInteractableList(input);
    }

    handleInput(input) {
        const { colony, button, player, } = input;

        // Determine if player is on elevator
        // this.playerIsOn = this.isPlayerOn({ player });

        // Handle vertical input only if player is on and delay expired
        let nextLevel = null;
        if (this.delayTimer <= 0 && !this.movingVertically) {
            if (button == 'w' && this.currentLevelIndex > 0) {
                this.currentLevelIndex = this.currentLevelIndex - 1;
                nextLevel = colony.levelListInOrder[this.currentLevelIndex];
            }
            else if (button == 's' && this.currentLevelIndex < colony.levelListInOrder.length - 1) {
                this.currentLevelIndex = this.currentLevelIndex + 1;
                nextLevel = colony.levelListInOrder[this.currentLevelIndex];

            }
        }
        if (nextLevel) {
            this.targetY = nextLevel.groundY;
            this.movingVertically = true;
            player.interactWith = this.animatedObject;
        }
    }
}