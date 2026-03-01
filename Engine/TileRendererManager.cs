using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MoonSharp.Interpreter;
using in254.Core;

namespace in254.Engine;

public sealed class TileRendererManager : LoggerBaseCore
{
    private static readonly TileRendererManager _instance = new();
    public static TileRendererManager Instance => _instance;

    // --- Tile grid RenderTarget cache ---
    private int _tileMargin = 20;
    private int _rebuildCooldownMax = 3;
    private RenderTarget2D _tileCache;
    private bool _tileCacheDirty = true;
    private bool _tileIdsDirty = true;
    private bool _tileColorsDirty = true;
    private int _rebuildCooldown;
    private int _cachedAlignedTX = int.MinValue;
    private int _cachedAlignedTY = int.MinValue;
    private int _cachedViewportW;
    private int _cachedViewportH;

    // Cached tile colors (avoids repeated MoonSharp table lookups)
    private Color[] _tileColorLUT;
    private int _tileColorLUTSize;

    // Pre-allocated buffers for bulk table reads
    private int[] _tileBuf;
    private byte[] _lightBuf;
    private bool _tileBufValid;

    // --- Config (one-time setup from Lua) ---
    private bool _configured;
    private Texture2D _pixelTex;
    private Table _tiles;
    private Table _tileData;
    private int _tileSize;
    private int _worldW, _worldH;
    private int _maxLight;
    private int _surfaceY;

    // --- Per-frame params ---
    private bool _hasFrameParams;
    private float _camX, _camY;
    private int _screenW, _screenH;
    private Table _lightMap;
    private byte _drawLayerId; // layer active when DrawTileMap was called

    // --- Native overlay buffer (replaces Lua table lightMap when set) ---
    private int _nativeOverlayHandle;

    private TileRendererManager() { }

    // --- One-time config (called from Lua SetTileMap) ---
    public void SetConfig(Texture2D pixelTex, Table tiles, Table tileData,
        int tileSize, int worldW, int worldH, int maxLight, int surfaceY)
    {
        _pixelTex = pixelTex;
        _tiles = tiles;
        _tileData = tileData;
        _tileSize = tileSize;
        _worldW = worldW;
        _worldH = worldH;
        _maxLight = maxLight;
        _surfaceY = surfaceY;
        _configured = true;

        if (_tileColorLUT == null)
            RebuildTileColorLUT(tileData);

        InvalidateTileCache();
    }

    // --- Runtime configuration (called from Lua ConfigureTileMap) ---
    public void Configure(int? tileMargin = null, int? rebuildCooldown = null)
    {
        if (tileMargin.HasValue) { _tileMargin = Math.Clamp(tileMargin.Value, 1, 100); InvalidateTileCache(); }
        if (rebuildCooldown.HasValue) _rebuildCooldownMax = Math.Max(0, rebuildCooldown.Value);
    }

    // --- Per-frame dynamic data (called from Lua DrawTileMap) ---
    public void SetFrameParams(float camX, float camY, int screenW, int screenH, Table lightMap)
    {
        _camX = camX;
        _camY = camY;
        _screenW = screenW;
        _screenH = screenH;
        _lightMap = lightMap;
        _hasFrameParams = true;
        _drawLayerId = DrawManager.Instance.ActiveLayerId;

        // Align camera to _tileMargin grid — only rebuild when crossing a margin boundary
        int camTX = (int)Math.Floor(camX / _tileSize);
        int camTY = (int)Math.Floor(camY / _tileSize);
        int alignedTX = (int)Math.Floor((double)camTX / _tileMargin) * _tileMargin;
        int alignedTY = (int)Math.Floor((double)camTY / _tileMargin) * _tileMargin;
        if (alignedTX != _cachedAlignedTX || alignedTY != _cachedAlignedTY)
        {
            InvalidateTileCache();
            _cachedAlignedTX = alignedTX;
            _cachedAlignedTY = alignedTY;
        }
        if (screenW != _cachedViewportW || screenH != _cachedViewportH)
        {
            InvalidateTileCache();
            _cachedViewportW = screenW;
            _cachedViewportH = screenH;
        }
    }

    /// <summary>Full invalidation — tile IDs + colors (used when tiles are mined/placed).</summary>
    public void InvalidateTileCache()
    {
        _tileCacheDirty = true;
        _tileIdsDirty = true;
        _tileColorsDirty = true;
        _tileBufValid = false;
    }

    /// <summary>Color-only invalidation — tile IDs are reused (used after lighting update).</summary>
    public void InvalidateTileColors()
    {
        _tileCacheDirty = true;
        _tileColorsDirty = true;
    }

