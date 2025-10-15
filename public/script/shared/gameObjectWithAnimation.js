export class GameObjectWithAnimation {

    static DEFAULT_FRAME_DURATION = 100; // ms;
    static EXCLUDE_KEY_LIST = ['name', 'default', 'animationList'];

    constructor(input) {
        const { animationData } = input;

        this.animatedObject = animationData.name;

        // This will hold all processed components
        this.componentList = {};
        if (Array.isArray(animationData.componentList)) {
            for (const comp of animationData.componentList) {
                this.processComponent({ comp });
            }
        }
        this.baseComponent = this.componentList[animationData.baseComponent];
    }

    processComponent(input) {
        const { comp, } = input;

        // Collect all other properties as defaults
        const defaultPropertyList = {};
        for (const key in comp) {
            if (!GameObjectWithAnimation.EXCLUDE_KEY_LIST.includes(key)) {
                defaultPropertyList[key] = comp[key];
            }
        }

        const compName = comp.name;
        this.componentList[compName] = {
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

            this.componentList[compName].animationList[stateName] = mergedState;

            // Initialize frame index
            this.componentList[compName].frameIndex[stateName] = 0;
        }
    }

    async loadAllSprite() {
        const loadPromiseList = [];

        for (const comp of Object.values(this.componentList)) {
            for (const [_, stateData] of Object.entries(comp.animationList)) {
                const folder = stateData.folder || '';
                stateData.imageList = []; // will store loaded images

                for (const fileName of stateData.frameList) {
                    const src = folder + fileName;
                    loadPromiseList.push(
                        Shared.loadImage({ src }).then(img => {
                            stateData.imageList.push(img);
                        })
                    );
                }
            }
            comp.currentState = comp.defaultState;
        }

        await Promise.all(loadPromiseList);

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
}
