using System.Text.Json;
using System.Text.Json.Serialization;

namespace Launcher.Models;

public sealed class ModsConfig
{
    private const string CONFIG_FILE = "mods-config.json";

    [JsonPropertyName("version")]
    public int Version { get; set; } = 1;

    [JsonPropertyName("modOrder")]
    public List<string> ModOrder { get; set; } = [];

    [JsonPropertyName("mods")]
    public Dictionary<string, ModConfigEntry> Mods { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    public static ModsConfig Load()
    {
        if (!File.Exists(CONFIG_FILE))
            return new ModsConfig();

        try
        {
            var json = File.ReadAllText(CONFIG_FILE);
            return JsonSerializer.Deserialize<ModsConfig>(json) ?? new ModsConfig();
        }
        catch
        {
            return new ModsConfig();
        }
    }

    public void Save()
    {
        var options = new JsonSerializerOptions { WriteIndented = true };
        var json = JsonSerializer.Serialize(this, options);
        File.WriteAllText(CONFIG_FILE, json);
    }
}

public sealed class ModConfigEntry
{
    [JsonPropertyName("enabled")]
    public bool Enabled { get; set; } = true;
}
