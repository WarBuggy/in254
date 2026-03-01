using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace in254.Engine;

public sealed class CameraManager
{
    private static readonly CameraManager _instance = new();
    public static CameraManager Instance => _instance;

    private readonly Dictionary<string, GameCamera> _cameras = new();

    public GameCamera Main { get; }

    private CameraManager()
    {
        Main = new GameCamera("main");
        _cameras["main"] = Main;
    }

    public GameCamera CreateCamera(string name)
    {
        if (_cameras.TryGetValue(name, out var existing))
            return existing;
        var cam = new GameCamera(name);
        _cameras[name] = cam;
        return cam;
    }

    public GameCamera GetCamera(string name)
    {
        _cameras.TryGetValue(name, out var cam);
        return cam;
    }

    public void RemoveCamera(string name)
    {
        if (name == "main") return;
        _cameras.Remove(name);
    }

    public Matrix GetTransformForLayer(string layerName)
    {
        foreach (var cam in _cameras.Values)
        {
            if (cam.HasLayer(layerName))
                return cam.GetTransform();
        }
        return Matrix.Identity;
    }

    public GameCamera GetCameraForLayer(string layerName)
    {
        foreach (var cam in _cameras.Values)
        {
            if (cam.HasLayer(layerName))
                return cam;
        }
        return null;
    }
}
