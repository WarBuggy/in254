using System;
using System.Collections;
using System.Collections.Specialized;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.VisualTree;

namespace Launcher.Controls;

public class DragReorderListBox : ListBox
{
    protected override Type StyleKeyOverride => typeof(ListBox);

    // -- Styled properties --------------------------------------------------

    public static readonly StyledProperty<string> GripHandleTagProperty =
        AvaloniaProperty.Register<DragReorderListBox, string>(nameof(GripHandleTag), "GripHandle");

    public static readonly StyledProperty<string> DropIndicatorNameProperty =
        AvaloniaProperty.Register<DragReorderListBox, string>(nameof(DropIndicatorName), "DropIndicator");

    public static readonly StyledProperty<string> DragSourceClassNameProperty =
        AvaloniaProperty.Register<DragReorderListBox, string>(nameof(DragSourceClassName), "dragSource");

    public static readonly StyledProperty<double> DragThresholdProperty =
        AvaloniaProperty.Register<DragReorderListBox, double>(nameof(DragThreshold), 8.0);

    public string GripHandleTag
    {
        get => GetValue(GripHandleTagProperty);
        set => SetValue(GripHandleTagProperty, value);
    }

    public string DropIndicatorName
    {
        get => GetValue(DropIndicatorNameProperty);
        set => SetValue(DropIndicatorNameProperty, value);
    }

    public string DragSourceClassName
    {
        get => GetValue(DragSourceClassNameProperty);
        set => SetValue(DragSourceClassNameProperty, value);
    }

    public double DragThreshold
    {
        get => GetValue(DragThresholdProperty);
        set => SetValue(DragThresholdProperty, value);
    }

    // -- Routed event -------------------------------------------------------

    public static readonly RoutedEvent<ReorderedEventArgs> ReorderedEvent =
        RoutedEvent.Register<DragReorderListBox, ReorderedEventArgs>(
            nameof(Reordered), RoutingStrategies.Bubble);

    public event EventHandler<ReorderedEventArgs>? Reordered
    {
        add => AddHandler(ReorderedEvent, value);
        remove => RemoveHandler(ReorderedEvent, value);
    }

    // -- Private state ------------------------------------------------------

    private int _dragSourceIndex = -1;
    private Point _dragStartPoint;
    private bool _isDragging;
    private ListBoxItem? _dragSourceItem;
    private ListBoxItem? _currentDropTarget;

    // -- Constructor --------------------------------------------------------

    public DragReorderListBox()
    {
        AddHandler(DragDrop.DropEvent, OnDrop);
        AddHandler(DragDrop.DragOverEvent, OnDragOver);
        AddHandler(DragDrop.DragLeaveEvent, OnDragLeave);
        DragDrop.SetAllowDrop(this, true);

        AddHandler(PointerPressedEvent, OnPointerPressedHandler, RoutingStrategies.Tunnel);
        AddHandler(PointerMovedEvent, OnPointerMovedHandler, RoutingStrategies.Tunnel);
    }

    // -- Pointer handlers ---------------------------------------------------

    private void OnPointerPressedHandler(object? sender, PointerPressedEventArgs e)
    {
        _isDragging = false;
        _dragSourceIndex = -1;

        if (!e.GetCurrentPoint(this).Properties.IsLeftButtonPressed)
            return;

        if (!IsGripHandle(e.Source as Visual))
            return;

        var item = FindListBoxItem(e.Source as Visual);
        if (item == null) return;

        int index = IndexFromContainer(item);
        if (index < 0) return;

        var items = ItemsSource as IList;
        if (items == null || index >= items.Count) return;

        if (items[index] is IDragLockable { IsLocked: true })
            return;

        _dragSourceIndex = index;
        _dragStartPoint = e.GetPosition(this);
        _isDragging = true;
    }

    private async void OnPointerMovedHandler(object? sender, PointerEventArgs e)
    {
        if (!_isDragging || _dragSourceIndex < 0)
            return;

        if (!e.GetCurrentPoint(this).Properties.IsLeftButtonPressed)
        {
            _isDragging = false;
            return;
        }

        var pos = e.GetPosition(this);
        var diff = pos - _dragStartPoint;
        if (Math.Abs(diff.X) < DragThreshold && Math.Abs(diff.Y) < DragThreshold)
            return;

        _isDragging = false; // prevent re-entry

        #pragma warning disable CS0618 // Avalonia obsolete drag-drop API
        var data = new DataObject();
        data.Set(DataFormats.Text, _dragSourceIndex.ToString());

        _dragSourceItem = ContainerFromIndex(_dragSourceIndex) as ListBoxItem;
        _dragSourceItem?.Classes.Add(DragSourceClassName);

        try
        {
            await DragDrop.DoDragDrop(e, data, DragDropEffects.Move);
        }
        finally
        {
            ClearDragVisuals();
        }
    }

