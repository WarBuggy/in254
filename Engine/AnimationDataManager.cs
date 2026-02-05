#nullable enable
using System;
using System.Collections.Generic;
using System.Linq;
using AxiomPlayground.Data;
using AxiomPlayground.Modding;
using in254.Core;
using in254.Engine.LuaBindings;

namespace in254.Engine;

public class AnimationDataManager : BaseManager
{
    private static readonly AnimationDataManager _instance = new();
    public static AnimationDataManager Instance => _instance;
    private readonly LoggerBaseCore _logger = new();
    private readonly Dictionary<string, List<string>> _animationNames = new(StringComparer.OrdinalIgnoreCase); // TODO: Evaluate existance
    private static readonly string _DEFAULT_VALUE_PATH = "__default";

    private AnimationDataManager() : base("animationData", true) { }

    public override Dictionary<string, Dictionary<string, object?>> ProcessPathData
    (
        IReadOnlyList<CategoryData> collectedCategoryDataList,
        out Dictionary<string, Dictionary<string, PathHistory>> processedHistory
    )
    {
        // Result: modId -> resolved paths dictionary
        var result = new Dictionary<string, Dictionary<string, object?>>(StringComparer.OrdinalIgnoreCase);
        processedHistory = new Dictionary<string, Dictionary<string, PathHistory>>(StringComparer.OrdinalIgnoreCase);

        foreach (var modData in collectedCategoryDataList)
        {
            string modId = modData.ModId;
            var animationData = modData.Values; // Dictionary<string, object> for this mod

            var animationIndex = BuildAnimationIndex(animationData);
            var rawAnimationNames = animationIndex.Keys.ToList();

            _animationNames[modId] = [];
            var resolvedPaths = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
            var resolvedHistories = new Dictionary<string, PathHistory>(StringComparer.OrdinalIgnoreCase);

            foreach (var animationName in rawAnimationNames)
            {
                var index = animationIndex[animationName];
                var animationResolved = BuildResolvedAnimationPathsWithHistory(
                    animationName, animationData, index, modId, resolvedHistories);
                if (animationResolved == null)
                    continue;

                foreach (var kvp in animationResolved)
                    resolvedPaths[kvp.Key] = kvp.Value;

                _animationNames[modId].Add(animationName);
            }

            result[modId] = resolvedPaths;
            processedHistory[modId] = resolvedHistories;
        }

        return result;
    }

    private Dictionary<string, AnimationIndex> BuildAnimationIndex(
        IReadOnlyDictionary<string, object> paths
    )
    {
        Dictionary<string, AnimationIndex> index = new(StringComparer.OrdinalIgnoreCase);

        foreach (var path in paths.Keys)
        {
            // Expect: animationData.{animationName}.components...
            var parts = path.Split('.', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length < 3)
                continue;

            if (!parts[0].Equals(CategoryName, StringComparison.OrdinalIgnoreCase))
                continue;

            var animationName = parts[1];

            if (!index.TryGetValue(animationName, out var animationIndex))
            {
                animationIndex = new AnimationIndex();
                index[animationName] = animationIndex;
            }

            // Only component/state/frame paths matter from here
            if (!parts[2].Equals("components", StringComparison.OrdinalIgnoreCase))
                continue;

            if (parts.Length < 4)
                continue;

            var componentName = parts[3];
            if (!animationIndex.Components.TryGetValue(componentName, out var componentIndex))
            {
                componentIndex = new AnimationComponentIndex();
                animationIndex.Components[componentName] = componentIndex;
            }

            // states.{state}.frames.{index}.xxx
            if (parts.Length >= 6 &&
                parts[4].Equals("states", StringComparison.OrdinalIgnoreCase))
            {
                var stateName = parts[5];
                if (!componentIndex.States.TryGetValue(stateName, out var state))
                {
                    state = new AnimationStateIndex();
                    componentIndex.States[stateName] = state;
                }

                if (parts.Length >= 8 &&
                    parts[6].Equals("frames", StringComparison.OrdinalIgnoreCase) &&
                    int.TryParse(parts[7], out var frameIndex))
                {
                    state.Frames.Add(frameIndex);
                }
            }
        }

        return index;
    }

