using System;
using AxiomPlayground.GameFlag;
using AxiomPlayground.Modding;
using in254.Engine;

class Program
{
    static void Main(string[] args)
    {
        GameFlagManager.GetFlagsFromArgs(args);

        ModManager.Instance.LoadModsFromSelection();

        Console.WriteLine("Final Mods:");
        foreach (var mod in ModManager.Instance.LoadedMods)
        {
            Console.WriteLine($"  {mod.Info.Name} (modId={mod.Info.Id}, path={ModManager.Instance.GetModFolderPath(mod)})");
        }

        EngineManager.Instance.Run();
    }
}