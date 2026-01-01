using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace in254.Data.DTO;

public sealed class AnimationComponentDTO
{
    public string Name { get; set; } = string.Empty;
    public string DefaultState { get; set; } = string.Empty;
    public Dictionary<string, AnimationStateDTO> StateList { get; set; } = [];
    /// <summary>File name of the frame graphic.</summary>
    public string File { get; set; } = string.Empty;
    /// <summary>Folder containing the file.</summary>
    public string Folder { get; set; } = string.Empty;
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
}
