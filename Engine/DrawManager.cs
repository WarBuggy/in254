using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using FontStashSharp;
using MoonSharp.Interpreter;
using in254.Core;
using in254.Engine.LuaBindings;

namespace in254.Engine;

public sealed class DrawManager : LoggerBaseCore
{
    private static readonly DrawManager _instance = new();
    public static DrawManager Instance => _instance;

    // --- Sprite registry (persistent across frames) ---
    public struct SpriteRegion
    {
        public Texture2D Texture;
        public Rectangle SourceRect;
    }

    private SpriteRegion[] _spriteRegions = new SpriteRegion[256];
    private int _spriteRegionCount;

    public int RegisterSprite(Texture2D texture, int srcX, int srcY, int srcW, int srcH)
    {
        if (_spriteRegionCount >= _spriteRegions.Length)
            Array.Resize(ref _spriteRegions, _spriteRegions.Length * 2);
        _spriteRegions[_spriteRegionCount] = new SpriteRegion
        {
            Texture = texture,
            SourceRect = new Rectangle(srcX, srcY, srcW, srcH)
        };
        return _spriteRegionCount++;
    }

    public int RegisterPixelSprite(Texture2D pixelTexture)
        => RegisterSprite(pixelTexture, 0, 0, 1, 1);

    // --- Draw request pool (struct array, zero-alloc per frame) ---
    private DrawRequest[] _drawPool = new DrawRequest[4096];
    private int _drawCount;

    // --- Text request pool (struct array, zero-alloc per frame) ---
    private TextDrawRequest[] _textPool = new TextDrawRequest[128];
    private int _textCount;

    // --- Texture slot indirection (keeps DrawRequest blittable) ---
    private Texture2D[] _textureSlots = new Texture2D[64];
    private int _textureSlotCount;

    // --- Render layers ---
    private RenderLayer[] _layers = new RenderLayer[16];
    private int _layerCount;
    private byte _activeLayerId;
    public byte ActiveLayerId => _activeLayerId;
    public void SetActiveLayerId(byte id) => _activeLayerId = id;

    // Scratch buffers for layer-sorted rendering
    private DrawRequest[] _sortScratch = new DrawRequest[4096];
    private int[] _layerOrder;
    private static readonly Comparer<int> _layerComparer =
        Comparer<int>.Create((a, b) => Instance._layers[a].Priority.CompareTo(Instance._layers[b].Priority));

    private DrawManager() { }

    // --- Texture slot registration ---

    private short RegisterTextureSlot(Texture2D texture)
    {
        for (int i = 0; i < _textureSlotCount; i++)
            if (_textureSlots[i] == texture) return (short)i;

        if (_textureSlotCount >= _textureSlots.Length)
            Array.Resize(ref _textureSlots, _textureSlots.Length * 2);

        _textureSlots[_textureSlotCount] = texture;
        return (short)_textureSlotCount++;
    }

    // --- Layer registration ---

    public void RegisterLayer(string name, int priority,
        BlendState blendState, SpriteSortMode sortMode, SamplerState samplerState)
    {
        for (int i = 0; i < _layerCount; i++)
            if (_layers[i].Name == name) return;

        if (_layerCount == 0)
        {
            _layers[0] = new RenderLayer
            {
                Id = 0, Name = "__default", Priority = -1,
                BlendState = BlendState.AlphaBlend,
                SortMode = SpriteSortMode.Deferred,
                SamplerState = SamplerState.PointClamp,
            };
            _layerCount = 1;
        }

        if (_layerCount >= _layers.Length)
            Array.Resize(ref _layers, _layers.Length * 2);

        _layers[_layerCount] = new RenderLayer
        {
            Id = (byte)_layerCount,
            Name = name,
            Priority = priority,
            BlendState = blendState,
            SortMode = sortMode,
            SamplerState = samplerState,
        };
        _layerCount++;
    }

    public void SetActiveLayer(string name)
    {
        for (int i = 0; i < _layerCount; i++)
        {
            if (_layers[i].Name == name)
            {
                _activeLayerId = _layers[i].Id;
                return;
            }
        }
    }

    public void ResetActiveLayer() => _activeLayerId = 0;


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

        short handle = RegisterTextureSlot(texture);
        byte flags = 0;
        if (flipX) flags |= 1;
        if (flipY) flags |= 2;

