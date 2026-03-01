using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using FontStashSharp;
using MoonSharp.Interpreter;
using AxiomPlayground.Scripting;
using AxiomPlayground.GameFlag;

namespace in254.Engine;

public sealed class ConsoleManager
{
    private static readonly ConsoleManager _instance = new();
    public static ConsoleManager Instance => _instance;

    private bool _isOpen;
    private string _inputBuffer = "";
    private int _cursorPos;

    private readonly List<ConsoleLine> _outputLines = [];
    private readonly List<string> _commandHistory = [];
    private int _historyIndex = -1;
    private string _savedInput = "";
    private int _scrollOffset; // 0 = bottom/newest

    private readonly Dictionary<string, ConsoleCommand> _registeredCommands =
        new(StringComparer.OrdinalIgnoreCase);

    private Texture2D _pixelTexture;
    private bool _isDebugMode;

    private float _cursorBlinkTimer;
    private bool _cursorVisible = true;
    private const float CursorBlinkRate = 0.5f;

    public bool IsOpen => _isOpen;

    private ConsoleManager() { }

    public void Initialize(GraphicsDevice graphicsDevice)
    {
        _pixelTexture = new Texture2D(graphicsDevice, 1, 1);
        _pixelTexture.SetData([Color.White]);

        _isDebugMode = GameFlagManager.IsSet(FrameworkGameFlag.Debug);

        RegisterBuiltInCommands();
    }

    private void RegisterBuiltInCommands()
    {
        RegisterCommand("help", "List all available commands", args =>
        {
            WriteLine("Available commands:", Color.Cyan);
            foreach (var kvp in _registeredCommands)
            {
                string debug = kvp.Value.IsDebugOnly ? " [debug]" : "";
                WriteLine($"  {kvp.Key} - {kvp.Value.Description}{debug}", Color.White);
            }
            if (_isDebugMode)
                WriteLine("  lua <code> - Execute Lua code [debug]", Color.White);
        });

        RegisterCommand("clear", "Clear console output", _ =>
        {
            _outputLines.Clear();
            _scrollOffset = 0;
        });

        RegisterCommand("history", "Show command history", _ =>
        {
            if (_commandHistory.Count == 0)
            {
                WriteLine("No command history.", Color.Gray);
                return;
            }
            for (int i = 0; i < _commandHistory.Count; i++)
                WriteLine($"  {i + 1}: {_commandHistory[i]}", Color.White);
        });
    }

