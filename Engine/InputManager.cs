using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace in254.Engine;

public sealed class InputManager
{
    private static readonly InputManager _instance = new();
    public static InputManager Instance => _instance;

    // Keyboard
    private KeyboardState _prevKeyboard;
    private KeyboardState _currKeyboard;

    // Mouse
    private MouseState _prevMouse;
    private MouseState _currMouse;

    // GamePad (player 1)
    private GamePadState _prevGamePad;
    private GamePadState _currGamePad;

    // Key name → Keys enum cache
    private static readonly Dictionary<string, Keys> _keyNameCache = new(StringComparer.OrdinalIgnoreCase);

    private InputManager() { }

    /// <summary>
    /// Call once per frame at the very start of Update(), before anything reads input.
    /// </summary>
    public void UpdateState()
    {
        _prevKeyboard = _currKeyboard;
        _prevMouse = _currMouse;
        _prevGamePad = _currGamePad;

        _currKeyboard = Keyboard.GetState();
        _currMouse = Mouse.GetState();
        _currGamePad = GamePad.GetState(PlayerIndex.One);
    }

    // ========== Keyboard ==========

    /// <summary>Held this frame.</summary>
    public bool IsKeyDown(Keys key) => _currKeyboard.IsKeyDown(key);

    /// <summary>Just pressed (down now, up last frame).</summary>
    public bool IsKeyPressed(Keys key) =>
        _currKeyboard.IsKeyDown(key) && !_prevKeyboard.IsKeyDown(key);

    /// <summary>Just released (up now, down last frame).</summary>
    public bool IsKeyReleased(Keys key) =>
        !_currKeyboard.IsKeyDown(key) && _prevKeyboard.IsKeyDown(key);

    /// <summary>String-based key lookup for Lua.</summary>
    public bool IsKeyDown(string keyName) => TryResolveKey(keyName, out var k) && IsKeyDown(k);
    public bool IsKeyPressed(string keyName) => TryResolveKey(keyName, out var k) && IsKeyPressed(k);
    public bool IsKeyReleased(string keyName) => TryResolveKey(keyName, out var k) && IsKeyReleased(k);

    /// <summary>Returns 0-9 if a number key was just pressed, or -1 if none.</summary>
    public int GetNumberKeyPressed()
    {
        if (IsKeyPressed(Keys.D1)) return 1;
        if (IsKeyPressed(Keys.D2)) return 2;
        if (IsKeyPressed(Keys.D3)) return 3;
        if (IsKeyPressed(Keys.D4)) return 4;
        if (IsKeyPressed(Keys.D5)) return 5;
        if (IsKeyPressed(Keys.D6)) return 6;
        if (IsKeyPressed(Keys.D7)) return 7;
        if (IsKeyPressed(Keys.D8)) return 8;
        if (IsKeyPressed(Keys.D9)) return 9;
        if (IsKeyPressed(Keys.D0)) return 0;
        return -1;
    }

    // ========== Mouse Buttons ==========

    public bool IsMouseDown(MouseButton button) => GetButtonState(_currMouse, button) == ButtonState.Pressed;

    public bool IsMousePressed(MouseButton button) =>
        GetButtonState(_currMouse, button) == ButtonState.Pressed &&
        GetButtonState(_prevMouse, button) == ButtonState.Released;

    public bool IsMouseReleased(MouseButton button) =>
        GetButtonState(_currMouse, button) == ButtonState.Released &&
        GetButtonState(_prevMouse, button) == ButtonState.Pressed;

    /// <summary>String-based mouse button lookup for Lua.</summary>
    public bool IsMouseDown(string button) => TryResolveMouseButton(button, out var b) && IsMouseDown(b);
    public bool IsMousePressed(string button) => TryResolveMouseButton(button, out var b) && IsMousePressed(b);
    public bool IsMouseReleased(string button) => TryResolveMouseButton(button, out var b) && IsMouseReleased(b);

    // ========== Mouse Position & Scroll ==========

    public int MouseX => _currMouse.X;
    public int MouseY => _currMouse.Y;
    public int ScrollDelta => _currMouse.ScrollWheelValue - _prevMouse.ScrollWheelValue;

    // ========== GamePad ==========

    public bool IsButtonDown(Buttons button) => _currGamePad.IsButtonDown(button);

    public bool IsButtonPressed(Buttons button) =>
        _currGamePad.IsButtonDown(button) && !_prevGamePad.IsButtonDown(button);

    public bool IsButtonReleased(Buttons button) =>
        !_currGamePad.IsButtonDown(button) && _prevGamePad.IsButtonDown(button);

    // ========== Raw State Accessors (for EngineManager action system) ==========

    public KeyboardState CurrentKeyboard => _currKeyboard;
    public MouseState CurrentMouse => _currMouse;
    public GamePadState CurrentGamePad => _currGamePad;

    // ========== Helpers ==========

    public enum MouseButton { Left, Right, Middle, X1, X2 }

    private static ButtonState GetButtonState(MouseState state, MouseButton button)
    {
        return button switch
        {
            MouseButton.Left => state.LeftButton,
            MouseButton.Right => state.RightButton,
            MouseButton.Middle => state.MiddleButton,
            MouseButton.X1 => state.XButton1,
            MouseButton.X2 => state.XButton2,
            _ => ButtonState.Released
        };
    }

    public static bool TryResolveKey(string keyName, out Keys key)
    {
        if (_keyNameCache.TryGetValue(keyName, out key))
            return true;

        if (Enum.TryParse(keyName, true, out key))
        {
            _keyNameCache[keyName] = key;
            return true;
        }

        // Common aliases
        key = keyName.ToLowerInvariant() switch
        {
            "enter" or "return" => Keys.Enter,
            "esc" or "escape" => Keys.Escape,
            "space" or "spacebar" => Keys.Space,
            "left" => Keys.Left,
            "right" => Keys.Right,
            "up" => Keys.Up,
            "down" => Keys.Down,
            "tab" => Keys.Tab,
            "backspace" or "back" => Keys.Back,
            "delete" or "del" => Keys.Delete,
            "shift" or "leftshift" => Keys.LeftShift,
            "ctrl" or "leftcontrol" => Keys.LeftControl,
            "alt" or "leftalt" => Keys.LeftAlt,
            _ => Keys.None
        };

        if (key != Keys.None)
        {
            _keyNameCache[keyName] = key;
            return true;
        }

        return false;
    }

    // ========== Console Text Input ==========

    private readonly List<char> _textInputBuffer = [];

    public bool ConsoleBlocksInput { get; set; }

    public void AccumulateTextInput(char c) => _textInputBuffer.Add(c);

    public List<char> GetAndClearTextInput()
    {
        var copy = new List<char>(_textInputBuffer);
        _textInputBuffer.Clear();
        return copy;
    }

    // ========== Mouse Button Resolution ==========

    private static bool TryResolveMouseButton(string name, out MouseButton button)
    {
        button = name.ToLowerInvariant() switch
        {
            "left" or "leftmouse" or "lmb" => MouseButton.Left,
            "right" or "rightmouse" or "rmb" => MouseButton.Right,
            "middle" or "middlemouse" or "mmb" => MouseButton.Middle,
            "x1" or "mouse4" or "back" or "xbutton1" => MouseButton.X1,
            "x2" or "mouse5" or "forward" or "xbutton2" => MouseButton.X2,
            _ => (MouseButton)(-1)
        };
        return (int)button >= 0;
    }
}
