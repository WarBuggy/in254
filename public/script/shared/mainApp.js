export class MainApp {
    constructor(input) {
        this.emitter = new window.GameClasses.EventEmitter();
        // allow mods to import data, or modify other mods' data if needed.
        this.modData = {};
        this.modHistory = {};
        this.modDataTree = null;
        this.loadModData({
            savedModData: input.savedModData,
            modData: this.modData,
            modHistory: this.modHistory,
        });
        this.overlay = new window.GameClasses.Overlay({ emitter: this.emitter, });
        this.createPageHTMLComponent();
        this.setupKeyBinding();
    }

    loadModData(input) {
        let { savedModData, modData, modHistory } = input;
        for (let i = 0; i < savedModData.length; i++) {
            const { modName, item } = savedModData[i];
            window.GameClasses.DataLoader.processModItem({ modName, item, modData, modHistory, });
        }
        // add each entry's name to its own payload
        for (const entries of Object.values(modData)) {
            for (const [name, data] of Object.entries(entries)) {
                data.name = name;
            }
        }
    }

    showModDataTree(input) {
        if (this.overlay.visible) return;
        if (!this.modDataTree) {
            this.modDataTree = new window.GameClasses.ModDataTree({
                modData: this.modData,
                modHistory: this.modHistory,
                overlay: this.overlay,
            });
            delete this.modHistory;
        }
        this.overlay.show({ divChild: this.modDataTree.divOuter, });
        this.modDataTree.onVisible();
    }

    createPageHTMLComponent(input) {
        throw new Error(`${taggedString.generalImplementInSubClass('createPageHTMLComponent')}`);
    }

    setupKeyBinding(input) {
        document.addEventListener('keydown', (e) => {
            // Check for Ctrl + Shift + P, open Mod Data Tree popup
            if (e.shiftKey && e.key.toLowerCase() === 'p') {
                e.preventDefault(); // prevent accidental browser behavior
                this.showModDataTree();
            }
        });
    }

    static modifyClassProperty(input) {
        // for modders
        // intentionally left empty 
    }
}