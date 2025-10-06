// test add new classes
export class Player2 extends GameClasses.Player {
    constructor(input) {
        super(input);
    };

    roll() {
        console.log(`${this.name} rolled and avoided all damage.`);
    };

    // method with error
    sit() {
        kill();
        console.log(`${this.name} sit down.`);
    };
}