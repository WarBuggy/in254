export class GameManager extends GameClasses.MainApp {
    static CANVAS_ID = 'canvas';
    static BACKGROUND_IMAGE = 'asset/samplebg.jpg';

    constructor(input) {
        super(input);

        const interiorData = this.modData[Shared.MOD_STRING.MOD_DATA_TYPE.COLONY_DATA].interiorData;
        this.colony = new GameClasses.Colony({
            interiorData,
            levelData: this.modData[Shared.MOD_STRING.MOD_DATA_TYPE.COLONY_DATA].levelData,
        });

        this.canvas = document.getElementById(GameManager.CANVAS_ID);
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;

        // Camera / viewport
        this.camera = { x: 0, y: 0, width: window.innerWidth, height: window.innerHeight };
        // Player
        this.player = new GameClasses.Player({
            colony: this.colony,
            generalData: this.modData[Shared.MOD_STRING.MOD_DATA_TYPE.PLAYER_DATA].general,
            animationData: this.modData[Shared.MOD_STRING.MOD_DATA_TYPE.ANIMATION_DATA].player,
        });

        this.mapLimit = {
            left: interiorData.outerWallPaddingLeft,
            right: this.colony.width - interiorData.outerWallPaddingRight,
        };

        this.elevator = new GameClasses.Elevator({
            x: this.colony.elevatorX,
            speed: interiorData.elevatorSpeed,
            delayDuration: interiorData.elevatorDelayDuration,
            animationData: this.modData[Shared.MOD_STRING.MOD_DATA_TYPE.ANIMATION_DATA].elevator,
            colony: this.colony,
        });

        // Load background image
        this.bgImage = new Image();
        this.bgImage.src = GameManager.BACKGROUND_IMAGE;

        // Handle window resize
        window.addEventListener('resize', () => {
            this.camera.width = window.innerWidth;
            this.camera.height = window.innerHeight;
            this.canvas.width = window.innerWidth;
            this.canvas.height = window.innerHeight;
        });

        this.inputManager = new GameClasses.InputManager();
        this.drawManager = new GameClasses.DrawManager({
            ctx: this.canvas.getContext('2d'),
            drawLayerData: this.modData[Shared.MOD_STRING.MOD_DATA_TYPE.DRAW_LAYER_DATA].layer,
        });
        this.gowaInstanceList = this.collectAllGOWAInstance().result;
    }

    collectAllGOWAInstance(input) {
        const result = {};

        for (const key of Object.keys(this)) {
            const value = this[key];

            if (!value) continue;

            // Case 1: Direct instance of GOWA
            if (value instanceof GameClasses.GameObjectWithAnimation) {
                result[value.animatedObject] = value;
                continue;
            }

            // Case 2: Array of potential GOWA instances
            if (Array.isArray(value)) {
                for (const element of value) {
                    if (element instanceof GameClasses.GameObjectWithAnimation) {
                        result[element.animatedObject] = element;
                    }
                }
            }
        }

        return { result };
    }

    async loadAllSprite() {
        // Load background
        this.bgImage = await Shared.loadImage({ src: GameManager.BACKGROUND_IMAGE });

        const loadPromiseList = [];
        for (const obj of Object.values(this.gowaInstanceList)) {
            loadPromiseList.push(obj.loadAllSprite());
        }

        await Promise.all(loadPromiseList);
        console.log(`[GameManager] ${taggedString.gameManagerAllSpriteLoaded()}`);
    }

    start() {
        requestAnimationFrame(() => this.loop());
    }

    update(input) {
        const { deltaTime, } = input;

        this.elevator.update({
            deltaTime, colony: this.colony,
            player: this.player, inputManager: this.inputManager,
        });

        this.player.update({
            elevator: this.elevator, colony: this.colony,
            levelList: this.colony.levelListInOrder,
            inputManager: this.inputManager,
            deltaTime, mapLimit: this.mapLimit,
        });

        // Center camera on player
        this.camera.x = this.player.x + this.player.width / 2 - this.camera.width / 2;
        this.camera.y = this.player.y + this.player.height / 2 - this.camera.height / 2;

        // Clamp camera to map
        this.camera.x = Math.max(0, Math.min(this.colony.width - this.camera.width, this.camera.x));
        this.camera.y = Math.max(0, Math.min(this.colony.height - this.camera.height, this.camera.y));
    }

    loop() {
        const now = performance.now();
        if (!this.lastFrameTime) this.lastFrameTime = now;
        const deltaTime = now - this.lastFrameTime;
        this.lastFrameTime = now;
        this.update({ deltaTime, });

        // Draw all game objects using DrawManager
        this.drawManager.draw({
            camera: this.camera,
            mapLimit: this.mapLimit,
            colony: this.colony,
            bgImage: this.bgImage,
            objectList: this.gowaInstanceList,
        });

        requestAnimationFrame(() => this.loop());
    }

    createPageHTMLComponent() {
        Shared.createHTMLComponent({
            tag: 'canvas',
            id: GameManager.CANVAS_ID,
            parent: document.body,
        });
    }
};
