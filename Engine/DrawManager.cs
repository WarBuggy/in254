using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using FontStashSharp;
using in254.Core;

namespace in254.Engine;

public sealed class DrawManager : LoggerBaseCore
{
    private static readonly DrawManager _instance = new();
    public static DrawManager Instance => _instance;

    private readonly List<DrawRequest> _drawQueue = new();
    private readonly List<TextDrawRequest> _textQueue = new();

    private DrawManager() { }

    /// <summary>
    /// Adds a draw request to the queue.
    /// </summary>
    public void AddRequest(Texture2D texture, Vector2 position,
                      float rotation = 0f, Vector2 scale = default,
                      Color? color = null, float layerDepth = 0f,
                      int width = 0, int height = 0,
                      int spriteOffsetX = 0, int spriteOffsetY = 0,
                      bool flipX = false, bool flipY = false)
    {
        if (texture == null)
            throw new LocalizedErrorCore<ArgumentNullException>("system.drawManager.textureNull");

        if (scale == default)
            scale = Vector2.One;

        var sourceRect = new Rectangle(spriteOffsetX, spriteOffsetY, width, height);
        _drawQueue.Add(new DrawRequest
        {
            Texture = texture,
            Position = position,
            SourceRectangle = sourceRect,
            Rotation = rotation,
            Scale = scale,
            Color = color ?? Color.White,
            LayerDepth = layerDepth,
            FlipX = flipX,
            FlipY = flipY
        });
    }

    /// <summary>
    /// Adds a text draw request to the queue.
    /// </summary>
    public void AddTextRequest(string text, Vector2 position, int fontSize, Color? color = null, string fontName = null)
    {
        _textQueue.Add(new TextDrawRequest
        {
            Text = text,
            Position = position,
            FontSize = fontSize,
            Color = color ?? Color.White,
            FontName = fontName
        });
    }

    /// <summary>
    /// Render all draw requests in the queue and clear it.
    /// Call this from EngineManager.Draw().
    /// </summary>
    public void RenderQueue(SpriteBatch spriteBatch)
    {
        foreach (var req in _drawQueue)
        {
            SpriteEffects effects = SpriteEffects.None;
            if (req.FlipX) effects |= SpriteEffects.FlipHorizontally;
            if (req.FlipY) effects |= SpriteEffects.FlipVertically;

            spriteBatch.Draw(
                req.Texture,
                req.Position,
                req.SourceRectangle,
                req.Color,
                req.Rotation,
                Vector2.Zero,   // origin: top-left
                req.Scale,
                effects,        // use computed SpriteEffects
                req.LayerDepth
            );
        }

        foreach (var req in _textQueue)
        {
            var font = FontManager.Instance.GetFont(req.FontSize, req.FontName);
            spriteBatch.DrawString(font, req.Text, req.Position, req.Color);
        }

        _drawQueue.Clear();
        _textQueue.Clear();
    }

    /// <summary>
    /// A single text draw request.
    /// </summary>
    public class TextDrawRequest
    {
        public string Text { get; set; } = "";
        public Vector2 Position { get; set; }
        public int FontSize { get; set; } = 16;
        public Color Color { get; set; } = Color.White;
        public string FontName { get; set; }
    }

    /// <summary>
    /// A single draw request.
    /// </summary>
    public class DrawRequest
    {
        public Texture2D Texture { get; set; } = null;
        public Vector2 Position { get; set; }
        public Rectangle SourceRectangle { get; set; }
        public float Rotation { get; set; }
        public Vector2 Scale { get; set; } = Vector2.One;
        public Color Color { get; set; } = Color.White;
        public float LayerDepth { get; set; } = 0f;
        public bool FlipX { get; set; } = false;  // new property
        public bool FlipY { get; set; } = false;  // new property
    }
}
