// using System;
// using System.Collections.Generic;
// using in254.Core;
// using in254.Data;
// using Microsoft.Xna.Framework;

// namespace in254.Engine;

// /// <summary>
// /// Game object with animation support.
// /// Holds runtime state and baked animation frames.
// /// </summary>
// public class GameObjectWithAnimation : GameObject
// {
//     // Reference to the original animation DTO (optional)
//     public AnimationData AnimationData { get; }

//     // Runtime components keyed by component name
//     public Dictionary<string, RuntimeAnimationComponent> Components { get; } = new();

//     // Base component for offset calculations
//     public RuntimeAnimationComponent BaseComponent => Components[AnimationData.BaseComponent];

//     // Global flip applied to all components
//     public bool GlobalFlip { get; set; } = false;

//     public GameObjectWithAnimation(AnimationData animationData, Vector2 position) : base(position)
//     {
//         AnimationData = animationData ?? throw new ArgumentNullException(nameof(animationData));

//         // Bake all components and states
//         foreach (var compDto in AnimationData.ComponentList)
//         {
//             var runtimeComp = new RuntimeAnimationComponent
//             {
//                 Name = compDto.Name,
//                 DefaultState = compDto.Default
//             };

//             // Bake all states
//             foreach (var kvp in compDto.AnimationList)
//             {
//                 string stateName = kvp.Key;
//                 var stateDto = kvp.Value;

//                 var resolved = new ResolvedAnimationState
//                 {
//                     Name = stateName,
//                     Frames = new List<string>(stateDto.FrameList), // could later be Texture2D[]
//                     OffsetX = compDto.OffsetX + stateDto.OffsetX,
//                     OffsetY = compDto.OffsetY + stateDto.OffsetY,
//                     Width = compDto.Width,
//                     Height = compDto.Height,
//                     Layer = string.IsNullOrEmpty(stateDto.Layer) ? compDto.Layer : stateDto.Layer
//                 };

//                 runtimeComp.States[stateName] = resolved;
//             }

//             runtimeComp.CurrentState = runtimeComp.DefaultState;
//             Components[compDto.Name] = runtimeComp;
//         }
//     }

//     /// <summary>
//     /// Update animation frames based on elapsed time
//     /// </summary>
//     public void Update(GameTime gameTime, float frameDuration = 0.1f)
//     {
//         float deltaTime = (float)gameTime.ElapsedGameTime.TotalSeconds;

//         foreach (var comp in Components.Values)
//         {
//             var state = comp.CurrentResolvedState;
//             if (state.Frames.Count <= 1) continue;

//             comp.TimeSinceLastFrame += deltaTime;

//             if (comp.TimeSinceLastFrame >= frameDuration)
//             {
//                 comp.CurrentFrameIndex = (comp.CurrentFrameIndex + 1) % state.Frames.Count;
//                 comp.TimeSinceLastFrame = 0f;
//             }
//         }
//     }

//     /// <summary>
//     /// Get the current frame for a component (filename or Texture2D)
//     /// </summary>
//     public string GetCurrentFrame(string componentName)
//     {
//         if (!Components.TryGetValue(componentName, out var comp))
//             throw new ArgumentException($"Component '{componentName}' not found");

//         var state = comp.CurrentResolvedState;
//         return state.Frames[comp.CurrentFrameIndex];
//     }

//     /// <summary>
//     /// Change component state
//     /// </summary>
//     public void SetState(string componentName, string stateName, bool resetFrameIndex = true)
//     {
//         if (!Components.TryGetValue(componentName, out var comp))
//             throw new ArgumentException($"Component '{componentName}' not found");

//         if (!comp.States.ContainsKey(stateName))
//             throw new ArgumentException($"State '{stateName}' not found in component '{componentName}'");

//         if (comp.CurrentState == stateName) return;

//         comp.CurrentState = stateName;
//         if (resetFrameIndex)
//         {
//             comp.CurrentFrameIndex = 0;
//             comp.TimeSinceLastFrame = 0f;
//         }
//     }

//     /// <summary>
//     /// Get final draw position of a component relative to the base component
//     /// </summary>
//     public Vector2 GetComponentDrawPosition(string componentName)
//     {
//         if (!Components.TryGetValue(componentName, out var comp))
//             throw new ArgumentException($"Component '{componentName}' not found");

//         var state = comp.CurrentResolvedState;
//         float x = Position.X + state.OffsetX - BaseComponent.CurrentResolvedState.OffsetX;
//         float y = Position.Y + state.OffsetY - BaseComponent.CurrentResolvedState.OffsetY;
//         return new Vector2(x, y);
//     }

//     /// <summary>
//     /// Nested runtime class for per-component state
//     /// </summary>
//     public sealed class RuntimeAnimationComponent
//     {
//         public string Name { get; init; } = string.Empty;
//         public string DefaultState { get; init; } = string.Empty;

//         public Dictionary<string, ResolvedAnimationState> States { get; init; } = new();
//         public string CurrentState { get; set; } = string.Empty;
//         public int CurrentFrameIndex { get; set; } = 0;
//         public float TimeSinceLastFrame { get; set; } = 0f;
//         public bool IsFlipped { get; set; } = false;

//         public ResolvedAnimationState CurrentResolvedState => States[CurrentState];
//     }
// }