    //TODO: Work on who really owns the old path by looking at its history
    private Dictionary<string, object>? BuildResolvedAnimationPathsWithHistory
    (
        string animationName,
        IReadOnlyDictionary<string, object> animationData,
        AnimationIndex index,
        string owningModId,
        Dictionary<string, PathHistory> resolvedHistories
    )
    {
        var result = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
        string prefix = $"{ProcessedCategoryName}.{animationName}";

        var oldBaseComponentPath = $"{CategoryName}.{animationName}.baseComponent";
        // Animation-level validation (soft)
        if (!animationData.TryGetValue(oldBaseComponentPath, out var baseCompObj)
            || baseCompObj is not string baseComponent)
        {
            _logger.Log(
                "system.animationDataManager.skipAnimationMissingBaseComponent",
                animationName, owningModId);
            return null;
        }

        if (!index.Components.ContainsKey(baseComponent))
        {
            _logger.Log(
                "system.animationDataManager.skipAnimationInvalidBaseComponent",
                animationName, baseComponent, owningModId);
            return null;
        }

        var processBaseComponentPath = $"{prefix}.BaseComponent";
        result[processBaseComponentPath] = baseComponent;
        PropagateDerivedHistory(resolvedHistories, [oldBaseComponentPath], processBaseComponentPath, baseComponent, owningModId);

        var resolvedComponents = new List<string>();
        int stateCount = 0;
        int totalFrameCount = 0;

        foreach (var (componentName, componentIndex) in index.Components)
        {
            string defaultStatePath =
                $"{CategoryName}.{animationName}.components.{componentName}.defaultState";

            if (!animationData.TryGetValue(defaultStatePath, out var defaultStateObj)
                || defaultStateObj is not string defaultState)
            {
                _logger.Log(
                    "system.animationDataManager.skipComponentMissingDefaultState",
                    animationName, componentName, owningModId);
                continue;
            }

            if (!componentIndex.States.ContainsKey(defaultState))
            {
                _logger.Log(
                    "system.animationDataManager.skipComponentInvalidDefaultState",
                    animationName, componentName, defaultState, owningModId);
                continue;
            }

            var resolvedStates = new List<string>();
            foreach (var (stateName, stateIndex) in componentIndex.States)
            {
                int frameCount = 0;
                foreach (var frameIndex in stateIndex.Frames)
                {
                    if (TryResolveFrameWithHistory(
                        result,
                        animationData,
                        animationName,
                        componentName,
                        stateName,
                        frameIndex,
                        frameCount,
                        prefix,
                        owningModId,
                        resolvedHistories))
                    {
                        frameCount++;
                    }
                }

                if (frameCount == 0)
                {
                    _logger.Log(
                        "system.animationDataManager.skipStateNoValidFrames",
                        animationName, componentName, stateName, owningModId);
                    continue;
                }

                string statePrefix = $"{prefix}.{componentName}.{stateName}";
                string stateFrameCount = $"{statePrefix}.FrameCount";
                result[stateFrameCount] = frameCount;
                PropagateDerivedHistory(resolvedHistories, [], stateFrameCount, frameCount, owningModId);

                var stateCurrentFrame = $"{statePrefix}.CurrentFrame";
                result[stateCurrentFrame] = 1; // LUA use 1-based index
                PropagateDerivedHistory(resolvedHistories, [], stateCurrentFrame, 1, owningModId);

                resolvedStates.Add(stateName);
                totalFrameCount += frameCount;
            }

            if (resolvedStates.Count == 0 || !resolvedStates.Contains(defaultState))
            {
                _logger.Log(
                    "system.animationDataManager.skipComponentNoValidStates",
                    animationName, componentName, owningModId);
                continue;
            }

            string compPrefix = $"{prefix}.{componentName}";
            var processDefaultStatePath = $"{compPrefix}.DefaultState";
            result[processDefaultStatePath] = defaultState;
            PropagateDerivedHistory(resolvedHistories, [defaultStatePath], processDefaultStatePath, defaultState, owningModId);

            var compStatesLedger = new LedgerArray();
            foreach (var stateName in resolvedStates)
                compStatesLedger.InsertLast(stateName, owningModId);
            string compStates = $"{compPrefix}.States";
            result[compStates] = compStatesLedger;
            PropagateDerivedHistory(resolvedHistories, [], compStates, compStatesLedger, owningModId);


            var processComponentCurrentStatePath = $"{compPrefix}.CurrentState";
            result[processComponentCurrentStatePath] = defaultState;
            PropagateDerivedHistory(resolvedHistories, [], processComponentCurrentStatePath, defaultState, owningModId);

            var processComponentFlipX = $"{compPrefix}.FlipX";
            result[processComponentFlipX] = false;
            PropagateDerivedHistory(resolvedHistories, [], processComponentFlipX, false, owningModId);

            var processComponentFlipY = $"{compPrefix}.FlipY";
            result[processComponentFlipY] = false;
            PropagateDerivedHistory(resolvedHistories, [], processComponentFlipY, false, owningModId);

            resolvedComponents.Add(componentName);
            stateCount += resolvedStates.Count;
        }

        // Final animation validation (soft)
        if (resolvedComponents.Count == 0 || !resolvedComponents.Contains(baseComponent))
        {
            _logger.Log(
                "system.animationDataManager.skipAnimationNoValidComponents",
                animationName, owningModId);
            return null;
        }

        var compLedger = new LedgerArray();
        foreach (var compName in resolvedComponents)
            compLedger.InsertLast(compName, owningModId);
        string compListPath = $"{prefix}.Components";
        result[compListPath] = compLedger;
        PropagateDerivedHistory(resolvedHistories, [], compListPath, compLedger, owningModId);

        _logger.Log(
            "system.animationDataManager.animationBuiltSuccessfully",
            owningModId, animationName, resolvedComponents.Count, stateCount, totalFrameCount);

        return result;
    }

