namespace in254.Engine.Animation;

public sealed class AnimationState
{
    public string Name { get; set; } = string.Empty;
    public AnimationFrame[] Frames { get; set; } = [];
}