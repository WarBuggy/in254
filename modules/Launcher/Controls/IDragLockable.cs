namespace Launcher.Controls;

/// <summary>
/// Items implementing this interface can prevent being dragged or dropped onto.
/// Items not implementing this interface are treated as unlocked.
/// </summary>
public interface IDragLockable
{
    bool IsLocked { get; }
}
