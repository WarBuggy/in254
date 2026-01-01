using System;

namespace in254.Core;

public abstract class LoggerBase
{
    private string ClassName => GetType().Name;

    protected void Log(params object[] args)
    {
        Console.WriteLine($"[{ClassName}] Log: {StringUtils.Localize(args)}");
    }

    protected void LogWarning(params object[] args)
    {
        Console.WriteLine($"[{ClassName}] Warning: {StringUtils.Localize(args)}");
    }

    protected void LogError(params object[] args)
    {
        Console.WriteLine($"[{ClassName}] Error: {StringUtils.Localize(args)}");
    }
}
