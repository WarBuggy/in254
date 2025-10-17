export class Bunker extends GameClasses.GameObjectWithInteraction {

    constructor(input) {
        super(input);

        const { level, bunker, } = input;
        this.width = this.baseComponent.width;
        this.height = this.baseComponent.height;
        this.x = bunker.x;
        this.y = level.groundY - this.height;
    }
}