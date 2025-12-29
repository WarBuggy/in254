using System;
using System.IO;
using System.Text.Json;
using in254.Core;
using in254.Localization;

namespace in254.Engine;

public class SettingManager : LoggerBase
{
    // --- Singleton ---
    private static readonly SettingManager _instance = new();
    public static SettingManager Instance => _instance;

    private readonly string SETTINGS_FILE_NAME = "Settings.json";

    // --- Paths ---
    private readonly string SettingsFolder;
    private readonly string SettingsFilePath;

    // --- Constructor ---
    private SettingManager()
    {
#if DEV_ENV
        SettingsFolder = Directory.GetCurrentDirectory();
#else
        SettingsFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "in254");
#endif
        if (!Directory.Exists(SettingsFolder))
            Directory.CreateDirectory(SettingsFolder);

        SettingsFilePath = Path.Combine(SettingsFolder, SETTINGS_FILE_NAME);
    }

    // --- GameSetting wrapper ---
    public class GameSetting<T>(T defaultValue)
    {
        public T Value { get; set; } = defaultValue;
        public T DefaultValue { get; } = defaultValue;
    }

    // --- General settings ---
    public class GeneralSettings
    {
        public GameSetting<string> Language { get; set; } =
            new(LocalizationManager.Instance.DefaultCulture);
    }

    // --- Internal storage ---
    private class SettingsData
    {
        public GeneralSettings General { get; set; } = new();
    }

    private SettingsData _settings = new();
    public GeneralSettings General => _settings.General;

    // --- Load settings ---
    public void Load()
    {
        try
        {
            if (!File.Exists(SettingsFilePath))
            {
                LogWarning("system.settingManager.settingNotFound", SettingsFilePath);
                Save(); // create default settings file
                return;
            }

            string jsonText = File.ReadAllText(SettingsFilePath);
            _settings = JsonSerializer.Deserialize<SettingsData>(jsonText) ?? new SettingsData();
        }
        catch (Exception ex)
        {
            LogWarning("system.settingManager.settingFailToLoad", ex.Message);
            _settings = new SettingsData();
        }
    }

    // --- Save settings ---
    public void Save()
    {
        try
        {
            string jsonText = JsonSerializer.Serialize(_settings, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(SettingsFilePath, jsonText);
        }
        catch (Exception ex)
        {
            LogError("system.settingManager.settingFailToSave", ex.Message);
        }
    }
}
