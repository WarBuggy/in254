using System;
using AxiomPlayground.GameFlag;
using AxiomPlayground.Modding;
using in254.Core;
using in254.Engine;
using Microsoft.Xna.Framework;
using MoonSharp.Interpreter;

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

        ModManager.Instance.PopulateFinalLoadableMods(allMods);
        Console.WriteLine("Final Mods:");
        foreach (var mod in ModManager.Instance.FinalModList)
        {
            Console.WriteLine($"  {mod.DisplayName} (modId={mod.ModId}, path={ModManager.Instance.GetModFolderPath(mod)})");
        }

        EngineManager.Instance.Run();

    }
}