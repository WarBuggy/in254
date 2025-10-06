class ScriptLoader {
    static GameClasses = window.GameClasses = window.GameClasses || {};
    static modHooksSymbol = Symbol.for('modHooks');

    async getModList(input) {
        const { modDirLocation, } = input;
        const { modList, } = await ScriptLoader.parseModSettingXML({
            modDirLocation,
        });
        this.removeReservedNameFromModList({ modList, });
        this.addBaseModToModList({ modList, });
        return { modList, };
    }

    async loadScriptMod(input) {
        const { modList, modDirLocation } = input;
        const savedModData = [];
        for (let h = 0; h < modList.length; h++) {
            const modMetaData = modList[h];
            const modData = await ScriptLoader.parseModAboutXML({
                modDirLocation,
                dirName: modMetaData.dirName,
            });
            const dirPath = `${modDirLocation}${modMetaData.dirName}/`;
            for (let i = 0; i < modData.hooks.length; i++) {
                const modFile = modData.hooks[i];
                const modPath = `${dirPath}${modFile}`;
                if (modFile.toLowerCase().endsWith(".css")) {
                    ScriptLoader.importCSSLink({ modPath, modName: modData.name, });
                    continue;
                }
                await this.loadAScriptMod({
                    modPath,
                    modName: modData.name,
                    modFile,
                    savedModData,
                });
            }
        }
        return { savedModData, };
    }

    async loadAScriptMod(input) {
        const { modPath, modName, modFile, savedModData, } = input;
        try {
            const modModule = await import(modPath);
            const parent = this;
            // Check if default export is a function — method-hook mod
            if (typeof modModule.default === 'function') {
                await modModule.default({
                    register: (regObj) => {
                        switch (regObj.mode) {
                            case Shared.MOD_STRING.REGISTRATION_MODE.BEFORE:
                            case Shared.MOD_STRING.REGISTRATION_MODE.AFTER:
                            case Shared.MOD_STRING.REGISTRATION_MODE.REPLACE:
                                try {
                                    parent.registerMethodMod({ modName, hookInfo: regObj, });
                                    console.log(`[ScriptLoader] ${taggedString.scriptLoaderMethodHookLoaded(
                                        modName, modFile, regObj.className, regObj.methodName, regObj.mode)}`);
                                } catch (e) {
                                    console.error(`[ScriptLoader] ${taggedString.scriptLoaderMethodHookFailed(
                                        modName, modFile, e)}`);
                                }
                                break;

                            case Shared.MOD_STRING.REGISTRATION_MODE.NEW_METHOD:
                                try {
                                    parent.registerNewMethodMod(regObj);
                                    console.log(`[ScriptLoader] ${taggedString.scriptLoaderNewMethodLoaded(
                                        modName, modFile, regObj.className, regObj.methodName)}`);
                                } catch (e) {
                                    console.error(`[ScriptLoader] ${taggedString.scriptLoaderNewMethodFailed(
                                        modName, modFile, e)}`);
                                }
                                break;
                            default:
                                console.warn(`[ScriptLoader] ${taggedString.scriptLoaderUnknownMethodMod(
                                    modFile, modName, regObj.mode)}`);
                        }
                    },
                });
                return;
            }
            // Otherwise, expect named exports which are classes — new-class mod
            const exportedClassNames = Object.entries(modModule)
                .filter(([name, val]) =>
                    typeof val === "function" && /^\s*class\s/.test(val.toString())
                )
                .map(([name]) => name);

            if (exportedClassNames.length === 0) {
                const { validModData } = this.checkModDataStructure({ modName, modFile, modModule, });
                savedModData.push(...validModData);
            }
            // Register each exported class
            for (const className of exportedClassNames) {
                const cls = modModule[className];
                if (ScriptLoader.GameClasses[className]) {
                    console.warn(`[ScriptLoader] ${taggedString.scriptLoaderNewClassExists(modName, className)}`);
                }
                ScriptLoader.GameClasses[className] = cls;
                console.log(`[ScriptLoader] ${taggedString.scriptLoaderNewClassLoaded(modName, className)}`);
            }
        } catch (e) {
            console.error(`[ScriptLoader] ${taggedString.scriptLoaderUnexpectedScriptLoadFailed(modFile, modName, e)}`);
        }
    }

    checkModDataStructure(input) {
        const { modName, modFile, modModule, } = input;
        if (!modModule || typeof modModule !== "object" ||
            !modModule.default || !Array.isArray(modModule.default.modData)) {
            console.error(`[ScriptLoader] ${taggedString.scriptLoaderInvalidModDataStructure(modName, modFile)}`);
            return { validModData: [], };
        }

        const validModData = [];
        for (let i = 0; i < modModule.default.modData.length; i++) {
            try {
                const item = modModule.default.modData[i];
                // Check required properties
                if (!item || typeof item !== "object") {
                    throw new Error(`${taggedString.scriptLoaderInvalidModDataItemNotObject(i)}`);
                }
                // If all checks passed, include in validData
                validModData.push({ modName, item, });
            }
            catch (e) {
                console.error(`[ScriptLoader] ${taggedString.scriptLoaderBadModDataStructure(modName, modFile, e)}`);
            }
        }
        return { validModData, };
    }

    registerMethodMod(input) {
        const { hookInfo, modName, } = input;
        const { className, methodName, mode, handler, } = hookInfo;

        if (!className || !methodName || !mode || typeof handler !== "function") {
            throw new Error(taggedString.scriptLoaderMethodHookInvalidInfo());
        }

        const targetClass = ScriptLoader.GameClasses[className];
        if (!targetClass) {
            throw new Error(taggedString.scriptLoaderMethodHookNoClass(className));
        }

        // Detect static or instance method
        const isStatic = methodName in targetClass;
        const targetObject = isStatic ? targetClass : targetClass.prototype;

        if (!(methodName in targetObject)) {
            throw new Error(taggedString.scriptLoaderMethodHookNoMethod(methodName, className, isStatic));
        }

        // Initialize hook storage for this method if not exists
        targetObject[ScriptLoader.modHooksSymbol] = targetObject[ScriptLoader.modHooksSymbol] || {};
        if (!targetObject[ScriptLoader.modHooksSymbol][methodName]) {
            targetObject[ScriptLoader.modHooksSymbol][methodName] = {
                originalFunc: targetObject[methodName],
                beforeHooks: [],
                afterHooks: [],
                replaceHook: null
            };
        }

        const hookData = targetObject[ScriptLoader.modHooksSymbol][methodName];

        // Wrap handler to catch errors and log mod info
        const safeHandler = function (...args) {
            try {
                return handler.apply(this, args);
            } catch (e) {
                // Swallow error
                console.error(`[ScriptLoader] ${taggedString.scriptLoaderMethodHookErrorCode(
                    modName, mode, className, methodName, e)}`);
            }
        };

        // Register hooks by mode
        if (mode === Shared.MOD_STRING.REGISTRATION_MODE.BEFORE) {
            hookData.beforeHooks.unshift({ modName, handler: safeHandler });
        } else if (mode === Shared.MOD_STRING.REGISTRATION_MODE.AFTER) {
            hookData.afterHooks.push({ modName, handler: safeHandler });
        } else if (mode === Shared.MOD_STRING.REGISTRATION_MODE.REPLACE) {
            // Replace hook: discard previous replace hook
            hookData.replaceHook = { modName, handler: safeHandler };
        } else {
            throw new Error(taggedString.scriptLoaderMethodHookUnknownMode(mode));
        }

        // Rebuild the method with hooks in a separate helper
        this._rebuildHookedMethod({ targetObject, methodName, hookData, className, });
    }

    /**
     * Internal helper to rebuild the method with registered hooks.
     */
    _rebuildHookedMethod(input) {
        const { targetObject, methodName, hookData, className, } = input;
        targetObject[methodName] = function hookedMethod(...args) {
            const parent = this;

            // Run BEFORE hooks
            for (const { modName, handler } of hookData.beforeHooks) {
                try {
                    handler.call(parent, ...args);
                } catch (e) {
                    console.error(`[ScriptLoader] ${taggedString.scriptLoaderMethodHookBeforeError(
                        hookData.beforeHooks.modName, className, methodName, e)}`);
                }
            }

            // Call REPLACE or ORIGINAL
            let result;
            if (hookData.replaceHook) {
                try {
                    result = hookData.replaceHook.handler.call(parent, ...args);
                } catch (e) {
                    console.error(`[ScriptLoader] ${taggedString.scriptLoaderMethodHookReplaceError(
                        hookData.replaceHook.modName, className, methodName, e)}`);
                }
            } else {
                try {
                    result = hookData.originalFunc.apply(parent, args);
                } catch (e) {
                    console.error(`[ScriptLoader] ${taggedString.scriptLoaderMethodHookReplaceErrorOriginal(
                        className, methodName, e)}`);
                }
            }

            // Run AFTER hooks
            for (const { modName, handler } of hookData.afterHooks) {
                try {
                    handler.call(parent, ...args, result);
                } catch (e) {
                    console.error(`[ScriptLoader] ${taggedString.scriptLoaderMethodHookAfterError(
                        modName, className, methodName, e)}`);
                }
            }

            return result;
        };
    }

    registerNewMethodMod(input) {
        const { className, methodName, handler, isStatic = false } = input;

        // Validate required inputs
        if (!className || !methodName || typeof handler !== "function") {
            throw new Error(taggedString.scriptLoaderNewMethodInvalidInput());
        }
        // Find the target class
        const targetClass = ScriptLoader.GameClasses[className];
        if (!targetClass) {
            throw new Error(taggedString.scriptLoaderNewMethodInvalidClassName(className));
        }

        // Decide where to attach the method: static or instance
        const targetObject = isStatic ? targetClass : targetClass.prototype;

        // Prevent overwriting existing methods
        if (Object.prototype.hasOwnProperty.call(targetObject, methodName)) {
            throw new Error(taggedString.scriptLoaderNewMethodMethodExists(
                methodName, isStatic ? "static" : "instance", className));
        }

        try {
            // Add the new method
            targetObject[methodName] = handler;
            console.log(`[ScriptLoader] ${taggedString.scriptLoaderNewMethodAdded(
                isStatic ? "static" : "instance", methodName, className)}`);
        } catch (e) {
            throw new Error(taggedString.scriptLoaderNewMethodError(methodName, className, e));
        }
    }

    removeReservedNameFromModList(input) {
        const { modList, } = input;
        for (let i = modList.length - 1; i >= 0; i--) {
            const modName = modList[i].modName.toLowerCase().trim();
            if (Shared.MOD_STRING.RESERVED_MOD_NAME_LIST.includes(modName)) {
                modList.splice(i, 1);
                console.warn(`[ScriptLoader] ${taggedString.scriptLoaderReservedModNameFound(modName)}`);
            }
        }
    }

    addBaseModToModList(input) {
        const { modList, } = input;
        const baseMod = {
            modName: 'Base',
            dirName: '../public/script',
        };
        modList.unshift(baseMod);
    }

    /**
     * Parses a mod's `about.xml` file to extract metadata such as name,
     * version, author, and hooks, etc...
     *
     * @async
     * @param {string} input.modDirLocation - Base directory path where the mod is stored.
     * @param {string} input.dirName - The specific mod's folder name.
     * @returns {Object|null} - Parsed mod metadata if all fields are valid, otherwise null:
     *   @property {string} name - The name of the mod from the XML.
     *   @property {string} version - The version string of the mod.
     *   @property {string} author - The author or creator of the mod.
     *   @property {string[]} hooks - Array of hook identifiers extracted from XML.
     */
    static async parseModAboutXML(input) {
        const { modDirLocation, dirName, } = input;
        const filePath = `${modDirLocation}${dirName}/${Shared.MOD_STRING.ABOUT_XML.FILE_NAME}`;
        const response = await fetch(filePath);
        const text = await response.text();

        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(text, 'application/xml');

        const name = xmlDoc.querySelector(Shared.MOD_STRING.ABOUT_XML.NAME)?.textContent.trim() || null;
        const version = xmlDoc.querySelector(Shared.MOD_STRING.ABOUT_XML.VERSION)?.textContent.trim() || null;
        const author = xmlDoc.querySelector(Shared.MOD_STRING.ABOUT_XML.AUTHOR)?.textContent.trim() || null;
        const tagTransverseString = `${Shared.MOD_STRING.ABOUT_XML.HOOKS} > ${Shared.MOD_STRING.ABOUT_XML.HOOK}`;
        const hooks = [...xmlDoc.querySelectorAll(tagTransverseString)]
            .map(h => h.textContent.trim())
            .filter(h => h.length > 0); // Ignore empty hooks

        // If any field is missing or empty, return null
        if (!name || !version || !author || hooks.length === 0) {
            return null;
        }
        return { name, version, author, hooks, };
    }

    /**
     * Parses the mod settings XML file to extract a list of mod entries.
     * Fetches and parses the XML, then reads each <listEntry> for mod metadata.
     *
     * @async
     * @param {string} input.modDirLocation - Base directory path for the mod settings XML.
     * @returns {Object} - Parsed mod settings object containing:
     *   @property {Array<Object>} list - Array of mod entries:
     *     Each entry contains:
     *     @property {string} modName - The mod's name from the XML entry.
     *     @property {string} dirName - The directory name of the mod.
     */
    static async parseModSettingXML(input) {
        const { modDirLocation, } = input;
        // Fetch the XML file
        const filePath = `${modDirLocation}${Shared.MOD_STRING.SETTING_XML.FILE_NAME}`;
        const response = await fetch(filePath);
        const xmlText = await response.text();

        // Parse XML text into a DOM
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(xmlText, 'application/xml');

        // CONSIDER TO REMOVE
        // Grab <setting> content (could be empty string if no text inside)
        // const setting = xmlDoc.querySelector("mod > setting")?.textContent.trim() || "";

        // Grab <listEntry> items
        const tagTransverseString = `${Shared.MOD_STRING.BASE_TAG_NAME} > ${Shared.MOD_STRING.SETTING_XML.LIST} > ${Shared.MOD_STRING.SETTING_XML.LIST_ENTRY}`;
        const modList = [];
        const listEntries = xmlDoc.querySelectorAll(tagTransverseString);

        listEntries.forEach((entry, index) => {
            const modName = entry.querySelector(Shared.MOD_STRING.SETTING_XML.MOD_NAME)?.textContent.trim() || "";
            const dirName = entry.querySelector(Shared.MOD_STRING.SETTING_XML.DIR_NAME)?.textContent.trim() || "";

            if (!modName || !dirName) {
                console.error(`[ScriptLoader] ${window.taggedString.scriptLoaderInvalidModSettingListEntry(index)}`);
                return; // Skip this entry
            }

            modList.push({ modName, dirName });
        });

        // Return as JS object
        return { modList, };
    }

    static importCSSLink(input) {
        const { modPath, modName, } = input;
        try {
            const link = document.createElement('link');
            link.rel = 'stylesheet';
            link.href = modPath;
            document.head.appendChild(link);
            console.log(`[ScriptLoader] ${taggedString.scriptLoaderImportedCss(modPath, modName)}`);
        } catch (e) {
            console.error(`[ScriptLoader] ${taggedString.scriptLoaderImportedCssFailed(modPath, modName, e)}`);
        }
    }

    // Helper function: allows adding default properties to any existing class
    // Example usage: Person = addDefaultProperty(Person, "location", "Unknown");
    static addDefaultProperty(input) {
        const { ClassRef, propName, defaultValue, } = input;

        // Step 1: Keep track of all default properties added by mods
        // __defaults is an object stored on the class itself
        // Each key is a property name, value is the default value
        // If this is the first time a default is added, create the __defaults object
        if (!ClassRef.__defaults) {
            ClassRef.__defaults = {};
        }

        // Add or update the default for this property
        ClassRef.__defaults[propName] = defaultValue;

        // Step 2: Wrap the class constructor only once
        // We need to make sure that whenever someone creates a new instance (new ClassRef(...)),
        // the defaults are automatically assigned to the instance
        if (!ClassRef.__defaultsWrapped) {
            // Save the original class so we can extend it
            const OriginalClass = ClassRef;

            // Step 2a: Create a new class that extends the original
            // This is a "wrapper" class that adds default property behavior
            const Wrapped = class extends OriginalClass {
                constructor(...args) {
                    // Call the original constructor first to initialize original properties
                    super(...args);

                    // Step 2b: Assign all default properties to this instance
                    // Wrapped.__defaults contains all defaults added by mods
                    const defs = Wrapped.__defaults || {};

                    // Loop through each default property
                    for (const [key, value] of Object.entries(defs)) {
                        // Only assign the property if it doesn't already exist on this instance
                        if (!Object.prototype.hasOwnProperty.call(this, key)) {
                            // If the default value is a function, call it to compute the value
                            // Otherwise, just assign the value directly
                            this[key] = (typeof value === "function") ? value(this) : value;
                        }
                    }
                }
            };

            // Step 2c: Copy static members (like ClassRef.someStaticMethod) to the Wrapped class
            // We skip "prototype", "name", and "length" because they are special built-ins
            Object.getOwnPropertyNames(OriginalClass).forEach(name => {
                if (!["prototype", "name", "length"].includes(name)) {
                    Object.defineProperty(
                        Wrapped,
                        name,
                        Object.getOwnPropertyDescriptor(OriginalClass, name)
                    );
                }
            });

            // Step 2d: Store the defaults on the wrapped class too
            Wrapped.__defaults = ClassRef.__defaults;

            // Step 2e: Mark the class as wrapped so we don't wrap it again
            Wrapped.__defaultsWrapped = true;

            // Step 2f: Return the wrapped class
            // IMPORTANT: The caller must reassign the class reference
            // Example: Person = addDefaultProperty(Person, "location", "Unknown");
            return Wrapped;
        }

        // If the class was already wrapped, just return it
        return { ClassRef, };
    }
    /*
    Key Concepts for Beginners

        ClassRef – this is the reference to the class we’re modifying. It could be Person, Tile, or any other class.

        Extending a class – class Wrapped extends OriginalClass creates a new class that inherits everything from the original class.

        super(...args) – calls the original constructor to make sure all normal properties are set.

        Own properties – this[key] = value creates a property directly on the instance. These show up in JSON.stringify and Object.keys.

        Static members – methods like Person.someStaticMethod are not on the prototype. We copy them over so the wrapped class behaves exactly like the original.

        Wrapping once – __defaultsWrapped ensures we don’t wrap the same class multiple times, which would break inheritance.

        Why reassign the class – JavaScript doesn’t allow changing the constructor of a class after it’s defined, so we return a new wrapped class and ask the caller to replace the original reference.
    

    Drawbacks
        1️⃣ Must reassign the class reference
            Every time a mod calls addDefaultProperty, it returns a new wrapped class.
            You must reassign the class, e.g., Person = addDefaultProperty(Person, "location", "Unknown").
            Forgetting to reassign can break everything, because new instances won’t get defaults.

        2️⃣ Only future instances get defaults
            Instances created before wrapping do not receive the added properties automatically.
            You’d have to call setDefaults() manually on old instances if you want them updated.

        3️⃣ Slightly more memory usage per instance
            Defaults are copied to each instance as own properties.
            For very large objects or thousands of instances, this can use more memory than storing defaults on the prototype.

        4️⃣ Wrapping may confuse debugging
            Your wrapped class is technically a different class than the original.
            alice instanceof Person will still work, but the constructor is now a subclass, which can confuse stack traces or class comparisons in some tools.

        5️⃣ Static members have to be manually copied
            The code copies static properties, but some rare symbols or non-enumerable statics may not copy correctly.
            This is usually fine, but for very complex classes it can be a limitation.
        
        6️⃣ Order of mod loading matters
            If multiple mods add defaults, the latest mod overwrites the same property name in __defaults.
            So you need to be careful if two mods want different default values for the same property.

        7️⃣ Functions as defaults are evaluated once per instance
            If a default is a function, it’s called every time a new instance is created.
            That’s usually fine, but if the function has side effects, it could cause unexpected behavior.

        8️⃣ Prototype methods are not affected
            Only properties are automatically added.
            If a mod wants to add methods, they still need to modify ClassRef.prototype directly.
    */

    /**
     * Safely adds a new property to a class constructor.
     * Automatically assigns the property to all future instances.
     * Properties are own and enumerable, so they work with JSON.stringify and Object.keys.
     *
     * @param {class} ClassRef - The class to modify
     * @param {string} propName - Name of the property to add
     * @param {*} defaultValue - Default value, can also be a function for per-instance computation
     * @returns {class} - The wrapped class; caller must reassign the reference
     */
    static addConstructorProperty(input) {
        const { ClassRef, propName, defaultValue, } = input;
        // Initialize registry of added properties on the class
        if (!ClassRef.__constructorDefaults) {
            ClassRef.__constructorDefaults = {};
        }
        // Store or overwrite the property default
        ClassRef.__constructorDefaults[propName] = defaultValue;

        // Wrap the class constructor only once
        if (!ClassRef.__constructorWrapped) {
            const OriginalClass = ClassRef;

            const Wrapped = class extends OriginalClass {
                constructor(...args) {
                    super(...args);

                    // Assign all registered properties to this instance
                    const defs = Wrapped.__constructorDefaults || {};
                    for (const [key, value] of Object.entries(defs)) {
                        if (!Object.prototype.hasOwnProperty.call(this, key)) {
                            this[key] = (typeof value === "function") ? value(this) : value;
                        }
                    }
                }
            };

            // Copy static members
            Object.getOwnPropertyNames(OriginalClass).forEach(name => {
                if (!["prototype", "name", "length"].includes(name)) {
                    Object.defineProperty(
                        Wrapped,
                        name,
                        Object.getOwnPropertyDescriptor(OriginalClass, name)
                    );
                }
            });

            // Copy registry and mark as wrapped
            Wrapped.__constructorDefaults = ClassRef.__constructorDefaults;
            Wrapped.__constructorWrapped = true;

            return Wrapped;
        }

        // Already wrapped, just return the class
        return ClassRef;
    }
}