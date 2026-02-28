using System.Collections.ObjectModel;
using Avalonia.Media.Imaging;
using Launcher.Models;

namespace Launcher.ViewModels;

public class ModDetailViewModel
{
    public ModEntryViewModel Mod { get; }
    public ModInfo? Info { get; }

    public Bitmap? PreviewImage { get; }
    public bool HasPreview => PreviewImage != null;
    public ObservableCollection<Bitmap> Screenshots { get; } = [];

    public string VersionDisplay => Info?.Version ?? "—";
    public string AuthorDisplay => Info?.Author ?? "Unknown";
    public string DescriptionDisplay => Info?.Description ?? "No description available.";
    public string TagsDisplay => Info?.Tags.Count > 0 ? string.Join(", ", Info.Tags) : "—";
    public string DependenciesDisplay => Info?.Dependencies.Count > 0 ? string.Join(", ", Info.Dependencies) : "None";
    public string GameVersionDisplay => Info?.GameVersion ?? "—";
    public string WorkshopIdDisplay => !string.IsNullOrEmpty(Info?.WorkshopId) ? Info.WorkshopId : "Not published";
    public bool HasScreenshots => Screenshots.Count > 0;

    public ModDetailViewModel(ModEntryViewModel mod)
    {
        Mod = mod;
        Info = ModInfo.Load(mod.FolderPath);
        PreviewImage = LoadPreview();
        LoadScreenshots();
    }

    private Bitmap? LoadPreview()
    {
        if (string.IsNullOrEmpty(Info?.Preview)) return Mod.Thumbnail;

        var path = Path.Combine(Mod.FolderPath, Info.Preview);
        if (!File.Exists(path)) return Mod.Thumbnail;

        try { return new Bitmap(path); }
        catch { return Mod.Thumbnail; }
    }

    private void LoadScreenshots()
    {
        if (Info?.Screenshots == null) return;
        foreach (var ss in Info.Screenshots)
        {
            var path = Path.Combine(Mod.FolderPath, ss);
            if (!File.Exists(path)) continue;
            try { Screenshots.Add(new Bitmap(path)); }
            catch { /* skip corrupt images */ }
        }
    }
}
