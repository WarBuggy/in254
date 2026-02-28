using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using AxiomPlayground.GameFlag;
using AxiomPlayground.Modding;
using in254.Engine;

class Program
{
    static void Main(string[] args)
    {
        GameFlagManager.GetFlagsFromArgs(args);

        ModManager.Instance.DiscoverMods();
        var allMods = ModManager.Instance.GetAllModsSortedByDisplayName();
        Console.WriteLine("Discovered Mods:");
        foreach (var mod in allMods)
        {
            Console.WriteLine($"  {mod.DisplayName} (modId={mod.ModId}, path={ModManager.Instance.GetModFolderPath(mod)})");
        }

        var filteredMods = ApplyModConfig(allMods);

        ModManager.Instance.PopulateFinalLoadableMods(filteredMods);
        Console.WriteLine("Final Mods:");
        foreach (var mod in ModManager.Instance.FinalModList)
        {
            Console.WriteLine($"  {mod.DisplayName} (modId={mod.ModId}, path={ModManager.Instance.GetModFolderPath(mod)})");
        }

        EngineManager.Instance.Run();
    }

    private static List<Mod> ApplyModConfig(List<Mod> allMods)
    {
        const string configFile = "mods-config.json";
        if (!File.Exists(configFile))
            return allMods;

        try
        {
            var json = File.ReadAllText(configFile);
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            if (!root.TryGetProperty("mods", out var modsElement))
                return allMods;

            var reserved = ModManager.Instance.ReservedModIds;
            var filtered = new List<Mod>();

            foreach (var mod in allMods)
            {
                bool isReserved = false;
                foreach (var r in reserved)
                {
                    if (r.Equals(mod.ModId, StringComparison.OrdinalIgnoreCase))
                    {
                        isReserved = true;
                        break;
                    }
                }

                if (isReserved)
                {
                    filtered.Add(mod);
                    continue;
                }

                if (modsElement.TryGetProperty(mod.ModId, out var modEntry) &&
                    modEntry.TryGetProperty("enabled", out var enabledProp) &&
                    !enabledProp.GetBoolean())
                {
                    Console.WriteLine($"  [config] Disabled: {mod.DisplayName}");
                    continue;
                }

                filtered.Add(mod);
            }

            return filtered;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"  [config] Failed to read {configFile}: {ex.Message}");
            return allMods;
        }
    }
}