using System;
using System.Collections.Generic;
using System.IO;
using FontStashSharp;
using AxiomPlayground.Modding;
using in254.Core;

namespace in254.Engine;

public sealed class FontManager
{
    private static readonly FontManager _instance = new();
    public static FontManager Instance => _instance;
    private readonly LoggerBaseCore _logger = new();

    private static readonly string FONTS_FOLDER = "Engine/Fonts/";
    private static readonly string DEFAULT_FONT_FILE = "default.ttf";

    /// <summary>
    /// The reserved name for the engine's built-in default font.
    /// </summary>
    public const string DefaultFontName = "default";

    // fontName → FontSystem (each font is its own FontSystem so sizes are cached independently)
    private readonly Dictionary<string, FontSystem> _fonts = new(StringComparer.OrdinalIgnoreCase);

    // Reference counting: fontName → refCount
    private readonly Dictionary<string, int> _refCounts = new(StringComparer.OrdinalIgnoreCase);
    // Per-mod font tracking: modId → set of fontNames loaded by that mod
    private readonly Dictionary<string, HashSet<string>> _modFonts = new(StringComparer.OrdinalIgnoreCase);

    private FontManager() { }

    /// <summary>
    /// Initialize and load the engine default font.
    /// Call from EngineManager.LoadContent().
    /// </summary>
    public void Initialize()
    {
        string fontPath = Path.Combine(FONTS_FOLDER, DEFAULT_FONT_FILE);
        if (!File.Exists(fontPath))
            fontPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, FONTS_FOLDER, DEFAULT_FONT_FILE);

        if (!File.Exists(fontPath))
            throw new LocalizedErrorCore<FileNotFoundException>(
                "system.fontManager.fontFileNotFound", fontPath);

        LoadFontInternal(DefaultFontName, fontPath);
        _refCounts[DefaultFontName] = 1; // engine holds permanent reference
        _logger.Log("system.fontManager.initialized");
    }

    /// <summary>
    /// Load a .ttf/.otf font from a mod's folder and register it under a name.
    /// The file path is relative to the mod's root (e.g. "Fonts/pixel.ttf").
    /// </summary>
    public void LoadFont(string fontName, string modId, string relativePath)
    {
        if (string.IsNullOrWhiteSpace(fontName))
            throw new ArgumentException("[FontManager] fontName cannot be empty.");

        // Track which mod loaded this font
        if (!_modFonts.TryGetValue(modId, out var modFontSet))
        {
            modFontSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            _modFonts[modId] = modFontSet;
        }
        modFontSet.Add(fontName);

        if (_fonts.ContainsKey(fontName))
        {
            _refCounts[fontName] = _refCounts.GetValueOrDefault(fontName) + 1;
            return; // already loaded, just added a reference
        }

        string modFolder = ModManager.Instance.GetModFolderPath(modId);
        string fullPath = Path.Combine(modFolder, relativePath);

        if (!File.Exists(fullPath))
            throw new LocalizedErrorCore<FileNotFoundException>(
                "system.fontManager.fontFileNotFound", fullPath);

        LoadFontInternal(fontName, fullPath);
        _refCounts[fontName] = 1;
        Console.WriteLine($"[FontManager] Loaded font '{fontName}' from mod '{modId}' ({relativePath}).");
    }

    /// <summary>
    /// Get a DynamicSpriteFont at the requested pixel size for a named font.
    /// </summary>
    public DynamicSpriteFont GetFont(int size, string fontName = null)
    {
        fontName ??= DefaultFontName;

        if (!_fonts.TryGetValue(fontName, out var fontSystem))
            throw new LocalizedErrorCore<KeyNotFoundException>(
                "system.fontManager.fontNotFound", fontName);

        return fontSystem.GetFont(size);
    }

    /// <summary>
    /// Check if a named font is loaded.
    /// </summary>
    public bool HasFont(string fontName)
    {
        return _fonts.ContainsKey(fontName);
    }

    /// <summary>
    /// Decrement refCount for a font. Disposes when refCount reaches 0.
    /// Skips the default font (engine holds permanent reference).
    /// </summary>
    public void Release(string fontName)
    {
        if (string.Equals(fontName, DefaultFontName, StringComparison.OrdinalIgnoreCase))
            return; // never release the default font

        if (!_refCounts.TryGetValue(fontName, out var count))
            return;

        count--;
        if (count <= 0)
        {
            if (_fonts.TryGetValue(fontName, out var fontSystem))
            {
                fontSystem.Dispose();
                _fonts.Remove(fontName);
            }
            _refCounts.Remove(fontName);
            Console.WriteLine($"[FontManager] Released font '{fontName}' (disposed).");
        }
        else
        {
            _refCounts[fontName] = count;
        }
    }

    /// <summary>
    /// Release all fonts loaded by a specific mod.
    /// </summary>
    public void UnloadAllForMod(string modId)
    {
        if (!_modFonts.TryGetValue(modId, out var modFontSet))
            return;

        foreach (var fontName in modFontSet)
            Release(fontName);

        modFontSet.Clear();
        Console.WriteLine($"[FontManager] Released all fonts for mod '{modId}'.");
    }

    private void LoadFontInternal(string fontName, string fullPath)
    {
        var fontSystem = new FontSystem();
        byte[] fontData = File.ReadAllBytes(fullPath);
        fontSystem.AddFont(fontData);
        _fonts[fontName] = fontSystem;
    }
}
