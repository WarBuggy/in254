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

            // Text.Draw(text, x, y)
            // Text.Draw(text, x, y, size)
            // Text.Draw(text, x, y, size, {r, g, b})
            // Text.Draw(text, x, y, size, {r, g, b, a})
            // Text.Draw(text, x, y, size, {r, g, b, a}, "fontName")
            textTable["Draw"] = (Action<string, DynValue, DynValue, DynValue, DynValue, DynValue>)(
                (text, xDyn, yDyn, sizeDyn, colorDyn, fontDyn) =>
            {
                float x = (float)(xDyn.IsNil() ? 0 : xDyn.Number);
                float y = (float)(yDyn.IsNil() ? 0 : yDyn.Number);
                int size = (int)(sizeDyn.IsNil() ? 16 : sizeDyn.Number);

                Color color = Color.White;
                if (colorDyn != null && colorDyn.Type == DataType.Table)
                {
                    var t = colorDyn.Table;
                    int r = (int)(t.Get(1).IsNil() ? 255 : t.Get(1).Number);
                    int g = (int)(t.Get(2).IsNil() ? 255 : t.Get(2).Number);
                    int b = (int)(t.Get(3).IsNil() ? 255 : t.Get(3).Number);
                    int a = (int)(t.Get(4).IsNil() ? 255 : t.Get(4).Number);
                    color = Color.FromNonPremultiplied(r, g, b, a);
                }

                string fontName = null;
                if (fontDyn != null && fontDyn.Type == DataType.String)
                    fontName = fontDyn.String;

                DrawManager.Instance.AddTextRequest(text, new Vector2(x, y), size, color, fontName);
            });

            luaScript.Globals["Text"] = textTable;
        }
    }
}
