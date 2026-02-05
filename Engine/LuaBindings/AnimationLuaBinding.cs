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

        // BaseComponentFrom(modId, animationName)
        animationTable["BaseComponentFrom"] = (Func<string, string, DynValue>)((modId, animationName) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetBaseComponent(modId, animationName, out var baseComp))
                return DynValue.NewString(baseComp);

            return DynValue.Nil;
        });

        animationTable["ComponentsFrom"] = (Func<string, string, DynValue>)((modId, animationName) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetComponents(modId, animationName, out var components))
                return DynValue.FromObject(luaScript, components);

            return DynValue.Nil;
        });

        animationTable["DefaultStateFrom"] = (Func<string, string, string, DynValue>)((modId, animationName, componentName) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetDefaultState(modId, animationName, componentName, out var state))
                return DynValue.NewString(state);

            return DynValue.Nil;
        });

        animationTable["StatesFrom"] = (Func<string, string, string, DynValue>)((modId, animationName, componentName) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetStates(modId, animationName, componentName, out var states))
                return DynValue.FromObject(luaScript, states);

            return DynValue.Nil;
        });

        animationTable["FrameCountFrom"] = (Func<string, string, string, string, DynValue>)((modId, anim, comp, state) =>
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

        animationTable["FrameTextureIdFrom"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "TextureId", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameWidthFrom"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "Width", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameHeightFrom"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "Height", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameLayerFrom"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<string>(
                modId, anim, comp, state, frame, "Layer", out var value))
                return DynValue.NewString(value);

            return DynValue.Nil;
        });

        animationTable["FrameOffsetXFrom"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "OffsetX", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameOffsetYFrom"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "OffsetY", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameSpriteOffsetXFrom"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "SpriteOffsetX", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FrameSpriteOffsetYFrom"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<int>(
                modId, anim, comp, state, frame, "SpriteOffsetY", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["CurrentState"] = (Func<string, string, DynValue>)((animationName, componentName) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            string state = AnimationDataManager.Instance.GetCurrentState(modId, animationName, componentName);
            return DynValue.NewString(state);
        });

        // Get current state from a specific mod
        animationTable["CurrentStateFrom"] = (Func<string, string, string, DynValue>)((modId, animationName, componentName) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            string state = AnimationDataManager.Instance.GetCurrentState(modId, animationName, componentName);
            return DynValue.NewString(state);
        });

        // Set current state of a component
        animationTable["SetCurrentState"] = (Action<string, string, string>)((animationName, componentName, newState) =>
        {
            var actingModId = currentModId();
            var owningModId = actingModId;
            if (!string.IsNullOrWhiteSpace(actingModId))
                AnimationDataManager.Instance.SetCurrentState(owningModId, animationName, componentName, newState, actingModId);
        });

        // Set current state on a specific mod
        animationTable["SetCurrentStateTo"] = (Action<string, string, string, string>)((owningModId, animationName, componentName, newState) =>
        {
            var actingModId = currentModId();
            if (!string.IsNullOrWhiteSpace(owningModId))
                AnimationDataManager.Instance.SetCurrentState(owningModId, animationName, componentName, newState, actingModId);
        });

        // Get current frame index of a component state
        animationTable["CurrentFrame"] = (Func<string, string, string, DynValue>)((animationName, componentName, stateName) =>
        {
            var owningModId = currentModId();
            if (string.IsNullOrWhiteSpace(owningModId))
                return DynValue.Nil;

            int frame = AnimationDataManager.Instance.GetCurrentFrame(owningModId, animationName, componentName, stateName);
            return DynValue.NewNumber(frame);
        });

        // Get current frame from a specific mod
        animationTable["CurrentFrameFrom"] = (Func<string, string, string, string, DynValue>)((owningModId, animationName, componentName, stateName) =>
        {
            if (string.IsNullOrWhiteSpace(owningModId))
                return DynValue.Nil;

            int frame = AnimationDataManager.Instance.GetCurrentFrame(owningModId, animationName, componentName, stateName);
            return DynValue.NewNumber(frame);
        });

        // Set current frame index of a component state
        animationTable["SetCurrentFrame"] = (Action<string, string, string, int>)((animationName, componentName, stateName, frameIndex) =>
        {
            var actingModId = currentModId();
            var owningModId = actingModId;
            if (!string.IsNullOrWhiteSpace(actingModId))
                AnimationDataManager.Instance.SetCurrentFrame(owningModId, animationName, componentName, stateName, frameIndex, actingModId);
        });

        // Set current frame on a specific mod
        animationTable["SetCurrentFrameTo"] = (Action<string, string, string, string, int>)((owningModId, animationName, componentName, stateName, frameIndex) =>
        {
            var actingModId = currentModId();
            if (!string.IsNullOrWhiteSpace(owningModId))
                AnimationDataManager.Instance.SetCurrentFrame(owningModId, animationName, componentName, stateName, frameIndex, actingModId);
        });

        // Set FlipX for the current mod
        animationTable["SetFlipX"] = (Action<string, string, bool>)((animationName, componentName, value) =>
        {
            var actingModId = currentModId();
            if (!string.IsNullOrWhiteSpace(actingModId))
                AnimationDataManager.Instance.SetFlipX(actingModId, animationName, componentName, value, actingModId);
        });

        // Set FlipY for the current mod
        animationTable["SetFlipY"] = (Action<string, string, bool>)((animationName, componentName, value) =>
        {
            var actingModId = currentModId();
            if (!string.IsNullOrWhiteSpace(actingModId))
                AnimationDataManager.Instance.SetFlipY(actingModId, animationName, componentName, value, actingModId);
        });

        // Set FlipX for a specific owning mod
        animationTable["SetFlipXTo"] = (Action<string, string, string, bool>)((owningModId, animationName, componentName, value) =>
        {
            var actingModId = currentModId();
            if (!string.IsNullOrWhiteSpace(owningModId))
                AnimationDataManager.Instance.SetFlipX(owningModId, animationName, componentName, value, actingModId);
        });

        // Set FlipY for a specific owning mod
        animationTable["SetFlipYTo"] = (Action<string, string, string, bool>)((owningModId, animationName, componentName, value) =>
        {
            var actingModId = currentModId();
            if (!string.IsNullOrWhiteSpace(owningModId))
                AnimationDataManager.Instance.SetFlipY(owningModId, animationName, componentName, value, actingModId);
        });

        animationTable["FlipX"] = (Func<string, string, DynValue>)((animationName, componentName) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            bool flipX = AnimationDataManager.Instance.GetFlipX(modId, animationName, componentName);
            return DynValue.NewBoolean(flipX);
        });

        animationTable["FlipY"] = (Func<string, string, DynValue>)((animationName, componentName) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            bool flipY = AnimationDataManager.Instance.GetFlipY(modId, animationName, componentName);
            return DynValue.NewBoolean(flipY);
        });

        animationTable["FlipXFrom"] = (Func<string, string, string, DynValue>)((owningModId, animationName, componentName) =>
        {
            if (string.IsNullOrWhiteSpace(owningModId))
                return DynValue.Nil;

            bool flipX = AnimationDataManager.Instance.GetFlipX(owningModId, animationName, componentName);
            return DynValue.NewBoolean(flipX);
        });

        animationTable["FlipYFrom"] = (Func<string, string, string, DynValue>)((owningModId, animationName, componentName) =>
        {
            if (string.IsNullOrWhiteSpace(owningModId))
                return DynValue.Nil;

            bool flipY = AnimationDataManager.Instance.GetFlipY(owningModId, animationName, componentName);
            return DynValue.NewBoolean(flipY);
        });

        animationTable["FramePosX"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frame) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<float>(
                modId, anim, comp, state, frame, "PosX", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FramePosXFrom"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<float>(
                modId, anim, comp, state, frame, "PosX", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FramePosY"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frame) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<float>(
                modId, anim, comp, state, frame, "PosY", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["FramePosYFrom"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frame) =>
        {
            if (string.IsNullOrWhiteSpace(modId))
                return DynValue.Nil;

            if (AnimationDataManager.Instance.TryGetFrameProperty<float>(
                modId, anim, comp, state, frame, "PosY", out var value))
                return DynValue.NewNumber(value);

            return DynValue.Nil;
        });

        animationTable["SetFramePosX"] = (Action<string, string, string, int, float>)((anim, comp, state, frame, value) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return;

            AnimationDataManager.Instance.SetFramePosX(
                modId, anim, comp, state, frame, value, modId);
        });

        animationTable["SetFramePosY"] = (Action<string, string, string, int, float>)((anim, comp, state, frame, value) =>
        {
            var modId = currentModId();
            if (string.IsNullOrWhiteSpace(modId))
                return;

            AnimationDataManager.Instance.SetFramePosY(
                modId, anim, comp, state, frame, value, modId);
        });

        animationTable["SetFramePosXTo"] = (Action<string, string, string, string, int, float>)((owningModId, anim, comp, state, frame, value) =>
        {
            if (string.IsNullOrWhiteSpace(owningModId))
                return;

            var actingModId = currentModId();
            if (string.IsNullOrWhiteSpace(actingModId))
                return;

            AnimationDataManager.Instance.SetFramePosX(
                owningModId, anim, comp, state, frame, value, actingModId);
        });

        animationTable["SetFramePosYTo"] = (Action<string, string, string, string, int, float>)((owningModId, anim, comp, state, frame, value) =>
        {
            if (string.IsNullOrWhiteSpace(owningModId))
                return;

            var actingModId = currentModId();
            if (string.IsNullOrWhiteSpace(actingModId))
                return;

            AnimationDataManager.Instance.SetFramePosY(
                owningModId, anim, comp, state, frame, value, actingModId);
        });

        // animationTable["Frame"] = (Func<string, string, string, int, DynValue>)((anim, comp, state, frameIndex) =>
        // {
        //     var modId = currentModId();
        //     if (string.IsNullOrWhiteSpace(modId))
        //         return DynValue.Nil;

        //     return BuildFrameTable(modId, anim, comp, state, frameIndex);
        // });

        // animationTable["FrameFrom"] = (Func<string, string, string, string, int, DynValue>)((modId, anim, comp, state, frameIndex) =>
        // {
        //     if (string.IsNullOrWhiteSpace(modId))
        //         return DynValue.Nil;

        //     return BuildFrameTable(modId, anim, comp, state, frameIndex);
        // });

        // // Builds a Lua table containing all available frame properties
        // DynValue BuildFrameTable
        // (
        //     string modId,
        //     string anim,
        //     string comp,
        //     string state,
        //     int frameIndex
        // )
        // {
        //     var table = new Table(luaScript);
        //     bool found = false;

        //     void tryAdd<T>(string key)
        //     {
        //         if (key == "PosX")
        //         {
        //             Console.WriteLine();
        //         }
        //         if (AnimationDataManager.Instance.TryGetFrameProperty<T>(
        //             modId, anim, comp, state, frameIndex, key, out var value))
        //         {
        //             table[key] = DynValue.FromObject(luaScript, value);
        //             found = true;
        //             Console.WriteLine($"Build Frame Table: key {key}, value {value}");
        //         }
        //     }

        //     tryAdd<int>("TextureId");
        //     tryAdd<string>("Layer");
        //     tryAdd<int>("Width");
        //     tryAdd<int>("Height");
        //     tryAdd<int>("OffsetX");
        //     tryAdd<int>("OffsetY");
        //     tryAdd<int>("SpriteOffsetX");
        //     tryAdd<int>("SpriteOffsetY");
        //     tryAdd<int>("PosX");
        //     tryAdd<int>("PosY");

        //     return found ? DynValue.NewTable(table) : DynValue.Nil;
        // }

        luaScript.Globals["Animation"] = animationTable;
    }
}
