using Avalonia.Media.Imaging;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Launcher.Controls;

namespace Launcher.ViewModels;

public partial class ModEntryViewModel : ObservableObject, IDragLockable
{
    private static readonly string[] ThumbnailFileNames = ["preview.png", "preview.jpg", "thumbnail.png", "thumbnail.jpg", "thumb.png", "thumb.jpg"];

    public bool IsLocked => IsReserved;
    public string ModId { get; }
    public string DisplayName { get; }
    public bool IsReserved { get; }
    public string Source { get; }
    public string FolderPath { get; }
    public Bitmap? Thumbnail { get; }
    public bool HasThumbnail => Thumbnail != null;

    [ObservableProperty]
    private bool _isEnabled;

    [RelayCommand]
    private void Disable()
    {
        if (!IsReserved) IsEnabled = false;
    }

    public ModEntryViewModel(string modId, string displayName, bool isReserved, bool isEnabled, string source, string folderPath)
    {
        ModId = modId;
        DisplayName = displayName;
        IsReserved = isReserved;
        _isEnabled = isReserved || isEnabled;
        Source = source;
        FolderPath = folderPath;
        Thumbnail = LoadThumbnail(folderPath);
    }

    private static Bitmap? LoadThumbnail(string folderPath)
    {
        foreach (var name in ThumbnailFileNames)
        {
            var path = Path.Combine(folderPath, name);
            if (File.Exists(path))
            {
                try { return new Bitmap(path); }
                catch { /* ignore corrupt images */ }
            }
        }
        return null;
    }
}
