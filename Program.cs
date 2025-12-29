// using var engineManager = new in254.Engine.EngineManager();
// engineManager.Run();

using in254.Engine;
using in254.Localization;
using System;
using in254.Data;
using System.Collections.Generic;

class Program
{
    static void Main()
    {
        LocalizationManager.Instance.LoadAll();
        SettingManager.Instance.Load();

        var dm = DataManager.Instance;

        // Load all JSON data
        dm.LoadAll();

        Console.WriteLine("=== Raw Blocks Debug Print ===");
        foreach (var kvp in dm.GetValue<Dictionary<string, object>>("levelData"))
        {
            Console.WriteLine($"{kvp.Key}: {kvp.Value}");
        }

        // Test GetByPath
        int leftCell = dm.GetValue<int>("levelData.leftSide.cell");
        int leftWall = dm.GetValue<int>("levelData.leftSide.wall");
        int rightCell = dm.GetValue<int>("levelData.rightSide.cell");
        int width = dm.GetValue<int>("levelData.width");
        int height = dm.GetValue<int>("levelData.height");

        Console.WriteLine($"leftSide.cell = {leftCell}");
        Console.WriteLine($"leftSide.wall = {leftWall}");
        Console.WriteLine($"rightSide.cell = {rightCell}");
        Console.WriteLine($"width = {width}");
        Console.WriteLine($"height = {height}");

        // Test type mismatch (should throw localized exception)
        try
        {
            string invalid = dm.GetValue<string>("levelData.width");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Caught exception as expected: {ex.Message}");
        }

        // Test non-existent path (should throw localized exception)
        try
        {
            int missing = dm.GetValue<int>("levelData.center.cell");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Caught exception as expected: {ex.Message}");
        }
    }
}

