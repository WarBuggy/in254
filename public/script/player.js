export class Player {
    static ASSET_PATH = 'asset/in254/';

    constructor(input) {
        const { colony } = input;
        this.width = 256;
        this.height = 256;
        this.x = (colony.width - this.width) / 2;
        this.y = colony.firstLevelWithControlRoom.groundY - this.height;
        this.speed = 16;
        this.level = colony.firstLevelWithControlRoom;
        this.targetLevel = null;
        this.movingVertically = false;
        this.facingRight = false;
        this.frameIndex = 0;
        this.lastFrameTime = 0;

        this.sprites = {
            idle: null,
            move: [],
        };

        this.keys = {}; // input tracking
    }

    bindInput() {
        window.addEventListener('keydown', e => this.keys[e.key.toLowerCase()] = true);
        window.addEventListener('keyup', e => this.keys[e.key.toLowerCase()] = false);
    }

    loadAllSprite(input) {
        const { callback } = input;
        let totalToLoad = 1 + 7;
        let loaded = 0;

        const checkAllLoaded = () => {
            loaded++;
            if (loaded === totalToLoad && typeof callback === 'function') {
                console.log(taggedString.playerAllAssetLoaded());
                callback();
            }
        };

        const idleImg = new Image();
        idleImg.src = `${Player.ASSET_PATH}idle.svg`;
        idleImg.onload = checkAllLoaded;
        this.sprites.idle = idleImg;

        for (let i = 1; i <= 7; i++) {
            const img = new Image();
            const fileNum = String(i).padStart(4, '0');
            img.src = `${Player.ASSET_PATH}move_${fileNum}.svg`;
            img.onload = checkAllLoaded;
            this.sprites.move.push(img);
        }
    }

    update(input) {
        const { onElevator, levelList, elevator, } = input;

        // Smooth vertical movement if in transition
        if (this.movingVertically && this.targetLevel) {
            const targetY = this.targetLevel.groundY - this.height;

            if (this.y < targetY) {
                this.y += elevator.speed;
                if (this.y >= targetY) {
                    this.y = targetY;
                    this.level = this.targetLevel;
                    this.movingVertically = false;

                    // Start elevator delay at the new level
                    if (elevator) elevator.startDelay();
                }
            } else if (this.y > targetY) {
                this.y -= elevator.speed;
                if (this.y <= targetY) {
                    this.y = targetY;
                    this.level = this.targetLevel;
                    this.movingVertically = false;

                    if (elevator) elevator.startDelay();
                }
            }
        } else {
            // Horizontal movement
            if (this.keys['a']) this.x -= this.speed;
            if (this.keys['d']) this.x += this.speed;

            // Determine current level index
            const currentIndex = levelList.findIndex(l => l.name === this.level.name);

            // Only allow elevator transitions if delayTimer is zero
            if (!elevator || elevator.delayTimer <= 0) {
                if (onElevator && this.keys['s'] && currentIndex < levelList.length - 1) {
                    this.targetLevel = levelList[currentIndex + 1];
                    this.movingVertically = true;
                } else if (onElevator && this.keys['w'] && currentIndex > 0) {
                    this.targetLevel = levelList[currentIndex - 1];
                    this.movingVertically = true;
                }
            }
        }
    }

    draw(input) {
        const { ctx, camera } = input;
        if (!this.sprites || !this.sprites.idle || this.sprites.move.length === 0) return;

        const now = performance.now();
        const movingLeft = this.keys['a'];
        const movingRight = this.keys['d'];

        if (movingLeft) this.facingRight = false;
        else if (movingRight) this.facingRight = true;

        let currentSprite;
        if (movingLeft || movingRight) {
            if (now - this.lastFrameTime > 100) {
                this.frameIndex = (this.frameIndex + 1) % this.sprites.move.length;
                this.lastFrameTime = now;
            }
            currentSprite = this.sprites.move[this.frameIndex];
        } else {
            currentSprite = this.sprites.idle;
            this.frameIndex = 0;
        }

        const drawX = this.x - camera.x;
        const drawY = this.y - camera.y;

        ctx.save();
        if (this.facingRight) {
            ctx.drawImage(currentSprite, drawX, drawY, this.width, this.height);
        } else {
            ctx.scale(-1, 1);
            ctx.drawImage(currentSprite, -drawX - this.width, drawY, this.width, this.height);
        }
        ctx.restore();
    }
}
