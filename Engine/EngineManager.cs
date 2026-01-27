using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Graphics;
using AxiomPlayground.Modding;
using AxiomPlayground.Data;
using AxiomPlayground.Scripting;
using in254.Engine.LuaBindings;

namespace in254.Engine;

public class EngineManager : Game
{
    private static readonly EngineManager _instance = new();
    public static EngineManager Instance => _instance;
    private GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch;
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

    }

    protected override void Update(GameTime gameTime)
    {
        var keyboard = Keyboard.GetState();

        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed ||
            keyboard.IsKeyDown(Keys.Escape))
            Exit();

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
