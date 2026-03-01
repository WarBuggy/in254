using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Graphics;
using AxiomPlayground.Modding;
using AxiomPlayground.Data;
using AxiomPlayground.Scripting;
using in254.Engine.LuaBindings;
using System.Collections.Generic;
using in254.Core;
using System;
using System.Linq;
using MoonSharp.Interpreter;

namespace in254.Engine;

public class EngineManager : Game
{
    private static readonly EngineManager _instance = new();
    public static EngineManager Instance => _instance;
    private GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch;
    private const float FrameDuration = 0.12f;

    private readonly Dictionary<string, ActionInput> _actionInputBindings = [];
    private Texture2D _errorPixelTexture;

    private EngineManager()
    {
        _graphics = new GraphicsDeviceManager(this);
        _graphics.PreferredBackBufferWidth = 1280;
        _graphics.PreferredBackBufferHeight = 800;
        Content.RootDirectory = "Content";
        IsMouseVisible = true;
        Window.AllowUserResizing = true;
    }

    protected override void Initialize()
    {
        // Reduce GC pauses during gameplay
        System.Runtime.GCSettings.LatencyMode = System.Runtime.GCLatencyMode.SustainedLowLatency;

        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        var managers = BaseManager.DiscoverManagers();

        DataManager.Instance.LoadAll(ModManager.Instance.FinalModList, managers);

        FontManager.Instance.Initialize();

        ConsoleManager.Instance.Initialize(GraphicsDevice);
        Window.TextInput += (_, e) => InputManager.Instance.AccumulateTextInput(e.Character);

        _errorPixelTexture = new Texture2D(GraphicsDevice, 1, 1);
        _errorPixelTexture.SetData([Color.White]);

        var queue = ScriptManager.Instance.LoadAll(ModManager.Instance.FinalModList);
        ScriptManager.Instance.ExecuteQueue(queue);

        try
        {
            ScriptManager.Instance.Fire(LuaGameEvents.OnDataInit, DynValue.Nil);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[EngineManager] Error during OnDataInit: {ex.Message}");
        }

        foreach (var manager in managers)
        {
            foreach (var dispatch in manager.CollectLoadEvents())
            {
                try
                {
                    var dynArgs = ScriptManager.Instance.BuildEventArgs(dispatch.Args);
                    ScriptManager.Instance.Fire(dispatch.EventName, dynArgs);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[EngineManager] Error during '{dispatch.EventName}': {ex.Message}");
                }
            }
        }

        BuildActionInputMap();
    }

    protected override void Update(GameTime gameTime)
    {
        // Snapshot input state for the frame — everything reads from InputManager after this
        InputManager.Instance.UpdateState();

        float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
        float totalTime = (float)gameTime.TotalGameTime.TotalSeconds;

        // Bridge C# state into Lua Frame table — zero-crossing reads for Lua
        InputBridgeLuaBinding.Instance?.Push(deltaTime, totalTime);
        bool consoleConsumed = ConsoleManager.Instance.Update(deltaTime);

        if (!consoleConsumed)
        {
            if (InputManager.Instance.IsButtonDown(Buttons.Back) ||
                InputManager.Instance.IsKeyDown(Keys.Escape))
            {
                Exit();
                return;
            }
            DataManager.Instance.SetData("Core", "gowi.list", new LedgerMap(), "Core");
            CreateActiveActionList();
        }

        SoundManager.Instance.Update();

        ScriptManager.Instance.TickEngineCore(deltaTime, totalTime);

        ScriptManager.Instance.Fire(
            LuaGameEvents.OnUpdate,
            DynValue.NewNumber(deltaTime),
            DynValue.NewNumber(totalTime)
        );

        SceneManager.Instance.FireSceneUpdates(
            DynValue.NewNumber(deltaTime),
            DynValue.NewNumber(totalTime)
        );

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.Black);

        ScriptManager.Instance.Fire(LuaGameEvents.OnDraw);
        SceneManager.Instance.FireSceneDraws();

        // Tile RT update + injection, then all game rendering
        TileRendererManager.Instance.UpdateAndInject(GraphicsDevice, _spriteBatch);
        DrawManager.Instance.Render(GraphicsDevice, _spriteBatch);

