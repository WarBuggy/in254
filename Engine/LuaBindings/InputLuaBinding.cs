using System;
using MoonSharp.Interpreter;
using AxiomPlayground.Scripting.LuaBindings;

namespace in254.Engine.LuaBindings
{
    public sealed class InputLuaBinding : LuaBindingBase
    {
        public override void Register(Script luaScript)
        {
            ArgumentNullException.ThrowIfNull(luaScript);

            Table inputTable = new(luaScript);

            // ========== Keyboard ==========
            // Input.IsKeyDown("space")    — held this frame
            // Input.IsKeyPressed("e")     — just pressed (edge: up→down)
            // Input.IsKeyReleased("e")    — just released (edge: down→up)
            inputTable["IsKeyDown"] = (Func<string, bool>)(key =>
                InputManager.Instance.IsKeyDown(key));
            inputTable["IsKeyPressed"] = (Func<string, bool>)(key =>
                InputManager.Instance.IsKeyPressed(key));
            inputTable["IsKeyReleased"] = (Func<string, bool>)(key =>
                InputManager.Instance.IsKeyReleased(key));

            // Input.GetNumberKeyPressed() → 0-9 or -1
            inputTable["GetNumberKeyPressed"] = (Func<int>)(() =>
                InputManager.Instance.GetNumberKeyPressed());

            // ========== Mouse Buttons ==========
            // Input.IsMouseDown("left")      — held
            // Input.IsMousePressed("left")    — just clicked
            // Input.IsMouseReleased("left")   — just released
            inputTable["IsMouseDown"] = (Func<string, bool>)(btn =>
                InputManager.Instance.IsMouseDown(btn));
            inputTable["IsMousePressed"] = (Func<string, bool>)(btn =>
                InputManager.Instance.IsMousePressed(btn));
            inputTable["IsMouseReleased"] = (Func<string, bool>)(btn =>
                InputManager.Instance.IsMouseReleased(btn));

            // ========== Mouse Position & Scroll ==========
            inputTable["MouseX"] = (Func<int>)(() =>
                InputManager.Instance.MouseX);
            inputTable["MouseY"] = (Func<int>)(() =>
                InputManager.Instance.MouseY);
            inputTable["ScrollDelta"] = (Func<int>)(() =>
                InputManager.Instance.ScrollDelta);

            luaScript.Globals["Input"] = inputTable;
        }
    }
}
