#nullable enable
using System;
using System.Collections.Generic;
using MoonSharp.Interpreter;
using AxiomPlayground.Scripting;
using AxiomPlayground.Modding;

namespace in254.Engine;

public sealed class SceneManager
{
    private static readonly SceneManager _instance = new();
    public static SceneManager Instance => _instance;

    // Flat scenes: modId → (sceneName → SceneDefinition)
    private readonly Dictionary<string, Dictionary<string, SceneDefinition>> _scenes = new(StringComparer.OrdinalIgnoreCase);
    // modId → active scene name (null = no scene active)
    private readonly Dictionary<string, string?> _activeScenes = new(StringComparer.OrdinalIgnoreCase);

    // Tree scenes: modId → (sceneName → NodeDefinition root)
    private readonly Dictionary<string, Dictionary<string, NodeDefinition>> _treeScenes = new(StringComparer.OrdinalIgnoreCase);

    // Per-frame input blocking flag (set during FireSceneUpdates)
    private bool _inputBlocked;
    public bool IsInputBlocked => _inputBlocked;

    // Scene resource tracking: modId → list of resources acquired during the active scene
    private readonly Dictionary<string, List<ResourceRef>> _sceneResources = new(StringComparer.OrdinalIgnoreCase);

    public enum ResourceType { Sound, Texture, Font }
    public readonly record struct ResourceRef(ResourceType Type, string Key, int TextureId = 0);

    private SceneManager() { }

    /// <summary>
    /// Track a resource acquired during the current scene. Only records if a scene is active.
    /// </summary>
    public void TrackResource(string modId, ResourceType type, string key, int textureId = 0)
    {
        if (!_activeScenes.TryGetValue(modId, out var scene) || scene == null)
            return; // no active scene, skip tracking (e.g. data-init phase)

        if (!_sceneResources.TryGetValue(modId, out var resources))
        {
            resources = [];
            _sceneResources[modId] = resources;
        }

        resources.Add(new ResourceRef(type, key, textureId));
    }

    /// <summary>
    /// Release all resources tracked for the current scene of a mod.
    /// </summary>
    private void ReleaseSceneResources(string modId)
    {
        if (!_sceneResources.TryGetValue(modId, out var resources))
            return;

        foreach (var r in resources)
        {
            switch (r.Type)
            {
                case ResourceType.Sound:
                    SoundManager.Instance.Release(modId, r.Key);
                    break;
                case ResourceType.Texture:
                    TextureManager.Instance.Release(modId, r.TextureId);
                    break;
                case ResourceType.Font:
                    FontManager.Instance.Release(r.Key);
                    break;
            }
        }

        resources.Clear();
    }

    // ========== Flat Scene API ==========

    public void RegisterScene(string modId, string sceneName, SceneDefinition definition)
    {
        if (!_scenes.TryGetValue(modId, out var modScenes))
        {
            modScenes = new Dictionary<string, SceneDefinition>(StringComparer.OrdinalIgnoreCase);
            _scenes[modId] = modScenes;
        }
        modScenes[sceneName] = definition;
        Console.WriteLine($"[SceneManager] Registered scene '{sceneName}' for mod '{modId}'.");
    }

    // ========== Tree Scene API ==========

    public void RegisterTreeScene(string modId, string sceneName, NodeDefinition root)
    {
        if (!_treeScenes.TryGetValue(modId, out var modTrees))
        {
            modTrees = new Dictionary<string, NodeDefinition>(StringComparer.OrdinalIgnoreCase);
            _treeScenes[modId] = modTrees;
        }
        modTrees[sceneName] = root;
        Console.WriteLine($"[SceneManager] Registered tree scene '{sceneName}' for mod '{modId}'.");
    }

    public NodeDefinition? GetTreeRoot(string modId, string sceneName)
    {
        if (_treeScenes.TryGetValue(modId, out var modTrees) &&
            modTrees.TryGetValue(sceneName, out var root))
            return root;
        return null;
    }

    /// <summary>Search all tree scenes for a mod to find a node by name.</summary>
    public NodeDefinition? FindNode(string modId, string name)
    {
        if (!_treeScenes.TryGetValue(modId, out var modTrees)) return null;
        foreach (var kvp in modTrees)
        {
            var root = kvp.Value;
            if (string.Equals(root.Name, name, StringComparison.OrdinalIgnoreCase))
                return root;
            var found = root.Find(name);
            if (found != null) return found;
        }
        return null;
    }

    // ========== Switch Scene (dual registry) ==========

