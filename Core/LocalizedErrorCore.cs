using System;
using AxiomPlayground.Localization;

namespace in254.Core;

public sealed class LocalizedErrorCore<TException> : LocalizedError<TException> where TException : Exception
{
    private const string MOD_ID = "Core";

    public LocalizedErrorCore(string key, params object[] args)
        : base(MOD_ID)
    {
        Throw(key, args);
    }

    public LocalizedErrorCore(EndingWrapper endingWrapper, string key, params object[] args)
        : base(MOD_ID)
    {
        Throw(endingWrapper, key, args);
    }
}
