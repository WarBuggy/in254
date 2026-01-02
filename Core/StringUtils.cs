using System;
using in254.Localization;

namespace in254.Core;

public static class StringUtils
{
    /// <summary>
    /// Localizes a string using the LocalizationManager.
    /// The first argument is the key, remaining arguments are formatting arguments.
    /// If the last argument is an EndingWrapper, its value is used as the ending; otherwise, a period is appended.
    /// 
    /// Usage:
    ///     Localize("system.key")                                      -> "Localized message."
    ///     Localize("system.key", arg1, arg2)                          -> "Localized message with args."
    ///     Localize("system.key", arg1, arg2, new EndingWrapper("..."))-> "Localized message with args..."
    /// </summary>
    /// <param name="args">First arg is key, remaining are optional formatting args, optional EndingWrapper at end</param>
    /// <returns>Localized and formatted string</returns>
    public static string Localize(params object[] args)
    {
        if (args.Length == 0)
            throw new ArgumentException("[StringUtils.Localize] At least one argument (the localization key) must be provided.");

        string key = args[0]?.ToString() ?? throw new ArgumentNullException("Localization key cannot be null.");

        // Default ending
        string ending = ".";

        // Extract formatting arguments
        object[] formatArgs = [];
        if (args.Length > 1)
        {
            int formatLength = args.Length - 1;
            // Check if last arg is EndingWrapper
            if (args[^1] is EndingWrapper ew)
            {
                ending = ew.Value;
                formatLength--; // exclude the last element from formatArgs
            }
            // Copy everything after the first element up to formatLength
            if (formatLength > 0)
            {
                formatArgs = new object[formatLength];
                Array.Copy(args, 1, formatArgs, 0, formatLength);
            }
        }
        string message = LocalizationManager.Instance.Get(key);
        string msg = formatArgs.Length > 0 ? string.Format(message, formatArgs) : message;
        return msg + ending;
    }
}

/// <summary>
/// Small helper to wrap a custom ending when calling Localize.
/// </summary>
public readonly struct EndingWrapper(string value)
{
    public string Value { get; } = value;
}