    public void SwitchScene(string modId, string? sceneName)
    {
        // Exit current scene if any
        if (_activeScenes.TryGetValue(modId, out var currentScene) && currentScene != null)
        {
            // Try tree scene first
            if (_treeScenes.TryGetValue(modId, out var modTrees) &&
                modTrees.TryGetValue(currentScene, out var oldRoot))
            {
                oldRoot.Exit();
            }
            else if (_scenes.TryGetValue(modId, out var modScenes) &&
                modScenes.TryGetValue(currentScene, out var oldDef))
            {
                if (oldDef.OnExit != null)
                    ScriptManager.Instance.CallWithModContext(modId, oldDef.OnExit);
            }

            // Release all resources tracked for this scene (ref-counted)
            ReleaseSceneResources(modId);
        }

        // Enter new scene (or clear if null)
        if (sceneName != null)
        {
            bool isTree = _treeScenes.TryGetValue(modId, out var modTrees2) &&
                          modTrees2.ContainsKey(sceneName);
            bool isFlat = _scenes.TryGetValue(modId, out var modScenes2) &&
                          modScenes2.ContainsKey(sceneName);

            if (!isTree && !isFlat)
            {
                Console.WriteLine($"[SceneManager] Scene '{sceneName}' not found for mod '{modId}'.");
                _activeScenes[modId] = null;
                return;
            }

            _activeScenes[modId] = sceneName;

            if (isTree)
                modTrees2![sceneName].Enter();
            else if (modScenes2![sceneName].OnEnter != null)
                ScriptManager.Instance.CallWithModContext(modId, modScenes2[sceneName].OnEnter!);

            Console.WriteLine($"[SceneManager] Mod '{modId}' switched to scene '{sceneName}'.");
        }
        else
        {
            _activeScenes[modId] = null;
            Console.WriteLine($"[SceneManager] Mod '{modId}' exited scene.");
        }
    }

    public string? GetActiveScene(string modId)
    {
        return _activeScenes.TryGetValue(modId, out var scene) ? scene : null;
    }

    public bool HasScene(string modId, string sceneName)
    {
        return (_scenes.TryGetValue(modId, out var modScenes) && modScenes.ContainsKey(sceneName)) ||
               (_treeScenes.TryGetValue(modId, out var modTrees) && modTrees.ContainsKey(sceneName));
    }

    // ========== Frame Dispatch ==========

    public void FireSceneUpdates(params DynValue[] args)
    {
        _inputBlocked = false;

        foreach (var kvp in _activeScenes)
        {
            string modId = kvp.Key;
            if (ModErrorTracker.Instance.IsModErrored(modId)) continue;

            string? sceneName = kvp.Value;
            if (sceneName == null) continue;

            try
            {
                // Tree scene?
                if (_treeScenes.TryGetValue(modId, out var modTrees) &&
                    modTrees.TryGetValue(sceneName, out var root))
                {
                    if (root.HasBlockingNode())
                        _inputBlocked = true;

                    root.Update(args.Length > 0 ? args[0] : DynValue.Nil,
                                args.Length > 1 ? args[1] : DynValue.Nil);
                    continue;
                }

                // Flat scene
                if (_scenes.TryGetValue(modId, out var modScenes) &&
                    modScenes.TryGetValue(sceneName, out var def) &&
                    def.OnUpdate != null)
                {
                    ScriptManager.Instance.CallWithModContext(modId, def.OnUpdate, args);
                }
            }
            catch (Exception ex)
            {
                ModErrorTracker.Instance.MarkModErrored(modId, ex.Message, $"scene update '{sceneName}'");
            }
        }
    }

    public void FireSceneDraws()
    {
        foreach (var kvp in _activeScenes)
        {
            string modId = kvp.Key;
            if (ModErrorTracker.Instance.IsModErrored(modId)) continue;

            string? sceneName = kvp.Value;
            if (sceneName == null) continue;

            try
            {
                // Tree scene?
                if (_treeScenes.TryGetValue(modId, out var modTrees) &&
                    modTrees.TryGetValue(sceneName, out var root))
                {
                    root.Draw();
                    continue;
                }

                // Flat scene
                if (_scenes.TryGetValue(modId, out var modScenes) &&
                    modScenes.TryGetValue(sceneName, out var def) &&
                    def.OnDraw != null)
                {
                    ScriptManager.Instance.CallWithModContext(modId, def.OnDraw);
                }
            }
            catch (Exception ex)
            {
                ModErrorTracker.Instance.MarkModErrored(modId, ex.Message, $"scene draw '{sceneName}'");
            }
        }
    }

    // ========== Nested Types ==========

