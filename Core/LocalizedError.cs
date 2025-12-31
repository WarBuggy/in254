using System;
using System.Diagnostics;

namespace in254.Core;

/// <summary>
/// A helper class that immediately throws a localized exception of type <typeparamref name="TException"/> 
/// upon construction. This class is intended for rare or fatal errors where you want:
/// 1. A fully localized exception message.
/// 2. Automatic prefixing of the message with the caller's class name.
/// 3. Optional preservation of an inner exception.
/// 
/// Important behavior:
/// - The constructor always throws. The LocalizedError object itself is never actually created.
/// - <typeparamref name="TException"/> must define a constructor with the signature:
///       (string message, Exception innerException)
///   If it does not, an <see cref="InvalidOperationException"/> is thrown at runtime.
/// - Automatically resolves the caller's class name using stack inspection.
/// 
/// Usage examples:
/// <code>
/// // Throwing with just localization key and arguments:
/// throw new LocalizedError<InvalidOperationException>(
///     "system.someKey",
///     arg1,
///     arg2,
///     new EndingWrapper("...") // optional
/// );
///
/// // Throwing with an inner exception:
/// throw new LocalizedError<InvalidOperationException>(
///     originalException,       // first arg is innerException
///     "system.someKey",
///     arg1,
///     arg2
/// );
/// </code>
/// 
/// Notes:
/// - Because the constructor throws immediately, no "return" is required after instantiation.
/// - Stack trace inspection in <see cref="ResolveCallerClassName"/> is slightly expensive, 
///   so this class should not be used in performance-critical loops.
/// - Supports custom ending characters via <see cref="StringUtils.EndingWrapper"/> passed 
///   as the last argument.
/// </summary>
public sealed class LocalizedError<TException> : Exception where TException : Exception
{
    /// <summary>
    /// Constructor that immediately throws the exception of type <typeparamref name="TException"/>.
    /// 
    /// Parameters (via <paramref name="args"/>):
    /// - Optional first argument: if of type <see cref="Exception"/>, treated as the inner exception.
    /// - Subsequent arguments: passed to <see cref="StringUtils.Localize(object[])"/> for message formatting.
    /// - Last argument may optionally be an <see cref="StringUtils.EndingWrapper"/> to override the default period at the end.
    /// 
    /// Throws:
    /// - An instance of <typeparamref name="TException"/> with the localized message.
    /// - <see cref="InvalidOperationException"/> if <typeparamref name="TException"/> does not define the required constructor.
    /// </summary>
    public LocalizedError(params object[] args) : base()
    {
        // Optional inner exception
        Exception innerException = null;
        object[] localizeArgs;

        if (args.Length > 0 && args[0] is Exception ex)
        {
            innerException = ex;
            localizeArgs = args[1..]; // all args except first
        }
        else
        {
            localizeArgs = args;
        }

        // Resolve the caller's class name for message prefix
        string className = ResolveCallerClassName();

        // Generate the localized message using StringUtils
        string message = $"[{className}] {StringUtils.Localize(localizeArgs)}";

        // Retrieve the required constructor for the target exception type
        var ctor = typeof(TException).GetConstructor([typeof(string), typeof(Exception)])
                   ?? throw new InvalidOperationException(
                        $"[LocalizedError] Exception type {typeof(TException).Name} must define a constructor " +
                        "(string message, Exception innerException)."
                   );

        // Create and immediately throw the actual exception
        var exception = (TException)ctor.Invoke([message, innerException]);
        throw exception;
    }

    /// <summary>
    /// Inspects the stack trace to determine the class name of the caller
    /// that instantiated the LocalizedError. Intended only for rare error cases.
    /// 
    /// Returns "UnknownClass" if no suitable class is found.
    /// </summary>
    private static string ResolveCallerClassName()
    {
        var stackTrace = new StackTrace(skipFrames: 2, fNeedFileInfo: false);

        foreach (var frame in stackTrace.GetFrames()!)
        {
            var type = frame.GetMethod()?.DeclaringType;
            if (type != null && !type.IsGenericType)
                return type.Name;
        }

        return "UnknownClass";
    }
}
