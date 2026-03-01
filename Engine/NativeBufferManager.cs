using System;
using System.Numerics;
using System.Runtime.CompilerServices;

namespace in254.Engine;

/// <summary>
/// Pool of flat int[] buffers accessible from Lua via integer handles.
/// Provides SIMD-accelerated bulk operations (Fill, SweepMax).
/// </summary>
public sealed class NativeBufferManager
{
    private static readonly NativeBufferManager _instance = new();
    public static NativeBufferManager Instance => _instance;

    private const int MaxBuffers = 64;
    private readonly int[][] _buffers = new int[MaxBuffers][];
    private readonly int[] _sizes = new int[MaxBuffers];
    private int _nextHandle = 1; // 0 = invalid

    private NativeBufferManager() { }

    // --------------------------------------------------
    // Lifecycle
    // --------------------------------------------------

    /// <summary>Create a buffer of <paramref name="size"/> ints, zero-filled. Returns handle.</summary>
    public int Create(int size)
    {
        if (size <= 0) return 0;
        int handle = _nextHandle;
        if (handle >= MaxBuffers)
        {
            // Reclaim first free slot
            handle = -1;
            for (int i = 1; i < MaxBuffers; i++)
            {
                if (_buffers[i] == null) { handle = i; break; }
            }
            if (handle < 0) return 0; // full
        }
        else
        {
            _nextHandle++;
        }

        _buffers[handle] = new int[size];
        _sizes[handle] = size;
        return handle;
    }

    /// <summary>Destroy a buffer and free its handle.</summary>
    public void Destroy(int handle)
    {
        if (handle <= 0 || handle >= MaxBuffers) return;
        _buffers[handle] = null;
        _sizes[handle] = 0;
    }

