
using System.Collections.Generic;
namespace in254.Engine.Animation;

public sealed class AnimationComponent
{
    public string Name { get; set; } = string.Empty;
    public string DefaultState { get; set; } = string.Empty;
    public Dictionary<string, AnimationState> States { get; set; } = [];
}