    /// <summary>
    /// Returns true if the console consumed input this frame.
    /// </summary>
    public bool Update(float deltaTime)
    {
        var input = InputManager.Instance;

        // Toggle console
        if (input.IsKeyPressed(Keys.OemTilde))
        {
            _isOpen = !_isOpen;
            InputManager.Instance.ConsoleBlocksInput = _isOpen;
            if (_isOpen)
            {
                _historyIndex = -1;
                _savedInput = "";
            }
            // Drain any pending text input (the tilde character itself)
            input.GetAndClearTextInput();
            return true;
        }

        if (!_isOpen) return false;

        // Cursor blink
        _cursorBlinkTimer += deltaTime;
        if (_cursorBlinkTimer >= CursorBlinkRate)
        {
            _cursorBlinkTimer -= CursorBlinkRate;
            _cursorVisible = !_cursorVisible;
        }

        // Handle special keys
        if (input.IsKeyPressed(Keys.Escape))
        {
            _isOpen = false;
            InputManager.Instance.ConsoleBlocksInput = false;
            return true;
        }

        if (input.IsKeyPressed(Keys.Enter))
        {
            ExecuteInput();
            return true;
        }

        // History navigation
        if (input.IsKeyPressed(Keys.Up))
        {
            NavigateHistory(1);
            return true;
        }
        if (input.IsKeyPressed(Keys.Down))
        {
            NavigateHistory(-1);
            return true;
        }

        // Cursor movement
        if (input.IsKeyPressed(Keys.Left))
        {
            if (_cursorPos > 0) _cursorPos--;
            ResetCursorBlink();
            return true;
        }
        if (input.IsKeyPressed(Keys.Right))
        {
            if (_cursorPos < _inputBuffer.Length) _cursorPos++;
            ResetCursorBlink();
            return true;
        }
        if (input.IsKeyPressed(Keys.Home))
        {
            _cursorPos = 0;
            ResetCursorBlink();
            return true;
        }
        if (input.IsKeyPressed(Keys.End))
        {
            _cursorPos = _inputBuffer.Length;
            ResetCursorBlink();
            return true;
        }

        // Backspace
        if (input.IsKeyPressed(Keys.Back))
        {
            if (_cursorPos > 0)
            {
                _inputBuffer = _inputBuffer.Remove(_cursorPos - 1, 1);
                _cursorPos--;
                ResetCursorBlink();
            }
            return true;
        }

        // Delete
        if (input.IsKeyPressed(Keys.Delete))
        {
            if (_cursorPos < _inputBuffer.Length)
            {
                _inputBuffer = _inputBuffer.Remove(_cursorPos, 1);
                ResetCursorBlink();
            }
            return true;
        }

        // Ctrl+C → clear line
        if (input.IsKeyDown(Keys.LeftControl) && input.IsKeyPressed(Keys.C))
        {
            _inputBuffer = "";
            _cursorPos = 0;
            ResetCursorBlink();
            return true;
        }

        // Scroll output
        if (input.IsKeyPressed(Keys.PageUp))
        {
            _scrollOffset = Math.Min(_scrollOffset + 5, MaxScrollOffset());
            return true;
        }
        if (input.IsKeyPressed(Keys.PageDown))
        {
            _scrollOffset = Math.Max(_scrollOffset - 5, 0);
            return true;
        }
        int scroll = input.ScrollDelta;
        if (scroll != 0)
        {
            _scrollOffset = Math.Clamp(_scrollOffset + (scroll > 0 ? 3 : -3), 0, MaxScrollOffset());
        }

        // Text input from Window.TextInput event
        var chars = input.GetAndClearTextInput();
        foreach (char c in chars)
        {
            // Filter backtick/tilde and control chars
            if (c == '`' || c == '~' || char.IsControl(c))
                continue;

            _inputBuffer = _inputBuffer.Insert(_cursorPos, c.ToString());
            _cursorPos++;
            ResetCursorBlink();
        }

        return true;
    }

    private void ExecuteInput()
    {
        string command = _inputBuffer.Trim();
        _inputBuffer = "";
        _cursorPos = 0;
        _scrollOffset = 0;

        if (string.IsNullOrEmpty(command))
            return;

        // Add to history
        if (_commandHistory.Count == 0 || _commandHistory[^1] != command)
            _commandHistory.Add(command);
        _historyIndex = -1;

        // Echo
        WriteLine($"> {command}", Color.LightGray);

        // Debug lua execution
        if (_isDebugMode && command.StartsWith("lua ", StringComparison.OrdinalIgnoreCase))
        {
            string luaCode = command[4..];
            try
            {
                string result = ScriptManager.Instance.DoString(luaCode);
                if (result != null)
                    WriteLine(result, Color.LightGreen);
            }
            catch (Exception ex)
            {
                WriteLine($"Error: {ex.Message}", Color.Red);
            }
            return;
        }

        // Parse command name and args
        var parts = command.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        string cmdName = parts[0];
        string[] args = parts.Length > 1 ? parts[1..] : [];

        if (_registeredCommands.TryGetValue(cmdName, out var cmd))
        {
            try
            {
                cmd.Handler(args);
            }
            catch (Exception ex)
            {
                WriteLine($"Error executing '{cmdName}': {ex.Message}", Color.Red);
            }
        }
        else
        {
            WriteLine($"Unknown command: '{cmdName}'. Type 'help' for available commands.", Color.Red);
        }
    }

    private void NavigateHistory(int direction)
    {
        if (_commandHistory.Count == 0) return;

        if (_historyIndex == -1 && direction > 0)
        {
            _savedInput = _inputBuffer;
            _historyIndex = _commandHistory.Count - 1;
        }
        else
        {
            _historyIndex -= direction;
        }

        if (_historyIndex < 0)
        {
            _historyIndex = -1;
            _inputBuffer = _savedInput;
        }
        else if (_historyIndex >= _commandHistory.Count)
        {
            _historyIndex = _commandHistory.Count - 1;
        }

        if (_historyIndex >= 0)
            _inputBuffer = _commandHistory[_historyIndex];

        _cursorPos = _inputBuffer.Length;
        ResetCursorBlink();
    }

