using System.Text.Json;
using System.Text.Json.Serialization;

namespace Launcher.Models;

public sealed class ModInfo
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = "";

    [JsonPropertyName("version")]
    public string Version { get; set; } = "";

    [JsonPropertyName("author")]
    public string Author { get; set; } = "";

    [JsonPropertyName("description")]
    public string Description { get; set; } = "";

    [JsonPropertyName("tags")]
    public List<string> Tags { get; set; } = [];

    [JsonPropertyName("gameVersion")]
    public string GameVersion { get; set; } = "";

    [JsonPropertyName("preview")]
    public string Preview { get; set; } = "";

    [JsonPropertyName("screenshots")]
    public List<string> Screenshots { get; set; } = [];

    [JsonPropertyName("workshopId")]
    public string WorkshopId { get; set; } = "";

    [JsonPropertyName("url")]
    public string Url { get; set; } = "";

    [JsonPropertyName("dependencies")]
    public List<string> Dependencies { get; set; } = [];

    public static ModInfo? Load(string modFolder)
    {
        var path = Path.Combine(modFolder, "mod.json");
        if (!File.Exists(path)) return null;
        try
        {
            var json = File.ReadAllText(path);
            return JsonSerializer.Deserialize<ModInfo>(json, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });
        }
        catch { return null; }
    }
}