    /// <summary>Set native overlay buffer handle. When > 0, reads overlay values from C# int[] instead of Lua table.</summary>
    public void SetNativeOverlayBuffer(int handle)
    {
        _nativeOverlayHandle = handle;
    }

    /// <summary>
    /// Update tile RT if dirty, then inject as a draw request into DrawManager.
    /// Called from EngineManager.Draw() before DrawManager.Render().
    /// </summary>
    public void UpdateAndInject(GraphicsDevice gd, SpriteBatch sb)
    {
        if (!_configured || !_hasFrameParams) return;

        UpdateTileCache(gd, sb);

        if (_tileCache != null)
        {
            int ts = _tileSize;
            float rtOriginX = (_cachedAlignedTX - _tileMargin) * ts;
            float rtOriginY = (_cachedAlignedTY - _tileMargin) * ts;
            float offsetX = (float)Math.Floor(-(_camX - rtOriginX));
            float offsetY = (float)Math.Floor(-(_camY - rtOriginY));

            // Inject on the same layer that was active when DrawTileMap was called
            var dm = DrawManager.Instance;
            byte savedLayer = dm.ActiveLayerId;
            dm.SetActiveLayerId(_drawLayerId);
            dm.AddRequest(
                _tileCache,
                new Vector2(offsetX, offsetY)
            );
            dm.SetActiveLayerId(savedLayer);
        }

        _hasFrameParams = false;
    }

    // --- Internals ---

    private void UpdateTileCache(GraphicsDevice gd, SpriteBatch sb)
    {
        int rtW = _screenW + _tileSize * (1 + 2 * _tileMargin);
        int rtH = _screenH + _tileSize * (1 + 2 * _tileMargin);
        if (_tileCache == null ||
            _tileCache.Width != rtW || _tileCache.Height != rtH)
        {
            _tileCache?.Dispose();
            _tileCache = new RenderTarget2D(gd, rtW, rtH, false,
                SurfaceFormat.Color, DepthFormat.None, 0, RenderTargetUsage.PreserveContents);
            _tileCacheDirty = true;
            _tileIdsDirty = true;
            _tileColorsDirty = true;
            _tileBufValid = false;
        }

        if (_rebuildCooldown > 0) { _rebuildCooldown--; return; }
        if (!_tileCacheDirty) return;
        _tileCacheDirty = false;
        _rebuildCooldown = _rebuildCooldownMax;

        gd.SetRenderTarget(_tileCache);
        gd.Clear(Color.Transparent);
        sb.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend,
            SamplerState.PointClamp, DepthStencilState.None, RasterizerState.CullCounterClockwise);
        DrawTiles(sb);
        sb.End();
        gd.SetRenderTarget(null);

