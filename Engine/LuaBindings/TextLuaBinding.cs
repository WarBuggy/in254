using System;
using MoonSharp.Interpreter;
using Microsoft.Xna.Framework;
using AxiomPlayground.Scripting;
using AxiomPlayground.Scripting.LuaBindings;

namespace in254.Engine.LuaBindings
{
    public sealed class TextLuaBinding : LuaBindingBase
    {
        public override void Register(Script luaScript)
        {
            ArgumentNullException.ThrowIfNull(luaScript);

            Table textTable = new(luaScript);

            // Text.LoadFont(fontName, relativePath)
            // Loads a .ttf/.otf from the calling mod's folder.
            // e.g. Text.LoadFont("pixel", "Fonts/pixel.ttf")
            textTable["LoadFont"] = (Action<string, string>)((fontName, relativePath) =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                FontManager.Instance.LoadFont(fontName, modId, relativePath);
                SceneManager.Instance.TrackResource(modId, SceneManager.ResourceType.Font, fontName);
            });

            // Text.HasFont(fontName) → bool
            textTable["HasFont"] = (Func<string, bool>)(fontName =>
                FontManager.Instance.HasFont(fontName));

            luaScript.Globals["Text"] = textTable;
        }
    }
}
