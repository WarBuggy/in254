using System;
using System.IO;
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
    /// Constructor builds the full path and registers it with TextureManager.
    /// </summary>
    /// <param name="assetFolder">Root asset folder from animation data.</param>
    /// <param name="folder">Subfolder of the texture.</param>
    /// <param name="file">Filename of the texture.</param>
    public AnimationFrame(string assetFolder, string folder, string file)
    {
        string fullPath = Path.Combine(assetFolder, folder, file);

        if (string.IsNullOrWhiteSpace(fullPath))
            throw new LocalizedError<ArgumentException>("system.animationFrame.invalidFullPath", fullPath);

        // Register with TextureManager and store the index
        TextureIndex = TextureManager.Instance.AddPath(fullPath);

        Log("system.animationFrame.frameCreated", fullPath, TextureIndex);
    }
    public Microsoft.Xna.Framework.Graphics.Texture2D Texture => TextureManager.Instance.GetTexture(TextureIndex);
}