    private bool TryResolveFrameWithHistory
    (
        Dictionary<string, object> result,
        IReadOnlyDictionary<string, object> animationData,
        string animationName,
        string componentName,
        string stateName,
        int frameIndex,
        int frameCount,
        string prefix,
        string owningModId,
        Dictionary<string, PathHistory> resolvedHistories
    )
    {
        try
        {
            // Use LUA script's 1-based index array
            string framePrefix = $"{prefix}.{componentName}.{stateName}.{frameCount + 1}";

            object ResolveRequired(string prop, out string[] sourcePaths)
            {
                string[] candidatePaths =
                {
                $"{CategoryName}.{animationName}.components.{componentName}.states.{stateName}.frames.{frameIndex}.{prop}",
                $"{CategoryName}.{animationName}.components.{componentName}.states.{stateName}.{prop}",
                $"{CategoryName}.{animationName}.components.{componentName}.{prop}",
                $"{CategoryName}.{animationName}.{prop}"
            };

                foreach (var path in candidatePaths)
                {
                    if (animationData.TryGetValue(path, out var value))
                    {
                        sourcePaths = [path];
                        return value!;
                    }
                }

                sourcePaths = [];
                return null!;
            }

            string ResolveOptionalString(string prop, string defaultValue, out string[] sources)
            {
                var value = ResolveRequired(prop, out sources) as string;

                if (string.IsNullOrWhiteSpace(value))
                {
                    value = defaultValue;
                    sources = [_DEFAULT_VALUE_PATH];
                }

                return value;
            }

            // required properties
            var file = ResolveRequired("file", out var fileSources) as string;
            var folder = ResolveOptionalString("folder", "./", out var folderSources);
            var sourceModId = ResolveOptionalString("sourceMod", owningModId, out var sourceModSources);
            var layer = ResolveRequired("layer", out var layerSources) as string;


            if (string.IsNullOrWhiteSpace(file)
                || string.IsNullOrWhiteSpace(folder)
                || string.IsNullOrWhiteSpace(sourceModId)
                || string.IsNullOrWhiteSpace(layer))
                return false;

            if (!TryConvertInt(ResolveRequired("width", out var widthSources), out int width))
                return false;

            if (!TryConvertInt(ResolveRequired("height", out var heightSources), out int height))
                return false;

            int ResolveOptionalInt(string prop, out string[] sources)
            {
                var value = ResolveRequired(prop, out sources);

                if (!TryConvertInt(value, out var d))
                {
                    d = 0;
                    sources = [_DEFAULT_VALUE_PATH];
                }

                return d;
            }

            int offsetX = ResolveOptionalInt("offsetX", out var offsetXSources);
            int offsetY = ResolveOptionalInt("offsetY", out var offsetYSources);
            int spriteOffsetX = ResolveOptionalInt("spriteOffsetX", out var spriteOffsetXSources);
            int spriteOffsetY = ResolveOptionalInt("spriteOffsetY", out var spriteOffsetYSources);

            string modFolderPath = ModManager.Instance.GetModFolderPath(sourceModId);
            // Register textures
            int textureId = TextureManager.Instance.RegisterTexture(owningModId, modFolderPath, folder, file);

            // Record all resolved properties as Derived from their respective original paths
            AssignWithDerivedHistory(resolvedHistories, [.. fileSources, .. folderSources, .. sourceModSources],
                $"{framePrefix}.TextureId", textureId, result, owningModId);
            AssignWithDerivedHistory(resolvedHistories, layerSources, $"{framePrefix}.Layer", layer, result, owningModId);
            AssignWithDerivedHistory(resolvedHistories, widthSources, $"{framePrefix}.Width", width, result, owningModId);
            AssignWithDerivedHistory(resolvedHistories, heightSources, $"{framePrefix}.Height", height, result, owningModId);
            AssignWithDerivedHistory(resolvedHistories, offsetXSources, $"{framePrefix}.OffsetX", offsetX, result, owningModId);
            AssignWithDerivedHistory(resolvedHistories, offsetYSources, $"{framePrefix}.OffsetY", offsetY, result, owningModId);
            AssignWithDerivedHistory(resolvedHistories, spriteOffsetXSources, $"{framePrefix}.SpriteOffsetX", spriteOffsetX, result, owningModId);
            AssignWithDerivedHistory(resolvedHistories, spriteOffsetYSources, $"{framePrefix}.SpriteOffsetY", spriteOffsetY, result, owningModId);
            AssignWithDerivedHistory(resolvedHistories, [], $"{framePrefix}.PosX", 0, result, owningModId);
            AssignWithDerivedHistory(resolvedHistories, [], $"{framePrefix}.PosY", 0, result, owningModId);

            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine
            (
                $"[AnimationDataManager] Error resolving frame: Animation='{animationName}', " +
                $"Component='{componentName}', State='{stateName}', FrameIndex={frameIndex}, " +
                $"Mod='{owningModId}'. Exception: {ex.Message}"
            );
            return false;
        }
    }

