using System;
using System.Collections.Generic;

namespace in254.Mod;

public sealed class ModContext
{
    private readonly Dictionary<string, object> _data = new(StringComparer.OrdinalIgnoreCase);

    public string ModName { get; }

    internal ModContext(string modName)
    {
        ModName = modName;
    }

    public void Set(string key, object value)
    {
        _data[key] = value;
    }

    public object Get(string key, object defaultValue = null!)
    {
        if (_data.TryGetValue(key, out var value))
            return value;
        return defaultValue;
    }
    public bool HasKey(string key) => _data.ContainsKey(key);

    public void Remove(string key) => _data.Remove(key);

    public void Clear() => _data.Clear();
}
