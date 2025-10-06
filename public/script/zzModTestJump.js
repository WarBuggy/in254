export default function ({ register }) {
    // Test fail to load case
    registers({
        className: "Player",
        methodName: "jump",
        mode: Shared.MOD_STRING.REGISTRATION_MODE.AFTER,
        handler(input, result) {
            console.log(`${this.namse} feels much better.`);
            console.log(input);
            console.log(result);
        },
    });

    // Test replace hook
    register({
        className: "Player",
        methodName: "toBeReplace1",
        mode: Shared.MOD_STRING.REGISTRATION_MODE.REPLACE,
        handler: function () {
            console.log('This line should show up.');
        },
    });

    // Test replace hook
    register({
        className: "Player",
        methodName: "toBeReplace2",
        mode: Shared.MOD_STRING.REGISTRATION_MODE.REPLACE,
        handler: function () {
            console.log('This line should not show up because it will be replaced.');
        },
    });
}