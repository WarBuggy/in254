using System;
using System.Collections.Generic;
using in254.Core;

namespace in254.Engine;

/// <summary>
/// Manages all unique file paths for animation frames.
/// Later can also load and cache Texture2D.
/// </summary>
public sealed class TextureManager : LoggerBase
{
    private static readonly TextureManager _instance = new();
    public static TextureManager Instance => _instance;

    // Pool of unique full file paths
    private readonly List<string> _fullPathPool = [];
    private readonly Dictionary<string, int> _pathToIndex = new(StringComparer.OrdinalIgnoreCase);

    private TextureManager() { }

    /// <summary>
    /// Adds a path to the pool if it does not exist yet.
    /// Returns the index in the pool.
    /// </summary>
    public int AddPath(string fullPath)
    {
        if (string.IsNullOrWhiteSpace(fullPath))
            throw new LocalizedError<ArgumentException>("system.textureManager.invalidPath", fullPath);

        if (_pathToIndex.TryGetValue(fullPath, out int index))
        {
            Log("system.textureManager.pathAlreadyExists", fullPath);
            return index;
        }

        index = _fullPathPool.Count;
        _fullPathPool.Add(fullPath);
        _pathToIndex[fullPath] = index;

        Log("system.textureManager.pathAdded", fullPath, index);
        return index;
    }

    /// <summary>
    /// Get the full path by index.
    /// </summary>
    public string GetPath(int index)
    {
        if (index < 0 || index >= _fullPathPool.Count)
            throw new LocalizedError<IndexOutOfRangeException>("system.textureManager.invalidIndex", index);

        return _fullPathPool[index];
    }

    /// <summary>
    /// Get all paths (read-only).
    /// </summary>
    public IReadOnlyList<string> AllPaths => _fullPathPool.AsReadOnly();

    /// <summary>
    /// Total number of unique paths stored.
    /// </summary>
    public int Count => _fullPathPool.Count;
}
