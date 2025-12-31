using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using in254.Core;

namespace in254.Data;

public sealed class DataManager : LoggerBase
{
    // --- Singleton ---
    private static readonly DataManager _instance = new();
    public static DataManager Instance => _instance;

    // --- Data storage ---
    private readonly Dictionary<string, JsonElement> _blocks =
        new(StringComparer.OrdinalIgnoreCase);

    // --- Paths ---
    private static readonly string DATA_DIRECTORY =
        Path.Combine(AppContext.BaseDirectory, "Data");

    private DataManager() { }

    // --- Load all JSON files from data directory ---
    public void LoadAll()
    {
        if (!Directory.Exists(DATA_DIRECTORY))
            throw new LocalizedError<InvalidOperationException>("system.dataManager.dataDirectoryNotFound", DATA_DIRECTORY);

        foreach (string file in Directory.EnumerateFiles(DATA_DIRECTORY, "*.json"))
        {
            LoadSingleFile(file);
        }

        Log("system.dataManager.loadedFiles", _blocks.Count);
    }

    private void LoadSingleFile(string filePath)
    {
        string jsonText = "";
        try
        {
            jsonText = File.ReadAllText(filePath);
        }
        catch (Exception ex)
        {
            throw new LocalizedError<IOException>("system.dataManager.failedToReadFile", filePath, ex.Message);
        }

        using JsonDocument doc = JsonDocument.Parse(jsonText);
        JsonElement root = doc.RootElement;

        if (!root.TryGetProperty("name", out JsonElement nameElement))
            throw new LocalizedError<InvalidDataException>("system.dataManager.missingName", filePath);

        if (!root.TryGetProperty("data", out JsonElement dataElement))
            throw new LocalizedError<InvalidDataException>("system.dataManager.missingData", filePath);

        string name = nameElement.GetString();
        if (string.IsNullOrWhiteSpace(name))
            throw new LocalizedError<InvalidDataException>("system.dataManager.invalidName", filePath);

        // Merge or add block
        if (_blocks.TryGetValue(name, out var existing))
            _blocks[name] = MergeJson(existing, dataElement);
        else
            _blocks[name] = dataElement.Clone();
    }

    /// <summary>
    /// Recursively merges two JsonElements (objects only). New values override existing ones.
    /// </summary>
    private static JsonElement MergeJson(JsonElement original, JsonElement incoming)
    {
        if (original.ValueKind != JsonValueKind.Object || incoming.ValueKind != JsonValueKind.Object)
            return incoming.Clone(); // not objects, just override

        using var doc = JsonDocument.Parse(original.GetRawText());
        var mergedDict = new Dictionary<string, JsonElement>(StringComparer.OrdinalIgnoreCase);

        // copy original properties
        foreach (var prop in doc.RootElement.EnumerateObject())
            mergedDict[prop.Name] = prop.Value.Clone();

        // merge incoming
        foreach (var prop in incoming.EnumerateObject())
        {
            if (mergedDict.TryGetValue(prop.Name, out var existing) &&
                existing.ValueKind == JsonValueKind.Object &&
                prop.Value.ValueKind == JsonValueKind.Object)
            {
                mergedDict[prop.Name] = MergeJson(existing, prop.Value);
            }
            else
                mergedDict[prop.Name] = prop.Value.Clone();
        }

        // serialize merged dictionary back to JsonElement
        string mergedJson = JsonSerializer.Serialize(mergedDict);
        using JsonDocument mergedDoc = JsonDocument.Parse(mergedJson);
        return mergedDoc.RootElement.Clone();
    }

    /// <summary>
    /// Retrieve a JsonElement or value by a dot-separated path string.
    /// Example: "levelData.left.cell"
    /// </summary>
    public JsonElement GetByPath(string path)
    {
        if (string.IsNullOrWhiteSpace(path))
            throw new LocalizedError<ArgumentException>("system.dataManager.invalidPath", path);

        var parts = path.Split('.', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 0)
            throw new LocalizedError<ArgumentException>("system.dataManager.invalidPath", path);

        // First part is the block name
        string blockName = parts[0];
        if (!_blocks.TryGetValue(blockName, out var element))
            throw new LocalizedError<KeyNotFoundException>("system.dataManager.blockNotFound", blockName);

        // Walk nested properties
        for (int i = 1; i < parts.Length; i++)
        {
            if (element.ValueKind != JsonValueKind.Object)
                throw new LocalizedError<InvalidOperationException>(
                    "system.dataManager.invalidPropertyType", parts[i - 1], blockName
                );

            if (!element.TryGetProperty(parts[i], out element))
                throw new LocalizedError<KeyNotFoundException>("system.dataManager.propertyNotFound", parts[i], blockName);
        }

        return element;
    }

    public T GetValue<T>(string path)
    {
        var elem = GetByPath(path);

        try
        {
            return elem.Deserialize<T>()!;
        }
        catch (Exception)
        {
            throw new LocalizedError<InvalidOperationException>("system.dataManager.propertyTypeMismatch", path, typeof(T).Name);
        }
    }
}
