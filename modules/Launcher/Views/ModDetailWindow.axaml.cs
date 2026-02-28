using Avalonia.Controls;
using Avalonia.Interactivity;

namespace Launcher.Views;

public partial class ModDetailWindow : Window
{
    public ModDetailWindow()
    {
        InitializeComponent();
    }

    private void OnClose(object? sender, RoutedEventArgs e)
    {
        Close();
    }
}
