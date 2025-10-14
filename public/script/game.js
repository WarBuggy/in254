export class Game extends GameClasses.MainApp {
    static CANVAS_ID = 'canvas';
    static BACKGROUND_IMAGE = 'asset/samplebg.jpg';

    constructor(input) {
        super(input);

        const interiorData = this.modData[Shared.MOD_STRING.MOD_DATA_TYPE.COLONY_DATA].interiorData;
        this.colony = new GameClasses.Colony({
            interiorData,
            levelData: this.modData[Shared.MOD_STRING.MOD_DATA_TYPE.COLONY_DATA].levelData,
        });

        this.canvas = document.getElementById(Game.CANVAS_ID);
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
        this.ctx = this.canvas.getContext('2d');

        // Camera / viewport
        this.camera = { x: 0, y: 0, width: window.innerWidth, height: window.innerHeight };
        // Player
        this.player = new GameClasses.Player({
            colony: this.colony,
            animationData: this.modData[Shared.MOD_STRING.MOD_DATA_TYPE.ANIMATION_DATA].player,
        });

        this.mapLimit = {
            left: interiorData.outerWallPaddingLeft,
            right: this.colony.width - interiorData.outerWallPaddingRight,
        };

        this.elevator = new GameClasses.Elevator({
            x: this.colony.width / 2 - this.player.width / 2,
            width: interiorData.elevatorWidth,
            height: interiorData.elevatorHeight,
            speed: interiorData.elevatorSpeed,
            delayDuration: interiorData.elevatorDelayDuration,
            animationData: this.modData[Shared.MOD_STRING.MOD_DATA_TYPE.ANIMATION_DATA].elevator,
            colony: this.colony,
        });

        // Load background image
        this.bgImage = new Image();
        this.bgImage.src = Game.BACKGROUND_IMAGE;

        // Handle window resize
        window.addEventListener('resize', () => {
            this.camera.width = window.innerWidth;
            this.camera.height = window.innerHeight;
            this.canvas.width = window.innerWidth;
            this.canvas.height = window.innerHeight;
        });

        this.keyList = {};
        window.addEventListener('keydown', (e) => { this.keyList[e.key.toLowerCase()] = true; });
        window.addEventListener('keyup', (e) => { this.keyList[e.key.toLowerCase()] = false; });
    }

    async loadAllSprite() {
        this.bgImage = await Shared.loadImage({ src: Game.BACKGROUND_IMAGE });

        const visited = new Set();
        const objectsToLoad = [];

        function collectObjects(obj) {
            if (!obj || typeof obj !== 'object' || visited.has(obj)) return;
            visited.add(obj);

            if (obj instanceof GameClasses.GameObjectWithAnimation && typeof obj.loadAllSprite === 'function') {
                objectsToLoad.push(obj);
            }

            for (const key in obj) {
                if (obj.hasOwnProperty(key)) collectObjects(obj[key]);
            }

            if (Array.isArray(obj)) {
                for (const item of obj) collectObjects(item);
            }
        }

        collectObjects(this);

        await Promise.all(objectsToLoad.map(obj => obj.loadAllSprite()));
    }

    start() {
        requestAnimationFrame(() => this.loop());
    }

    update(input) {
        const { deltaTime, } = input;

        this.elevator.update({
            deltaTime, colony: this.colony,
            player: this.player, keyList: this.keyList,
        });

        this.player.update({
            elevator: this.elevator, colony: this.colony,
            levelList: this.colony.levelListInOrder,
            keyList: this.keyList,
            deltaTime, mapLimit: this.mapLimit,
        });

        // Center camera on player
        this.camera.x = this.player.x + this.player.width / 2 - this.camera.width / 2;
        this.camera.y = this.player.y + this.player.height / 2 - this.camera.height / 2;

        // Clamp camera to map
        this.camera.x = Math.max(0, Math.min(this.colony.width - this.camera.width, this.camera.x));
        this.camera.y = Math.max(0, Math.min(this.colony.height - this.camera.height, this.camera.y));
    }

    draw() {
        const ctx = this.ctx;

        // Draw black background
        ctx.fillStyle = 'black';
        ctx.fillRect(0, 0, this.camera.width, this.camera.height);

        // Draw background
        ctx.drawImage(
            this.bgImage,
            0, 0, this.bgImage.width, this.bgImage.height,
            -this.camera.x, -this.camera.y,
            this.colony.width, this.colony.height
        );

        // Draw edges
        ctx.strokeStyle = 'yellow';
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.moveTo(this.mapLimit.left - this.camera.x, 0 - this.camera.y);
        ctx.lineTo(this.mapLimit.left - this.camera.x, this.colony.height - this.camera.y);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(this.mapLimit.right - this.camera.x, 0 - this.camera.y);
        ctx.lineTo(this.mapLimit.right - this.camera.x, this.colony.height - this.camera.y);
        ctx.stroke();

        // Draw ground lines
        ctx.strokeStyle = 'green';
        for (const level of this.colony.levelListInOrder) {
            ctx.beginPath();
            ctx.moveTo(this.mapLimit.left - this.camera.x, level.groundY - this.camera.y);
            ctx.lineTo(this.mapLimit.right - this.camera.x, level.groundY - this.camera.y);
            ctx.stroke();
        }

        // Draw elevator
        this.elevator.draw({ ctx, camera: this.camera, });

        // Draw player
        this.player.draw({ ctx, camera: this.camera });
    }

    loop() {
        const now = performance.now();
        if (!this.lastFrameTime) this.lastFrameTime = now;
        const deltaTime = now - this.lastFrameTime;
        this.lastFrameTime = now;
        this.update({ deltaTime, });
        this.draw();

        requestAnimationFrame(() => this.loop());
    }

    createPageHTMLComponent() {
        Shared.createHTMLComponent({
            tag: 'canvas',
            id: Game.CANVAS_ID,
            parent: document.body,
        });
    }
};
