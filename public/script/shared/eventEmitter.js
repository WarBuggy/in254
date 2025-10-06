export class EventEmitter {
    constructor() {
        this.events = {};
    }

    on(input) {
        const { event, handler, } = input;
        if (!this.events[event]) this.events[event] = [];
        this.events[event].push(handler);
    }

    emit(input) {
        const { event, data, } = input;
        if (!this.events[event]) return;
        for (const handler of this.events[event]) {
            handler(data);
        }
    }

    off(input) {
        const { event, handler, } = input;
        if (!this.events[event]) return;
        this.events[event] = this.events[event].filter(h => h !== handler);
    }
}