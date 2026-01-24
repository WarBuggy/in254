using AxiomPlayground.Data;

namespace in254.Core;

public class BaseManagerCore
(
    string categoryName,
    bool requiredProcessedPaths = false,
    string processedCategoryName = null
) : BaseManager(categoryName, requiredProcessedPaths, processedCategoryName)
{
    protected LoggerBaseCore _logger = new();
}
