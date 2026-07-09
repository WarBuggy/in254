using System;
using AxiomPlayground.Localization;
using AxiomPlayground.Shared;

namespace in254.Core;

public sealed class LocalizedErrorCore<TException> : LocalizedError<TException> where TException : Exception
{
    public LocalizedErrorCore(string key, params object[] args)
        : base(ModSystemPolicy.CORE_MOD_ID)
    {
        Throw(key, args);
    }

    public LocalizedErrorCore(EndingWrapper endingWrapper, string key, params object[] args)
        : base(ModSystemPolicy.CORE_MOD_ID)
    {
        Throw(endingWrapper, key, args);
    }
}
