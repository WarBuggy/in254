using System.Collections.ObjectModel;
using System.Diagnostics;
using AxiomPlayground.Modding;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Launcher.Models;

namespace Launcher.ViewModels;

public enum GameState { Ready, Launching, Running, Error }

public partial class MainWindowViewModel : ObservableObject
{
    public ObservableCollection<ModEntryViewModel> Mods { get; } = [];

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(IsDetailVisible))]
    private ModEntryViewModel? _selectedMod;

    [ObservableProperty]
    [NotifyPropertyChangedFor(nameof(CanLaunch))]
    [NotifyPropertyChangedFor(nameof(LaunchButtonText))]
    private GameState _gameState = GameState.Ready;

    public bool CanLaunch => GameState is GameState.Ready or GameState.Error;
    public string LaunchButtonText => GameState switch
    {
        GameState.Launching => "Launching...",
        GameState.Running => "Game Running",
        GameState.Error => "Retry Launch",
        _ => "Launch Game",
    };

    [ObservableProperty]
    private string _statusText = string.Empty;

    [ObservableProperty]
    private int _totalModCount;

    [ObservableProperty]
    private int _enabledModCount;

    [ObservableProperty]
    private int _disabledModCount;

    public bool IsDetailVisible => SelectedMod != null;

    public MainWindowViewModel()
    {
        LoadMods();
        UpdateCounts();
    }

    private void LoadMods()
    {
        ModManager.Instance.DiscoverMods();
        var allMods = ModManager.Instance.GetAllModsSortedByDisplayName();
        var config = ModsConfig.Load();
        var reserved = ModManager.Instance.ReservedModIds;

        var entries = new List<ModEntryViewModel>();
        foreach (var mod in allMods)
        {
            bool isReserved = reserved.Contains(mod.ModId, StringComparer.OrdinalIgnoreCase);
            bool isEnabled = isReserved
                || !config.Mods.TryGetValue(mod.ModId, out var entry)
                || entry.Enabled;
            string source = mod.Source == ModSource.Steam ? "Steam" : "Local";
            string folderPath = ModManager.Instance.GetModFolderPath(mod);
            entries.Add(new ModEntryViewModel(mod.ModId, mod.DisplayName, isReserved, isEnabled, source, folderPath));
        }

        // Apply saved order if available
        if (config.ModOrder.Count > 0)
        {
            var ordered = new List<ModEntryViewModel>();
            foreach (var modId in config.ModOrder)
            {
                var match = entries.Find(e => string.Equals(e.ModId, modId, StringComparison.OrdinalIgnoreCase));
                if (match != null)
                {
                    ordered.Add(match);
                    entries.Remove(match);
                }
            }
            // Append any mods not in the saved order
            ordered.AddRange(entries);
            entries = ordered;
        }

        foreach (var e in entries)
        {
            e.PropertyChanged += (_, args) =>
            {
                if (args.PropertyName == nameof(ModEntryViewModel.IsEnabled))
                    UpdateCounts();
            };
            Mods.Add(e);
        }
    }

    private void UpdateCounts()
    {
        TotalModCount = Mods.Count;
        EnabledModCount = Mods.Count(m => m.IsEnabled);
        DisabledModCount = TotalModCount - EnabledModCount;
    }

    [RelayCommand]
    private void MoveUp()
    {
        if (SelectedMod == null) return;
        int index = Mods.IndexOf(SelectedMod);
        if (index <= 0) return;
        // Don't move above reserved mods
        if (Mods[index - 1].IsReserved) return;
        var mod = SelectedMod;
        Mods.Move(index, index - 1);
        SelectedMod = mod;
    }

    [RelayCommand]
    private void MoveDown()
    {
        if (SelectedMod == null) return;
        int index = Mods.IndexOf(SelectedMod);
        if (index < 0 || index >= Mods.Count - 1) return;
        var mod = SelectedMod;
        Mods.Move(index, index + 1);
        SelectedMod = mod;
    }

    [RelayCommand]
    private void AutoReOrder()
    {
        // Placeholder — does nothing for now
    }

    [RelayCommand]
    private void AddMod()
    {
        // Placeholder — does nothing for now
    }

    [RelayCommand]
    private void DeleteMod()
    {
        // Placeholder — does nothing for now
    }

    [RelayCommand]
    private void Save()
    {
        var config = new ModsConfig();
        config.ModOrder = Mods.Select(m => m.ModId).ToList();
        foreach (var mod in Mods)
        {
            config.Mods[mod.ModId] = new ModConfigEntry { Enabled = mod.IsEnabled };
        }
        config.Save();
    }

    [RelayCommand(CanExecute = nameof(CanLaunch))]
    private async Task LaunchGame()
    {
        Save();
        GameState = GameState.Launching;

        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = "dotnet",
                Arguments = "run --project in254.csproj",
                UseShellExecute = false,
            };
            var process = Process.Start(startInfo);
            if (process == null)
            {
                GameState = GameState.Error;
                StatusText = "Failed to start process.";
                return;
            }

            GameState = GameState.Running;
            await process.WaitForExitAsync();
            GameState = GameState.Ready;
        }
        catch (Exception ex)
        {
            StatusText = $"Failed to launch: {ex.Message}";
            GameState = GameState.Error;
        }
    }
}
