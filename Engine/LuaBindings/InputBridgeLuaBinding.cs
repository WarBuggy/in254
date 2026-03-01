using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework.Input;
using MoonSharp.Interpreter;
using AxiomPlayground.Scripting.LuaBindings;

namespace in254.Engine.LuaBindings;

/// <summary>
/// Bridges per-frame C# state (input, screen, timing) into a hidden Lua table
/// (Input._cache) once per frame. Lua-side wrappers in input.lua
/// transparently read from this table — zero interop crossings for high-frequency reads.
/// Keyboard keys auto-register on first use via the Lua wrappers.
/// </summary>
public sealed class InputBridgeLuaBinding : LuaBindingBase
{
    public static InputBridgeLuaBinding Instance { get; private set; }

    private Table _cache;

    // Watched keyboard keys — auto-registered by Lua wrappers, C# pushes state each frame
    private readonly List<(Keys key, string cacheKey)> _watchedDown = [];
    private readonly List<(Keys key, string cacheKey)> _watchedPressed = [];
    private readonly List<(Keys key, string cacheKey)> _watchedReleased = [];

    public override void Register(Script luaScript)
    {
        ArgumentNullException.ThrowIfNull(luaScript);
        Instance = this;
        _cache = new Table(luaScript);

        // Internal: called by input.lua on first key access (hidden from mods)
        _cache.Set("_WatchKey", DynValue.NewCallback((ctx, args) =>
        {
            string keyName = args[0].String;
            string mode = args.Count > 1 ? args[1].String : "down";
            WatchKey(keyName, mode);
            return DynValue.Nil;
        }));

        // Attach as hidden sub-table on Input (mods never see this directly)
        var inputTable = luaScript.Globals.Get("Input");
        if (inputTable.Type == DataType.Table)
            inputTable.Table.Set("_cache", DynValue.NewTable(_cache));
    }

    /// <summary>
    /// Register a keyboard key for per-frame pushing.
    /// Called internally by input.lua when a key is first queried.
    /// </summary>
    private void WatchKey(string keyName, string mode)
    {
        if (!InputManager.TryResolveKey(keyName, out var key))
            return;

        string cacheKey = mode switch
        {
            "pressed" => "kp_" + keyName,
            "released" => "kr_" + keyName,
            _ => "kd_" + keyName
        };

        var list = mode switch
        {
            "pressed" => _watchedPressed,
            "released" => _watchedReleased,
            _ => _watchedDown
        };

        // Avoid duplicates
        foreach (var (k, _) in list)
            if (k == key) return;

        list.Add((key, cacheKey));
    }

    /// <summary>
    /// Called once per frame from EngineManager.Update(), after InputManager.UpdateState().
    /// Writes all frequently-read state + watched keys into Input._cache.
    /// </summary>
    public void Push(float deltaTime, float totalTime)
    {
        var input = InputManager.Instance;

        // Mouse position
        _cache.Set("mouseX", DynValue.NewNumber(input.MouseX));
        _cache.Set("mouseY", DynValue.NewNumber(input.MouseY));

        // Mouse buttons (DynValue.True/False are cached singletons — zero alloc)
        _cache.Set("leftDown", DynValue.NewBoolean(
            input.IsMouseDown(InputManager.MouseButton.Left)));
        _cache.Set("leftPressed", DynValue.NewBoolean(
            input.IsMousePressed(InputManager.MouseButton.Left)));
        _cache.Set("leftReleased", DynValue.NewBoolean(
            input.IsMouseReleased(InputManager.MouseButton.Left)));
        _cache.Set("rightDown", DynValue.NewBoolean(
            input.IsMouseDown(InputManager.MouseButton.Right)));
        _cache.Set("rightPressed", DynValue.NewBoolean(
            input.IsMousePressed(InputManager.MouseButton.Right)));
        _cache.Set("rightReleased", DynValue.NewBoolean(
            input.IsMouseReleased(InputManager.MouseButton.Right)));
        _cache.Set("middleDown", DynValue.NewBoolean(
            input.IsMouseDown(InputManager.MouseButton.Middle)));
        _cache.Set("middlePressed", DynValue.NewBoolean(
            input.IsMousePressed(InputManager.MouseButton.Middle)));
        _cache.Set("middleReleased", DynValue.NewBoolean(
            input.IsMouseReleased(InputManager.MouseButton.Middle)));
        _cache.Set("x1Down", DynValue.NewBoolean(
            input.IsMouseDown(InputManager.MouseButton.X1)));
        _cache.Set("x1Pressed", DynValue.NewBoolean(
            input.IsMousePressed(InputManager.MouseButton.X1)));
        _cache.Set("x1Released", DynValue.NewBoolean(
            input.IsMouseReleased(InputManager.MouseButton.X1)));
        _cache.Set("x2Down", DynValue.NewBoolean(
            input.IsMouseDown(InputManager.MouseButton.X2)));
        _cache.Set("x2Pressed", DynValue.NewBoolean(
            input.IsMousePressed(InputManager.MouseButton.X2)));
        _cache.Set("x2Released", DynValue.NewBoolean(
            input.IsMouseReleased(InputManager.MouseButton.X2)));

        // Scroll
        _cache.Set("scrollDelta", DynValue.NewNumber(input.ScrollDelta));

        // Screen dimensions
        var viewport = EngineManager.Instance.GraphicsDevice.Viewport;
        _cache.Set("screenW", DynValue.NewNumber(viewport.Width));
        _cache.Set("screenH", DynValue.NewNumber(viewport.Height));

        // Number key (0-9 or -1)
        _cache.Set("numberKey", DynValue.NewNumber(input.GetNumberKeyPressed()));

        // Timing
        _cache.Set("dt", DynValue.NewNumber(deltaTime));
        _cache.Set("time", DynValue.NewNumber(totalTime));

        // Watched keyboard keys
        for (int i = 0; i < _watchedDown.Count; i++)
        {
            var (key, ck) = _watchedDown[i];
            _cache.Set(ck, DynValue.NewBoolean(input.IsKeyDown(key)));
        }
        for (int i = 0; i < _watchedPressed.Count; i++)
        {
            var (key, ck) = _watchedPressed[i];
            _cache.Set(ck, DynValue.NewBoolean(input.IsKeyPressed(key)));
        }
        for (int i = 0; i < _watchedReleased.Count; i++)
        {
            var (key, ck) = _watchedReleased[i];
            _cache.Set(ck, DynValue.NewBoolean(input.IsKeyReleased(key)));
        }
    }
}