        EnsurePoolCapacity();
        _drawPool[_drawCount++] = new DrawRequest
        {
            TextureHandle = handle,
            Position = position,
            SourceRectangle = new Rectangle(spriteOffsetX, spriteOffsetY, width, height),
            Rotation = rotation,
            Scale = scale,
            Color = color ?? Color.White,
            LayerDepth = layerDepth,
            LayerId = _activeLayerId,
            Flags = flags
        };
    }

    public void AddRect(int spriteId, float x, float y, float w, float h, int packedColor)
    {
        ref var region = ref _spriteRegions[spriteId];
        short handle = RegisterTextureSlot(region.Texture);
        Color color = packedColor == 0 ? Color.White : ColorLuaBinding.ToColor(packedColor);
        EnsurePoolCapacity();
        _drawPool[_drawCount++] = new DrawRequest
        {
            TextureHandle = handle,
            Position = new Vector2(x, y),
            SourceRectangle = region.SourceRect,
            Scale = new Vector2(w, h),
            Color = color,
            LayerId = _activeLayerId,
            Flags = 0
        };
    }

    public void AddLine(int spriteId, float x1, float y1, float x2, float y2, float thickness, int packedColor)
    {
        ref var region = ref _spriteRegions[spriteId];
        short handle = RegisterTextureSlot(region.Texture);
        Color color = packedColor == 0 ? Color.White : ColorLuaBinding.ToColor(packedColor);

        float dx = x2 - x1, dy = y2 - y1;
        float length = MathF.Sqrt(dx * dx + dy * dy);
        float rotation = MathF.Atan2(dy, dx);

        EnsurePoolCapacity();
        _drawPool[_drawCount++] = new DrawRequest
        {
            TextureHandle = handle,
            Position = new Vector2(x1, y1),
            SourceRectangle = region.SourceRect,
            Rotation = rotation,
            Scale = new Vector2(length, thickness),
            Color = color,
            LayerId = _activeLayerId,
            Flags = 0
        };
    }

    public void AddLineBatch(int spriteId, Table data, int count)
    {
        ref var region = ref _spriteRegions[spriteId];
        short handle = RegisterTextureSlot(region.Texture);

        for (int i = 0; i < count; i++)
        {
            int off = i * 7;
            float x1 = (float)data.Get(off + 1).Number;
            float y1 = (float)data.Get(off + 2).Number;
            float x2 = (float)data.Get(off + 3).Number;
            float y2 = (float)data.Get(off + 4).Number;
            float thickness = (float)data.Get(off + 5).Number;
            int packed = (int)data.Get(off + 6).Number;
            Color color = packed == 0 ? Color.White : ColorLuaBinding.ToColor(packed);

            float dx = x2 - x1, dy = y2 - y1;
            float length = MathF.Sqrt(dx * dx + dy * dy);
            float rotation = MathF.Atan2(dy, dx);

            EnsurePoolCapacity();
            _drawPool[_drawCount++] = new DrawRequest
            {
                TextureHandle = handle,
                Position = new Vector2(x1, y1),
                SourceRectangle = region.SourceRect,
                Rotation = rotation,
                Scale = new Vector2(length, thickness),
                Color = color,
                LayerId = _activeLayerId,
                Flags = 0
            };
        }
    }

    public void AddRectBatchPacked(int spriteId, Table data, int count)
    {
        ref var region = ref _spriteRegions[spriteId];
        short handle = RegisterTextureSlot(region.Texture);

        for (int i = 0; i < count; i++)
        {
            int off = i * 5;
            float x = (float)data.Get(off + 1).Number;
            float y = (float)data.Get(off + 2).Number;
            float w = (float)data.Get(off + 3).Number;
            float h = (float)data.Get(off + 4).Number;
            int packed = (int)data.Get(off + 5).Number;
            Color color = packed == 0 ? Color.White : ColorLuaBinding.ToColor(packed);

            EnsurePoolCapacity();
            _drawPool[_drawCount++] = new DrawRequest
            {
                TextureHandle = handle,
                Position = new Vector2(x, y),
                SourceRectangle = region.SourceRect,
                Scale = new Vector2(w, h),
                Color = color,
                LayerId = _activeLayerId,
                Flags = 0
            };
        }
    }

    public void AddRectBatch(Texture2D texture, Table data, int count)
    {
        if (texture == null)
            throw new LocalizedErrorCore<ArgumentNullException>("system.drawManager.textureNull");

        short handle = RegisterTextureSlot(texture);

        for (int i = 0; i < count; i++)
        {
            int offset = i * 8;
            float x = (float)data.Get(offset + 1).Number;
            float y = (float)data.Get(offset + 2).Number;
            float w = (float)data.Get(offset + 3).Number;
            float h = (float)data.Get(offset + 4).Number;
            int r = (int)data.Get(offset + 5).Number;
            int g = (int)data.Get(offset + 6).Number;
            int b = (int)data.Get(offset + 7).Number;
            int a = (int)data.Get(offset + 8).Number;

            EnsurePoolCapacity();
            _drawPool[_drawCount++] = new DrawRequest
            {
                TextureHandle = handle,
                Position = new Vector2(x, y),
                SourceRectangle = Rectangle.Empty,
                Rotation = 0f,
                Scale = new Vector2(w, h),
                Color = Color.FromNonPremultiplied(r, g, b, a),
                LayerDepth = 0f,
                LayerId = _activeLayerId,
                Flags = 0
            };
        }
    }

    private void EnsurePoolCapacity()
    {
        if (_drawCount < _drawPool.Length) return;
        int newSize = _drawPool.Length * 2;
        var newPool = new DrawRequest[newSize];
        Array.Copy(_drawPool, newPool, _drawPool.Length);
        _drawPool = newPool;
    }

    public void AddTextRequest(string text, Vector2 position, int fontSize, Color? color = null, string fontName = null)
    {
        if (_textCount >= _textPool.Length)
            Array.Resize(ref _textPool, _textPool.Length * 2);

        _textPool[_textCount++] = new TextDrawRequest
        {
            Text = text,
            Position = position,
            FontSize = fontSize,
            Color = color ?? Color.White,
            FontName = fontName,
            LayerId = _activeLayerId
        };
    }

    /// <summary>
    /// Batch text requests from a stride-5 Lua table: text, x, y, size, packedColor.
    /// Single C# crossing for N text draws.
    /// </summary>
    public void AddTextBatch(Table data, int count)
    {
        for (int i = 0; i < count; i++)
        {
            int off = i * 5;
            string text = data.Get(off + 1).String;
            float x = (float)data.Get(off + 2).Number;
            float y = (float)data.Get(off + 3).Number;
            int size = (int)data.Get(off + 4).Number;
            int packed = (int)data.Get(off + 5).Number;
            Color color = packed == 0 ? Color.White : ColorLuaBinding.ToColor(packed);

            if (_textCount >= _textPool.Length)
                Array.Resize(ref _textPool, _textPool.Length * 2);

            _textPool[_textCount++] = new TextDrawRequest
            {
                Text = text,
                Position = new Vector2(x, y),
                FontSize = size,
                Color = color,
                LayerId = _activeLayerId
            };
        }
    }

    // =============================================
    // Render
    // =============================================

    public void Render(GraphicsDevice graphicsDevice, SpriteBatch spriteBatch)
    {
        if (_layerCount > 1)
            RenderMultiLayer(spriteBatch);
        else
            RenderSinglePass(spriteBatch);

        _drawCount = 0;
        _textCount = 0;
        _textureSlotCount = 0;
    }

    // --- Internals ---

    private void DrawBatch(SpriteBatch spriteBatch, DrawRequest[] pool, int start, int count)
    {
        for (int i = start; i < start + count; i++)
        {
            ref var req = ref pool[i];
            SpriteEffects effects = SpriteEffects.None;
            if ((req.Flags & 1) != 0) effects |= SpriteEffects.FlipHorizontally;
            if ((req.Flags & 2) != 0) effects |= SpriteEffects.FlipVertically;

            Rectangle? srcRect = (req.SourceRectangle.Width > 0 && req.SourceRectangle.Height > 0)
                ? req.SourceRectangle
                : null;

            spriteBatch.Draw(
                _textureSlots[req.TextureHandle],
                req.Position, srcRect, req.Color,
                req.Rotation, Vector2.Zero, req.Scale,
                effects, req.LayerDepth
            );
        }
    }

    private void DrawText(SpriteBatch spriteBatch)
    {
        for (int i = 0; i < _textCount; i++)
        {
            ref var req = ref _textPool[i];
            var font = FontManager.Instance.GetFont(req.FontSize, req.FontName);
            spriteBatch.DrawString(font, req.Text, req.Position, req.Color);
        }
    }

    private void DrawTextForLayer(SpriteBatch spriteBatch, byte layerId)
    {
        for (int i = 0; i < _textCount; i++)
        {
            ref var req = ref _textPool[i];
            if (req.LayerId != layerId) continue;
            var font = FontManager.Instance.GetFont(req.FontSize, req.FontName);
            spriteBatch.DrawString(font, req.Text, req.Position, req.Color);
        }
    }

    private void RenderSinglePass(SpriteBatch spriteBatch)
    {
        spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend,
            SamplerState.PointClamp, DepthStencilState.None, RasterizerState.CullCounterClockwise);
        DrawBatch(spriteBatch, _drawPool, 0, _drawCount);
        DrawText(spriteBatch);
        spriteBatch.End();
    }

    private void RenderMultiLayer(SpriteBatch spriteBatch)
    {
        // Counting sort by LayerId
        if (_sortScratch.Length < _drawPool.Length)
            _sortScratch = new DrawRequest[_drawPool.Length];

        Span<int> counts = stackalloc int[_layerCount];
        counts.Clear();
        for (int i = 0; i < _drawCount; i++)
            counts[_drawPool[i].LayerId]++;

        Span<int> offsets = stackalloc int[_layerCount];
        offsets[0] = 0;
        for (int i = 1; i < _layerCount; i++)
            offsets[i] = offsets[i - 1] + counts[i - 1];

        Span<int> writePos = stackalloc int[_layerCount];
        offsets.CopyTo(writePos);
        for (int i = 0; i < _drawCount; i++)
        {
            byte lid = _drawPool[i].LayerId;
            _sortScratch[writePos[lid]++] = _drawPool[i];
        }

        // Sort layers by priority (cached comparer, no lambda alloc)
        if (_layerOrder == null || _layerOrder.Length < _layerCount)
            _layerOrder = new int[_layerCount];
        for (int i = 0; i < _layerCount; i++) _layerOrder[i] = i;
        Array.Sort(_layerOrder, 0, _layerCount, _layerComparer);

        // Merge consecutive layers with identical render state + transform into one Begin/End.
        // Reduces GPU pipeline flushes (e.g. world+entities share alpha blend + zoom → 1 flush).
        var camMgr = CameraManager.Instance;
        int li = 0;
        while (li < _layerCount)
        {
            int layerIdx = _layerOrder[li];
            ref var layer = ref _layers[layerIdx];

            // Skip empty non-last layers
            if (counts[layerIdx] == 0 && _textCount == 0 && li != _layerCount - 1)
            {
                li++;
                continue;
            }

            var layerTransform = camMgr.GetTransformForLayer(layer.Name);
            spriteBatch.Begin(layer.SortMode, layer.BlendState, layer.SamplerState,
                DepthStencilState.None, RasterizerState.CullCounterClockwise,
                null, layerTransform);

            // Draw this layer and all consecutive layers with matching render state + transform
            while (li < _layerCount)
            {
                layerIdx = _layerOrder[li];

                if (counts[layerIdx] > 0)
                    DrawBatch(spriteBatch, _sortScratch, offsets[layerIdx], counts[layerIdx]);

                DrawTextForLayer(spriteBatch, (byte)layerIdx);

                li++;

                // Check if next layer has a different render state or transform → must break
                if (li < _layerCount)
                {
                    ref var next = ref _layers[_layerOrder[li]];
                    var nextTransform = camMgr.GetTransformForLayer(next.Name);
                    if (next.BlendState != layer.BlendState ||
                        next.SortMode != layer.SortMode ||
                        next.SamplerState != layer.SamplerState ||
                        nextTransform != layerTransform)
                        break;
                }
            }

            spriteBatch.End();
        }
    }

    /// <summary>
    /// A single text draw request (struct — no heap allocation).
    /// </summary>
    public struct TextDrawRequest
    {
        public string Text;
        public Vector2 Position;
        public int FontSize;
        public Color Color;
        public string FontName;
        public byte LayerId;
    }

    /// <summary>
    /// A single draw request (blittable — no managed references).
    /// </summary>
    public struct DrawRequest
    {
        public Vector2 Position;         // 8
        public Rectangle SourceRectangle;// 16
        public float Rotation;          // 4
        public Vector2 Scale;           // 8
        public Color Color;             // 4
        public float LayerDepth;        // 4
        public short TextureHandle;     // 2 — index into _textureSlots[]
        public byte LayerId;            // 1 — index into _layers[]
        public byte Flags;              // 1 — bit 0 = FlipX, bit 1 = FlipY
    }

    private struct RenderLayer
    {
        public byte Id;
        public string Name;
        public int Priority;
        public BlendState BlendState;
        public SpriteSortMode SortMode;
        public SamplerState SamplerState;
    }
}
