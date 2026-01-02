using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using in254.Core;

namespace in254.Localization;

public sealed class LocalizationManager
{
    private static readonly LocalizationManager _instance = new();
    public static LocalizationManager Instance => _instance;
    private static readonly string LOCALIZATION_ROOT = Path.Combine(AppContext.BaseDirectory, "Localization");
    private const string DEFAULT_CULTURE = "en-US";
    public static string DefaultCulture => DEFAULT_CULTURE;
    private string _currentCulture = DEFAULT_CULTURE;
    // culture -> (key -> string)
    private readonly Dictionary<string, Dictionary<string, string>> _localizations
        = new(StringComparer.OrdinalIgnoreCase);
    public IReadOnlyCollection<string> AvailableCultures => _localizations.Keys;
    // Tracks keys that fell back to the default language
    private readonly HashSet<(string culture, string key)> _defaultFallbackLog = [];
    // Tracks keys that could not be found at all (corrupted keys)
    private readonly HashSet<(string culture, string key)> _corruptKeyLog = [];
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
        // Fallback to default language (visible)
        if (culture != DEFAULT_CULTURE &&
            _localizations.TryGetValue(DEFAULT_CULTURE, out var fallbackTable) &&
            fallbackTable.TryGetValue(key, out var fallback))
        {
            if (_defaultFallbackLog.Add((culture, key)))
                Console.WriteLine("[LocalizationManager] " + StringUtils.Localize("system.localizationManager.fallbackUsed", key, culture));
            return HandleDefaultFallback(fallback);
        }
        // final fallback: visibly corrupted key
        if (_corruptKeyLog.Add((culture, key)))
            Console.WriteLine("[LocalizationManager] " + StringUtils.Localize("system.localizationManager.keyNotFound", key, culture, DEFAULT_CULTURE));
        return CorruptKey(key);
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

    private static string CorruptKey(string key)
    {
        var map = new Dictionary<char, char>
        {
            ['a'] = 'à',
            ['A'] = 'Á',
            ['e'] = 'è',
            ['E'] = 'É',
            ['i'] = 'ì',
            ['I'] = 'Í',
            ['o'] = 'ò',
            ['O'] = 'Ó',
            ['u'] = 'ù',
            ['U'] = 'Ú',
            ['r'] = 'ř',
            ['R'] = 'Ř',
            ['s'] = 'š',
            ['S'] = 'Š',
        };

        var chars = key.ToCharArray();
        for (int i = 0; i < chars.Length; i++)
        {
            if (map.TryGetValue(chars[i], out char replacement))
                chars[i] = replacement;
        }

        return new string(chars);
    }

    private static string HandleDefaultFallback(string text)
    {
        return $"[{DEFAULT_CULTURE}] {text}";
    }
}
