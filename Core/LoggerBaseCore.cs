using AxiomPlayground.Localization;
using AxiomPlayground.Modding;

namespace in254.Core;

public class LoggerBaseCore : LoggerBase
{
    public LoggerBaseCore() : base(ModManager.CORE_MOD_ID) { }
}