export class Player {
    constructor(input) {
        this.name = input.name;
    };

    fire(input) {
        console.log(`${this.name} shoots for ${input.dmg} damage points.`);
        return 5;
    };

    static heal(input) {
        console.log(`Player heals.`);
    };

    static toBeReplace1(input) {
        console.log('This line should not show up.');
    };

    static toBeReplace2(input) {
        console.log('This line should not show up either.');
    };
}
