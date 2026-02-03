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

    private EngineManager()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        IsMouseVisible = true;
    }

    protected override void Initialize()
    {
        // Initialize TextureManager with the game's ContentManager
        // TextureManager.Instance.Initialize(Content);
        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        var managers = BaseManager.DiscoverManagers();

        DataManager.Instance.LoadAll(ModManager.Instance.FinalModList, managers);

        var queue = ScriptManager.Instance.LoadAll(ModManager.Instance.FinalModList);
        ScriptManager.Instance.ExecuteQueue(queue);

        foreach (var manager in managers)
        {
            foreach (var dispatch in manager.CollectLoadEvents())
            {
                var dynArgs = ScriptManager.Instance.BuildEventArgs(dispatch.Args);
                ScriptManager.Instance.Fire(dispatch.EventName, dynArgs);
            }
        }

        BuildActionInputMap();
        PrintActionInputBindings();
    }

    protected override void Update(GameTime gameTime)
    {
        var keyboard = Keyboard.GetState();

        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed ||
            keyboard.IsKeyDown(Keys.Escape))
        {
            Exit();
            return;
        }

        CreateActiveActionList(Keyboard.GetState(), GamePad.GetState(0), Mouse.GetState());
        float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;
        float totalTime = (float)gameTime.TotalGameTime.TotalSeconds;

        ScriptManager.Instance.Fire(
            LuaGameEvents.OnUpdate,
            DynValue.NewNumber(deltaTime),
            DynValue.NewNumber(totalTime)
        );

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.Black);

        // Begin the sprite batch
        _spriteBatch.Begin(
            SpriteSortMode.Deferred,
            BlendState.AlphaBlend,
            SamplerState.PointClamp,
            DepthStencilState.None,
            RasterizerState.CullCounterClockwise
        );

        ScriptManager.Instance.Fire(LuaGameEvents.OnDraw);
        DrawManager.Instance.RenderQueue(_spriteBatch);

        _spriteBatch.End();

        base.Draw(gameTime);
    }

    private void CreateActiveActionList(
     KeyboardState keyboard,
     GamePadState gamePad,
     MouseState mouse
 )
    {
        var ledgerMap = new LedgerMap();

        foreach (var kvp in _actionInputBindings)
        {
            string action = kvp.Key;
            var input = kvp.Value;

            bool isActive = false;

            switch (input.DeviceType)
            {
                case InputDeviceType.Keyboard:
                    if (input.KeyboardKey.HasValue)
                        isActive = keyboard.IsKeyDown(input.KeyboardKey.Value);
                    break;

                case InputDeviceType.Mouse:
                    if (input.MouseButton != null)
                    {
                        switch (input.MouseButton)
                        {
                            case "Left":
                                isActive = mouse.LeftButton == ButtonState.Pressed;
                                break;
                            case "Right":
                                isActive = mouse.RightButton == ButtonState.Pressed;
                                break;
                            case "Middle":
                                isActive = mouse.MiddleButton == ButtonState.Pressed;
                                break;
                        }
                    }
                    break;

                case InputDeviceType.GamePad:
                    if (input.GamePadButton.HasValue)
                        isActive = gamePad.IsButtonDown(input.GamePadButton.Value);
                    break;
            }

            if (isActive)
            {
                // Set the ModId in the LedgerMap, actorId is "Core"
                ledgerMap.Set(action, input.ModId, "Core");
            }
        }

        // Save the LedgerMap instead of a Lua table
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
