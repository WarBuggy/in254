#nullable enable
using System;
using MoonSharp.Interpreter;
using AxiomPlayground.Scripting;
using AxiomPlayground.Scripting.LuaBindings;

namespace in254.Engine.LuaBindings;

public sealed class SceneLuaBinding : LuaBindingBase
{
    public override void Register(Script luaScript)
    {
        ArgumentNullException.ThrowIfNull(luaScript);

        Table sceneTable = new(luaScript);

        // ========== Existing Flat API (unchanged) ==========

        // Scene.Register(sceneName, { onEnter=fn, onExit=fn, onUpdate=fn, onDraw=fn })
        sceneTable["Register"] = (Action<string, Table>)((sceneName, options) =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            var definition = new SceneDefinition
            {
                OnEnter = options.Get("onEnter").Type == DataType.Function
                    ? options.Get("onEnter").Function : null,
                OnExit = options.Get("onExit").Type == DataType.Function
                    ? options.Get("onExit").Function : null,
                OnUpdate = options.Get("onUpdate").Type == DataType.Function
                    ? options.Get("onUpdate").Function : null,
                OnFixedUpdate = options.Get("onFixedUpdate").Type == DataType.Function
                    ? options.Get("onFixedUpdate").Function : null,
                OnDraw = options.Get("onDraw").Type == DataType.Function
                    ? options.Get("onDraw").Function : null,
            };
            SceneManager.Instance.RegisterScene(modId, sceneName, definition);
        });

        // Scene.Switch(sceneName)
        sceneTable["Switch"] = (Action<string>)(sceneName =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            SceneManager.Instance.SwitchScene(modId, sceneName);
        });

        // Scene.Exit()
        sceneTable["Exit"] = (Action)(() =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            SceneManager.Instance.SwitchScene(modId, null);
        });

        // Scene.Active() → string or nil
        sceneTable["Active"] = (Func<string?>)(() =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            return SceneManager.Instance.GetActiveScene(modId);
        });

        // Scene.Has(sceneName) → bool
        sceneTable["Has"] = (Func<string, bool>)(sceneName =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            return SceneManager.Instance.HasScene(modId, sceneName);
        });

        // ========== Tree Scene API ==========

        // Scene.RegisterTree(sceneName, opts) — register a root node as a tree scene
        sceneTable["RegisterTree"] = (Action<string, Table>)((sceneName, opts) =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            var root = CreateNodeFromTable(modId, opts);
            SceneManager.Instance.RegisterTreeScene(modId, sceneName, root);
        });

        // Scene.AddChild(parentName, childOpts) — create child node, add to parent
        sceneTable["AddChild"] = (Action<string, Table>)((parentName, childOpts) =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            var parent = SceneManager.Instance.FindNode(modId, parentName);
            if (parent == null)
            {
                Console.WriteLine($"[Scene.AddChild] Parent node '{parentName}' not found for mod '{modId}'.");
                return;
            }
            var child = CreateNodeFromTable(modId, childOpts);
            parent.AddChild(child);
        });

        // Scene.RemoveChild(parentName, childName) — exit + detach child
        sceneTable["RemoveChild"] = (Action<string, string>)((parentName, childName) =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            var parent = SceneManager.Instance.FindNode(modId, parentName);
            if (parent == null)
            {
                Console.WriteLine($"[Scene.RemoveChild] Parent node '{parentName}' not found for mod '{modId}'.");
                return;
            }
            parent.RemoveChild(childName);
        });

        // Scene.FindNode(name) → string? (returns name if found, nil if not)
        sceneTable["FindNode"] = (Func<string, string?>)(name =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            var node = SceneManager.Instance.FindNode(modId, name);
            return node?.Name;
        });

        // Scene.SetNodeActive(name, bool) — toggle node active state
        sceneTable["SetNodeActive"] = (Action<string, bool>)((name, active) =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            var node = SceneManager.Instance.FindNode(modId, name);
            if (node == null)
            {
                Console.WriteLine($"[Scene.SetNodeActive] Node '{name}' not found for mod '{modId}'.");
                return;
            }
            node.SetActive(active);
        });

        // Scene.SetNodeBlocksInput(name, bool) — toggle input blocking
        sceneTable["SetNodeBlocksInput"] = (Action<string, bool>)((name, blocksInput) =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            var node = SceneManager.Instance.FindNode(modId, name);
            if (node == null)
            {
                Console.WriteLine($"[Scene.SetNodeBlocksInput] Node '{name}' not found for mod '{modId}'.");
                return;
            }
            node.BlocksInput = blocksInput;
        });

        // Scene.IsInputBlocked() → bool
        sceneTable["IsInputBlocked"] = (Func<bool>)(() =>
        {
            return SceneManager.Instance.IsInputBlocked;
        });

        // Scene.TagSound(nodeName, soundName) — associate sound with node for auto-cleanup
        sceneTable["TagSound"] = (Action<string, string>)((nodeName, soundName) =>
        {
            string modId = ScriptManager.Instance.CurrentExecutingModId;
            var node = SceneManager.Instance.FindNode(modId, nodeName);
            if (node == null)
            {
                Console.WriteLine($"[Scene.TagSound] Node '{nodeName}' not found for mod '{modId}'.");
                return;
            }
            if (!node.SoundTags.Contains(soundName))
                node.SoundTags.Add(soundName);
        });

        luaScript.Globals["Scene"] = sceneTable;
    }

    /// <summary>Parse a Lua table into a SceneManager.NodeDefinition.</summary>
    private static SceneManager.NodeDefinition CreateNodeFromTable(string modId, Table opts)
    {
        var node = new SceneManager.NodeDefinition
        {
            ModId = modId,
            Name = opts.Get("name").Type == DataType.String
                ? opts.Get("name").String : "unnamed",
            Active = opts.Get("active").Type != DataType.Boolean || opts.Get("active").Boolean,
            BlocksInput = opts.Get("blocksInput").Type == DataType.Boolean && opts.Get("blocksInput").Boolean,
            OnEnter = opts.Get("onEnter").Type == DataType.Function
                ? opts.Get("onEnter").Function : null,
            OnExit = opts.Get("onExit").Type == DataType.Function
                ? opts.Get("onExit").Function : null,
            OnUpdate = opts.Get("onUpdate").Type == DataType.Function
                ? opts.Get("onUpdate").Function : null,
            OnDraw = opts.Get("onDraw").Type == DataType.Function
                ? opts.Get("onDraw").Function : null,
            OnFixedUpdate = opts.Get("onFixedUpdate").Type == DataType.Function
                ? opts.Get("onFixedUpdate").Function : null,
        };

        // Shared state (Lua table reference)
        var sharedVal = opts.Get("shared");
        if (sharedVal.Type == DataType.Table)
            node.Shared = sharedVal;

        return node;
    }
}
