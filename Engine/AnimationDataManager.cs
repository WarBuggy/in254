using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using AxiomPlayground.Data;
using AxiomPlayground.Modding;
using in254.Core;
using MoonSharp.Interpreter;

namespace in254.Engine;

/// <summary>
/// Manages animation data for all mods.
/// Builds fully resolved Animation objects from JSON in DataManager.
/// </summary>
public class AnimationDataManager : BaseManager
{
    private static readonly AnimationDataManager _instance = new();
    public static AnimationDataManager Instance => _instance;
    private readonly LoggerBaseCore _logger = new();

    private readonly Dictionary<string, Dictionary<string, Animation>> _animations = new(StringComparer.OrdinalIgnoreCase);
    // Cache Lua tables per mod
    private readonly Dictionary<string, Table> _luaAnimationCache = new(StringComparer.OrdinalIgnoreCase);


    private AnimationDataManager() : base("animationData") { }

    /// <summary>
    /// Load all animations for a single mod, skipping invalid frames/states/components/animations.
    /// </summary>
    protected override void LoadForMod(ModInstance mod)
    {
        var container = DataManager.Instance.TryGetContainer(mod.ModId);
        if (container == null) return;

        var animationNames = CollectAnimationNames(container);

        var modAnimations = new Dictionary<string, Animation>(StringComparer.OrdinalIgnoreCase);

        var modFolderPath = ModManager.Instance.GetModFolderPath(mod);
        foreach (var name in animationNames)
        {
            try
            {
                var animation = BuildAnimation(mod.ModId, modFolderPath, container, name);
                if (animation != null && animation.Components.Count > 0)
                    modAnimations[name] = animation;
            }
            catch (Exception ex)
            {
                _logger.Log("system.animationDataManager.errorBuildingAnimation", name, mod.ModId, ex.Message);
            }
        }

        _animations[mod.ModId] = modAnimations;
        _luaAnimationCache.Remove(mod.ModId);
    }

    private HashSet<string> CollectAnimationNames(DataContainer container)
    {
        var result = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var path in container.GetPathsInCategory(CategoryName))
        {
            var parts = path.Split('.', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length < 2) continue;

            string animationName = parts[0];
            if (string.IsNullOrWhiteSpace(animationName)) continue;
            if (result.Contains(animationName)) continue;

            string baseComponentPath = $"{animationName}.baseComponent";
            string componentListPath = $"{animationName}.componentList";

            object baseComponentValue = container.GetFlatData(baseComponentPath);
            object componentListValue = container.GetFlatData(componentListPath);

            if (baseComponentValue != null && componentListValue is List<object>)
                result.Add(animationName);
        }

