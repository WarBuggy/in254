using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;

namespace in254.Engine;

public sealed class GameCamera
{
    public string Name { get; }
    public float X { get; private set; }
    public float Y { get; private set; }
    public float TargetX { get; private set; }
    public float TargetY { get; private set; }
    public float LerpSpeed { get; set; } = 6f;
    public float Zoom { get; set; } = 2f;

    private readonly HashSet<string> _layerNames = new();

    public GameCamera(string name)
    {
        Name = name;
    }

    public void AddLayer(string layerName) => _layerNames.Add(layerName);
    public void RemoveLayer(string layerName) => _layerNames.Remove(layerName);
    public bool HasLayer(string layerName) => _layerNames.Contains(layerName);
    public IEnumerable<string> Layers => _layerNames;

    public void Follow(float centerX, float centerY, float screenW, float screenH)
    {
        float viewW = screenW / Zoom;
        float viewH = screenH / Zoom;
        TargetX = centerX - MathF.Floor(viewW / 2f);
        TargetY = centerY - MathF.Floor(viewH / 2f);
    }

    public void ClampTarget(float minX, float minY, float maxX, float maxY)
    {
        TargetX = Math.Clamp(TargetX, minX, maxX);
        TargetY = Math.Clamp(TargetY, minY, maxY);
    }

    public void Update(float dt)
    {
        float speed = Math.Min(LerpSpeed * dt, 1f);
        X += (TargetX - X) * speed;
        Y += (TargetY - Y) * speed;
        if (MathF.Abs(X - TargetX) < 0.5f) X = TargetX;
        if (MathF.Abs(Y - TargetY) < 0.5f) Y = TargetY;
    }

    public void Snap(float x, float y)
    {
        X = x;
        Y = y;
        TargetX = x;
        TargetY = y;
    }

    public Matrix GetTransform()
    {
        return Matrix.CreateTranslation(-MathF.Floor(X), -MathF.Floor(Y), 0f)
             * Matrix.CreateScale(Zoom, Zoom, 1f);
    }

    public float ScreenToWorldX(float sx) => sx / Zoom + X;
    public float ScreenToWorldY(float sy) => sy / Zoom + Y;
    public float WorldToScreenX(float wx) => (wx - X) * Zoom;
    public float WorldToScreenY(float wy) => (wy - Y) * Zoom;

    public Rectangle GetWorldBounds(float screenW, float screenH)
    {
        float viewW = screenW / Zoom;
        float viewH = screenH / Zoom;
        return new Rectangle(
            (int)MathF.Floor(X),
            (int)MathF.Floor(Y),
            (int)MathF.Ceiling(viewW),
            (int)MathF.Ceiling(viewH)
        );
    }
}
