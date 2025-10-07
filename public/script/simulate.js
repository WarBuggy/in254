export class Simulate {
    constructor() {
        this.currentCycle = 1;
        this.currentQuadrant = 1;
        this.periods = [
            'Preparation',
            'Work',
            'Pre-meal',
            'Meal',
            'Post-meal',
            'Downtime',
            'Rest'
        ];
        this.currentPeriodIndex = 0;

        this.isRunning = true; // Control quitting

        // Store choices for each quadrant
        this.preparationChoice = null;
        this.preMealNumber = null;
        this.postMealChoice = null;

        // Inmate stats
        this.inmate = {
            morale: 100,
            stamina: 100,
            sentenceCredit: 150000,
            creditEarned: 0,
            pcho: 40,

            lastWorkCredit: 0,
            lastDowntimeCredit: 0,  // for now always 0
            quadrantCredit: 0,
            cycleCredit: 0
        };

        this.interactionCounter = 2;
    }

    start() {
        console.clear();
        console.log('Simulation started.');
        this.showStatus();
        this.runCurrentPeriod();
    }

    showStatus() {
        const period = this.periods[this.currentPeriodIndex];
        console.log(
            `\nCycle ${this.currentCycle} - Quadrant ${this.currentQuadrant} - ${period}`
        );
    }

    showInmateStats() {
        const percent = ((this.inmate.creditEarned / this.inmate.sentenceCredit) * 100).toFixed(2);
        console.log(
            `Morale: ${this.inmate.morale} / 150\n` +
            `Stamina: ${this.inmate.stamina} / 150\n` +
            `Credit Earned: ${this.inmate.creditEarned}\n` +
            `Sentence Credit: ${this.inmate.sentenceCredit}\n` +
            `% of Sentence Credit Earned: ${percent}%\n` +
            `PCHO: ${this.inmate.pcho}`
        );
    }

    runCurrentPeriod() {
        if (!this.isRunning) return;

        const period = this.periods[this.currentPeriodIndex];

        switch (period) {
            case 'Preparation':
                this.handlePreparation();
                break;
            case 'Work':
                this.handleWork();
                break;
            case 'Pre-meal':
                this.handlePreMeal();
                break;
            case 'Meal':
                this.handleMeal();
                break;
            case 'Post-meal':
                this.handlePostMeal();
                break;
            case 'Downtime':
                this.handleDowntime();
                break;
            case 'Rest':
                this.handleRest();
                break;
            default:
                console.log('Unknown period.');
                break;
        }
    }

    // ----- Player input periods -----
    handlePreparation() {
        this.showInmateStats();
        let input = prompt('Preparation period.\nWork?\n1. Yes\n2. No\n(Press Enter for default "Yes", type "q" to quit)');

        if (input === 'q') return this.quit();

        // Default to Yes if input is empty
        if (input === null || input.trim() === '') {
            input = '1';
        }

        this.preparationChoice = input === '1' ? 'Yes' : 'No';
        this.advancePeriod();
    }

    handlePreMeal() {
        this.showInmateStats();

        let input = prompt(
            'Pre-meal period.\nHow much PCHO should be given?\nEnter an integer from 0 to 15\n(Press Enter for default 10, type "q" to quit)'
        );

        if (input === 'q') return this.quit();

        // If input is empty, default to 100
        if (input === null || input.trim() === '') {
            input = '10';
        }

        let number = Number(input);
        // Clamp between 0 and 15
        this.preMealNumber = Math.max(0, Math.min(15, number, this.inmate.pcho));

        this.advancePeriod();
    }

    handlePostMeal() {
        this.showInmateStats();

        let input = prompt(
            'Post-meal period.\nWork during downtime?\n1. Yes\n2. No\n(Press Enter for default "No", type "q" to quit)'
        );

        if (input === 'q') return this.quit();

        // Default to "No" if input is empty
        if (input === null || input.trim() === '') {
            input = '2';
        }

        this.postMealChoice = input === '1' ? 'Yes' : 'No';
        this.advancePeriod();
    }


    handleDowntime() {
        console.log(`Downtime period: Your Post-meal choice was "${this.postMealChoice}".`);

        if (this.postMealChoice === 'Yes') {
            if (this.interactionCounter <= 0) {
                console.log('No more interactions possible this cycle. Treated as "No".');
                this.postMealChoice = 'No';
                this.inmate.lastDowntimeCredit = 0;
            } else {
                if (this.inmate.morale < 10) {
                    console.log('Inmate cannot work due to abysmal morale.');
                    this.postMealChoice = 'No';
                    this.inmate.lastDowntimeCredit = 0;
                } else if (this.inmate.stamina <= 0) {
                    console.log('Inmate cannot work due to abysmal stamina.');
                    this.postMealChoice = 'No';
                    this.inmate.lastDowntimeCredit = 0;
                } else {
                    this.interactionCounter--;
                    console.log(`Interaction used. Remaining interactions: ${this.interactionCounter}`);
                    this.inmate.morale = this.inmate.morale - 10;
                    console.log(`Morale reduced by 10 due to working during downtime. Inmate morale is now at ${this.inmate.morale}.`);

                    const { staminaLeft, workCreditEarned, bracketPoints, bracketCredits, totalDeduct, } =
                        this.calculateCreditEarned({
                            maxDeduct: 20,
                            inmateCurrentStamina: this.inmate.stamina,
                            inmateCurrentMorale: this.inmate.morale,
                        });

                    // Update inmate stats
                    this.inmate.stamina = Math.max(0, staminaLeft);
                    this.inmate.creditEarned += workCreditEarned;
                    this.inmate.lastDowntimeCredit = workCreditEarned;
                    this.inmate.quadrantCredit += workCreditEarned;
                    this.inmate.cycleCredit += workCreditEarned;

                    console.log('--- Downtime Credits by Stamina Bracket ---');
                    console.log(`High (>=50)   - Points: ${bracketPoints.high}, Credits: ${bracketCredits.high}`);
                    console.log(`Mid (20-49)  - Points: ${bracketPoints.mid}, Credits: ${bracketCredits.mid}`);
                    console.log(`Low (0-19)   - Points: ${bracketPoints.low}, Credits: ${bracketCredits.low}`);

                    console.log(`Downtime is over! Total stamina deducted: ${totalDeduct}`);
                    console.log(`Total Credits earned this downtime period: ${workCreditEarned}`);
                    console.log(`Total Credits Earned this Quadrant: ${this.inmate.creditEarned}`);
                    console.log(`Remaining Stamina: ${this.inmate.stamina}`);
                }
            }
        } else {
            console.log('No work performed. No stamina, morale, or credit change.');
            this.inmate.lastDowntimeCredit = 0;
        }

        this.advancePeriod();
    }

    handleWork() {
        console.log(`Work period: Your Preparation choice was "${this.preparationChoice}".`);

        if (this.inmate.stamina <= 0) {
            console.log('Inmate cannot work due to abysmal stamina.');
            this.preparationChoice = 'No';
        }

        if (this.preparationChoice !== 'Yes') {
            console.log('No work performed. No stamina, morale, or credit change.');
            this.inmate.lastWorkCredit = 0;
            this.advancePeriod();
            return;
        }

        const { staminaLeft, workCreditEarned, bracketPoints, bracketCredits, totalDeduct, } =
            this.calculateCreditEarned({
                maxDeduct: 80,
                inmateCurrentStamina: this.inmate.stamina,
                inmateCurrentMorale: this.inmate.morale,
            });

        // Update inmate stats
        this.inmate.stamina = Math.max(0, staminaLeft);
        this.inmate.creditEarned += workCreditEarned;
        this.inmate.lastWorkCredit = workCreditEarned;
        this.inmate.quadrantCredit += workCreditEarned;
        this.inmate.cycleCredit += workCreditEarned;

        // Log summary by bracket
        console.log('--- Work Credits by Stamina Bracket ---');
        console.log(`High (>=50)   - Points: ${bracketPoints.high}, Credits: ${bracketCredits.high}`);
        console.log(`Mid (20-49)  - Points: ${bracketPoints.mid}, Credits: ${bracketCredits.mid}`);
        console.log(`Low (0-19)   - Points: ${bracketPoints.low}, Credits: ${bracketCredits.low}`);

        console.log(`Work done! Total stamina deducted: ${totalDeduct}`);
        console.log(`Total Credits earned this work period: ${workCreditEarned}`);
        console.log(`Total Credits Earned this Quadrant: ${this.inmate.creditEarned}`);
        console.log(`Remaining Stamina: ${this.inmate.stamina}`);

        this.advancePeriod();
    }

    calculateCreditEarned(input) {
        const { inmateCurrentStamina, maxDeduct, inmateCurrentMorale, } = input;
        let workCreditEarned = 0;
        // Morale modifier
        let moraleBonus = 0;
        if (inmateCurrentMorale > 100) moraleBonus = 2;
        else if (inmateCurrentMorale < 50) moraleBonus = -1;

        // Track points & credits per stamina bracket
        let bracketPoints = { high: 0, mid: 0, low: 0 };
        let bracketCredits = { high: 0, mid: 0, low: 0 };

        // Calculate total stamina deduction (up to 80)
        let totalDeduct = Math.min(maxDeduct, inmateCurrentStamina);
        let staminaLeft = inmateCurrentStamina;
        // Calculate per-bracket deduction
        let remaining = totalDeduct;

        // High bracket (>= 50)
        if (staminaLeft > 50 && remaining > 0) {
            let points = Math.min(staminaLeft - 50, remaining);
            let credit = Math.floor(points * (10 + moraleBonus));
            bracketPoints.high = points;
            bracketCredits.high = credit;
            remaining -= points;
            workCreditEarned += credit;
            staminaLeft = staminaLeft - points;
        }

        // Mid bracket (20–49)
        if (staminaLeft > 20 && remaining > 0) {
            let start = Math.min(staminaLeft, 50);
            let points = Math.min(start - 20, remaining);
            let credit = Math.floor(points * (7 + moraleBonus));
            bracketPoints.mid = points;
            bracketCredits.mid = credit;
            remaining -= points;
            workCreditEarned += credit;
            staminaLeft = staminaLeft - points;
        }

        // Low bracket (0–19)
        if (staminaLeft > 0 && remaining > 0) {
            let start = Math.min(staminaLeft, 20);
            let points = Math.min(start, remaining);
            let credit = Math.floor(points * (3 + moraleBonus));
            bracketPoints.low = points;
            bracketCredits.low = credit;
            remaining -= points;
            workCreditEarned += credit;
            staminaLeft = staminaLeft - points;
        }

        return {
            staminaLeft, workCreditEarned,
            bracketPoints, bracketCredits, totalDeduct,
        };
    }

    handleMeal() {
        console.log(`Meal period: Your Pre-meal number was ${this.preMealNumber}.`);

        // Calculate changes
        const staminaGain = this.preMealNumber * 4;
        const moraleGain = this.preMealNumber - 10;

        // Log calculations
        console.log('--- Meal Effect Summary ---');
        console.log(`Stamina modified by meal: +${staminaGain}`);
        console.log(`Morale modified by meal: ${moraleGain >= 0 ? '+' : ''}${moraleGain}`);

        // Apply updates
        const newStamina = Math.min(150, this.inmate.stamina + staminaGain);
        const newMorale = Math.min(150, this.inmate.morale + moraleGain);

        console.log(`Stamina after meal: ${newStamina}`);
        console.log(`Morale after meal: ${newMorale}`);

        this.inmate.stamina = newStamina;
        this.inmate.morale = newMorale;
        this.inmate.pcho = this.inmate.pcho - this.preMealNumber;

        this.advancePeriod();
    }

    handleRest() {
        // --- Credit Summary ---
        console.log('--- Credit Summary ---');
        console.log(`Credit earned during Work: ${this.inmate.lastWorkCredit}`);
        console.log(`Credit earned during Downtime: ${this.inmate.lastDowntimeCredit}`);
        console.log(`Credit earned this Quadrant: ${this.inmate.quadrantCredit}`);
        console.log(`Credit earned this Cycle: ${this.inmate.cycleCredit}`);
        console.log(`Total Credit Earned: ${this.inmate.creditEarned}`);
        console.log(`Sentence Credit: ${this.inmate.sentenceCredit}`);
        const percent = ((this.inmate.creditEarned / this.inmate.sentenceCredit) * 100).toFixed(2);
        console.log(`% of Sentence Credit Earned: ${percent}%`);

        // --- Stats Summary ---
        console.log('--- Stats Summary ---');

        const staminaGain = Math.floor(this.preMealNumber * 4);
        const moraleGain = this.preMealNumber - 10;
        const moraleDrop = -5;

        console.log(`Stamina gain from resting: +${staminaGain}`);
        console.log(
            `Stamina after resting: ${Math.min(150, this.inmate.stamina + staminaGain)}`
        );

        console.log(`Morale modified by ration: ${moraleGain >= 0 ? '+' : ''}${moraleGain}`);
        console.log(`Morale drop due to being imprisoned: ${moraleDrop}`);
        // --- Morale bonus based on sentence completion ---
        let moraleBonus = 0;
        const percentNum = parseFloat(percent);
        if (percentNum >= 90) moraleBonus += 10;
        if (percentNum >= 80) moraleBonus += 5;
        if (percentNum >= 70) moraleBonus += 5;
        console.log(`Morale bonus for nearly complete sentence credit: +${moraleBonus}`);
        console.log(
            `Morale after resting: ${Math.min(150, this.inmate.morale + moraleGain + moraleDrop)}`
        );

        // Apply updates
        this.inmate.stamina = Math.min(150, this.inmate.stamina + staminaGain);
        this.inmate.morale = Math.min(150, this.inmate.morale + moraleGain + moraleDrop + moraleBonus);

        // Reset quadrant credit for next quadrant
        this.inmate.quadrantCredit = 0;

        this.advanceQuadrant();
    }

    // ----- Period / Quadrant / Cycle progression -----
    advancePeriod() {
        if (!this.isRunning) return;

        this.currentPeriodIndex++;
        if (this.currentPeriodIndex >= this.periods.length) {
            this.advanceQuadrant();
        } else {
            this.showStatus();
            this.runCurrentPeriod();
        }
    }

    advanceQuadrant() {
        if (!this.isRunning) return;

        this.currentQuadrant++;
        if (this.currentQuadrant > 4) {
            this.advanceCycle();
        } else {
            this.currentPeriodIndex = 0;
            console.log(`--- Moving to Quadrant ${this.currentQuadrant} ---`);
            this.showStatus();
            this.runCurrentPeriod();
        }
    }

    advanceCycle() {
        if (!this.isRunning) return;

        this.currentCycle++;
        this.currentQuadrant = 1;
        this.currentPeriodIndex = 0;
        this.inmate.cycleCredit = 0;
        this.inmate.pcho = this.inmate.pcho + 40;

        // Reset interaction counter each cycle
        this.interactionCounter = 2;

        console.log(`=== Starting Cycle ${this.currentCycle} ===`);
        this.showStatus();
        this.runCurrentPeriod();
    }

    quit() {
        this.isRunning = false;
        console.log('\nSimulation ended by user.');
    }
}
