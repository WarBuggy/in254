using System;
using MoonSharp.Interpreter;
using AxiomPlayground.Scripting.LuaBindings;

namespace in254.Engine;

/// <summary>
/// Exposes NativeBufferManager to Lua as "NativeBuffer.*".
/// Provides fast flat int[] arrays for compute-heavy code (lighting, physics).
/// </summary>
public sealed class NativeBufferLuaBinding : LuaBindingBase
{
    public override void Register(Script luaScript)
    {
        ArgumentNullException.ThrowIfNull(luaScript);

        var mgr = NativeBufferManager.Instance;
        Table t = new(luaScript);

        // -- Lifecycle --
        t["Create"] = (Func<int, int>)(size => mgr.Create(size));
        t["Destroy"] = (Action<int>)(handle => mgr.Destroy(handle));

        // -- Individual access --
        t["Get"] = (Func<int, int, int>)((handle, index) => mgr.Get(handle, index));
        t["Set"] = (Action<int, int, int>)((handle, index, value) => mgr.Set(handle, index, value));
        t["Size"] = (Func<int, int>)(handle => mgr.GetSize(handle));

        // -- Bulk ops --
        t["Fill"] = (Action<int, int, int, int>)((handle, value, offset, count) =>
            mgr.Fill(handle, value, offset, count));

        // -- Sync (Lua table <-> C# buffer) --
        t["SyncFromTable"] = (Action<int, DynValue, int>)((handle, tableDyn, count) =>
        {
            if (tableDyn.Type != DataType.Table) return;
            mgr.SyncFromTable(handle, tableDyn.Table, count);
        });

        t["SyncToTable"] = (Action<int, DynValue, int>)((handle, tableDyn, count) =>
        {
            if (tableDyn.Type != DataType.Table) return;
            mgr.SyncToTable(handle, tableDyn.Table, count);
        });

        // -- Rect fill (2D region clear) --
        t["FillRect"] = (Action<int, int, int, int, int, int, int>)(
            (handle, W, x0, y0, x1, y1, value) =>
            mgr.FillRect(handle, W, x0, y0, x1, y1, value));

        // -- Compute: 4-directional sweep relaxation --
        t["SweepMax"] = (Action<int, int, int, int, int, int, int, int, int>)(
            (handle, W, H, x0, x1, y0, y1, decay, passes) =>
            mgr.SweepMax(handle, W, H, x0, x1, y0, y1, decay, passes));

        // -- Generic compute ops --
        t["ColumnDecay"] = (Action<int, int, int, int, int, int, int, int, int, int, int, int>)(
            (destH, srcH, maskH, W, H, x0, x1, y0, y1, initVal, decayOnMask, decayWrite) =>
            mgr.ColumnDecay(destH, srcH, maskH, W, H, x0, x1, y0, y1, initVal, decayOnMask, decayWrite));

        t["ScatterLookup"] = (Action<int, int, int, int, int, int, int, int>)(
            (destH, srcH, lookupH, W, x0, x1, y0, y1) =>
            mgr.ScatterLookup(destH, srcH, lookupH, W, x0, x1, y0, y1));

        luaScript.Globals["NativeBuffer"] = t;
    }
}