        // Overlays (error banner, console) — always on top
        _spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend,
            SamplerState.PointClamp, DepthStencilState.None, RasterizerState.CullCounterClockwise);
        DrawModErrorOverlay(_spriteBatch);
        ConsoleManager.Instance.Draw(_spriteBatch, GraphicsDevice);
        _spriteBatch.End();

        base.Draw(gameTime);
    }

    private void DrawModErrorOverlay(SpriteBatch spriteBatch)
    {
        var errors = ModErrorTracker.Instance.GetErrors();
        if (errors.Count == 0 || _errorPixelTexture == null) return;

        var font = FontManager.Instance.GetFont(12);
        float lineHeight = font.MeasureString("A").Y + 2;
        int padding = 6;
        var viewport = GraphicsDevice.Viewport;

        // Group by mod — show one line per errored mod (first error only)
        var erroredMods = ModErrorTracker.Instance.GetErroredModIds();
        int lineCount = erroredMods.Count + 1; // header + one per mod
        int bannerHeight = (int)(lineCount * lineHeight) + padding * 2;

        // Semi-transparent red banner at top
        spriteBatch.Draw(_errorPixelTexture,
            new Rectangle(0, 0, viewport.Width, bannerHeight),
            new Color(140, 20, 20, 200));

        float y = padding;
        font.DrawText(spriteBatch, $"[{erroredMods.Count} mod(s) disabled due to errors]",
            new Vector2(padding, y), Color.Yellow);
        y += lineHeight;

        foreach (var modId in erroredMods)
        {
            var firstError = errors.First(e => string.Equals(e.ModId, modId, StringComparison.OrdinalIgnoreCase));
            string msg = firstError.Message;
            // Truncate long messages
            int maxChars = (int)(viewport.Width / 7) - modId.Length - 10;
            if (maxChars > 0 && msg.Length > maxChars)
                msg = msg[..maxChars] + "...";

            font.DrawText(spriteBatch, $"  {modId}: [{firstError.Context}] {msg}",
                new Vector2(padding, y), Color.White);
            y += lineHeight;
        }
    }

    private void CreateActiveActionList()
    {
        var ledgerMap = new LedgerMap();
        var im = InputManager.Instance;

        foreach (var kvp in _actionInputBindings)
        {
            string action = kvp.Key;
            var input = kvp.Value;

            bool isActive = false;

            switch (input.DeviceType)
            {
                case InputDeviceType.Keyboard:
                    if (input.KeyboardKey.HasValue)
                        isActive = im.IsKeyDown(input.KeyboardKey.Value);
                    break;

                case InputDeviceType.Mouse:
                    if (input.MouseButton != null)
                    {
                        isActive = im.IsMouseDown(input.MouseButton);
                    }
                    break;

                case InputDeviceType.GamePad:
                    if (input.GamePadButton.HasValue)
                        isActive = im.IsButtonDown(input.GamePadButton.Value);
                    break;
            }

            if (isActive)
            {
                ledgerMap.Set(action, input.ModId, "Core");
            }
        }

        DataManager.Instance.SetData("Core", "actions.activeList", ledgerMap, "Core");
    }

    private void BuildActionInputMap()
    {
        if (!DataManager.Instance.TryGetData("Core", "actions.list", out var obj) || obj == null)
            throw new LocalizedErrorCore<InvalidOperationException>("system.actionManager.actionsListMissing");

        if (obj is not LedgerMap ledger)
            throw new LocalizedErrorCore<InvalidCastException>(
                "system.actionManager.actionsListWrongType",
                obj?.GetType().FullName ?? "null");

        foreach (var ledgerKey in ledger.Keys)
        {
            if (!ledger.TryGet(ledgerKey, out var ledgerValue))
                continue; // skip if somehow missing

            string action = ledgerKey;
            string modId = ledgerValue.ToString();

            if (!DefinitionManager.Instance.TryGetPayload(modId, action, "key", out var inputObj))
                throw new LocalizedErrorCore<InvalidOperationException>(
                    "system.actionManager.missingKeyForAction", action, modId);

            string inputBinding = (inputObj?.ToString() ?? "").Trim();

            var actionInput = new ActionInput
            {
                ModId = modId
            };

            // Try Keyboard
            if (Enum.TryParse(inputBinding, true, out Keys key))
            {
                actionInput.DeviceType = InputDeviceType.Keyboard;
                actionInput.KeyboardKey = key;
            }
            else
            {
                // Mouse buttons
                switch (inputBinding.ToLowerInvariant())
                {
                    case "leftmouse":
                        actionInput.DeviceType = InputDeviceType.Mouse;
                        actionInput.MouseButton = "Left";
                        break;
                    case "rightmouse":
                        actionInput.DeviceType = InputDeviceType.Mouse;
                        actionInput.MouseButton = "Right";
                        break;
                    case "middlemouse":
                        actionInput.DeviceType = InputDeviceType.Mouse;
                        actionInput.MouseButton = "Middle";
                        break;
                    default:
                        // Try GamePad buttons
                        if (Enum.TryParse<Buttons>(inputBinding, true, out var button))
                        {
                            actionInput.DeviceType = InputDeviceType.GamePad;
                            actionInput.GamePadButton = button;
                        }
                        else
                        {
                            throw new LocalizedErrorCore<InvalidOperationException>(
                                "system.actionManager.invalidInputBinding", action, modId);
                        }
                        break;
                }
            }

            _actionInputBindings[action] = actionInput;
        }
    }

    private enum InputDeviceType
    {
        Keyboard,
        Mouse,
        GamePad
    }

    private struct ActionInput
    {
        public InputDeviceType DeviceType;
        public Keys? KeyboardKey;
        public Buttons? GamePadButton;
        public string MouseButton; // "Left", "Right", "Middle"
        public string ModId;
    }

    private void PrintActionInputBindings()
    {
        Console.WriteLine("===== Action Input Bindings =====");

        foreach (var kvp in _actionInputBindings)
        {
            string action = kvp.Key;
            ActionInput input = kvp.Value;

            string deviceStr = input.DeviceType.ToString();
            string keyStr = input.KeyboardKey?.ToString() ?? "-";
            string mouseStr = input.MouseButton ?? "-";
            string gamepadStr = input.GamePadButton?.ToString() ?? "-";
            string modIdStr = input.ModId ?? "-";

            Console.WriteLine($"Action: {action}, ModId: {modIdStr}, Device: {deviceStr}, Keyboard: {keyStr}, Mouse: {mouseStr}, GamePad: {gamepadStr}");
        }

        Console.WriteLine("================================");
    }
}
