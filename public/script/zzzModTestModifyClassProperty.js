export default function ({ register }) {
    // Test before hook
    register({
        className: "MainApp",
        methodName: "modifyClassProperty",
        mode: Shared.MOD_STRING.REGISTRATION_MODE.AFTER,
        handler(input) {
            window.GameClasses.Player =
                ScriptLoader.addDefaultProperty({
                    ClassRef: window.GameClasses.Player,
                    propName: "location",
                    defaultValue: "Unknown",
                });
        },
    });
    register({
        className: "MainApp",
        methodName: "modifyClassProperty",
        mode: Shared.MOD_STRING.REGISTRATION_MODE.AFTER,
        handler(input) {
            window.GameClasses.Player = ScriptLoader.addDefaultProperty({
                ClassRef: window.GameClasses.Player,
                propName: "blackMagic",
                defaultValue: false
            });
        },
    });
}
