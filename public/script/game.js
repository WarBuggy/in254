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

        // Camera / viewport = screen size
        this.camera = { x: 0, y: 0, width: window.innerWidth, height: window.innerHeight, };
        // Player
        this.player = new GameClasses.Player({ colony: this.colony, });

        this.mapLimits = {
            left: interiorData.outerWallPaddingLeft,
            top: this.colony.topLevel.groundY + this.player.height,
            right: interiorData.outerWallPaddingRight,
            bottom: this.colony.bottomLevel.groundY,
        };

        this.elevator = new GameClasses.Elevator({
            x: this.colony.width / 2 - this.player.width / 2,
            y: this.colony.firstLevelWithControlRoom.groundY,
            width: interiorData.elevatorWidth,
            height: interiorData.elevatorHeight,
            speed: interiorData.elevatorSpeed,
            delayDuration: interiorData.elevatorDelayDuration,
            spriteData: this.modData[Shared.MOD_STRING.MOD_DATA_TYPE.SPRITE].elevator,
        });

        // Load background image
        this.bgImage = new Image();
        this.bgImage.src = Game.BACKGROUND_IMAGE;
        this.bgImage.onload = () => {
            this.player.loadAllSprite({
                callback: () => {
                    this.player.bindInput();
                    requestAnimationFrame(() => this.loop());
                }
            });

        };

        // Handle window resize
        window.addEventListener('resize', () => {
            this.camera.width = window.innerWidth;
            this.camera.height = window.innerHeight;
            this.canvas.width = window.innerWidth;
            this.canvas.height = window.innerHeight;
        });
    }

    update(input) {
        const { deltaTime, } = input;

        this.elevator.update({ deltaTime });
        // Check if player is on the elevator
        const onElevator = this.elevator.isPlayerOn({ player: this.player, });
        // Update player (movement, elevator transitions, vertical smoothing)
        this.player.update({
            onElevator, elevator: this.elevator,
            levelList: this.colony.levelListInOrder,
        });

        // Clamp camera to center player
        this.camera.x = this.player.x + this.player.width / 2 - this.camera.width / 2;
        this.camera.y = this.player.y + this.player.height / 2 - this.camera.height / 2;

        // Clamp camera within map bounds
        this.camera.x = Math.max(0, Math.min(this.colony.width - this.camera.width, this.camera.x));
        this.camera.y = Math.max(0, Math.min(this.colony.height - this.camera.height, this.camera.y));
    }


    draw() {
        const ctx = this.ctx;

        // Fill the entire screen black first
        ctx.fillStyle = 'black';
        ctx.fillRect(0, 0, this.camera.width, this.camera.height);

        // Draw stretched background image to match map dimensions
        ctx.drawImage(
            this.bgImage,
            0, 0, this.bgImage.width, this.bgImage.height, // source (entire image)
            -this.camera.x, -this.camera.y,                // destination start
            this.colony.width, this.colony.height        // stretch to map size
        );

        // Draw left and right edges as vertical lines
        ctx.strokeStyle = 'yellow';
        ctx.lineWidth = 3;

        // Left edge
        ctx.beginPath();
        ctx.moveTo(this.mapLimits.left - this.camera.x, 0 - this.camera.y);
        ctx.lineTo(this.mapLimits.left - this.camera.x, this.colony.height - this.camera.y);
        ctx.stroke();

        // Right edge
        ctx.beginPath();
        ctx.moveTo(this.colony.width - this.mapLimits.right - this.camera.x, 0 - this.camera.y);
        ctx.lineTo(this.colony.width - this.mapLimits.right - this.camera.x, this.colony.height - this.camera.y);
        ctx.stroke();

        // Draw all ground lines green
        ctx.strokeStyle = 'green';
        for (const level of this.colony.levelListInOrder) {
            ctx.beginPath();
            ctx.moveTo(this.mapLimits.left - this.camera.x, level.groundY - this.camera.y);
            ctx.lineTo(this.colony.width - this.mapLimits.right - this.camera.x, level.groundY - this.camera.y);
            ctx.stroke();
        }

        // Draw elevator
        this.elevator.draw({
            ctx, camera: this.camera,
            topY: this.colony.topLevel.groundY, bottomY: this.colony.bottomLevel.groundY,
        });

        // Draw player
        this.player.draw({ ctx, camera: this.camera, });
    }

    loop() {
        const now = performance.now();

        // Initialize lastFrameTime on first frame
        if (!this.lastFrameTime) this.lastFrameTime = now;
        const deltaTime = now - this.lastFrameTime; // in milliseconds
        this.lastFrameTime = now;

        this.update({ deltaTime, });
        this.draw();

        requestAnimationFrame(() => this.loop());
    }

    createPageHTMLComponent(input) {
        Shared.createHTMLComponent({
            tag: 'canvas',
            id: Game.CANVAS_ID,
            parent: document.body,
        });
    }
};