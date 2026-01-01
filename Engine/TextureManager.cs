using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Content;
using in254.Core;
using System.IO;
using System.Threading;

namespace in254.Engine;

/// <summary>
/// Singleton manager for loading and storing textures.
/// Maps fullPath -> Texture2D and index -> fullPath.
/// </summary>
public sealed class TextureManager : LoggerBase
{
    private static readonly TextureManager _instance = new();
    public static TextureManager Instance => _instance;
    private readonly Dictionary<string, Texture2D> _texturesByPath = [];
    private readonly Dictionary<int, string> _indexToPath = [];
    private int _nextIndex = 0;
    private ContentManager _contentManager;
    private readonly Lock _lock = new();

    private TextureManager() { }

    /// <summary>
    /// Initialize TextureManager with MonoGame ContentManager.
    /// Must be called before loading textures.
    /// </summary>
    public void Initialize(ContentManager content)
    {
        _contentManager = content ?? throw new LocalizedError<ArgumentNullException>("system.textureManager.contentManagerNull");
        Log("system.textureManager.initialized");
    }

    /// <summary>
    /// Adds a texture by fullPath. Returns a unique index.
    /// If already loaded, returns existing index.
    /// </summary>
    public int AddPath(string fullPath)
    {
        if (string.IsNullOrWhiteSpace(fullPath))
            throw new LocalizedError<ArgumentException>("system.textureManager.invalidPath", fullPath);
        lock (_lock)
        {
            if (_texturesByPath.ContainsKey(fullPath))
            {
                // Return existing index
                int existingIndex = GetExistingIndex(fullPath);
                if (existingIndex != -1)
                    return existingIndex;
            }

            if (_contentManager == null)
                throw new LocalizedError<InvalidOperationException>("system.textureManager.notInitialized");

            Texture2D texture;
            try
            {
                // Load texture from fullPath (without extension, MonoGame Content expects relative path)
                string assetPath = Path.ChangeExtension(fullPath, null);
                texture = _contentManager.Load<Texture2D>(assetPath);
            }
            catch (Exception ex)
            {
                throw new LocalizedError<InvalidOperationException>("system.textureManager.loadFailed", fullPath, ex.Message);
            }

            // Store
            _texturesByPath[fullPath] = texture;
            int index = _nextIndex++;
            _indexToPath[index] = fullPath;

            Log("system.textureManager.textureLoaded", fullPath, index);
            return index;
        }
    }

    /// <summary>
    /// Get Texture2D by index.
    /// Resolves index -> fullPath -> Texture2D.
    /// </summary>
    public Texture2D GetTexture(int index)
    {
        if (!_indexToPath.TryGetValue(index, out string fullPath))
            throw new LocalizedError<KeyNotFoundException>("system.textureManager.indexNotFound", index);

        if (!_texturesByPath.TryGetValue(fullPath, out Texture2D texture))
            throw new LocalizedError<KeyNotFoundException>("system.textureManager.textureNotFound", fullPath);

        return texture;
    }

    /// <summary>
    /// Returns the existing index for a fullPath if it exists, or -1 if not found.
    /// </summary>
    private int GetExistingIndex(string fullPath)
    {
        foreach (var kvp in _indexToPath)
        {
            if (kvp.Value == fullPath)
                return kvp.Key;
        }
        return -1;
    }
}