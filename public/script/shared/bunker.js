export class Bunker extends GameClasses.GameObjectWithInteraction {

    constructor(input) {
        super(input);

        this.width = this.baseComponent.width;
        this.height = this.baseComponent.height;
    }
}