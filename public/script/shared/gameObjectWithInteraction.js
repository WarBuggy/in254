export class GameObjectWithInteraction extends GameClasses.GameObjectWithAnimation {
    constructor(input) {
        super(input);

        this.interactionList = [];

        const { interactionData, } = input;
        if (!interactionData) return;

        for (const interactionComp of interactionData.componentList) {
            const { name, interaction, } = interactionComp;
            const { offsetX, offsetY, width, height, } = interactionComp;
            if (!interaction) continue;
            const comp = this.componentList[name];
            if (!comp) {
                console.error('[GameObjectWithInteraction] ' +
                    taggedString.gameObjectWithInteractionCompNotFound(this.animatedObject, name));
                continue;
            }

            const interactionPoint = {
                offsetX: offsetX || 0,
                offsetY: offsetY || 0,
                width: width || comp.width,
                height: height || comp.height,
                comp, buttonList: interactionComp.interaction,
            };
            this.interactionList.push(interactionPoint);
        }
        this.interactableList = [];
    }

    postUpdate(input) {
        super.postUpdate(input);
        this.getInteractableList(input);
    }

    calculateInteractionBound(input) {
        const { comp, offsetX, offsetY, width, height, } = input;
        const x = (comp.x || 0) + offsetX;
        const right = x + width;
        const top = (comp.y || 0) + offsetY;
        const y = top + (height / 2);
        return { x, right, y, };
    }

    getInteractableList(input) {
        this.interactableList = [];
        if (!this.isVisible) {
            return;
        }
        const { player, } = input;
        if (player.interactWith) {
            return;
        }

        for (const interactionPoint of this.interactionList) {
            const { comp, offsetX, offsetY, width, height, } = interactionPoint;
            const { x, right, y, } =
                this.calculateInteractionBound({ comp, offsetX, offsetY, width, height, });
            if (x < player.interactionX && right > player.interactionX &&
                player.y < y && (player.y + player.height) > y) {
                this.interactableList.push(interactionPoint);
            }
        }
    }

    checkInput(input) {
        const { inputManager, colony, player, } = input;
        for (const interactionPoint of this.interactableList) {
            const { comp, } = interactionPoint;
            for (const button of interactionPoint.buttonList) {
                if (inputManager.isPressed({ key: button, })) {
                    this.handleInput({ comp, button, colony, player, });
                }
            }
        }
    }

    handleInput(input) {
        throw new Error('[GameObjectWithInteraction] ' +
            taggedString.gameObjectWithInteractionHandleInputNotImplemented(this.animatedObject));
    }
}