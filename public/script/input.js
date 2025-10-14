export class InputManager {
    constructor(input) {
        this.keyList = {};
        this.listeners = [];

        // Keyboard events
        window.addEventListener('keydown', (e) => this.onKeyChange({ e, isPressed: true, }));
        window.addEventListener('keyup', (e) => this.onKeyChange({ e, isPressed: false, }));
    }

    onKeyChange(input) {
        const { e, isPressed, } = input;
        const key = e.key.toLowerCase();
        this.keyList[key] = isPressed;
    }

    isPressed(input) {
        const { key, } = input;
        return !!this.keyList[key.toLowerCase()];
    }
}