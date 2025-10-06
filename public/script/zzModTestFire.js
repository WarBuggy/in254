export default function ({ register }) {
    // Test before hook
    register({
        className: "Player",
        methodName: "fire",
        mode: Shared.MOD_STRING.REGISTRATION_MODE.BEFORE,
        handler(input) {
            console.log(`${this.name} aims carefully at the target.`);
        },
    });

    // Test after hook
    register({
        className: "Player",
        methodName: "heal",
        mode: Shared.MOD_STRING.REGISTRATION_MODE.AFTER,
        handler() {
            console.log(`Player feels much better.`);
        },
    });
}
