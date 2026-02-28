using Avalonia.Controls;
using Avalonia.Interactivity;
using Launcher.ViewModels;

namespace Launcher.Views;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    private async void OnShowModDetail(object? sender, RoutedEventArgs e)
    {
        if (DataContext is not MainWindowViewModel vm || vm.SelectedMod == null) return;

        var detailVm = new ModDetailViewModel(vm.SelectedMod);
        var window = new ModDetailWindow { DataContext = detailVm };
        await window.ShowDialog(this);
    }
}
