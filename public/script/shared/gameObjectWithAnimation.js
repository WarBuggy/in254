export class GameObjectWithAnimation {

    static IGNORE_KEY_LIST = ['name', 'default', 'folder',];
    static DEFAULT_FRAME_DURATION = 100; // ms;

    constructor(input) {
        const { animationData, } = input;

        this.animatedObject = animationData.name;
        this.animationData = animationData;
        this.animationList = {};

        // Extract keys to load
        this.animationKeyList = Object.keys(animationData).filter(
            k => !GameObjectWithAnimation.IGNORE_KEY_LIST.includes(k)
        );

        this.defaultState = animationData.default;
        this.lastFrameTime = 0;
        this.noAnimationPossible = false;

        this.frameIndex = {};
    }

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
        console.log(`[GameObjectWithAnimation] ${taggedString.gameObjectWithAnimationAllSpriteLoaded(this.animatedObject)}`);
        this.setState({ state: this.defaultState, });
    }

    update(input) {
        if (this.noAnimationPossible) {
            return;
        }

        const { deltaTime, } = input;
        this.lastFrameTime += deltaTime;
        if (this.lastFrameTime >= GameObjectWithAnimation.DEFAULT_FRAME_DURATION) {
            this.lastFrameTime = 0;
            this.frameIndex[this.currentState] =
                (this.frameIndex[this.currentState] + 1) % this.animationList[this.currentState].length;
        }
    }

    draw(input) {
        if (this.noAnimationPossible) {
            return;
        }

        const { ctx, x, y, flipX = false } = input;
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

    setState(input) {
        const { state, resetFrameIndex = true, } = input;
        if (this.currentState === state) return;

        this.currentState = state;
        this.lastFrameTime = 0;
        if (!this.currentState || !this.animationList[this.currentState] ||
            this.animationList[this.currentState].length < 1) {
            this.noAnimationPossible = true;
            console.error(`[GameObjectWithAnimation] ${taggedString.gameObjectWithAnimationFailedStateChange(state, this.animatedObject)}`);
            return;
        }

        this.noAnimationPossible = false;
        if (resetFrameIndex) {
            this.frameIndex[this.currentState] = 0;
        }
    }
}
