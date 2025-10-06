export class SeededRandom {
    constructor(input) {
        const { seed, } = input;
        this.m = 0x80000000;        // 2**31
        this.a = 1664525;           // LCG multiplier
        this.c = 1013904223;        // LCG increment
        this.seed = seed || Math.floor(Math.random() * (this.m - 1));
        this.state = this.seed;      // current state
    }

    // Returns a pseudo-random number between 0 (inclusive) and 1 (exclusive)
    next(input) {
        this.state = (this.a * this.state + this.c) % this.m;
        return { value: this.state / (this.m - 1), };
    }

    // Returns an integer between min and max (inclusive)
    nextInt(input) {
        const { min, max, } = input;
        return { value: Math.floor(this.next() * (max - min + 1)) + min, };
    }

    // Optionally, reset the RNG to its original seed
    reset() {
        this.state = this.seed;
    }

    createShuffledArray(input) {
        const { arr, } = input;
        const array = arr.slice(); // make a copy
        for (let i = array.length - 1; i > 0; i--) {
            const j = Math.floor(this.next() * (i + 1));
            [array[i], array[j]] = [array[j], array[i]];
        }
        return { array, };
    }
}