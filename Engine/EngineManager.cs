using System;
using Microsoft.Xna.Framework;
using in254.Data;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Graphics;
using System.Collections.Generic;

namespace in254.Engine;

public class EngineManager : Game
{
    private GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch;
    private Dictionary<string, Animation.Animation> animations;
    private float _animTimer = 0f;
    private int _frameIndex = 0;
    private const float FrameDuration = 0.12f;
    private bool _facingLeft = false;
    private string _currentState = "idle";

    public EngineManager()
    {
        _graphics = new GraphicsDeviceManager(this);
        Content.RootDirectory = "Content";
        IsMouseVisible = true;
    }

    protected override void Initialize()
    {
        // Initialize TextureManager with the game's ContentManager
        TextureManager.Instance.Initialize(Content);

        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        // Load all animations from JSON
        animations = AnimationResolver.Instance.ResolveAnimations();
        Console.WriteLine($"Total animations loaded: {animations.Count}");
        Console.WriteLine();
#if DEV_ENV
        DebugPrintAnimations();
#endif
    }

    protected override void Update(GameTime gameTime)
    {
        var keyboard = Keyboard.GetState();

        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed ||
            keyboard.IsKeyDown(Keys.Escape))
            Exit();

        bool moving = false;

        if (keyboard.IsKeyDown(Keys.D))
        {
            _currentState = "moving";
            _facingLeft = false;
            moving = true;
        }
        else if (keyboard.IsKeyDown(Keys.A))
        {
            _currentState = "moving";
            _facingLeft = true;
            moving = true;
        }

        if (!moving)
        {
            _currentState = "idle";
            _frameIndex = 0;
            _animTimer = 0f;
        }

        // Advance animation
        if (_currentState == "moving")
        {
            _animTimer += (float)gameTime.ElapsedGameTime.TotalSeconds;

            if (_animTimer >= FrameDuration)
            {
                _animTimer -= FrameDuration;

                var frames = animations["player"]
                    .Components["base"]
                    .States[_currentState]
                    .Frames;

                _frameIndex = (_frameIndex + 1) % frames.Length;
            }
        }

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.Black);

        _spriteBatch.Begin(
            SpriteSortMode.Deferred,
            BlendState.AlphaBlend,
            SamplerState.PointClamp
        );

        var state = animations["player"]
            .Components["base"]
            .States[_currentState];

        var frame = state.Frames[_frameIndex];
        var texture = frame.Texture;

        var sourceRect = new Rectangle(
            frame.SpriteOffsetX,
            frame.SpriteOffsetY,
            frame.Width,
            frame.Height
        );

        var viewport = GraphicsDevice.Viewport;
        var screenCenter = new Vector2(
            viewport.Width / 2f,
            viewport.Height / 2f
        );

        var origin = new Vector2(
            frame.Width / 2f,
            frame.Height / 2f
        );

        var position = screenCenter + new Vector2(
            frame.OffsetX,
            frame.OffsetY
        );

        var effects = _facingLeft
            ? SpriteEffects.FlipHorizontally
            : SpriteEffects.None;

        _spriteBatch.Draw(
            texture,
            position,
            sourceRect,
            Color.White,
            rotation: 0f,
            origin: origin,
            scale: 1f,
            effects: effects,
            layerDepth: 0f
        );

        _spriteBatch.End();

        base.Draw(gameTime);
    }

    private void DebugPrintAnimations()
    {
        // Iterate through all animations
        foreach (var animKvp in animations)
        {
            string animName = animKvp.Key;
            Animation.Animation anim = animKvp.Value;

            Console.WriteLine($"Animation: {animName}");
            Console.WriteLine($"  BaseComponent: {anim.BaseComponent}");
            Console.WriteLine($"  Components: {anim.Components.Count}");

            foreach (var compKvp in anim.Components)
            {
                var comp = compKvp.Value;
                Console.WriteLine($"    Component: {comp.Name}, DefaultState: {comp.DefaultState}");
                Console.WriteLine($"    States: {comp.States.Count}");

                foreach (var stateKvp in comp.States)
                {
                    var state = stateKvp.Value;
                    Console.WriteLine($"      State: {state.Name}, Frames: {state.Frames.Length}");

                    for (int i = 0; i < state.Frames.Length; i++)
                    {
                        var frame = state.Frames[i];
                        Console.WriteLine($"        Frame {i}: TextureIndex={frame.TextureIndex}, Layer={frame.Layer}, " +
                            $"Width={frame.Width}, Height={frame.Height}, OffsetX={frame.OffsetX}, OffsetY={frame.OffsetY}");
                    }
                }
            }

            Console.WriteLine();
        }
    }
}
