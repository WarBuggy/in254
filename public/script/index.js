window.addEventListener('load', async function () {
    window.scriptLoader = new ScriptLoader();
    const { modList, } = await window.scriptLoader.getModList({
        modDirLocation: Shared.MOD_STRING.MOD_DIR_LOCATION.BASE,
    });
    const { savedModData } = await window.scriptLoader.loadScriptMod({
        modList,
        modDirLocation: Shared.MOD_STRING.MOD_DIR_LOCATION.BASE,
    });
    GameClasses.MainApp.modifyClassProperty();
    window.gameManager = new GameClasses.GameManager({ savedModData, });
    await gameManager.loadAllSprite();
    gameManager.start();

    let seed = null;
    //seed = 609478887;
    //await window.editorMap.managerMap.generateRandomMap({ seed, });
    //window.editorMap.managerMap.requestAnimationFrame({});
    //window.sim = new GameClasses.Simulate();
});
