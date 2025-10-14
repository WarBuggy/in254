export class GameObjectWithAnimation {

    static IGNORE_KEY_LIST = ['name', 'default', 'folder',];
    static DEFAULT_FRAME_DURATION = 100; // ms;

    constructor(input) {
        const { animationData, } = input;

        this.animationData = animationData;
        this.animationList = {};

        // Extract keys to load
        this.animationKeyList = Object.keys(animationData).filter(
            k => !GameObjectWithAnimation.IGNORE_KEY_LIST.includes(k)
        );

        this.currentState = animationData.default;
        this.lastFrameTime = 0;

        // Store a separate frameIndex for each animation
        this.frameIndex = {};
    }

    // Load all frames for all animations
    async loadAllSprite() {
        for (const key of this.animationKeyList) {
            this.frameIndex[key] = 0;
            this.animationList[key] = [];
            for (const fileName of this.animationData[key]) {
                const src = this.animationData.folder + fileName;
                const img = await Shared.loadImage({ src });
                this.animationList[key].push(img);
            }
        }
    }

    // Update animation frame (looping)
    update(input) {
        const { deltaTime, } = input;
        if (!this.currentState || !this.animationList[this.currentState]) return;
        if (this.animationList[this.currentState].length === 0) return;

        this.lastFrameTime += deltaTime;
        if (this.lastFrameTime >= GameObjectWithAnimation.DEFAULT_FRAME_DURATION) {
            this.lastFrameTime = 0;
            this.frameIndex[this.currentState] =
                (this.frameIndex[this.currentState] + 1) % this.animationList[this.currentState].length;
        }
    }

    // Draw current frame with optional horizontal flip
    draw(input) {
        const { ctx, x, y, flipX = false } = input;
        if (!this.currentState || !this.animationList[this.currentState]) return;
        const frameList = this.animationList[this.currentState];
        const img = frameList[this.frameIndex[this.currentState]];
        if (!img) return;

        if (flipX) {
            ctx.save();
            ctx.scale(-1, 1);
            ctx.drawImage(img, -x - this.width, y, this.width, this.height);
            ctx.restore();
        } else {
            ctx.drawImage(img, x, y, this.width, this.height);
        }
    }

    // Switch to a different animation state
    setState(input) {
        const { state, resetFrameIndex = true, } = input;
        if (this.currentState === state) return;
        if (!this.animationList[state]) return;

        this.currentState = state;
        // Do not reset frameIndex unless you want to restart animation
        this.lastFrameTime = 0;
        if (resetFrameIndex) {
            this.frameIndex[state] = 0;
        }
    }
}
