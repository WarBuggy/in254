using System;
using AxiomPlayground.Scripting;
using AxiomPlayground.Scripting.LuaBindings;
using MoonSharp.Interpreter;

namespace in254.Engine.LuaBindings;

public sealed class AnimationLuaBinding : LuaBindingBase
{
    public override void Register(Script luaScript)
    {
        ArgumentNullException.ThrowIfNull(luaScript);

        // Helper to get current executing mod
        static string currentModId() => ScriptManager.Instance.CurrentExecutingModId;

        // Create a table in Lua for Animation
        Table animationTable = new(luaScript);

        animationTable["BaseComponent"] = (Func<string, DynValue>)(animationName =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetBaseComponent(modId, animationName, out var baseComp))
                return DynValue.NewString(baseComp);

            return DynValue.Nil;
        });

        animationTable["Components"] = (Func<string, DynValue>)(animationName =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetComponents(modId, animationName, out var components))
                return DynValue.FromObject(luaScript, components);

            return DynValue.Nil;
        });

        animationTable["DefaultState"] = (Func<string, string, DynValue>)((animationName, componentName) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetDefaultState(modId, animationName, componentName, out var state))
                return DynValue.NewString(state);

            return DynValue.Nil;
        });

        animationTable["States"] = (Func<string, string, DynValue>)((animationName, componentName) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetStates(modId, animationName, componentName, out var states))
                return DynValue.FromObject(luaScript, states);

            return DynValue.Nil;
        });

        animationTable["FrameCount"] = (Func<string, string, string, DynValue>)((animationName, componentName, stateName) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameCount(modId, animationName, componentName, stateName, out int? value))
                return DynValue.NewNumber((int)value);

            return DynValue.Nil;
        });

        // BaseComponentFor(modId, animationName)
        animationTable["BaseComponentFor"] = (Func<string, string, DynValue>)((modId, animationName) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetBaseComponent(modId, animationName, out var baseComp))
                return DynValue.NewString(baseComp);

            return DynValue.Nil;
        });

        animationTable["ComponentsFor"] = (Func<string, string, DynValue>)((modId, animationName) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetComponents(modId, animationName, out var components))
                return DynValue.FromObject(luaScript, components);

            return DynValue.Nil;
        });

        animationTable["DefaultStateFor"] = (Func<string, string, string, DynValue>)((modId, animationName, componentName) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetDefaultState(modId, animationName, componentName, out var state))
                return DynValue.NewString(state);

            return DynValue.Nil;
        });

        animationTable["StatesFor"] = (Func<string, string, string, DynValue>)((modId, animationName, componentName) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetStates(modId, animationName, componentName, out var states))
                return DynValue.FromObject(luaScript, states);

            return DynValue.Nil;
        });

        animationTable["FrameCountFor"] = (Func<string, string, string, string, DynValue>)((modId, anim, comp, state) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameCount(modId, anim, comp, state, out int? value))
                return DynValue.NewNumber((int)value);

            return DynValue.Nil;
        });

        animationTable["FrameTextureId"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frame) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "TextureId", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameWidth"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frame) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "Width", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameHeight"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frame) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "Height", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameLayer"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frame) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<string>(
                modId, anim, comp, state, frame, "Layer", out var value))
                return DynValue.NewString(value);

            return DynValue.Nil;
        });

        animationTable["FrameOffsetX"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frame) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "OffsetX", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameOffsetY"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frame) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "OffsetY", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameSpriteOffsetX"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frame) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "SpriteOffsetX", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameSpriteOffsetY"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frame) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "SpriteOffsetY", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameTextureIdFor"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "TextureId", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameWidthFor"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "Width", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameHeightFor"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "Height", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameLayerFor"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<string>(
                modId, anim, comp, state, frame, "Layer", out var value))
                return DynValue.NewString(value);

            return DynValue.Nil;
        });

        animationTable["FrameOffsetXFor"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "OffsetX", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameOffsetYFor"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "OffsetY", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameSpriteOffsetXFor"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "SpriteOffsetX", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameSpriteOffsetYFor"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "SpriteOffsetY", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });


        animationTable["Frame"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frameIndex) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            return BuildFrameTable(modId, anim, comp, state, frameIndex);
        });


        animationTable["FrameFor"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frameIndex) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            return BuildFrameTable(modId, anim, comp, state, frameIndex);
        });

        // Builds a Lua table containing all available frame properties
        DynValue BuildFrameTable
        (
            string modId,
            string anim,
            string comp,
            string state,
            int frameIndex
        )
        {
            var table = new Table(luaScript);
            bool found = false;

            void tryAdd<T>(string key)
            {
                if (AnimationDataManager.Instance.TryGetFrameProperty<T>(
                    modId, anim, comp, state, frameIndex, key, out var value))
                {
                    table[key] = DynValue.FromObject(luaScript, value);
                    found = true;
                }
            }

            tryAdd<int>("TextureId");
            tryAdd<string>("Layer");
            tryAdd<int>("Width");
            tryAdd<int>("Height");
            tryAdd<int>("OffsetX");
            tryAdd<int>("OffsetY");
            tryAdd<int>("SpriteOffsetX");
            tryAdd<int>("SpriteOffsetY");

            return found ? DynValue.NewTable(table) : DynValue.Nil;
        }

        luaScript.Globals["Animation"] = animationTable;
    }
}
