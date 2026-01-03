using System;
using System.Collections.Generic;

namespace in254.Mod;

public sealed class ModContextManager
{
    private static readonly ModContextManager _instance = new();
    public static ModContextManager Instance => _instance;

    private readonly Dictionary<string, ModContext> _contexts = new(StringComparer.OrdinalIgnoreCase);

    // Optional current mod tracking
    private string _currentMod;

    private ModContextManager()
    {
        // NO default "Global" context
    }

    /// <summary>
    /// Get the context for a mod, creating it if it doesn't exist.
    /// Updates the current mod.
    /// </summary>
    public ModContext ForMod(string modName)
    {
        if (!_contexts.TryGetValue(modName, out var context))
        {
            context = new ModContext(modName);
            _contexts[modName] = context;
        }
        _currentMod = modName;
        return context;
    }

    /// <summary>
    /// Convenient access to the current mod context.
    /// Throws if no current mod is set.
    /// </summary>
    public ModContext Current
    {
        get
        {
            if (_currentMod == null)
                throw new InvalidOperationException("No current mod context is set.");
            return _contexts[_currentMod];
        }
    }

    /// <summary>
    /// Get another mod's context without changing the current mod.
    /// </summary>
    public ModContext GetMod(string modName)
    {
        if (_contexts.TryGetValue(modName, out var context))
            return context;

        context = new ModContext(modName);
        _contexts[modName] = context;
        return context;
    }

    /// <summary>
    /// Enumerates all mod contexts currently loaded.
    /// </summary>
    public IEnumerable<ModContext> AllContexts => _contexts.Values;

    /// <summary>
    /// Reset all mod contexts (useful for testing or restarting a game session)
    /// </summary>
    public void ClearAll()
    {
        _contexts.Clear();
        _currentMod = null;
    }
}