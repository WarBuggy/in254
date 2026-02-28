using CommunityToolkit.Mvvm.ComponentModel;
using Launcher.Controls;

namespace Launcher.ViewModels;

public partial class ModEntryViewModel : ObservableObject, IDragLockable
{
    public bool IsLocked => IsReserved;
    public string ModId { get; }
    public string DisplayName { get; }
    public bool IsReserved { get; }
    public string Source { get; }
    public string FolderPath { get; }

    [ObservableProperty]
    private bool _isEnabled;

    public ModEntryViewModel(string modId, string displayName, bool isReserved, bool isEnabled, string source, string folderPath)
    {
        ModId = modId;
        DisplayName = displayName;
        IsReserved = isReserved;
        _isEnabled = isReserved || isEnabled;
        Source = source;
        FolderPath = folderPath;
    }
}