        _tileIdsDirty = false;
        _tileColorsDirty = false;
    }

    private void RebuildTileColorLUT(Table tileData)
    {
        int maxId = 0;
        foreach (var pair in tileData.Pairs)
        {
            if (pair.Key.Type == DataType.Number)
            {
                int id = (int)pair.Key.Number;
                if (id > maxId) maxId = id;
            }
        }

        _tileColorLUTSize = maxId + 1;
        _tileColorLUT = new Color[_tileColorLUTSize];

        for (int id = 0; id < _tileColorLUTSize; id++)
        {
            var dataDyn = tileData.Get(id);
            if (dataDyn.Type != DataType.Table) { _tileColorLUT[id] = Color.White; continue; }
            var colorDyn = dataDyn.Table.Get("color");
            if (colorDyn.Type != DataType.Table) { _tileColorLUT[id] = Color.White; continue; }
            var ct = colorDyn.Table;
            int r = (int)(ct.Get(1).IsNil() ? 200 : ct.Get(1).Number);
            int g = (int)(ct.Get(2).IsNil() ? 200 : ct.Get(2).Number);
            int b = (int)(ct.Get(3).IsNil() ? 200 : ct.Get(3).Number);
            int a = (int)(ct.Get(4).IsNil() ? 255 : ct.Get(4).Number);
            _tileColorLUT[id] = Color.FromNonPremultiplied(r, g, b, a);
        }
    }

    private void PreloadTileRegion(int startTX, int startTY, int endTX, int endTY)
    {
        int regionW = endTX - startTX + 1;
        int regionH = endTY - startTY + 1;
        int totalCells = regionW * regionH;

        if (_tileBuf == null || _tileBuf.Length < totalCells)
        {
            _tileBuf = new int[totalCells];
            _lightBuf = new byte[totalCells];
            _tileBufValid = false;
        }

        // Phase 1: Read tile IDs only when tiles changed
        if (_tileIdsDirty || !_tileBufValid)
        {
            int bufIdx = 0;
            for (int y = startTY; y <= endTY; y++)
            {
                int baseIdx = y * _worldW;
                for (int x = startTX; x <= endTX; x++)
                {
                    var tileDyn = _tiles.Get(baseIdx + x + 1);
                    _tileBuf[bufIdx++] = tileDyn.IsNil() ? 0 : (int)tileDyn.Number;
                }
            }
            _tileBufValid = true;
        }

        // Phase 2: Read light levels
        if (_nativeOverlayHandle > 0 && _tileColorsDirty)
        {
            // Fast path: read from C# native buffer (no Lua overhead)
            var nativeLightBuf = NativeBufferManager.Instance.GetRaw(_nativeOverlayHandle);
            if (nativeLightBuf != null)
            {
                int bufIdx = 0;
                int nLen = nativeLightBuf.Length;
                for (int y = startTY; y <= endTY; y++)
                {
                    int baseIdx = y * _worldW;
                    for (int x = startTX; x <= endTX; x++)
                    {
                        if (_tileBuf[bufIdx] == 0) { _lightBuf[bufIdx] = 0; bufIdx++; continue; }
                        int idx = baseIdx + x;
                        _lightBuf[bufIdx] = (byte)(idx >= 0 && idx < nLen ? nativeLightBuf[idx] : 0);
                        bufIdx++;
                    }
                }
            }
        }
        else if (_lightMap != null && _tileColorsDirty)
        {
            // Fallback: read from Lua table
            int bufIdx = 0;
            for (int y = startTY; y <= endTY; y++)
            {
                int baseIdx = y * _worldW;
                for (int x = startTX; x <= endTX; x++)
                {
                    if (_tileBuf[bufIdx] == 0) { _lightBuf[bufIdx] = 0; bufIdx++; continue; }
                    var lightDyn = _lightMap.Get(baseIdx + x + 1);
                    _lightBuf[bufIdx] = lightDyn.IsNil() ? (byte)0 : (byte)lightDyn.Number;
                    bufIdx++;
                }
            }
        }
        else if (_lightBuf != null && _tileColorsDirty)
        {
            Array.Fill(_lightBuf, (byte)0, 0, totalCells);
        }
    }

    private void DrawTiles(SpriteBatch spriteBatch)
    {
        var pixelTex = _pixelTex;
        int ts = _tileSize;
        float camX = (_cachedAlignedTX - _tileMargin) * (float)ts;
        float camY = (_cachedAlignedTY - _tileMargin) * (float)ts;
        int surfaceY = _surfaceY;
        int maxLight = _maxLight;

        int startTX = Math.Max(0, _cachedAlignedTX - _tileMargin);
        int startTY = Math.Max(0, _cachedAlignedTY - _tileMargin);
        int endTX = Math.Min(_worldW - 1, (int)Math.Floor((camX + _screenW) / ts) + _tileMargin + 2);
        int endTY = Math.Min(_worldH - 1, (int)Math.Floor((camY + _screenH) / ts) + _tileMargin + 2);

        PreloadTileRegion(startTX, startTY, endTX, endTY);

        var scale = new Vector2(ts, ts);
        var lut = _tileColorLUT;
        int lutSize = _tileColorLUTSize;
        float invMax = maxLight > 0 ? 1f / maxLight : 1f;
        int bufIdx = 0;

        for (int y = startTY; y <= endTY; y++)
        {
            float sy = (float)Math.Floor(y * ts - camY);

            for (int x = startTX; x <= endTX; x++)
            {
                int tileId = _tileBuf[bufIdx];
                if (tileId == 0) { bufIdx++; continue; }

                int light = _lightBuf[bufIdx];

                Color color;
                if (light <= 0 && y >= surfaceY + 3)
                {
                    color = Color.Black;
                }
                else
                {
                    Color baseColor = (tileId >= 0 && tileId < lutSize) ? lut[tileId] : Color.White;
                    float lf = light * invMax;
                    color = new Color(
                        (int)(baseColor.R * lf),
                        (int)(baseColor.G * lf),
                        (int)(baseColor.B * lf),
                        baseColor.A
                    );
                }

                float sx = (float)Math.Floor(x * ts - camX);
                spriteBatch.Draw(pixelTex, new Vector2(sx, sy), null,
                    color, 0f, Vector2.Zero, scale, SpriteEffects.None, 0f);

                bufIdx++;
            }
        }
    }
}
