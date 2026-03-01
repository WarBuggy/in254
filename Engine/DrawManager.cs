using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using FontStashSharp;
using MoonSharp.Interpreter;
using in254.Core;

namespace in254.Engine;

public sealed class DrawManager : LoggerBaseCore
{
    private static readonly DrawManager _instance = new();
    public static DrawManager Instance => _instance;

    // --- Draw request pool ---
    private DrawRequest[] _drawPool = new DrawRequest[4096];
    private int _drawCount;
    private readonly List<TextDrawRequest> _textQueue = new();

    // --- Texture slot indirection (keeps DrawRequest blittable) ---
    private Texture2D[] _textureSlots = new Texture2D[64];
    private int _textureSlotCount;

    // --- Render layers ---
    private RenderLayer[] _layers = new RenderLayer[16];
    private int _layerCount;
    private byte _activeLayerId;

    // Scratch buffers for layer-sorted rendering
    private DrawRequest[] _sortScratch = new DrawRequest[4096];
    private int[] _layerOrder;

    private bool HasLayers => _layerCount > 1;

    // --- Tile grid RenderTarget cache ---
    private RenderTarget2D _tileCache;
    private bool _tileCacheDirty = true;
    private int _cachedCamTileX = int.MinValue;
    private int _cachedCamTileY = int.MinValue;
    private int _cachedViewportW;
    private int _cachedViewportH;

    // Stored tile grid params (rendered to RT when dirty)
    private bool _hasPendingTileMap;
    private Table _pendingTiles, _pendingColorCache, _pendingLightMap, _pendingTileData;
    private float _pendingCamX, _pendingCamY;
    private int _pendingTileSize, _pendingWorldW, _pendingWorldH;
    private int _pendingScreenW, _pendingScreenH, _pendingMaxLight, _pendingSurfaceY;
    private Texture2D _pendingPixelTex;

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
        // Check for duplicate name
        for (int i = 0; i < _layerCount; i++)
            if (_layers[i].Name == name) return;

