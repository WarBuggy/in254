using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace in254.Localization;

public sealed class LocalizationManager
{
    private static readonly LocalizationManager _instance = new();
    public static LocalizationManager Instance => _instance;

    private static readonly string LOCALIZATION_ROOT =
        Path.Combine(AppContext.BaseDirectory, "Localization");
    private const string DEFAULT_CULTURE = "en-US";
    public string DefaultCulture => DEFAULT_CULTURE;
    private string _currentCulture = DEFAULT_CULTURE;

    // culture -> (key -> string)
    private readonly Dictionary<string, Dictionary<string, string>> _localizations
        = new(StringComparer.OrdinalIgnoreCase);

    public IReadOnlyCollection<string> AvailableCultures => _localizations.Keys;

    private LocalizationManager() { }

    public void LoadAll()
    {
        if (!Directory.Exists(LOCALIZATION_ROOT))
        {
            throw new InvalidOperationException(
                $"[LocalizationManager] Localization folder not found: {LOCALIZATION_ROOT}."
            );
        }

        foreach (string cultureDir in Directory.GetDirectories(LOCALIZATION_ROOT))
        {
            string cultureName = Path.GetFileName(cultureDir);
            LoadCulture(cultureName, cultureDir);
        }

        if (!_localizations.ContainsKey(DEFAULT_CULTURE))
        {
            throw new InvalidOperationException(
                $"[LocalizationManager] Default culture '{DEFAULT_CULTURE}' is missing. Game cannot start."
            );
        }

        Console.WriteLine($"[LocalizationManager] Loaded {_localizations.Count} cultures.");
    }

    private void LoadCulture(string culture, string culturePath)
    {
        Console.WriteLine($"[LocalizationManager] Loading culture: {culture}");

        if (!_localizations.TryGetValue(culture, out var table))
        {
            table = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            _localizations[culture] = table;
        }

        foreach (string file in Directory.GetFiles(culturePath, "*.json", SearchOption.AllDirectories))
        {
            LoadLocalizationFile(table, file);
        }
    }

    private static void LoadLocalizationFile(Dictionary<string, string> table, string filePath)
    {
        try
        {
            string jsonText = File.ReadAllText(filePath);
            using JsonDocument doc = JsonDocument.Parse(jsonText);

            if (doc.RootElement.ValueKind != JsonValueKind.Object)
            {
                Console.WriteLine($"[LocalizationManager] Warning: Skipping non-object JSON file: {filePath}");
                return;
            }

            foreach (JsonProperty prop in doc.RootElement.EnumerateObject())
            {
                table[prop.Name] = prop.Value.GetString() ?? string.Empty;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[LocalizationManager] Error: Failed to load localization file '{filePath}': {ex.Message}");
        }
    }

    public string Get(string key)
    {
        return Get(key, CurrentCulture);
    }

    public string Get(string key, string culture)
    {
        if (_localizations.TryGetValue(culture, out var table) &&
            table.TryGetValue(key, out var value))
        {
            return value;
        }

        // fallback to default language
        if (_localizations[DEFAULT_CULTURE].TryGetValue(key, out var fallback))
        {
            return fallback;
        }

        // final fallback: show key itself (useful during dev)
        return key;
    }

    public string CurrentCulture
    {
        get => _currentCulture;
        set
        {
            if (!_localizations.ContainsKey(value))
            {
                Console.WriteLine(
                    $"[LocalizationManager] Warning: Attempted to set unknown culture '{value}'. Falling back to default '{DEFAULT_CULTURE}'."
                );
                _currentCulture = DEFAULT_CULTURE;
            }
            else
            {
                _currentCulture = value;
            }
        }
    }
}
