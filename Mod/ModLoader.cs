using System;
using System.IO;
using MoonSharp.Interpreter;
using System.Collections.Generic;

namespace in254.Mod;

public class ModLoader
{
    private readonly string _modsRoot;

    // Store Script objects per mod
    private readonly Dictionary<string, Script> _modScripts = new(StringComparer.OrdinalIgnoreCase);

    // Global reference for automatic hook calls
    public static ModLoader Instance { get; private set; } = null!;

    public ModLoader(string modsRoot)
    {
        _modsRoot = modsRoot;
        Instance = this;
        UserData.RegisterType<ModContext>();
    }

    public void LoadMods()
    {
        if (!Directory.Exists(_modsRoot))
        {
            Console.WriteLine($"Mods folder not found: {_modsRoot}");
            return;
        }

        foreach (var modDir in Directory.GetDirectories(_modsRoot))
        {
            string modName = Path.GetFileName(modDir);
            var modCtx = ModContextManager.Instance.ForMod(modName);

            Console.WriteLine($"Loading mod '{modName}'...");

            Script lua = new Script();
            _modScripts[modName] = lua;

            lua.Globals["ctx"] = modCtx;

            foreach (var luaFile in Directory.GetFiles(modDir, "*.lua"))
            {
                Console.WriteLine($"  Loading script: {Path.GetFileName(luaFile)}");
                lua.DoFile(luaFile);
            }
        }
    }

    public void CallHook(string hookName, params object[] args)
    {
        foreach (var kvp in _modScripts)
        {
            var lua = kvp.Value;
            var modCtx = ModContextManager.Instance.GetMod(kvp.Key);

            lua.Globals["ctx"] = modCtx;

            DynValue func = lua.Globals.Get(hookName);
            if (func.Type == DataType.Function)
            {
                try
                {
                    lua.Call(func, args);
                }
                catch (ScriptRuntimeException ex)
                {
                    Console.WriteLine($"[MOD ERROR] {kvp.Key} - {hookName}: {ex.Message}");
                }
            }
        }
    }

    public void CallHookAuto(string csharpMethodName, params object[] args)
    {
        // Construct the default Lua hook name: prefix with "On"
        string hookName = "On" + csharpMethodName;

        CallHook(hookName, args);
    }
}