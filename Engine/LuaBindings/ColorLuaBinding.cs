using System;
using MoonSharp.Interpreter;
using Microsoft.Xna.Framework;
using AxiomPlayground.Scripting.LuaBindings;

namespace in254.Engine.LuaBindings
{
    public sealed class ColorLuaBinding : LuaBindingBase
    {
        public override void Register(Script luaScript)
        {
            ArgumentNullException.ThrowIfNull(luaScript);

            Table colorTable = new(luaScript);

            // Color.New(r, g, b [, a]) → packed integer
            colorTable["New"] = (Func<int, int, int, DynValue, int>)((r, g, b, aDyn) =>
            {
                r = Math.Clamp(r, 0, 255);
                g = Math.Clamp(g, 0, 255);
                b = Math.Clamp(b, 0, 255);
                int a = aDyn.IsNil() ? 255 : Math.Clamp((int)aDyn.Number, 0, 255);
                return (a << 24) | (r << 16) | (g << 8) | b;
            });

            luaScript.Globals["Color"] = colorTable;
        }

        /// <summary>
        /// Unpacks a packed ARGB integer into an XNA Color.
        /// </summary>
        public static Color ToColor(int packed)
        {
            int a = (packed >> 24) & 0xFF;
            int r = (packed >> 16) & 0xFF;
            int g = (packed >> 8) & 0xFF;
            int b = packed & 0xFF;
            // If no alpha was packed (old RGB-only format), default to opaque
            if (a == 0 && packed != 0) a = 255;
            return Color.FromNonPremultiplied(r, g, b, a);
        }
    }
}
