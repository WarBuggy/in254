using System;
using Microsoft.Xna.Framework;
using in254.Data;
using Microsoft.Xna.Framework.Input;
using Microsoft.Xna.Framework.Graphics;

namespace in254.Engine;

public class EngineManager : Game
{
    private GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch;

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
        var animations = AnimationDataLoader.Instance.LoadAnimations();

        Console.WriteLine($"Total animations loaded: {animations.Count}");
        Console.WriteLine();

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
            Exit();
        }
    }

    protected override void Update(GameTime gameTime)
    {
        if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
            Exit();

        // TODO: Add your update logic here

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.CornflowerBlue);

        // TODO: Add your drawing code here

        base.Draw(gameTime);
    }
}