    private static void AssignWithDerivedHistory<T>
    (
        Dictionary<string, PathHistory> resolvedHistories,
        string[] sourcePaths,
        string targetPath,
        T value,
        Dictionary<string, object> result,
        string actingModId
    )
    {
        // Propagate Derived history
        PropagateDerivedHistory(resolvedHistories, sourcePaths, targetPath, value!, actingModId);

        // Assign to resolved paths
        result[targetPath] = value!;
    }

    private static bool TryConvertInt(object value, out int result)
    {
        switch (value)
        {
            case int i:
                result = i;
                return true;
            case long l when l <= int.MaxValue && l >= int.MinValue:
                result = (int)l;
                return true;
            case double d when d <= int.MaxValue && d >= int.MinValue:
                result = (int)d; // truncate
                return true;
            case string s when int.TryParse(s, out var parsed):
                result = parsed;
                return true;
            default:
                result = 0;
                return false;
        }
    }

    private static void PropagateDerivedHistory
    (
        Dictionary<string, PathHistory> resolvedHistories,
        string[] sourcePaths,
        string newPath,
        object newValue,
        string actingModId
    )
    {
        var history = new PathHistory();

        if (sourcePaths == null || sourcePaths.Length == 0)
            history.AddCreate(actingModId, newValue);
        else
            history.AddDerived(actingModId, newValue, sourcePaths);

        resolvedHistories[newPath] = history;
    }

    public override IEnumerable<LoadEventDispatch> CollectLoadEvents()
    {
        foreach (var (modId, names) in _animationNames)
        {
            foreach (var name in names)
            {
                yield return new LoadEventDispatch
                (
                    LuaGameEvents.OnAnimationCreated,
                    modId,
                    [modId, name]
                );
            }
        }
    }

    #region LUA exposed functions

    public bool TryGetComponents(string modId, string animationName, out LedgerArray? compLedger)
    {
        string path = CreateFullPath([animationName, "Components"]);

        if (DataManager.Instance.TryGetData(modId, path, out var value) && value is LedgerArray ledger)
        {
            compLedger = ledger;
            return true;
        }

        compLedger = null;
        return false;
    }

    public bool TryGetBaseComponent(string modId, string animationName, out string baseComponent)
    {
        string path = CreateFullPath([animationName, "BaseComponent"]);

        if (DataManager.Instance.TryGetData(modId, path, out var value) && value is string s)
        {
            baseComponent = s;
            return true;
        }

        baseComponent = null!;
        return false;
    }

