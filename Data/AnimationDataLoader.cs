using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using in254.Core;
using in254.Data.DTO;
using in254.Engine;

namespace in254.Data;

/// <summary>
/// Loads animation data from JSON and resolves all frames.
/// Fully resolves fallback properties for each frame.
/// Registers full paths in TextureManager.
/// </summary>
public sealed class AnimationDataLoader : LoggerBase
{
    private const string ANIMATION_FILE_PATH = "Data/animationData.json";

    private static readonly AnimationDataLoader _instance = new();
    public static AnimationDataLoader Instance => _instance;

    private readonly JsonSerializerOptions _jsonSerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private AnimationDataLoader() { }

    /// <summary>
    /// Load animation JSON from file and return resolved AnimationFrameDTOs.
    /// </summary>
    public List<AnimationFrameDTO> LoadFromFile()
    {
        var result = new List<AnimationFrameDTO>();

        if (!File.Exists(ANIMATION_FILE_PATH))
            throw new LocalizedError<FileNotFoundException>("system.animationDataLoader.fileNotFound", ANIMATION_FILE_PATH);

        string json = File.ReadAllText(ANIMATION_FILE_PATH);
        AnimationDTO animationDto;

        try
        {
            animationDto = JsonSerializer.Deserialize<AnimationDTO>(json, _jsonSerializerOptions)!;
        }
        catch (Exception)
        {
            throw new LocalizedError<InvalidOperationException>("system.animationDataLoader.jsonParseFailed", ANIMATION_FILE_PATH);
        }
        result = ResolveFrames(animationDto);
        return result;
    }

    /// <summary>
    /// Resolve all frames from an AnimationDTO.
    /// Applies fallback rules and registers full paths in TextureManager.
    /// </summary>
    public List<AnimationFrameDTO> ResolveFrames(AnimationDTO animationDto)
    {
        var resolvedFrames = new List<AnimationFrameDTO>();

        if (animationDto.ComponentList == null || animationDto.ComponentList.Count == 0)
        {
            LogWarning("system.animationDataLoader.noComponents", animationDto.Name);
            return resolvedFrames;
        }

        foreach (var component in animationDto.ComponentList)
        {
            if (component.AnimationList == null || component.AnimationList.Count == 0)
            {
                LogWarning("system.animationDataLoader.componentNoStates", component.Name);
                continue;
            }

            foreach (var stateKvp in component.AnimationList)
            {
                string stateName = stateKvp.Key;
                var state = stateKvp.Value;

                if (state.FrameList == null || state.FrameList.Count == 0)
                {
                    LogWarning("system.animationDataLoader.stateNoFrames", component.Name, stateName);
                    continue;
                }

                foreach (var fileName in state.FrameList)
                {
                    var frame = new AnimationFrameDTO
                    {
                        File = ResolveValue(state.File, component.File, animationDto.File, fileName),
                        Folder = ResolveValue(state.Folder, component.Folder, animationDto.Folder, ""),
                        Layer = ResolveValue(state.Layer, component.Layer, animationDto.Layer, ""),
                        Width = ResolveValue(state.Width, component.Width, animationDto.Width),
                        Height = ResolveValue(state.Height, component.Height, animationDto.Height),
                        OffsetX = ResolveValue(state.OffsetX, component.OffsetX, animationDto.OffsetX),
                        OffsetY = ResolveValue(state.OffsetY, component.OffsetY, animationDto.OffsetY),
                        SpriteOffsetX = ResolveValue(state.SpriteOffsetX, component.SpriteOffsetX, animationDto.SpriteOffsetX),
                        SpriteOffsetY = ResolveValue(state.SpriteOffsetY, component.SpriteOffsetY, animationDto.SpriteOffsetY)
                    };

                    if (string.IsNullOrWhiteSpace(frame.File) || string.IsNullOrWhiteSpace(frame.Folder)
                        || frame.Width == 0 || frame.Height == 0)
                    {
                        LogWarning("system.animationDataLoader.skipFrameMissingProperty", component.Name, stateName, fileName);
                        continue;
                    }

                    // Register full path and get index
                    string fullPath = Path.Combine(frame.Folder, frame.File);
                    int pathIndex = TextureManager.Instance.AddPath(fullPath);

                    resolvedFrames.Add(frame);
                    Log("system.animationDataLoader.frameResolved", component.Name, stateName, frame.File, pathIndex);
                }
            }
        }

        Log("system.animationDataLoader.totalFramesResolved", resolvedFrames.Count);
        return resolvedFrames;
    }

    /// <summary>
    /// Helper to resolve fallback values for string properties.
    /// Returns first non-null, non-empty value, or defaultValue if none.
    /// </summary>
    private static string ResolveValue(string stateVal, string componentVal, string baseVal, string defaultValue = "")
    {
        return !string.IsNullOrWhiteSpace(stateVal) ? stateVal
             : !string.IsNullOrWhiteSpace(componentVal) ? componentVal
             : !string.IsNullOrWhiteSpace(baseVal) ? baseVal
             : defaultValue;
    }

    /// <summary>
    /// Helper to resolve fallback values for int properties.
    /// Returns first non-zero value, or 0 if none.
    /// </summary>
    private static int ResolveValue(int stateVal, int componentVal, int baseVal)
    {
        return stateVal != 0 ? stateVal
             : componentVal != 0 ? componentVal
             : baseVal;
    }
}
