using MoonSharp.Interpreter;
using AxiomPlayground.Scripting.LuaBindings;
using System;
using in254.Core;

namespace in254.Engine.LuaBindings
{
    /// <summary>
    /// Exposes screen-related properties and functions to Lua scripts.
    /// </summary>
    public sealed class ScreenLuaBinding : LuaBindingBase
    {
        public override void Register(Script luaScript)
        {
            if (luaScript == null)
                throw new LocalizedErrorCore<ArgumentNullException>(""); // give me the localize key value pair 

            Table screenTable = new(luaScript);

            // Functions for dynamic access (useful if screen can resize)
            screenTable["GetScreenWidth"] = (Func<int>)(() =>
                EngineManager.Instance.GraphicsDevice.Viewport.Width);
            screenTable["GetScreenHeight"] = (Func<int>)(() =>
                EngineManager.Instance.GraphicsDevice.Viewport.Height);

            // Register the table globally under "Screen"
            luaScript.Globals["Screen"] = screenTable;
        }
    }
}
