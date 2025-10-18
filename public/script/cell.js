export class Cell extends GameClasses.Bunker {
    constructor(input) {
        super(input);

        const { bunker, } = input;
        this.animatedObject = bunker.name;
        this.setState({ name: 'base', state: 'idle', });
    }

    update(input) {
        const { deltaTime, camera, player, } = input;
        super.update({ deltaTime, x: this.x, y: this.y, camera, player, });
    }
}