using System;
using System.IO;

namespace in254.Mod;

public sealed class ModExample1
{
    public static (int c, int d, int f) FunctionA(int a, int v)
    {
        var ctx = ModContextManager.Instance.Current;

        int c = a + v;
        int d = a - v;
        int f = a * v;

        Console.WriteLine($"FunctionA: a={a}, v={v}");
        return (c, d, f);
    }

    public static void FunctionZ(int t, int q, int e)
    {
        var ctx = ModContextManager.Instance.Current;
        int z = t + q + e;
        Console.WriteLine($"FunctionZ: t={t}, q={q}, e={e}, z={z}");
        ModLoader.Instance.CallHookAuto(nameof(FunctionZ), t, q, e);
    }

    public static void Run()
    {
        Console.WriteLine("Starting mod load and execution example 1...");

        string modsRoot = Path.Combine(AppContext.BaseDirectory, "Mod");
        ModLoader modLoader = new(modsRoot);
        modLoader.LoadMods();

        int a = 3, v = 5;
        var (c, d, f) = FunctionA(a, v);
        // Apply LUA hook externally
        ModLoader.Instance.CallHookAuto(nameof(FunctionA), a, v, c, d, f);

        int t = c, q = d, e = f;
        FunctionZ(t, q, e);

        Console.WriteLine("Mod example 1 completed.");
    }
}
