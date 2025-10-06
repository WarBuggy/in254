export default function ({ register }) {
    // test add new method hook, instance method
    register({
        className: "Player",
        methodName: "fire2",
        mode: Shared.MOD_STRING.REGISTRATION_MODE.NEW_METHOD,
        handler(input) {
            console.log(`${this.name} shoot laser out of his eyes for ${input.dmg - 2} damage.`);
        },
    });

    // test add new method hook, static method
    register({
        className: "Player",
        methodName: "fire3",
        mode: Shared.MOD_STRING.REGISTRATION_MODE.NEW_METHOD,
        isStatic: true,
        handler(input) {
            console.log(`The whole map explodes! Everything took ${Math.ceil(input.dmg * 0.1)} damange.`);
        },
    });
}