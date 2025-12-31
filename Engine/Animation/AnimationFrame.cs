using System;
using in254.Core;

namespace in254.Engine.Animation;

/// <summary>
/// Represents a single frame of animation.
/// Stores an index into TextureManager to avoid repeated full paths.
/// Fully resolved: contains all information needed to render the frame.
/// </summary>
public sealed class AnimationFrame : LoggerBase
{
    /// <summary>Index into TextureManager pool for the frame graphic.</summary>
    public int TextureIndex { get; private set; }

    /// <summary>Layer for rendering order.</summary>
    public string Layer { get; set; } = string.Empty;

    /// <summary>Width of the frame.</summary>
    public int Width { get; set; }

    /// <summary>Height of the frame.</summary>
    public int Height { get; set; }

    /// <summary>Offset X relative to base component (default 0).</summary>
    public int OffsetX { get; set; } = 0;

    /// <summary>Offset Y relative to base component (default 0).</summary>
    public int OffsetY { get; set; } = 0;

    /// <summary>Offset X within the spritesheet (default 0).</summary>
    public int SpriteOffsetX { get; set; } = 0;

    /// <summary>Offset Y within the spritesheet (default 0).</summary>
    public int SpriteOffsetY { get; set; } = 0;

    /// <summary>
    /// Constructor takes full path and registers it in TextureManager.
    /// </summary>
    /// <param name="fullPath">Full path to the frame graphic.</param>
    public AnimationFrame(string fullPath)
    {
        if (string.IsNullOrWhiteSpace(fullPath))
            throw new LocalizedError<ArgumentException>("system.animationFrame.invalidFullPath", fullPath);

        // Register or reuse existing path in TextureManager
        TextureIndex = TextureManager.Instance.AddPath(fullPath);

        Log("system.animationFrame.frameCreated", fullPath, TextureIndex);
    }

    /// <summary>
    /// Retrieves the full path from TextureManager.
    /// </summary>
    public string FullPath => TextureManager.Instance.GetPath(TextureIndex);
}