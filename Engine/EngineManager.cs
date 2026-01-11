using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Graphics;
using AxiomPlayground.Modding;
using AxiomPlayground.Data;
using AxiomPlayground.Localization;
using AxiomPlayground.Scripting;
using in254.Engine.LuaBindings;

namespace in254.Engine;

public class EngineManager : Game
{
    private static readonly EngineManager _instance = new();
    public static EngineManager Instance => _instance;
    private GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch;
    //private Dictionary<string, Animation.Animation> animations;
    private const float FrameDuration = 0.12f;

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

        DataManager.Instance.RegisterCategories(
                   [
                       LocalizationManager.Instance.CategoryName,
                AnimationDataManager.Instance.CategoryName,
            ]);
        DataManager.Instance.LoadAll(ModManager.Instance.FinalModList);

        LocalizationManager.Instance.LoadAll(ModManager.Instance.FinalModList);
        AnimationDataManager.Instance.LoadAll(ModManager.Instance.FinalModList);
        // AnimationDataManager.Instance.DebugPrintAllAnimations();

        ScriptManager.Instance.LoadAll(ModManager.Instance.FinalModList);
        ScriptManager.Instance.ExecuteAllModsScripts();
    }

    protected override void Update(GameTime gameTime)
    {
        var keyboard = Keyboard.GetState();

        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed ||
            keyboard.IsKeyDown(Keys.Escape))
            Exit();

        // bool moving = false;

        // if (keyboard.IsKeyDown(Keys.D))
        // {
        //     _currentState = "moving";
        //     _facingLeft = false;
        //     moving = true;
        // }
        // else if (keyboard.IsKeyDown(Keys.A))
        // {
        //     _currentState = "moving";
        //     _facingLeft = true;
        //     moving = true;
        // }

        // if (!moving)
        // {
        //     _currentState = "idle";
        //     _frameIndex = 0;
        //     _animTimer = 0f;
        // }

        // // Advance animation
        // if (_currentState == "moving")
        // {
        //     _animTimer += (float)gameTime.ElapsedGameTime.TotalSeconds;

        //     if (_animTimer >= FrameDuration)
        //     {
        //         _animTimer -= FrameDuration;

        //         var frames = animations["player"]
        //             .Components["base"]
        //             .States[_currentState]
        //             .Frames;

        //         _frameIndex = (_frameIndex + 1) % frames.Length;
        //     }
        // }

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

        ScriptManager.Instance.Fire(GameEvents.OnDraw);
        DrawManager.Instance.RenderQueue(_spriteBatch);

        _spriteBatch.End();

        base.Draw(gameTime);
    }
}
