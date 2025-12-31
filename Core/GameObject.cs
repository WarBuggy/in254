using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace in254.Core;

/// <summary>
/// Base class for all world objects.
/// Does NOT handle animation, input, or game logic.
/// </summary>
public abstract class GameObject(Vector2 position) : LoggerBase
{
    public Vector2 Position { get; protected set; } = position;
    public bool IsVisible { get; set; } = true;
    public Dictionary<string, object> ModData { get; } = [];

    public virtual void SetPosition(float x, float y)
    {
        Position = new Vector2(x, y);
    }
}