    private void ResetCursorBlink()
    {
        _cursorBlinkTimer = 0;
        _cursorVisible = true;
    }

    private int MaxScrollOffset()
    {
        return Math.Max(0, _outputLines.Count - 1);
    }

    // ========== Drawing ==========

    public void Draw(SpriteBatch spriteBatch, GraphicsDevice graphicsDevice)
    {
        if (!_isOpen || _pixelTexture == null) return;

        var viewport = graphicsDevice.Viewport;
        int consoleHeight = (int)(viewport.Height * 0.4f);
        var font = FontManager.Instance.GetFont(14);
        float lineHeight = font.MeasureString("A").Y + 2;

        // Background
        spriteBatch.Draw(_pixelTexture, new Rectangle(0, 0, viewport.Width, consoleHeight),
            new Color(0, 0, 0, 200));

        // Bottom separator line
        int separatorY = consoleHeight - (int)lineHeight - 6;
        spriteBatch.Draw(_pixelTexture, new Rectangle(0, separatorY, viewport.Width, 1), Color.Gray);

        // Input line
        string prompt = "> ";
        string inputDisplay = prompt + _inputBuffer;
        float inputY = separatorY + 3;
        font.DrawText(spriteBatch, inputDisplay, new Vector2(4, inputY), Color.White);

        // Blinking cursor
        if (_cursorVisible)
        {
            string beforeCursor = prompt + _inputBuffer[.._cursorPos];
            float cursorX = 4 + font.MeasureString(beforeCursor).X;
            spriteBatch.Draw(_pixelTexture, new Rectangle((int)cursorX, (int)inputY, 1, (int)lineHeight),
                Color.White);
        }

        // Output lines (rendered bottom-up from separator)
        int maxVisibleLines = (int)((separatorY - 4) / lineHeight);
        int startLine = _outputLines.Count - 1 - _scrollOffset;

        for (int i = 0; i < maxVisibleLines && startLine - i >= 0; i++)
        {
            var line = _outputLines[startLine - i];
            float y = separatorY - 4 - (i + 1) * lineHeight;
            if (y < 0) break;
            font.DrawText(spriteBatch, line.Text, new Vector2(4, y), line.Color);
        }

        // Scroll indicator
        if (_scrollOffset > 0)
        {
            string indicator = $"[Scrolled up {_scrollOffset} lines - PgDn to scroll down]";
            var indicatorSize = font.MeasureString(indicator);
            font.DrawText(spriteBatch, indicator,
                new Vector2(viewport.Width - indicatorSize.X - 4, 2), Color.Yellow);
        }
    }

    // ========== Command Registration ==========

    public void RegisterCommand(string name, string description, Action<string[]> handler, bool isDebugOnly = false)
    {
        _registeredCommands[name] = new ConsoleCommand
        {
            Description = description,
            Handler = handler,
            IsDebugOnly = isDebugOnly
        };
    }

    public void RegisterLuaCommand(string name, string description, Closure handler, string modId)
    {
        _registeredCommands[name] = new ConsoleCommand
        {
            Description = description,
            Handler = args =>
            {
                var dynArgs = new DynValue[args.Length];
                for (int i = 0; i < args.Length; i++)
                    dynArgs[i] = DynValue.NewString(args[i]);

                ScriptManager.Instance.CallWithModContext(modId, handler, dynArgs);
            },
            ModId = modId
        };
    }

    // ========== Output ==========

    public void WriteLine(string text)
    {
        _outputLines.Add(new ConsoleLine(text, Color.White));
    }

    public void WriteLine(string text, Color color)
    {
        _outputLines.Add(new ConsoleLine(text, color));
    }

    public void Clear()
    {
        _outputLines.Clear();
        _scrollOffset = 0;
    }

    // ========== Types ==========

    private sealed class ConsoleCommand
    {
        public required string Description { get; init; }
        public required Action<string[]> Handler { get; init; }
        public bool IsDebugOnly { get; init; }
        public string ModId { get; init; }
    }

    private readonly record struct ConsoleLine(string Text, Color Color);
}