    /// <summary>Tree node with lifecycle propagation, input blocking, and sound tag cleanup.</summary>
    public sealed class NodeDefinition
    {
        public string Name { get; set; } = "unnamed";
        public string ModId { get; set; } = "";
        public bool Active { get; set; } = true;
        public bool Live { get; private set; }
        public bool BlocksInput { get; set; }

        // Lua closures for lifecycle
        public Closure? OnEnter { get; set; }
        public Closure? OnExit { get; set; }
        public Closure? OnUpdate { get; set; }
        public Closure? OnDraw { get; set; }

        // Shared state (Lua table reference)
        public DynValue? Shared { get; set; }

        // Sound tags for auto-cleanup on exit
        public List<string> SoundTags { get; } = [];

        // Tree structure
        public NodeDefinition? Parent { get; private set; }
        private readonly List<NodeDefinition> _children = [];
        private readonly Dictionary<string, NodeDefinition> _childMap = new(StringComparer.OrdinalIgnoreCase);

        public IReadOnlyList<NodeDefinition> Children => _children;

        // ---- Tree Operations ----

        public void AddChild(NodeDefinition child)
        {
            if (_childMap.ContainsKey(child.Name)) return;
            child.Parent = this;
            _children.Add(child);
            _childMap[child.Name] = child;
            if (Live && child.Active)
                child.Enter();
        }

        public void RemoveChild(string name)
        {
            if (!_childMap.TryGetValue(name, out var child)) return;
            if (child.Live) child.Exit();
            child.Parent = null;
            _childMap.Remove(name);
            for (int i = _children.Count - 1; i >= 0; i--)
            {
                if (_children[i] == child)
                {
                    _children.RemoveAt(i);
                    break;
                }
            }
        }

        public NodeDefinition? GetChild(string name)
        {
            return _childMap.TryGetValue(name, out var child) ? child : null;
        }

        public NodeDefinition? Find(string name)
        {
            if (_childMap.TryGetValue(name, out var child)) return child;
            foreach (var c in _children)
            {
                var found = c.Find(name);
                if (found != null) return found;
            }
            return null;
        }

        public void SetActive(bool active)
        {
            if (Active == active) return;
            Active = active;
            if (Parent is { Live: true })
            {
                if (active) Enter();
                else Exit();
            }
        }

        // ---- Shared State Walk ----

        public DynValue? GetShared()
        {
            if (Shared != null && Shared.Type != DataType.Nil) return Shared;
            return Parent?.GetShared();
        }

        // ---- Lifecycle ----

        public void Enter()
        {
            if (Live) return;
            Live = true;
            if (OnEnter != null)
            {
                var sh = GetShared() ?? DynValue.Nil;
                ScriptManager.Instance.CallWithModContext(ModId, OnEnter, sh);
            }
            foreach (var child in _children)
            {
                if (child.Active) child.Enter();
            }
        }

        public void Exit()
        {
            if (!Live) return;
            for (int i = _children.Count - 1; i >= 0; i--)
            {
                if (_children[i].Live) _children[i].Exit();
            }
            if (OnExit != null)
            {
                var sh = GetShared() ?? DynValue.Nil;
                ScriptManager.Instance.CallWithModContext(ModId, OnExit, sh);
            }
            foreach (var tag in SoundTags)
            {
                SoundManager.Instance.Release(ModId, tag);
            }
            SoundTags.Clear();
            Live = false;
        }

        public void Update(DynValue dt, DynValue totalTime)
        {
            if (!Live || !Active) return;
            if (OnUpdate != null)
            {
                var sh = GetShared() ?? DynValue.Nil;
                ScriptManager.Instance.CallWithModContext(ModId, OnUpdate, dt, totalTime, sh);
            }
            foreach (var child in _children)
            {
                if (child.Active && child.Live) child.Update(dt, totalTime);
            }
        }

        public bool Draw()
        {
            if (!Live || !Active) return false;
            bool blocked = BlocksInput;
            if (OnDraw != null)
            {
                var sh = GetShared() ?? DynValue.Nil;
                ScriptManager.Instance.CallWithModContext(ModId, OnDraw, sh);
            }
            foreach (var child in _children)
            {
                if (child.Active && child.Live)
                {
                    if (child.Draw()) blocked = true;
                }
            }
            return blocked;
        }

        public bool HasBlockingNode()
        {
            if (!Live || !Active) return false;
            if (BlocksInput) return true;
            foreach (var child in _children)
            {
                if (child.HasBlockingNode()) return true;
            }
            return false;
        }
    }
}

public class SceneDefinition
{
    public Closure? OnEnter { get; set; }
    public Closure? OnExit { get; set; }
    public Closure? OnUpdate { get; set; }
    public Closure? OnDraw { get; set; }
}