    // -- Drag/drop handlers -------------------------------------------------

    private void OnDragOver(object? sender, DragEventArgs e)
    {
        e.DragEffects = DragDropEffects.None;

        if (!e.Data.Contains(DataFormats.Text))
            return;

        var targetIndex = GetDropTargetIndex(e);
        if (targetIndex < 0) return;

        int firstUnlocked = GetFirstUnlockedIndex();
        if (targetIndex < firstUnlocked)
            return;

        e.DragEffects = DragDropEffects.Move;

        var targetItem = FindListBoxItem(e.Source as Visual);
        if (targetItem != _currentDropTarget)
        {
            ClearDropIndicator();
            _currentDropTarget = targetItem;
            ShowDropIndicator(_currentDropTarget);
        }
    }

    private void OnDrop(object? sender, DragEventArgs e)
    {
        ClearDragVisuals();

        if (!e.Data.Contains(DataFormats.Text))
            return;

        var text = e.Data.GetText();
        if (text == null || !int.TryParse(text, out int sourceIndex))
            return;

        var items = ItemsSource as IList;
        if (items == null) return;
        if (sourceIndex < 0 || sourceIndex >= items.Count) return;

        var targetIndex = GetDropTargetIndex(e);
        if (targetIndex < 0) return;

        int firstUnlocked = GetFirstUnlockedIndex();
        if (targetIndex < firstUnlocked)
            return;

        if (sourceIndex == targetIndex) return;

        MoveItem(items, sourceIndex, targetIndex);
        SelectedIndex = targetIndex;

        RaiseEvent(new ReorderedEventArgs(ReorderedEvent, this, sourceIndex, targetIndex));
    }

    private void OnDragLeave(object? sender, DragEventArgs e)
    {
        ClearDragVisuals();
    }
    #pragma warning restore CS0618

    // -- Helpers ------------------------------------------------------------

    private bool IsGripHandle(Visual? visual)
    {
        var tag = GripHandleTag;
        while (visual != null)
        {
            if (visual is Control c && c.Tag is string t && t == tag)
                return true;
            visual = visual.GetVisualParent() as Visual;
        }
        return false;
    }

    private int GetDropTargetIndex(DragEventArgs e)
    {
        var item = FindListBoxItem(e.Source as Visual);
        if (item != null)
            return IndexFromContainer(item);

        var items = ItemsSource as IList;
        if (items != null && items.Count > 0)
            return items.Count - 1;

        return -1;
    }

    private int GetFirstUnlockedIndex()
    {
        var items = ItemsSource as IList;
        if (items == null) return 0;

        for (int i = 0; i < items.Count; i++)
        {
            if (items[i] is not IDragLockable { IsLocked: true })
                return i;
        }
        return items.Count;
    }

    private static void MoveItem(IList items, int sourceIndex, int targetIndex)
    {
        // Try ObservableCollection<T>.Move() via reflection
        var moveMethod = items.GetType().GetMethod("Move", new[] { typeof(int), typeof(int) });
        if (moveMethod != null)
        {
            moveMethod.Invoke(items, new object[] { sourceIndex, targetIndex });
            return;
        }

        // Fallback: remove + insert
        var item = items[sourceIndex]!;
        items.RemoveAt(sourceIndex);
        items.Insert(targetIndex, item);
    }

    private void ShowDropIndicator(ListBoxItem? item)
    {
        if (item == null) return;
        var indicator = FindDropIndicator(item);
        if (indicator != null)
            indicator.IsVisible = true;
    }

    private void ClearDropIndicator()
    {
        if (_currentDropTarget != null)
        {
            var indicator = FindDropIndicator(_currentDropTarget);
            if (indicator != null)
                indicator.IsVisible = false;
            _currentDropTarget = null;
        }
    }

    private Border? FindDropIndicator(Visual parent)
    {
        var name = DropIndicatorName;
        foreach (var child in parent.GetVisualDescendants())
        {
            if (child is Border border && border.Name == name)
                return border;
        }
        return null;
    }

    private void ClearDragVisuals()
    {
        if (_dragSourceItem != null)
        {
            _dragSourceItem.Classes.Remove(DragSourceClassName);
            _dragSourceItem = null;
        }
        ClearDropIndicator();
    }

    private static ListBoxItem? FindListBoxItem(Visual? visual)
    {
        while (visual != null)
        {
            if (visual is ListBoxItem lbi)
                return lbi;
            visual = visual.GetVisualParent() as Visual;
        }
        return null;
    }
}

public class ReorderedEventArgs : RoutedEventArgs
{
    public int OldIndex { get; }
    public int NewIndex { get; }

    public ReorderedEventArgs(RoutedEvent routedEvent, object source, int oldIndex, int newIndex)
        : base(routedEvent, source)
    {
        OldIndex = oldIndex;
        NewIndex = newIndex;
    }
}
