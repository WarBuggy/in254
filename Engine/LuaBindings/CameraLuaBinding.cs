using System;
using MoonSharp.Interpreter;
using AxiomPlayground.Scripting.LuaBindings;

namespace in254.Engine.LuaBindings;

public sealed class CameraLuaBinding : LuaBindingBase
{
    private Script _script;

    public override void Register(Script luaScript)
    {
        ArgumentNullException.ThrowIfNull(luaScript);
        _script = luaScript;

        Table camTable = new(luaScript);

        // --- Main camera shortcuts (no name param — operates on "main") ---

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
            WrapBounds(CameraManager.Instance.Main.GetWorldBounds(sw, sh)));

        // --- Object API ---

        camTable["Create"] = (Func<string, Table>)(name =>
        {
            var cam = CameraManager.Instance.CreateCamera(name);
            return WrapCamera(cam);
        });

        camTable["Main"] = (Func<Table>)(() =>
            WrapCamera(CameraManager.Instance.Main));

        camTable["Get"] = (Func<string, DynValue>)(name =>
        {
            var cam = CameraManager.Instance.GetCamera(name);
            return cam != null ? DynValue.NewTable(WrapCamera(cam)) : DynValue.Nil;
        });

        camTable["Remove"] = (Action<string>)(name =>
            CameraManager.Instance.RemoveCamera(name));

        luaScript.Globals["GameCamera"] = camTable;
    }

    private Table WrapCamera(GameCamera cam)
    {
        var t = new Table(_script);

        t["GetX"] = (Func<float>)(() => cam.X);
        t["GetY"] = (Func<float>)(() => cam.Y);
        t["GetZoom"] = (Func<float>)(() => cam.Zoom);
        t["SetZoom"] = (Func<Table, float, DynValue>)((self, z) => { cam.Zoom = z; return DynValue.Nil; });
        t["Follow"] = (Func<Table, float, float, float, float, DynValue>)((self, cx, cy, sw, sh) =>
            { cam.Follow(cx, cy, sw, sh); return DynValue.Nil; });
        t["ClampTarget"] = (Func<Table, float, float, float, float, DynValue>)((self, minX, minY, maxX, maxY) =>
            { cam.ClampTarget(minX, minY, maxX, maxY); return DynValue.Nil; });
        t["Update"] = (Func<Table, float, DynValue>)((self, dt) => { cam.Update(dt); return DynValue.Nil; });
        t["Snap"] = (Func<Table, float, float, DynValue>)((self, x, y) => { cam.Snap(x, y); return DynValue.Nil; });
        t["ScreenToWorldX"] = (Func<Table, float, float>)((self, sx) => cam.ScreenToWorldX(sx));
        t["ScreenToWorldY"] = (Func<Table, float, float>)((self, sy) => cam.ScreenToWorldY(sy));
        t["WorldToScreenX"] = (Func<Table, float, float>)((self, wx) => cam.WorldToScreenX(wx));
        t["WorldToScreenY"] = (Func<Table, float, float>)((self, wy) => cam.WorldToScreenY(wy));
        t["AddLayer"] = (Func<Table, string, DynValue>)((self, name) => { cam.AddLayer(name); return DynValue.Nil; });
        t["RemoveLayer"] = (Func<Table, string, DynValue>)((self, name) => { cam.RemoveLayer(name); return DynValue.Nil; });
        t["GetWorldBounds"] = (Func<Table, float, float, Table>)((self, sw, sh) =>
            WrapBounds(cam.GetWorldBounds(sw, sh)));
        t["GetName"] = (Func<string>)(() => cam.Name);

        return t;
    }

    private Table WrapBounds(Microsoft.Xna.Framework.Rectangle bounds)
    {
        var t = new Table(_script);
        t["x"] = bounds.X;
        t["y"] = bounds.Y;
        t["w"] = bounds.Width;
        t["h"] = bounds.Height;
        return t;
    }
}