    public bool TryGetDefaultState(string modId, string animationName, string componentName, out string defaultState)
    {
        string path = CreateFullPath([animationName, componentName, "DefaultState"]);

        if (DataManager.Instance.TryGetData(modId, path, out var value) && value is string s)
        {
            defaultState = s;
            return true;
        }

        defaultState = null!;
        return false;
    }

    public bool TryGetStates(string modId, string animationName, string componentName, out LedgerArray? stateLedger)
    {
        string path = CreateFullPath([animationName, componentName, "States"]);

        if (DataManager.Instance.TryGetData(modId, path, out var value) && value is LedgerArray ledger)
        {
            stateLedger = ledger;
            return true;
        }

        stateLedger = null;
        return false;
    }

    public bool TryGetFrameCount(string modId, string animationName, string componentName, string stateName, out int? frameCount)
    {
        string path = CreateFullPath(animationName, componentName, stateName, "FrameCount");

        if (DataManager.Instance.TryGetData(modId, path, out var value) && value is int v)
        {
            frameCount = v;
            return true;
        }

        frameCount = null!;
        return false;
    }

    public bool TryGetFrameProperty<T>(string modId, string animationName, string componentName, string stateName, int frameIndex, string propertyName, out T propertyValue)
    {
        string path = CreateFullPath([animationName, componentName, stateName, frameIndex.ToString(), propertyName]);

        if (DataManager.Instance.TryGetData(modId, path, out var value) && value is T t)
        {
            propertyValue = t;
            return true;
        }

        propertyValue = default!;
        return false;
    }

    public void SetFramePosX
    (
        string modId,
        string animationName,
        string componentName,
        string stateName,
        int frameIndex,
        float value,
        string actingModId
    )
    {
        SetFramePropertyInternal(
            modId,
            animationName,
            componentName,
            stateName,
            frameIndex,
            "PosX",
            value,
            actingModId);
    }

    public void SetFramePosY(
        string modId,
        string animationName,
        string componentName,
        string stateName,
        int frameIndex,
        float value,
        string actingModId
    )
    {
        SetFramePropertyInternal(
            modId,
            animationName,
            componentName,
            stateName,
            frameIndex,
            "PosY",
            value,
            actingModId);
    }

    private void SetFramePropertyInternal<T>
    (
        string owningModId,
        string animationName,
        string componentName,
        string stateName,
        int frameIndex,
        string propertyName,
        T value,
        string actingModId
    )
    {
        if (frameIndex < 1)
            throw new LocalizedErrorCore<ArgumentOutOfRangeException>(
                "system.animationDataManager.frameIndexOutOfRange",
                frameIndex,
                animationName,
                componentName,
                stateName);

        string propertyPath = CreateFullPath(
            animationName,
            componentName,
            stateName,
            frameIndex.ToString(),
            propertyName
        );

        // Validate that the property exists (or at least the frame exists)
        if (!DataManager.Instance.TryGetData(owningModId, propertyPath, out _))
        {
            throw new LocalizedErrorCore<InvalidOperationException>(
                "system.animationDataManager.frameMissingRequiredProperty",
                animationName,
                componentName,
                stateName,
                frameIndex,
                propertyName
            );
        }

        DataManager.Instance.SetData(owningModId, propertyPath, value, actingModId);
    }

    public bool GetFlipX(string modId, string animationName, string componentName)
    {
        string flipXPath = CreateFullPath(animationName, componentName, "FlipX");

        if (!DataManager.Instance.TryGetData(modId, flipXPath, out var value)
            || value is not bool flipX)
        {
            throw new LocalizedErrorCore<InvalidOperationException>(
                "system.animationDataManager.invalidAnimationOrComponent",
                animationName, componentName);
        }

        return flipX;
    }

    public bool GetFlipY(string modId, string animationName, string componentName)
    {
        string flipYPath = CreateFullPath(animationName, componentName, "FlipY");

        if (!DataManager.Instance.TryGetData(modId, flipYPath, out var value)
            || value is not bool flipY)
        {
            throw new LocalizedErrorCore<InvalidOperationException>(
                "system.animationDataManager.invalidAnimationOrComponent",
                animationName, componentName);
        }

        return flipY;
    }

