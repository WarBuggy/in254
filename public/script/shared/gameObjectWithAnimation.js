export class GameObjectWithAnimation {

    static IMAGE_CACHE = new Map();
    static DEFAULT_FRAME_DURATION = 100; // ms;
    static EXCLUDE_KEY_LIST = ['name', 'default', 'animationList',];

    constructor(input) {
        const { animationData, x, y, } = input;

        this.animatedObject = animationData.name;
        this.x = x;
        this.y = y;

        // This will hold all processed components
        this.componentList = {};
        if (Array.isArray(animationData.componentList)) {
            for (const comp of animationData.componentList) {
                this.processComponent({ comp, x, y, });
            }
        }
        this.baseComponent = this.componentList[animationData.baseComponent];
        this.isVisible = false;
    }

    processComponent(input) {
        const { comp, x, y, } = input;

        // Collect all other properties as defaults
        const defaultPropertyList = {};
        for (const key in comp) {
            if (!GameObjectWithAnimation.EXCLUDE_KEY_LIST.includes(key)) {
                defaultPropertyList[key] = comp[key];
            }
        }

        const compName = comp.name;
        const compData = {
            // Static properties
            name: compName,
            defaultState: comp.default,
            animationList: {},
            // Runtime properties
            frameIndex: {},
            currentState: comp.default,
            lastFrameTime: 0,
            noAnimationPossible: false,
            x: 0,
            y: 0,
            isFlipped: false,
            width: comp.width,
            height: comp.height,
        }

        for (const [stateName, stateData] of Object.entries(comp.animationList)) {
            // Start with the properties from defaultPropertyList
            const mergedState = { ...defaultPropertyList, ...stateData };
            // Ensure frameList exists
            mergedState.frameList = mergedState.frameList || [];

            compData.animationList[stateName] = mergedState;

            // Initialize frame index
            compData.frameIndex[stateName] = 0;
        }

        const stateName = compData.currentState;
        const stateData = compData.animationList[stateName];
        // Compute drawing position
        compData.x = x + (stateData.offsetX || 0);
        compData.y = y + (stateData.offsetY || 0);

        this.componentList[compName] = compData;
    }

    async loadAllSprite() {
        for (const comp of Object.values(this.componentList)) {
            for (const [_, stateData] of Object.entries(comp.animationList)) {
                const folder = stateData.folder || '';
                stateData.imageList = [];

                for (const fileName of stateData.frameList) {
                    const src = folder + fileName;

                    // Check cache first
                    if (GameObjectWithAnimation.IMAGE_CACHE.has(src)) {
                        // Reuse existing cached image
                        stateData.imageList.push(GameObjectWithAnimation.IMAGE_CACHE.get(src));
                    } else {
                        // Load image and store it immediately
                        const img = await Shared.loadImage({ src });
                        GameObjectWithAnimation.IMAGE_CACHE.set(src, img);
                        stateData.imageList.push(img);
                    }
                }
            }

            comp.currentState = comp.defaultState;
        }

        console.log(`[GameObjectWithAnimation] ${taggedString.gameObjectWithAnimationAllSpriteLoaded(this.animatedObject)}`);
    }

    update(input) {
        const { deltaTime, x, y, isFlipped = false, } = input;

        for (const comp of Object.values(this.componentList)) {
            if (comp.noAnimationPossible) continue;

            comp.isFlipped = isFlipped;
            const stateName = comp.currentState;
            const stateData = comp.animationList[stateName];

            // Update frame timing
            comp.lastFrameTime += deltaTime;
            if (comp.lastFrameTime >= GameObjectWithAnimation.DEFAULT_FRAME_DURATION) {
                comp.lastFrameTime = 0;
                const totalFrameNum = stateData.imageList?.length || 0;
                if (totalFrameNum > 0) {
                    comp.frameIndex[stateName] = (comp.frameIndex[stateName] + 1) % totalFrameNum;
                }
            }

            // Compute drawing position
            comp.x = x + (stateData.offsetX || 0);
            comp.y = y + (stateData.offsetY || 0);
        }
    }

    setState(input) {
        const { name, state, resetFrameIndex = true, } = input;
        const component = this.componentList[name];
        if (!component) {
            console.error(`[GameObjectWithAnimation] ${taggedString.gameObjectWithAnimationNoCompFound(name, this.animatedObject)}`);
            return;
        }
        if (component.currentState === state) return;

        component.currentState = state;
        component.lastFrameTime = 0;
        const stateData = component.animationList[state];
        if (!state || !stateData || stateData.imageList.length < 1) {
            component.noAnimationPossible = true;
            console.error(`[GameObjectWithAnimation] ${taggedString.gameObjectWithAnimationFailedStateChange(component, state, this.animatedObject)}`);
            return;
        }

        component.noAnimationPossible = false;
        if (resetFrameIndex) {
            component.frameIndex[state] = 0;
        }
    }

    postUpdate(input) {
        this.isVisible = this.checkVisibility(input);
    }

    checkVisibility(input) {
        const { camera, } = input;
        return !(
            this.baseComponent.x + this.baseComponent.width < camera.x ||
            this.baseComponent.x > camera.right ||
            this.baseComponent.y + this.baseComponent.height < camera.y ||
            this.baseComponent.y > camera.bottom
        );
    }
}
