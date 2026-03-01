using System;
using MoonSharp.Interpreter;
using AxiomPlayground.Scripting.LuaBindings;

namespace in254.Engine.LuaBindings;

public sealed class CameraLuaBinding : LuaBindingBase
{
    public override void Register(Script luaScript)
    {
        ArgumentNullException.ThrowIfNull(luaScript);

        Table camTable = new(luaScript);

        // --- Main camera shortcuts ---

        camTable["GetX"] = (Func<float>)(() => CameraManager.Instance.Main.X);
        camTable["GetY"] = (Func<float>)(() => CameraManager.Instance.Main.Y);

        camTable["GetZoom"] = (Func<float>)(() => CameraManager.Instance.Main.Zoom);
        camTable["SetZoom"] = (Action<float>)(z => CameraManager.Instance.Main.Zoom = z);

        camTable["Follow"] = (Action<float, float, float, float>)((cx, cy, sw, sh) =>
            CameraManager.Instance.Main.Follow(cx, cy, sw, sh));

        camTable["ClampTarget"] = (Action<float, float, float, float>)((minX, minY, maxX, maxY) =>
            CameraManager.Instance.Main.ClampTarget(minX, minY, maxX, maxY));

        camTable["Update"] = (Action<float>)(dt =>
            CameraManager.Instance.Main.Update(dt));

        camTable["Snap"] = (Action<float, float>)((x, y) =>
            CameraManager.Instance.Main.Snap(x, y));

        camTable["ScreenToWorldX"] = (Func<float, float>)(sx =>
            CameraManager.Instance.Main.ScreenToWorldX(sx));

        camTable["ScreenToWorldY"] = (Func<float, float>)(sy =>
            CameraManager.Instance.Main.ScreenToWorldY(sy));

        camTable["WorldToScreenX"] = (Func<float, float>)(wx =>
            CameraManager.Instance.Main.WorldToScreenX(wx));

        camTable["WorldToScreenY"] = (Func<float, float>)(wy =>
            CameraManager.Instance.Main.WorldToScreenY(wy));

        camTable["AddLayer"] = (Action<string>)(name =>
            CameraManager.Instance.Main.AddLayer(name));

        camTable["RemoveLayer"] = (Action<string>)(name =>
            CameraManager.Instance.Main.RemoveLayer(name));

        camTable["GetWorldBounds"] = (Func<float, float, Table>)((sw, sh) =>
        {
            var bounds = CameraManager.Instance.Main.GetWorldBounds(sw, sh);
            Table t = new(luaScript);
            t["x"] = bounds.X;
            t["y"] = bounds.Y;
            t["w"] = bounds.Width;
            t["h"] = bounds.Height;
            return t;
        });

        // --- Named camera API ---

        camTable["Create"] = (Action<string>)(name =>
            CameraManager.Instance.CreateCamera(name));

        camTable["Remove"] = (Action<string>)(name =>
            CameraManager.Instance.RemoveCamera(name));

        luaScript.Globals["GameCamera"] = camTable;
    }
}
