using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using in254.Core;
using in254.Data.DTO;
using in254.Engine.Animation;

namespace in254.Data
{
    /// <summary>
    /// Loads animation data from JSON and converts it into fully resolved Animation objects.
    /// Handles TextureManager registration for each frame.
    /// </summary>
    public sealed class AnimationDataLoader : LoggerBase
    {
        private const string ANIMATION_FILE_PATH = "Data/animation.json";

        private static readonly AnimationDataLoader _instance = new();
        public static AnimationDataLoader Instance => _instance;

        private readonly JsonSerializerOptions _jsonSerializerOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        private AnimationDataLoader() { }

        /// <summary>
        /// Load all animations from JSON and return a dictionary of Animation objects keyed by name.
        /// </summary>
        public Dictionary<string, Animation> LoadAnimations()
        {
            if (!File.Exists(ANIMATION_FILE_PATH))
                throw new LocalizedError<FileNotFoundException>("system.animationDataLoader.fileNotFound", ANIMATION_FILE_PATH);

            string json = File.ReadAllText(ANIMATION_FILE_PATH);
            JsonDocument doc;
            try
            {
                doc = JsonDocument.Parse(json);
            }
            catch (Exception)
            {
                throw new LocalizedError<InvalidOperationException>("system.animationDataLoader.jsonParseFailed", ANIMATION_FILE_PATH);
            }

            var root = doc.RootElement;
            string assetFolder = root.GetProperty("assetFolder").GetString() ?? string.Empty;

            var dataElement = root.GetProperty("data");

            var animations = new Dictionary<string, Animation>();

            foreach (var animProp in dataElement.EnumerateObject())
            {
                string animName = animProp.Name;
                var animDto = JsonSerializer.Deserialize<AnimationDTO>(animProp.Value.GetRawText(), _jsonSerializerOptions)!;
                var animation = ResolveAnimation(animDto, assetFolder);
                animations.Add(animName, animation);
            }

            Log("system.animationDataLoader.totalAnimationsLoaded", animations.Count);
            return animations;
        }

        /// <summary>
        /// Convert an AnimationDTO into a fully resolved Animation object.
        /// </summary>
        private static Animation ResolveAnimation(AnimationDTO dto, string assetFolder)
        {
            var animation = new Animation
            {
                Name = dto.Name,
                BaseComponent = dto.BaseComponent,
                Components = []
            };

            foreach (var compDto in dto.ComponentList)
            {
                var component = new AnimationComponent
                {
                    Name = compDto.Name,
                    DefaultState = compDto.DefaultState,
                    States = []
                };

                foreach (var stateKvp in compDto.StateList)
                {
                    string stateName = stateKvp.Key;
                    var stateDto = stateKvp.Value;

                    var frameList = new List<AnimationFrame>();
                    foreach (var frameDto in stateDto.FrameList)
                    {
                        // Resolve individual properties
                        string file = ResolveValue(s => !string.IsNullOrWhiteSpace(s),
                            frameDto.File, stateDto.File, compDto.File, dto.File);

                        string folder = ResolveValue(s => !string.IsNullOrWhiteSpace(s),
                            frameDto.Folder, stateDto.Folder, compDto.Folder, dto.Folder);

                        var frame = new AnimationFrame(assetFolder, folder, file)
                        {
                            Layer = ResolveValue(s => !string.IsNullOrWhiteSpace(s),
                                frameDto.Layer, stateDto.Layer, compDto.Layer, dto.Layer),

                            Width = ResolveValue(v => v != 0,
                                frameDto.Width, stateDto.Width, compDto.Width, dto.Width),

                            Height = ResolveValue(v => v != 0,
                                frameDto.Height, stateDto.Height, compDto.Height, dto.Height),

                            OffsetX = ResolveValue(v => true,
                                frameDto.OffsetX, stateDto.OffsetX, compDto.OffsetX, dto.OffsetX),

                            OffsetY = ResolveValue(v => true,
                                frameDto.OffsetY, stateDto.OffsetY, compDto.OffsetY, dto.OffsetY),

                            SpriteOffsetX = ResolveValue(v => true,
                                frameDto.SpriteOffsetX, stateDto.SpriteOffsetX, compDto.SpriteOffsetX, dto.SpriteOffsetX),

                            SpriteOffsetY = ResolveValue(v => true,
                                frameDto.SpriteOffsetY, stateDto.SpriteOffsetY, compDto.SpriteOffsetY, dto.SpriteOffsetY)
                        };
                        frameList.Add(frame);
                    }
                    var state = new AnimationState
                    {
                        Name = stateName,
                        Frames = [.. frameList]
                    };
                    component.States.Add(stateName, state);
                }
                animation.Components.Add(component.Name, component);
            }
            return animation;
        }

        /// <summary>
        /// Returns the first value that satisfies the isValid predicate. If none, returns default(T).
        /// </summary>
        /// <typeparam name="T">Type of the value.</typeparam>
        /// <param name="isValid">Predicate to test if a value is valid.</param>
        /// <param name="values">Values to test in order.</param>
        /// <returns>First valid value, or default(T) if none found.</returns>
        private static T ResolveValue<T>(Func<T, bool> isValid, params T[] values)
        {
            foreach (var v in values)
            {
                if (isValid(v))
                    return v;
            }
            return default!;
        }
    }
}
