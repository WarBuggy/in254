export class Game extends GameClasses.MainApp {
    static CANVAS_ID = 'canvas';
    static BACKGROUND_IMAGE = 'asset/samplebg.jpg';

    constructor(input) {
        super(input);
        this.canvas = document.getElementById(Game.CANVAS_ID);
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
        this.ctx = this.canvas.getContext('2d');

        // Camera / viewport = screen size
        this.camera = { x: 0, y: 0, width: window.innerWidth, height: window.innerHeight, };
        // Player
        this.player = { x: 0, y: 0, width: 64, height: 64, speed: 16, level: 'top', };

        this.levels = {
            top: { groundY: 1400 },
            bottom: { groundY: 2900 },
        };

        this.mapLimits = {
            left: 100,
            top: this.levels.top.groundY + this.player.height,
            right: 200,
            bottom: this.levels.bottom.groundY,
        };

        // Input
        this.keys = {};
        window.addEventListener('keydown', e => this.keys[e.key.toLowerCase()] = true);
        window.addEventListener('keyup', e => this.keys[e.key.toLowerCase()] = false);

        // Load background image
        this.bgImage = new Image();
        this.bgImage.src = Game.BACKGROUND_IMAGE;
        this.bgImage.onload = () => {
            this.mapPixelWidth = this.bgImage.width;
            this.mapPixelHeight = this.bgImage.height;

            // Start player at map center
            this.player.x = this.mapPixelWidth / 2 - this.player.width / 2;
            this.player.y = this.levels.top.groundY - this.player.height;

            this.elevator = {
                width: this.player.width,
                x: this.mapPixelWidth / 2 - this.player.width / 2,
                speed: 128,
            };

            // Start game loop
            requestAnimationFrame(() => this.loop());
        };

        // Handle window resize
        window.addEventListener('resize', () => {
            this.camera.width = window.innerWidth;
            this.camera.height = window.innerHeight;
            this.canvas.width = window.innerWidth;
            this.canvas.height = window.innerHeight;
        });
    }

    update() {
        // --- Elevator logic ---
        const onElevator = this.player.x + this.player.width > this.elevator.x &&
            this.player.x < this.elevator.x + this.elevator.width;

        // --- Smooth vertical movement ---
        if (this.player.movingVertically) {
            const targetY = this.levels[this.player.targetLevel].groundY - this.player.height;

            if (this.player.y < targetY) {
                this.player.y += this.elevator.speed;
                if (this.player.y >= targetY) {
                    this.player.y = targetY;
                    this.player.level = this.player.targetLevel;
                    this.player.movingVertically = false;
                }
            } else if (this.player.y > targetY) {
                this.player.y -= this.elevator.speed;
                if (this.player.y <= targetY) {
                    this.player.y = targetY;
                    this.player.level = this.player.targetLevel;
                    this.player.movingVertically = false;
                }
            }
        } else {
            // --- Horizontal movement allowed only when not moving vertically ---
            if (this.keys['a']) this.player.x -= this.player.speed;
            if (this.keys['d']) this.player.x += this.player.speed;

            // --- Trigger vertical movement when on elevator ---
            if (onElevator && this.keys['s'] && this.player.level === 'top') {
                this.player.targetLevel = 'bottom';
                this.player.movingVertically = true;
            } else if (onElevator && this.keys['w'] && this.player.level === 'bottom') {
                this.player.targetLevel = 'top';
                this.player.movingVertically = true;
            }
        }

        // --- Clamp player horizontally ---
        this.player.x = Math.max(
            this.mapLimits.left,
            Math.min(this.mapPixelWidth - this.mapLimits.right - this.player.width, this.player.x)
        );

        // --- Update camera to center player ---
        this.camera.x = this.player.x + this.player.width / 2 - this.camera.width / 2;
        this.camera.y = this.player.y + this.player.height / 2 - this.camera.height / 2;

        // --- Clamp camera to background edges ---
        this.camera.x = Math.max(0, Math.min(this.mapPixelWidth - this.camera.width, this.camera.x));
        this.camera.y = Math.max(0, Math.min(this.mapPixelHeight - this.camera.height, this.camera.y));
    }

    draw() {
        const ctx = this.ctx;

        // Clear viewport
        ctx.clearRect(0, 0, this.camera.width, this.camera.height);

        // Draw background portion visible in camera
        ctx.drawImage(
            this.bgImage,
            this.camera.x, this.camera.y,
            this.camera.width, this.camera.height,
            0, 0,
            this.camera.width, this.camera.height
        );

        // --- Draw left and right edges as vertical lines ---
        ctx.strokeStyle = 'yellow';
        ctx.lineWidth = 3;

        // Left edge
        ctx.beginPath();
        ctx.moveTo(this.mapLimits.left - this.camera.x, 0 - this.camera.y);
        ctx.lineTo(this.mapLimits.left - this.camera.x, this.mapPixelHeight - this.camera.y);
        ctx.stroke();

        // Right edge
        ctx.beginPath();
        ctx.moveTo(this.mapPixelWidth - this.mapLimits.right - this.camera.x, 0 - this.camera.y);
        ctx.lineTo(this.mapPixelWidth - this.mapLimits.right - this.camera.x, this.mapPixelHeight - this.camera.y);
        ctx.stroke();

        // Draw top ground line
        ctx.strokeStyle = 'green';
        ctx.beginPath();
        ctx.moveTo(this.mapLimits.left - this.camera.x, this.levels.top.groundY - this.camera.y);
        ctx.lineTo(this.mapPixelWidth - this.mapLimits.right - this.camera.x, this.levels.top.groundY - this.camera.y);
        ctx.stroke();

        // Draw bottom ground line
        ctx.strokeStyle = 'blue';
        ctx.beginPath();
        ctx.moveTo(this.mapLimits.left - this.camera.x, this.levels.bottom.groundY - this.camera.y);
        ctx.lineTo(this.mapPixelWidth - this.mapLimits.right - this.camera.x, this.levels.bottom.groundY - this.camera.y);
        ctx.stroke();

        // Draw player relative to camera
        ctx.fillStyle = 'red';
        ctx.fillRect(
            this.player.x - this.camera.x,
            this.player.y - this.camera.y,
            this.player.width,
            this.player.height
        );

        // Optional: draw elevator
        ctx.fillStyle = 'orange';
        ctx.fillRect(
            this.elevator.x - this.camera.x,
            this.levels.top.groundY - this.camera.y,
            this.elevator.width,
            this.levels.bottom.groundY - this.levels.top.groundY
        );
    }

    loop() {
        this.update();
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