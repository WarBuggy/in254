using System;

namespace in254.Core;

public abstract class LoggerBase
{
    private string ClassName => GetType().Name;

    protected void Log(string key, params object[] args)
    {
        Console.WriteLine($"[{ClassName}] Log: {StringUtils.Localize(key, args)}");
    }

    protected void LogWarning(string key, params object[] args)
    {
        Console.WriteLine($"[{ClassName}] Warning: {StringUtils.Localize(key, args)}");
    }

    protected void LogError(string key, params object[] args)
    {
        Console.WriteLine($"[{ClassName}] Error: {StringUtils.Localize(key, args)}");
    }
}
