export class Cell extends GameClasses.Bunker {
    constructor(input) {
        super(input);

        const { level, bunker, camera, } = input;
        this.animatedObject = bunker.name;
        this.setState({ name: 'base', state: 'idle', });
    }

    update(input) {
        const { deltaTime, camera, } = input;
        super.update({ deltaTime, x: this.x, y: this.y, camera, });
    }
}