        return result;
    }

    private Animation BuildAnimation(string modId, string modFolderPath, DataContainer container, string animationName)
    {
        string rootPath = animationName;

        var animation = new Animation(animationName)
        {
            BaseComponent = container.GetFlatData($"{rootPath}.baseComponent") as string ?? string.Empty
        };

        var componentListObj = container.GetFlatData($"{rootPath}.componentList") as List<object>;
        if (componentListObj == null) return null;

        foreach (var compJson in componentListObj.Cast<JsonElement>())
        {
            string compName = compJson.GetProperty("name").GetString()!;
            var component = new AnimationComponent(compName)
            {
                DefaultState = compJson.TryGetProperty("defaultState", out var ds) ? ds.GetString() ?? "" : ""
            };

            var stateListJson = compJson.GetProperty("stateList").EnumerateObject();
            foreach (var stateProp in stateListJson)
            {
                string stateName = stateProp.Name;
                var stateJson = stateProp.Value;
                var state = new AnimationState(stateName);

                foreach (var frameJson in stateJson.GetProperty("frameList").EnumerateArray())
                {
                    try
                    {
                        var frame = CreateAnimationFrame(modId, modFolderPath, container, frameJson, stateJson, compJson, rootPath);
                        state.Frames.Add(frame);
                    }
                    catch (Exception ex)
                    {
                        _logger.Log("system.animationDataManager.skippingFrame", animationName, compName, stateName, ex.Message);
                    }
                }

                if (state.Frames.Count > 0)
                    component.States[stateName] = state;
            }

            if (component.States.Count > 0)
                animation.Components[compName] = component;
        }

        return animation.Components.Count > 0 ? animation : null;
    }

    private static AnimationFrame CreateAnimationFrame(
        string modId,
        string modFolderPath,
        DataContainer container,
        JsonElement frameJson,
        JsonElement stateJson,
        JsonElement compJson,
        string animationRootPath)
    {
        var file = Resolve(container, frameJson, stateJson, compJson, animationRootPath, "file", null) as string;
        var folder = Resolve(container, frameJson, stateJson, compJson, animationRootPath, "folder", null) as string;
        var layer = Resolve(container, frameJson, stateJson, compJson, animationRootPath, "layer", null) as string;
        var width = Resolve(container, frameJson, stateJson, compJson, animationRootPath, "width", null);
        var height = Resolve(container, frameJson, stateJson, compJson, animationRootPath, "height", null);

        if (string.IsNullOrWhiteSpace(file))
            throw new LocalizedErrorCore<InvalidOperationException>("system.animationDataManager.frameMissingRequiredProperty", "file", animationRootPath);
        if (string.IsNullOrWhiteSpace(folder))
            throw new LocalizedErrorCore<InvalidOperationException>("system.animationDataManager.frameMissingRequiredProperty", "folder", animationRootPath);
        if (string.IsNullOrWhiteSpace(layer))
            throw new LocalizedErrorCore<InvalidOperationException>("system.animationDataManager.frameMissingRequiredProperty", "layer", animationRootPath);
        if (width == null)
            throw new LocalizedErrorCore<InvalidOperationException>("system.animationDataManager.frameMissingRequiredProperty", "width", animationRootPath);
        if (height == null)
            throw new LocalizedErrorCore<InvalidOperationException>("system.animationDataManager.frameMissingRequiredProperty", "height", animationRootPath);


        var textureId = TextureManager.Instance.RegisterTexture(modId, modFolderPath, folder, file);
        var offsetX = (double)Resolve(container, frameJson, stateJson, compJson, animationRootPath, "offsetX", 0.0);
        var offsetY = (double)Resolve(container, frameJson, stateJson, compJson, animationRootPath, "offsetY", 0.0);
        var spriteOffsetX = (double)Resolve(container, frameJson, stateJson, compJson, animationRootPath, "spriteOffsetX", 0.0);
        var spriteOffsetY = (double)Resolve(container, frameJson, stateJson, compJson, animationRootPath, "spriteOffsetY", 0.0);

        return new AnimationFrame
        {
            TextureId = textureId,
            Layer = layer,
            Width = (double)width,
            Height = (double)height,
            OffsetX = offsetX,
            OffsetY = offsetY,
            SpriteOffsetX = spriteOffsetX,
            SpriteOffsetY = spriteOffsetY
        };
    }

    private static object Resolve(DataContainer container,
        JsonElement frameJson, JsonElement stateJson, JsonElement compJson,
        string animationRootPath, string propertyName, object defaultValue = null!)
    {
        if (frameJson.TryGetProperty(propertyName, out var prop) && TryGetValue(prop, out var val1)) return val1;
        if (stateJson.TryGetProperty(propertyName, out prop) && TryGetValue(prop, out var val2)) return val2;
        if (compJson.TryGetProperty(propertyName, out prop) && TryGetValue(prop, out var val3)) return val3;

        var basePath = $"{animationRootPath}.{propertyName}";
        var obj = container.GetFlatData(basePath);
        return obj ?? defaultValue!;
    }

    private static bool TryGetValue(JsonElement element, out object value)
    {
        value = element.ValueKind switch
        {
            JsonValueKind.String => element.GetString()!,
            JsonValueKind.Number => element.GetDouble(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            _ => null
        };
        return value != null;
    }

    #region LUA exposed functions
    /// <summary>
    /// Get all animations for a specific mod.
    /// </summary>
    public Dictionary<string, Animation> GetAnimations(string modId)
    {
        if (_animations.TryGetValue(modId, out var modAnimations))
            return modAnimations;

        return new Dictionary<string, Animation>(StringComparer.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Get a specific animation by mod ID and animation name.
    /// Returns null if not found.
    /// </summary>
    public Animation GetAnimation(string modId, string animationName)
    {
        if (_animations.TryGetValue(modId, out var modAnimations) &&
            modAnimations.TryGetValue(animationName, out var animation))
        {
            return animation;
        }

        return null;
    }
    #endregion

    protected override void ProcessPath(string modId, string path, object value) { return; }

    public void DebugPrintAllAnimations()
    {
        foreach (var modKvp in _animations)
        {
            string modId = modKvp.Key;
            Console.WriteLine($"Mod: {modId}");
            foreach (var animKvp in modKvp.Value)
            {
                string animName = animKvp.Key;
                var animation = animKvp.Value;
                Console.WriteLine($"  Animation: {animName}, BaseComponent: {animation.BaseComponent}");

                foreach (var compKvp in animation.Components)
                {
                    var component = compKvp.Value;
                    Console.WriteLine($"    Component: {component.Name}, DefaultState: {component.DefaultState}");

                    foreach (var stateKvp in component.States)
                    {
                        var state = stateKvp.Value;
                        Console.WriteLine($"      State: {state.Name}, Frames: {state.Frames.Count}");

                        for (int i = 0; i < state.Frames.Count; i++)
                        {
                            var frame = state.Frames[i];
                            Console.WriteLine($"        Frame {i}: TextureId={frame.TextureId}, Layer={frame.Layer}, " +
                                              $"Width={frame.Width}, Height={frame.Height}, OffsetX={frame.OffsetX}, OffsetY={frame.OffsetY}, " +
                                              $"SpriteOffsetX={frame.SpriteOffsetX}, SpriteOffsetY={frame.SpriteOffsetY}");
                        }
                    }
                }
            }
        }
    }


    #region Animation Data Classes

    public sealed class AnimationFrame
    {
        public int TextureId { get; set; }
        public string Layer { get; set; } = string.Empty;
        public double Width { get; set; }
        public double Height { get; set; }
        public double OffsetX { get; set; } = 0;
        public double OffsetY { get; set; } = 0;
        public double SpriteOffsetX { get; set; } = 0;
        public double SpriteOffsetY { get; set; } = 0;
    }

    public sealed class AnimationState(string name)
    {
        public string Name { get; } = name;
        public List<AnimationFrame> Frames { get; } = new();
    }

    public sealed class AnimationComponent(string name)
    {
        public string Name { get; } = name;
        public string DefaultState { get; set; } = string.Empty;
        public Dictionary<string, AnimationState> States { get; } = new(StringComparer.OrdinalIgnoreCase);
    }

    public sealed class Animation(string name)
    {
        public string Name { get; } = name;
        public string BaseComponent { get; set; } = string.Empty;
        public Dictionary<string, AnimationComponent> Components { get; } = new(StringComparer.OrdinalIgnoreCase);
    }

    #endregion
}
