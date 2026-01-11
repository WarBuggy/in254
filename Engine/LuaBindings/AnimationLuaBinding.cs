using System;
using System.Collections.Generic;
using AxiomPlayground.Scripting;
using AxiomPlayground.Scripting.LuaBindings;
using MoonSharp.Interpreter;
using static in254.Engine.AnimationDataManager;

namespace in254.Engine.LuaBindings
{
    public sealed class AnimationLuaBinding : LuaBindingBase
    {
        // Cache Lua tables per mod
        private readonly Dictionary<string, Table> _luaAnimationCache = new(StringComparer.OrdinalIgnoreCase);

        public override void Register(Script luaScript)
        {
            ArgumentNullException.ThrowIfNull(luaScript);

            // Helper to get current executing mod
            static string currentModId() => ScriptManager.Instance.CurrentExecutingModId;

            // Create a table in Lua for Animation
            Table animTable = new(luaScript);

            // getAnimations() - current mod
            animTable["getAnimations"] = (Func<DynValue>)(() =>
            {
                var modId = currentModId();
                var animations = AnimationDataManager.Instance.GetAnimations(modId);
                return DynValue.NewTable(GetOrBuildLuaTable(luaScript, modId, animations));
            });

            // getAnimationsFrom(modId) - specific mod
            animTable["getAnimationsFrom"] = (Func<string, DynValue>)((modId) =>
            {
                var animations = AnimationDataManager.Instance.GetAnimations(modId);
                return DynValue.NewTable(GetOrBuildLuaTable(luaScript, modId, animations));
            });

            // getAnimation(animationName) - current mod
            animTable["getAnimation"] = (Func<string, DynValue>)((animationName) =>
            {
                var animation = AnimationDataManager.Instance.GetAnimation(currentModId(), animationName);
                return animation != null ? DynValue.NewTable(ToLuaTable(luaScript, animation)) : DynValue.Nil;
            });

            // getAnimationFrom(modId, animationName) - specific mod
            animTable["getAnimationFrom"] = (Func<string, string, DynValue>)((modId, animationName) =>
            {
                var animation = AnimationDataManager.Instance.GetAnimation(modId, animationName);
                return animation != null ? DynValue.NewTable(ToLuaTable(luaScript, animation)) : DynValue.Nil;
            });

            // Register the table globally under "Animation"
            luaScript.Globals["Animation"] = animTable;
        }

        /// <summary>
        /// Returns cached Lua table for all animations in a mod, or builds it if not cached.
        /// </summary>
        private Table GetOrBuildLuaTable(Script luaScript, string modId, Dictionary<string, Animation> animations)
        {
            if (_luaAnimationCache.TryGetValue(modId, out var cachedTable))
                return cachedTable;

            var table = ToLuaTable(luaScript, animations);
            _luaAnimationCache[modId] = table;
            return table;
        }

        private static Table ToLuaTable(Script script, Dictionary<string, Animation> animations)
        {
            var table = new Table(script);
            foreach (var kv in animations)
                table[kv.Key] = DynValue.NewTable(ToLuaTable(script, kv.Value));
            return table;
        }

        private static Table ToLuaTable(Script script, Animation animation)
        {
            var table = new Table(script)
            {
                ["name"] = animation.Name,
                ["baseComponent"] = animation.BaseComponent,
                ["components"] = ToLuaTable(script, animation.Components)
            };
            return table;
        }

        private static Table ToLuaTable(Script script, Dictionary<string, AnimationComponent> components)
        {
            var table = new Table(script);
            foreach (var kv in components)
                table[kv.Key] = DynValue.NewTable(ToLuaTable(script, kv.Value));
            return table;
        }

        private static Table ToLuaTable(Script script, AnimationComponent component)
        {
            var table = new Table(script)
            {
                ["name"] = component.Name,
                ["defaultState"] = component.DefaultState,
                ["states"] = ToLuaTable(script, component.States)
            };
            return table;
        }

        private static Table ToLuaTable(Script script, Dictionary<string, AnimationState> states)
        {
            var table = new Table(script);
            foreach (var kv in states)
                table[kv.Key] = DynValue.NewTable(ToLuaTable(script, kv.Value));
            return table;
        }

        private static Table ToLuaTable(Script script, AnimationState state)
        {
            var table = new Table(script);
            var frameArray = new Table(script);
            int i = 1;
            foreach (var frame in state.Frames)
                frameArray[i++] = DynValue.NewTable(ToLuaTable(script, frame));
            table["frames"] = frameArray;
            return table;
        }

        private static Table ToLuaTable(Script script, AnimationFrame frame)
        {
            var table = new Table(script)
            {
                ["textureId"] = frame.TextureId,
                ["layer"] = frame.Layer,
                ["width"] = frame.Width,
                ["height"] = frame.Height,
                ["offsetX"] = frame.OffsetX,
                ["offsetY"] = frame.OffsetY,
                ["spriteOffsetX"] = frame.SpriteOffsetX,
                ["spriteOffsetY"] = frame.SpriteOffsetY
            };
            return table;
        }
    }
}
