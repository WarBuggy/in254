using System;
using AxiomPlayground.Localization;
using AxiomPlayground.Modding;

namespace in254.Core;

public sealed class LocalizedErrorCore<TException> : LocalizedError<TException> where TException : Exception
{
    public LocalizedErrorCore(string key, params object[] args)
        : base(ModManager.CORE_MOD_ID)
    {
        Throw(key, args);
    }

    public LocalizedErrorCore(EndingWrapper endingWrapper, string key, params object[] args)
        : base(ModManager.CORE_MOD_ID)
    {
        Throw(endingWrapper, key, args);
    }
}
