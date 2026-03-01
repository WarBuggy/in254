using System;
using Microsoft.Xna.Framework;
using MoonSharp.Interpreter;
using AxiomPlayground.Scripting;
using AxiomPlayground.Scripting.LuaBindings;

namespace in254.Engine.LuaBindings;

public sealed class ConsoleLuaBinding : LuaBindingBase
{
    public override void Register(Script luaScript)
    {
        ArgumentNullException.ThrowIfNull(luaScript);
        Table consoleTable = new(luaScript);

        consoleTable["Register"] = (Action<string, string, Closure>)((name, description, handler) =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            ConsoleManager.Instance.RegisterLuaCommand(name, description, handler, modId);
        });

        consoleTable["Write"] = (Action<string>)(text =>
        {
            ConsoleManager.Instance.WriteLine(text);
        });

        consoleTable["WriteColor"] = (Action<string, int, int, int, int>)((text, r, g, b, a) =>
        {
            ConsoleManager.Instance.WriteLine(text, new Color(r, g, b, a));
        });

        consoleTable["WriteError"] = (Action<string>)(text =>
        {
            ConsoleManager.Instance.WriteLine(text, Color.Red);
        });

        consoleTable["WriteWarning"] = (Action<string>)(text =>
        {
            ConsoleManager.Instance.WriteLine(text, Color.Yellow);
        });

        consoleTable["Clear"] = (Action)(() =>
        {
            ConsoleManager.Instance.Clear();
        });

        consoleTable["IsOpen"] = (Func<bool>)(() =>
        {
            return ConsoleManager.Instance.IsOpen;
        });

        luaScript.Globals["Console"] = consoleTable;
    }
}
