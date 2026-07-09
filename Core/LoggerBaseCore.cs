using AxiomPlayground.Localization;
using AxiomPlayground.Shared;

namespace in254.Core;

public class LoggerBaseCore : LoggerBase
{
    public LoggerBaseCore() : base(ModSystemPolicy.CORE_MOD_ID) { }
}