    public void SetFlipX(string modId, string animationName, string componentName, bool value, string actingModId)
    {
        string flipXPath = CreateFullPath(animationName, componentName, "FlipX");

        // Validate path exists
        if (!DataManager.Instance.TryGetData(modId, flipXPath, out _))
        {
            throw new LocalizedErrorCore<InvalidOperationException>(
                "system.animationDataManager.invalidAnimationComponent",
                componentName, animationName);
        }

        DataManager.Instance.SetData(modId, flipXPath, value, actingModId);
    }

    public void SetFlipY(string modId, string animationName, string componentName, bool value, string actingModId)
    {
        string flipYPath = CreateFullPath(animationName, componentName, "FlipY");

        // Validate path exists
        if (!DataManager.Instance.TryGetData(modId, flipYPath, out _))
        {
            throw new LocalizedErrorCore<InvalidOperationException>(
                "system.animationDataManager.invalidAnimationComponent",
                componentName, animationName);
        }

        DataManager.Instance.SetData(modId, flipYPath, value, actingModId);
    }

    public void SetCurrentState
    (
        string modId,
        string animationName,
        string componentName,
        string newState,
        string actingModId)
    {
        string statesPath =
            CreateFullPath(animationName, componentName, "States");

        if (!DataManager.Instance.TryGetData(modId, statesPath, out var statesObj)
            || statesObj is not LedgerArray statesLedger
            || statesLedger.GetIndexOf(newState) < 0)
        {
            throw new LocalizedErrorCore<InvalidOperationException>(
                "system.animationDataManager.invalidAnimationState",
                newState, animationName, componentName);
        }

        string currentStatePath =
            CreateFullPath(animationName, componentName, "CurrentState");

        DataManager.Instance.SetData(modId, currentStatePath, newState, actingModId);

        // Reset frame (Lua-facing 1-based index)
        string currentFramePath =
            CreateFullPath(animationName, componentName, newState, "CurrentFrame");

        DataManager.Instance.SetData(modId, currentFramePath, 1, actingModId);
    }

    public void SetCurrentFrame
    (
        string modId,
        string animationName,
        string componentName,
        string stateName,
        int frameIndex,
        string actingModId
    )
    {
        if (frameIndex < 1)
            throw new LocalizedErrorCore<ArgumentOutOfRangeException>(
                "system.animationDataManager.frameIndexOutOfRange",
                frameIndex, animationName, componentName, stateName);


        string frameCountPath =
            CreateFullPath(animationName, componentName, stateName, "FrameCount");

        if (!DataManager.Instance.TryGetData(modId, frameCountPath, out var countObj)
            || countObj is not int frameCount
            || frameCount <= 0)
        {
            throw new LocalizedErrorCore<InvalidOperationException>(
                "system.animationDataManager.missingFrameCount",
                animationName, componentName, stateName);

        }

        int clampedFrame = Math.Min(frameIndex, frameCount);

        string currentFramePath =
            CreateFullPath(animationName, componentName, stateName, "CurrentFrame");

        DataManager.Instance.SetData(modId, currentFramePath, clampedFrame, actingModId);
    }

    public string GetCurrentState(string modId, string animationName, string componentName)
    {
        string path =
            CreateFullPath(animationName, componentName, "CurrentState");

        if (DataManager.Instance.TryGetData(modId, path, out var value)
            && value is string state)
        {
            return state;
        }

        throw new LocalizedErrorCore<InvalidOperationException>(
            "system.animationDataManager.missingCurrentState",
            animationName, componentName);

    }

    public int GetCurrentFrame
    (
        string modId,
        string animationName,
        string componentName,
        string stateName
    )
    {
        string path =
            CreateFullPath(animationName, componentName, stateName, "CurrentFrame");

        if (DataManager.Instance.TryGetData(modId, path, out var value)
            && value is int frame)
        {
            return frame;
        }

        throw new LocalizedErrorCore<InvalidOperationException>(
            "system.animationDataManager.missingCurrentFrame",
            animationName, componentName, stateName);

    }

    #endregion

    #region Animation Data Classes

    private sealed class AnimationIndex
    {
        public Dictionary<string, AnimationComponentIndex> Components { get; } = new(StringComparer.OrdinalIgnoreCase);
    }

    private sealed class AnimationComponentIndex
    {
        public Dictionary<string, AnimationStateIndex> States { get; } = new(StringComparer.OrdinalIgnoreCase);
    }

    private sealed class AnimationStateIndex
    {
        public SortedSet<int> Frames { get; } = [];

    }

    #endregion
}