        if (_layerCount == 0)
        {
            // Auto-create default layer at slot 0
            _layers[0] = new RenderLayer
            {
                Id = 0, Name = "__default", Priority = 0,
                BlendState = BlendState.AlphaBlend,
                SortMode = SpriteSortMode.Deferred,
                SamplerState = SamplerState.PointClamp
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
            SamplerState = samplerState
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

    /// <summary>
    /// Batch-add colored rects from a flat Lua table (stride 8: x, y, w, h, r, g, b, a).
    /// </summary>
    public void AddRectBatch(Texture2D texture, Table data, int count)
    {
        if (texture == null)
            throw new LocalizedErrorCore<ArgumentNullException>("system.drawManager.textureNull");

        short handle = RegisterTextureSlot(texture);

        for (int i = 0; i < count; i++)
        {
            int offset = i * 8; // stride 8
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

    // =============================================
    // Tile cache (Lua calls StoreTileMapParams / InvalidateTileCache,
    //             Render() handles everything else internally)
    // =============================================

    public void StoreTileMapParams(
        Texture2D pixelTex, Table tiles, Table colorCache, Table lightMap, Table tileData,
        float camX, float camY, int tileSize,
        int worldW, int worldH, int screenW, int screenH,
        int maxLight, int surfaceY)
    {
        _hasPendingTileMap = true;
        _pendingPixelTex = pixelTex;
        _pendingTiles = tiles;
        _pendingColorCache = colorCache;
        _pendingLightMap = lightMap;
        _pendingTileData = tileData;
        _pendingCamX = camX;
        _pendingCamY = camY;
        _pendingTileSize = tileSize;
        _pendingWorldW = worldW;
        _pendingWorldH = worldH;
        _pendingScreenW = screenW;
        _pendingScreenH = screenH;
        _pendingMaxLight = maxLight;
        _pendingSurfaceY = surfaceY;

        int camTX = (int)Math.Floor(camX / tileSize);
        int camTY = (int)Math.Floor(camY / tileSize);
        if (camTX != _cachedCamTileX || camTY != _cachedCamTileY)
        {
            _tileCacheDirty = true;
            _cachedCamTileX = camTX;
            _cachedCamTileY = camTY;
        }
        if (screenW != _cachedViewportW || screenH != _cachedViewportH)
        {
            _tileCacheDirty = true;
            _cachedViewportW = screenW;
            _cachedViewportH = screenH;
        }
    }

    public void InvalidateTileCache() => _tileCacheDirty = true;

    // =============================================
    // Render — single entry point called by EngineManager
    // Handles: tile RT update → tile blit → entity draw → text → cleanup
    // =============================================

    public void Render(GraphicsDevice graphicsDevice, SpriteBatch spriteBatch)
    {
        // 1. Update tile RenderTarget if dirty
        UpdateTileCache(graphicsDevice, spriteBatch);

        // 2. Draw everything (tiles + entities + text)
        if (_layerCount > 1)
            RenderMultiLayer(spriteBatch);
        else
            RenderSinglePass(spriteBatch);

        // 3. Cleanup
        _drawCount = 0;
        _textQueue.Clear();
        _hasPendingTileMap = false;
        _textureSlotCount = 0;
    }

    // --- Internals ---

    private void UpdateTileCache(GraphicsDevice graphicsDevice, SpriteBatch spriteBatch)
    {
        if (!_hasPendingTileMap) return;

        if (_tileCache == null ||
            _tileCache.Width != _pendingScreenW || _tileCache.Height != _pendingScreenH)
        {
            _tileCache?.Dispose();
            _tileCache = new RenderTarget2D(graphicsDevice, _pendingScreenW, _pendingScreenH);
            _tileCacheDirty = true;
        }

        if (!_tileCacheDirty) return;
        _tileCacheDirty = false;

        graphicsDevice.SetRenderTarget(_tileCache);
        graphicsDevice.Clear(Color.Transparent);
        spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend,
            SamplerState.PointClamp, DepthStencilState.None, RasterizerState.CullCounterClockwise);
        DrawTiles(spriteBatch);
        spriteBatch.End();
        graphicsDevice.SetRenderTarget(null);
    }

    private void BlitTileCache(SpriteBatch spriteBatch)
    {
        if (_tileCache != null && _hasPendingTileMap)
            spriteBatch.Draw(_tileCache, Vector2.Zero, Color.White);
    }

    private void DrawBatch(SpriteBatch spriteBatch, DrawRequest[] pool, int start, int count)
    {
        for (int i = start; i < start + count; i++)
        {
            ref var req = ref pool[i];
            SpriteEffects effects = SpriteEffects.None;
            if ((req.Flags & 1) != 0) effects |= SpriteEffects.FlipHorizontally;
            if ((req.Flags & 2) != 0) effects |= SpriteEffects.FlipVertically;

            spriteBatch.Draw(
                _textureSlots[req.TextureHandle],
                req.Position, req.SourceRectangle, req.Color,
                req.Rotation, Vector2.Zero, req.Scale,
                effects, req.LayerDepth
            );
        }
    }

    private void DrawText(SpriteBatch spriteBatch)
    {
        foreach (var req in _textQueue)
        {
            var font = FontManager.Instance.GetFont(req.FontSize, req.FontName);
            spriteBatch.DrawString(font, req.Text, req.Position, req.Color);
        }
    }

    private void RenderSinglePass(SpriteBatch spriteBatch)
    {
        spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend,
            SamplerState.PointClamp, DepthStencilState.None, RasterizerState.CullCounterClockwise);
        BlitTileCache(spriteBatch);
        DrawBatch(spriteBatch, _drawPool, 0, _drawCount);
        DrawText(spriteBatch);
        spriteBatch.End();
    }

    private void RenderMultiLayer(SpriteBatch spriteBatch)
    {
        // Blit tile cache in its own pass first
        spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend,
            SamplerState.PointClamp, DepthStencilState.None, RasterizerState.CullCounterClockwise);
        BlitTileCache(spriteBatch);
        spriteBatch.End();

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

        // Sort layers by priority
        if (_layerOrder == null || _layerOrder.Length < _layerCount)
            _layerOrder = new int[_layerCount];
        for (int i = 0; i < _layerCount; i++) _layerOrder[i] = i;
        Array.Sort(_layerOrder, 0, _layerCount,
            Comparer<int>.Create((a, b) => _layers[a].Priority.CompareTo(_layers[b].Priority)));

        // One Begin/End per layer
        for (int li = 0; li < _layerCount; li++)
        {
            int layerIdx = _layerOrder[li];
            int count = counts[layerIdx];
            if (count == 0) continue;

            ref var layer = ref _layers[layerIdx];
            spriteBatch.Begin(layer.SortMode, layer.BlendState, layer.SamplerState,
                DepthStencilState.None, RasterizerState.CullCounterClockwise);
            DrawBatch(spriteBatch, _sortScratch, offsets[layerIdx], count);
            if (li == _layerCount - 1) DrawText(spriteBatch);
            spriteBatch.End();
        }
    }

    private void DrawTiles(SpriteBatch spriteBatch)
    {
        var tiles = _pendingTiles;
        var tileData = _pendingTileData;
        var colorCache = _pendingColorCache;
        var lightMap = _pendingLightMap;
        var pixelTex = _pendingPixelTex;
        float camX = _pendingCamX, camY = _pendingCamY;
        int ts = _pendingTileSize;
        int worldW = _pendingWorldW;
        int maxLight = _pendingMaxLight, surfaceY = _pendingSurfaceY;
        int screenW = _pendingScreenW, screenH = _pendingScreenH;

        int startTX = Math.Max(0, (int)Math.Floor(camX / ts));
        int startTY = Math.Max(0, (int)Math.Floor(camY / ts));
        int endTX = Math.Min(_pendingWorldW - 1, (int)Math.Floor((camX + screenW) / ts) + 1);
        int endTY = Math.Min(_pendingWorldH - 1, (int)Math.Floor((camY + screenH) / ts) + 1);

        var scale = new Vector2(ts, ts);

        for (int y = startTY; y <= endTY; y++)
        {
            int baseIdx = y * worldW;
            float sy = (float)Math.Floor(y * ts - camY);

            for (int x = startTX; x <= endTX; x++)
            {
                int idx = baseIdx + x + 1;
                var tileDyn = tiles.Get(idx);
                int tileId = tileDyn.IsNil() ? 0 : (int)tileDyn.Number;
                if (tileId == 0) continue;

                Color color;

                if (colorCache != null)
                {
                    var cachedDyn = colorCache.Get(idx);
                    if (cachedDyn.Type == DataType.Table)
                    {
                        int lf = maxLight;
                        if (lightMap != null)
                        {
                            var lfDyn = lightMap.Get(idx);
                            lf = lfDyn.IsNil() ? 0 : (int)lfDyn.Number;
                        }
                        if (lf <= 0 && y >= surfaceY + 3) continue;

                        var ct = cachedDyn.Table;
                        int r = (int)(ct.Get(1).IsNil() ? 0 : ct.Get(1).Number);
                        int g = (int)(ct.Get(2).IsNil() ? 0 : ct.Get(2).Number);
                        int b = (int)(ct.Get(3).IsNil() ? 0 : ct.Get(3).Number);
                        int a = (int)(ct.Get(4).IsNil() ? 255 : ct.Get(4).Number);
                        color = Color.FromNonPremultiplied(r, g, b, a);
                    }
                    else
                    {
                        color = GetTileColorFromTable(tileData, tileId);
                    }
                }
                else
                {
                    color = GetTileColorFromTable(tileData, tileId);
                }

                float sx = (float)Math.Floor(x * ts - camX);

                spriteBatch.Draw(pixelTex, new Vector2(sx, sy), Rectangle.Empty,
                    color, 0f, Vector2.Zero, scale, SpriteEffects.None, 0f);
            }
        }
    }

    private static Color GetTileColorFromTable(Table tileData, int tileId)
    {
        var dataDyn = tileData.Get(tileId);
        Table data = dataDyn.Type == DataType.Table ? dataDyn.Table : tileData.Get(0).Table;
        var colorDyn = data.Get("color");
        if (colorDyn.Type == DataType.Table)
        {
            var ct = colorDyn.Table;
            int r = (int)(ct.Get(1).IsNil() ? 200 : ct.Get(1).Number);
            int g = (int)(ct.Get(2).IsNil() ? 200 : ct.Get(2).Number);
            int b = (int)(ct.Get(3).IsNil() ? 200 : ct.Get(3).Number);
            int a = (int)(ct.Get(4).IsNil() ? 255 : ct.Get(4).Number);
            return Color.FromNonPremultiplied(r, g, b, a);
        }
        return Color.White;
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