    // --------------------------------------------------
    // Individual access
    // --------------------------------------------------

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public int Get(int handle, int index)
    {
        var buf = _buffers[handle];
        if (buf == null || (uint)index >= (uint)buf.Length) return 0;
        return buf[index];
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public void Set(int handle, int index, int value)
    {
        var buf = _buffers[handle];
        if (buf == null || (uint)index >= (uint)buf.Length) return;
        buf[index] = value;
    }

    /// <summary>Get the size of a buffer.</summary>
    public int GetSize(int handle)
    {
        if (handle <= 0 || handle >= MaxBuffers) return 0;
        return _sizes[handle];
    }

    /// <summary>Get the raw array (for C# internal use, e.g. TileRenderer).</summary>
    public int[] GetRaw(int handle)
    {
        if (handle <= 0 || handle >= MaxBuffers) return null;
        return _buffers[handle];
    }

    // --------------------------------------------------
    // Fill — SIMD-accelerated memset
    // --------------------------------------------------

    public void Fill(int handle, int value, int offset, int count)
    {
        var buf = _buffers[handle];
        if (buf == null) return;
        int end = Math.Min(offset + count, buf.Length);
        if (offset < 0) offset = 0;
        if (end <= offset) return;

        Array.Fill(buf, value, offset, end - offset);
    }

    // --------------------------------------------------
    // FillRect — clear a rectangular region in a 2D buffer
    // --------------------------------------------------

    public void FillRect(int handle, int W, int x0, int y0, int x1, int y1, int value)
    {
        var buf = _buffers[handle];
        if (buf == null) return;
        x0 = Math.Max(0, x0);
        x1 = Math.Min(W - 1, x1);
        y0 = Math.Max(0, y0);
        for (int y = y0; y <= y1; y++)
        {
            int start = y * W + x0;
            int count = x1 - x0 + 1;
            if (start + count > buf.Length) count = buf.Length - start;
            if (count > 0) Array.Fill(buf, value, start, count);
        }
    }

    // --------------------------------------------------
    // ColumnDecay — generic top-down column propagation
    // For each column x in [x0..x1], start with initVal,
    // scan from y=0 down. Where maskBuf[srcBuf[idx]] != 0,
    // decay by decayAmount. Write max(destBuf[idx], val)
    // in [y0..y1] range. Above y0: only track decay.
    // --------------------------------------------------

    public void ColumnDecay(int destH, int srcH, int maskH,
        int W, int H, int x0, int x1, int y0, int y1,
        int initVal, int decayOnMask, int decayWrite)
    {
        var dest = _buffers[destH];
        var src = _buffers[srcH];
        var mask = _buffers[maskH];
        if (dest == null || src == null || mask == null) return;

        int maskLen = mask.Length;

        for (int x = x0; x <= x1; x++)
        {
            int val = initVal;

            // Above viewport — track decay only
            for (int y = 0; y < y0; y++)
            {
                int id = src[y * W + x];
                if (id >= 0 && id < maskLen && mask[id] != 0)
                {
                    val -= decayOnMask;
                    if (val <= 0) { val = 0; break; }
                }
            }

            // In viewport — write dest
            for (int y = y0; y <= y1; y++)
            {
                int idx = y * W + x;
                int id = src[idx];
                bool masked = id >= 0 && id < maskLen && mask[id] != 0;

                if (!masked)
                {
                    if (val > dest[idx]) dest[idx] = val;
                }
                else
                {
                    int reduced = val - decayWrite;
                    if (reduced < 0) reduced = 0;
                    if (reduced > dest[idx]) dest[idx] = reduced;
                    val -= decayOnMask;
                    if (val < 0) val = 0;
                }
            }
        }
    }

    // --------------------------------------------------
    // ScatterLookup — for each cell in region, look up
    // srcBuf[idx] in lookupBuf, write max into destBuf.
    // Generic "map tile IDs to values" operation.
    // --------------------------------------------------

    public void ScatterLookup(int destH, int srcH, int lookupH,
        int W, int x0, int x1, int y0, int y1)
    {
        var dest = _buffers[destH];
        var src = _buffers[srcH];
        var lookup = _buffers[lookupH];
        if (dest == null || src == null || lookup == null) return;

        int lookupLen = lookup.Length;

        for (int y = y0; y <= y1; y++)
        {
            int rowBase = y * W;
            for (int x = x0; x <= x1; x++)
            {
                int idx = rowBase + x;
                int id = src[idx];
                if (id >= 0 && id < lookupLen)
                {
                    int val = lookup[id];
                    if (val > dest[idx])
                        dest[idx] = val;
                }
            }
        }
    }

    // --------------------------------------------------
    // SweepMax — 4-directional relaxation with SIMD
    // Propagates: light[i] = max(light[i], neighbor - decay)
    // --------------------------------------------------

    /// <summary>
    /// Run <paramref name="passes"/> iterations of 4-directional max-decay sweep.
    /// Each pass does: right, left, down, up over the sub-region [x0..x1, y0..y1].
    /// </summary>
    public void SweepMax(int handle, int W, int H, int x0, int x1, int y0, int y1, int decay, int passes)
    {
        var buf = _buffers[handle];
        if (buf == null) return;

        // Clamp bounds
        x0 = Math.Max(0, x0);
        x1 = Math.Min(W - 1, x1);
        y0 = Math.Max(0, y0);
        y1 = Math.Min(H - 1, y1);
        if (x0 > x1 || y0 > y1) return;

        int vecLen = Vector<int>.Count;
        var decayVec = new Vector<int>(decay);
        var zeroVec = Vector<int>.Zero;

        // Pre-allocate scratch arrays outside loops (avoid stackalloc in loop)
        Span<int> scratchA = stackalloc int[vecLen];
        Span<int> scratchB = stackalloc int[vecLen];

        for (int pass = 0; pass < passes; pass++)
        {
            // --- Sweep RIGHT (x increases) ---
            int y = y0;
            for (; y + vecLen - 1 <= y1; y += vecLen)
            {
                for (int x = x0 + 1; x <= x1; x++)
                {
                    for (int v = 0; v < vecLen; v++)
                    {
                        int row = y + v;
                        scratchA[v] = buf[row * W + x];
                        scratchB[v] = buf[row * W + (x - 1)];
                    }
                    var curVec = new Vector<int>(scratchA);
                    var prevVec = new Vector<int>(scratchB);
                    var propagated = Vector.Max(prevVec - decayVec, zeroVec);
                    var result = Vector.Max(curVec, propagated);
                    result.CopyTo(scratchA);
                    for (int v = 0; v < vecLen; v++)
                        buf[(y + v) * W + x] = scratchA[v];
                }
            }
            for (; y <= y1; y++)
            {
                int rowBase = y * W;
                for (int x = x0 + 1; x <= x1; x++)
                {
                    int prop = buf[rowBase + x - 1] - decay;
                    if (prop > buf[rowBase + x]) buf[rowBase + x] = prop;
                }
            }

            // --- Sweep LEFT (x decreases) ---
            y = y0;
            for (; y + vecLen - 1 <= y1; y += vecLen)
            {
                for (int x = x1 - 1; x >= x0; x--)
                {
                    for (int v = 0; v < vecLen; v++)
                    {
                        int row = y + v;
                        scratchA[v] = buf[row * W + x];
                        scratchB[v] = buf[row * W + (x + 1)];
                    }
                    var curVec = new Vector<int>(scratchA);
                    var nextVec = new Vector<int>(scratchB);
                    var propagated = Vector.Max(nextVec - decayVec, zeroVec);
                    var result = Vector.Max(curVec, propagated);
                    result.CopyTo(scratchA);
                    for (int v = 0; v < vecLen; v++)
                        buf[(y + v) * W + x] = scratchA[v];
                }
            }
            for (; y <= y1; y++)
            {
                int rowBase = y * W;
                for (int x = x1 - 1; x >= x0; x--)
                {
                    int prop = buf[rowBase + x + 1] - decay;
                    if (prop > buf[rowBase + x]) buf[rowBase + x] = prop;
                }
            }

            // --- Sweep DOWN (y increases) ---
            // Process multiple columns at once with SIMD
            int x2 = x0;
            for (; x2 + vecLen - 1 <= x1; x2 += vecLen)
            {
                for (int row = y0 + 1; row <= y1; row++)
                {
                    int curBase = row * W + x2;
                    int prevBase = (row - 1) * W + x2;
                    var curVec = new Vector<int>(buf, curBase);
                    var prevVec = new Vector<int>(buf, prevBase);
                    var propagated = Vector.Max(prevVec - decayVec, zeroVec);
                    var result = Vector.Max(curVec, propagated);
                    result.CopyTo(buf, curBase);
                }
            }
            // Scalar remainder columns
            for (; x2 <= x1; x2++)
            {
                for (int row = y0 + 1; row <= y1; row++)
                {
                    int prop = buf[(row - 1) * W + x2] - decay;
                    if (prop > buf[row * W + x2]) buf[row * W + x2] = prop;
                }
            }

            // --- Sweep UP (y decreases) ---
            x2 = x0;
            for (; x2 + vecLen - 1 <= x1; x2 += vecLen)
            {
                for (int row = y1 - 1; row >= y0; row--)
                {
                    int curBase = row * W + x2;
                    int nextBase = (row + 1) * W + x2;
                    var curVec = new Vector<int>(buf, curBase);
                    var nextVec = new Vector<int>(buf, nextBase);
                    var propagated = Vector.Max(nextVec - decayVec, zeroVec);
                    var result = Vector.Max(curVec, propagated);
                    result.CopyTo(buf, curBase);
                }
            }
            for (; x2 <= x1; x2++)
            {
                for (int row = y1 - 1; row >= y0; row--)
                {
                    int prop = buf[(row + 1) * W + x2] - decay;
                    if (prop > buf[row * W + x2]) buf[row * W + x2] = prop;
                }
            }
        }
    }

    // --------------------------------------------------
    // SyncFromTable — bulk Lua table → C# buffer
    // --------------------------------------------------

    /// <summary>Copy <paramref name="count"/> values from a Lua table (1-indexed) into buffer at offset 0.</summary>
    public void SyncFromTable(int handle, MoonSharp.Interpreter.Table table, int count)
    {
        var buf = _buffers[handle];
        if (buf == null || table == null) return;
        int n = Math.Min(count, buf.Length);
        for (int i = 0; i < n; i++)
        {
            var dyn = table.Get(i + 1);
            buf[i] = dyn.IsNil() ? 0 : (int)dyn.Number;
        }
    }

    /// <summary>Copy <paramref name="count"/> values from C# buffer into a Lua table (1-indexed).</summary>
    public void SyncToTable(int handle, MoonSharp.Interpreter.Table table, int count)
    {
        var buf = _buffers[handle];
        if (buf == null || table == null) return;
        int n = Math.Min(count, buf.Length);
        for (int i = 0; i < n; i++)
        {
            table.Set(i + 1, MoonSharp.Interpreter.DynValue.NewNumber(buf[i]));
        }
    }

    /// <summary>Clean up all buffers.</summary>
    public void Reset()
    {
        for (int i = 0; i < MaxBuffers; i++)
        {
            _buffers[i] = null;
            _sizes[i] = 0;
        }
        _nextHandle = 1;
    }
}
