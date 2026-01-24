using System;
using System.Collections.Generic;
using System.IO;
using in254.Core;
using Microsoft.Xna.Framework.Graphics;

namespace in254.Engine;

public sealed class TextureManager
{
    private static readonly TextureManager _instance = new();
    public static TextureManager Instance => _instance;
    private readonly LoggerBaseCore _logger = new();
    private static readonly string SPRITE_FOLDER = "Sprites/";

    // Dictionary<modId, Dictionary<textureId, (path, texture)>>
    private readonly Dictionary<string, Dictionary<int, (string path, Texture2D texture)>> _textures = new(StringComparer.OrdinalIgnoreCase);
    // Dictionary<modId, Dictionary<path, textureId>>
    private readonly Dictionary<string, Dictionary<string, int>> _pathToId = new(StringComparer.OrdinalIgnoreCase);
    // Incremental ID generator per mod
    private readonly Dictionary<string, int> _nextId = new(StringComparer.OrdinalIgnoreCase);

    private TextureManager() { }

    /// <summary>
    /// Registers a texture by modId + path. Returns textureId.
    /// If already loaded, returns existing ID.
    /// </summary>
    public int RegisterTexture(string modId, string modFolderPath, string folder, string file)
    {
        string path = Path.Combine(modFolderPath, SPRITE_FOLDER, folder, file);
        // Ensure mod dictionaries exist
        if (!_textures.TryGetValue(modId, out var modTextures))
        {
            modTextures = [];
            _textures[modId] = modTextures;
        }

        if (!_pathToId.TryGetValue(modId, out var modPathToId))
        {
            modPathToId = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            _pathToId[modId] = modPathToId;
        }

        if (!_nextId.TryGetValue(modId, out var nextId))
        {
            nextId = 1;
            _nextId[modId] = nextId;
        }

        // Check if path already loaded
        if (modPathToId.TryGetValue(path, out var existingId))
        {
            return existingId;
        }

        // Load texture from file
        if (!File.Exists(path))
            throw new LocalizedErrorCore<FileNotFoundException>("system.textureManager.textureFileNotFound", path);

        using var stream = File.OpenRead(path);
        var texture = Texture2D.FromStream(EngineManager.Instance.GraphicsDevice, stream);

        // Assign ID
        int textureId = nextId;
        nextId++;
        _nextId[modId] = nextId;

        // Store in dictionaries
        modTextures[textureId] = (path, texture);
        modPathToId[path] = textureId;

        _logger.Log("system.textureManager.registered", modId, path, textureId);
        return textureId;
    }

    /// <summary>
    /// Get a Texture2D by modId and textureId.
    /// </summary>
    public Texture2D GetTexture(string modId, int textureId)
    {
        if (_textures.TryGetValue(modId, out var modTextures) &&
            modTextures.TryGetValue(textureId, out var tuple))
        {
            return tuple.texture;
        }
        throw new LocalizedErrorCore<KeyNotFoundException>("system.textureManager.textureNotFound", modId, textureId);
    }
}