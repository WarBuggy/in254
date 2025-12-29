using System;
using in254.Localization;

namespace in254.Core;

public abstract class LoggerBase
{
    private string ClassName => GetType().Name;

    protected void Log(string key, params object[] args)
    {
        Console.WriteLine($"[{ClassName}] Log: {Localize(key, args)}");
    }

    protected void LogWarning(string key, params object[] args)
    {
        Console.WriteLine($"[{ClassName}] Warning: {Localize(key, args)}");
    }

    protected void LogError(string key, params object[] args)
    {
        Console.WriteLine($"[{ClassName}] Error: {Localize(key, args)}");
    }

    private static string Localize(string key, params object[] args)
    {
        string culture = LocalizationManager.Instance.CurrentCulture;
        string msg = LocalizationManager.Instance.Get(key, culture);
        return args.Length > 0 ? string.Format(msg, args) : msg;
    }


    /// <summary>
    /// Throws an exception of type TException with a localized message and class prefix.
    /// Usage: ThrowLocalized<ArgumentException>("key", arg1, arg2);
    /// </summary>
    protected TException ThrowLocalized<TException>(string key, params object[] args)
        where TException : Exception
    {
        string msg = $"[{ClassName}] {Localize(key, args)}";

        // Dynamically create the exception with message
        var exception = (TException)Activator.CreateInstance(typeof(TException), msg)!;

        throw exception;
    }
}
