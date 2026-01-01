using System.Collections.Generic;
namespace in254.Engine.Animation;

public sealed class Animation
{
    public string Name { get; set; } = string.Empty;
    public string BaseComponent { get; set; } = string.Empty;
    public Dictionary<string, AnimationComponent> Components { get; set; } = [];
}
