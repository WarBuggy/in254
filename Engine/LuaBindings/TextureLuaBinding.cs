using MoonSharp.Interpreter;
using AxiomPlayground.Scripting.LuaBindings;
using System;
using in254.Core;

namespace in254.Engine.LuaBindings
{
    public sealed class TextureLuaBinding : LuaBindingBase
    {
        private readonly LoggerBaseCore _logger = new();
        public override void Register(Script luaScript)
        {
            ArgumentNullException.ThrowIfNull(luaScript);

            Table table = new(luaScript);

            table["TryRegister"] = (Func<string, string, DynValue, DynValue, DynValue>)((folder, file, sourceModIdDyn, modIdDyn) =>
            {
                if (!ResolveModId(modIdDyn, out var owningModId))
                {
                    _logger.LogError("system.textureLuaBinding.invalidInput", "modId");
                    return DynValue.NewTuple(DynValue.NewBoolean(false), DynValue.NewNumber(-1));
                }

                string sourceModId;
                if (sourceModIdDyn.Type == DataType.String && !string.IsNullOrEmpty(sourceModIdDyn.String))
                    sourceModId = sourceModIdDyn.String;
                else
                    sourceModId = owningModId;

                if (string.IsNullOrWhiteSpace(folder))
                {
                    _logger.LogError("system.textureLuaBinding.invalidInput", nameof(folder));
                    return DynValue.NewTuple(DynValue.NewBoolean(false), DynValue.NewNumber(-1));
                }

                if (string.IsNullOrWhiteSpace(file))
                {
                    _logger.LogError("system.textureLuaBinding.invalidInput", nameof(file));
                    return DynValue.NewTuple(DynValue.NewBoolean(false), DynValue.NewNumber(-1));
                }

                try
                {
                    int textureId = TextureManager.Instance.RegisterTexture(owningModId, sourceModId, folder, file);
                    return DynValue.NewTuple(DynValue.NewBoolean(true), DynValue.NewNumber(textureId));
                }
                catch (Exception ex)
                {
                    _logger.LogErrorWithEnding("", "system.textureLuaBinding.registerFailed", ex.Message);
                    return DynValue.NewTuple(DynValue.NewBoolean(false), DynValue.NewNumber(-1));
                }
            });

            luaScript.Globals["Texture"] = table;
        }
    }
}
