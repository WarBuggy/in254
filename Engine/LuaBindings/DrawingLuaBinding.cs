using System;
using MoonSharp.Interpreter;
using Microsoft.Xna.Framework;
using AxiomPlayground.Scripting.LuaBindings;
using AxiomPlayground.Scripting;

namespace in254.Engine.LuaBindings
{
    public sealed class DrawLuaBinding : LuaBindingBase
    {
        public override void Register(Script luaScript)
        {
            ArgumentNullException.ThrowIfNull(luaScript);

            // Draw namespace table
            Table drawTable = new(luaScript);

            // AddRequest(textureId, position, rotation=0, scale={1,1}, color=nil, layerDepth=0, width=0, height=0, spriteOffsetX=0, spriteOffsetY=0)
            drawTable["AddRequest"] = (Action<DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue>)((
                textureIdDyn, positionDyn, rotationDyn, scaleDyn, colorDyn, layerDepthDyn, widthDyn, heightDyn, spriteOffXDyn, spriteOffYDyn, flipXDyn, flipYDyn) =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId; // default to current mod
                AddRequestInternal(modId, textureIdDyn, positionDyn,
                    rotationDyn, scaleDyn, colorDyn, layerDepthDyn,
                    widthDyn, heightDyn, spriteOffXDyn, spriteOffYDyn, flipXDyn, flipYDyn);
            });

            // AddRequestFrom(modId, textureId, ...)
            // drawTable["AddRequestFrom"] = (Action<string, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue>)((
            //     modId, textureIdDyn, positionDyn, rotationDyn, scaleDyn, colorDyn, layerDepthDyn, widthDyn, heightDyn, spriteOffXDyn, spriteOffYDyn) =>
            // {
            //     AddRequestInternal(modId, textureIdDyn, positionDyn,
            //         rotationDyn, scaleDyn, colorDyn, layerDepthDyn,
            //         widthDyn, heightDyn, spriteOffXDyn, spriteOffYDyn);
            // });

            // Register globally
            luaScript.Globals["Drawing"] = drawTable;
        }

        private static void AddRequestInternal
        (
            string modId, DynValue textureIdDyn, DynValue positionDyn, DynValue rotationDyn,
            DynValue scaleDyn, DynValue colorDyn, DynValue layerDepthDyn,
            DynValue widthDyn, DynValue heightDyn, DynValue spriteOffXDyn, DynValue spriteOffYDyn,
            DynValue flipXDyn, DynValue flipYDyn
        )
        {
            if (textureIdDyn.IsNilOrNan())
                throw new ScriptRuntimeException("[DrawLuaBinding] AddRequest expects textureId (number) as first argument.");
            int textureId = (int)textureIdDyn.Number;
            var texture = TextureManager.Instance.GetTexture(modId, textureId);

            Vector2 position = positionDyn.Type == DataType.Table
                ? new Vector2((float)positionDyn.Table.Get(1).Number, (float)positionDyn.Table.Get(2).Number)
                : Vector2.Zero;
            float rotation = (float)(rotationDyn.IsNil() ? 0f : rotationDyn.Number);
            Vector2 scale = scaleDyn.Type == DataType.Table
                ? new Vector2((float)scaleDyn.Table.Get(1).Number, (float)scaleDyn.Table.Get(2).Number)
                : Vector2.One;
            Color? color = colorDyn.IsNil() ? null : (Color?)colorDyn.ToObject();
            float layerDepth = (float)(layerDepthDyn.IsNil() ? 0f : layerDepthDyn.Number);
            int width = (int)(widthDyn.IsNil() ? 0 : widthDyn.Number);
            int height = (int)(heightDyn.IsNil() ? 0 : heightDyn.Number);
            int spriteOffsetX = (int)(spriteOffXDyn.IsNil() ? 0 : spriteOffXDyn.Number);
            int spriteOffsetY = (int)(spriteOffYDyn.IsNil() ? 0 : spriteOffYDyn.Number);

            bool flipX = flipXDyn.IsNil() ? false : flipXDyn.Boolean;
            bool flipY = flipYDyn.IsNil() ? false : flipYDyn.Boolean;

            // Call engine
            DrawManager.Instance.AddRequest(
                texture,
                position,
                rotation,
                scale,
                color,
                layerDepth,
                width,
                height,
                spriteOffsetX,
                spriteOffsetY,
                flipX,
                flipY
            );
        }
    }
}
