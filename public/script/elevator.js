export class Elevator {
    constructor(input) {
        const { x, y, width, height, speed, delayDuration, spriteData, } = input;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.speed = speed;
        this.delayDuration = delayDuration;
        this.delayTimer = 0; // counts down when elevator reaches a level
    }

    move(input) {
        const { deltaY, } = input;
        this.x += deltaY; // Not used if elevator is stationary horizontally
    }

    startDelay() {
        this.delayTimer = this.delayDuration;
    }

    update(input) {
        const { deltaTime, } = input;
        if (this.delayTimer > 0) {
            this.delayTimer -= deltaTime;
            if (this.delayTimer < 0) this.delayTimer = 0;
            return false; // still in delay
        }
        return true; // ready to move
    }

    isPlayerOn(input) {
        const { player, } = input;
        return player.x + player.width > this.x && player.x < this.x + this.width;
    }

    draw(input) {
        const { ctx, camera, topY, bottomY, } = input;
        ctx.fillStyle = 'orange';
        ctx.fillRect(
            this.x - camera.x,
            topY - camera.y,
            this.width,
            bottomY - topY
        );
    }
}
