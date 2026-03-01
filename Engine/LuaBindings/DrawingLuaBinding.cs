using System;
using MoonSharp.Interpreter;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
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
            drawTable["Sprite"] = (Action<DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue>)((
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

            // DrawTileMap — batch render a tile grid with lighting to a cached RenderTarget
            drawTable["TileMap"] = (Action<DynValue, DynValue, DynValue, DynValue, DynValue,
                DynValue, DynValue, DynValue, DynValue, DynValue,
                DynValue, DynValue, DynValue, DynValue>)(
                (tilesDyn, colorCacheDyn, camXDyn, camYDyn, tileSizeDyn,
                 worldWDyn, worldHDyn, screenWDyn, screenHDyn, maxLightDyn,
                 lightMapDyn, surfaceYDyn, pixelIdDyn, tileDataDyn) =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                DrawTileMapInternal(modId, tilesDyn, colorCacheDyn, camXDyn, camYDyn,
                    tileSizeDyn, worldWDyn, worldHDyn, screenWDyn, screenHDyn,
                    maxLightDyn, lightMapDyn, surfaceYDyn, pixelIdDyn, tileDataDyn);
            });

            // InvalidateTileCache — mark tile RenderTarget as dirty for next frame
            drawTable["RefreshTileMap"] = (Action)(() => DrawManager.Instance.InvalidateTileCache());

            // DrawRectBatch — batch queue colored rects from a flat table (stride 8: x,y,w,h,r,g,b,a)
            drawTable["RectBatch"] = (Action<DynValue, DynValue, DynValue>)(
                (pixelIdDyn, dataDyn, countDyn) =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                int pixelId = (int)pixelIdDyn.Number;
                var pixelTex = TextureManager.Instance.GetTexture(modId, pixelId);
                int count = (int)countDyn.Number;
                DrawManager.Instance.AddRectBatch(pixelTex, dataDyn.Table, count);
            });

            // Text(text, x, y, size?, {r,g,b,a}?, "fontName"?)
            drawTable["Text"] = (Action<string, DynValue, DynValue, DynValue, DynValue, DynValue>)(
                (text, xDyn, yDyn, sizeDyn, colorDyn, fontDyn) =>
            {
                float x = (float)(xDyn.IsNil() ? 0 : xDyn.Number);
                float y = (float)(yDyn.IsNil() ? 0 : yDyn.Number);
                int size = (int)(sizeDyn.IsNil() ? 16 : sizeDyn.Number);

                Color color = Color.White;
                if (colorDyn != null && colorDyn.Type == DataType.Table)
                {
                    var t = colorDyn.Table;
                    int r = (int)(t.Get(1).IsNil() ? 255 : t.Get(1).Number);
                    int g = (int)(t.Get(2).IsNil() ? 255 : t.Get(2).Number);
                    int b = (int)(t.Get(3).IsNil() ? 255 : t.Get(3).Number);
                    int a = (int)(t.Get(4).IsNil() ? 255 : t.Get(4).Number);
                    color = Color.FromNonPremultiplied(r, g, b, a);
                }

                string fontName = null;
                if (fontDyn != null && fontDyn.Type == DataType.String)
                    fontName = fontDyn.String;

                DrawManager.Instance.AddTextRequest(text, new Vector2(x, y), size, color, fontName);
            });

            // RegisterLayer(name, priority, opts?)
            drawTable["RegisterLayer"] = (Action<string, DynValue, DynValue>)((name, priorityDyn, optsDyn) =>
            {
                int priority = (int)priorityDyn.Number;
                BlendState blend = BlendState.AlphaBlend;
                SpriteSortMode sort = SpriteSortMode.Deferred;
                SamplerState sampler = SamplerState.PointClamp;
                if (optsDyn != null && optsDyn.Type == DataType.Table)
                {
                    var opts = optsDyn.Table;
                    blend = ParseBlendState(opts.Get("blend"));
                    sort = ParseSortMode(opts.Get("sort"));
                    sampler = ParseSamplerState(opts.Get("sampler"));
                }
                DrawManager.Instance.RegisterLayer(name, priority, blend, sort, sampler);
            });

            // SetLayer(name)
            drawTable["SetLayer"] = (Action<string>)(name => DrawManager.Instance.SetActiveLayer(name));

            // ResetLayer()
            drawTable["ResetLayer"] = (Action)(() => DrawManager.Instance.ResetActiveLayer());

            // Register globally
            luaScript.Globals["Drawing"] = drawTable;
        }

        private static BlendState ParseBlendState(DynValue dyn) =>
            dyn.IsNil() ? BlendState.AlphaBlend :
            dyn.String.ToLowerInvariant() switch
            {
                "additive" => BlendState.Additive,
                "opaque" => BlendState.Opaque,
                "nonpremultiplied" => BlendState.NonPremultiplied,
                _ => BlendState.AlphaBlend
            };

        private static SpriteSortMode ParseSortMode(DynValue dyn) =>
            dyn.IsNil() ? SpriteSortMode.Deferred :
            dyn.String.ToLowerInvariant() switch
            {
                "backtofront" => SpriteSortMode.BackToFront,
                "fronttoback" => SpriteSortMode.FrontToBack,
                "texture" => SpriteSortMode.Texture,
                "immediate" => SpriteSortMode.Immediate,
                _ => SpriteSortMode.Deferred
            };

        private static SamplerState ParseSamplerState(DynValue dyn) =>
            dyn.IsNil() ? SamplerState.PointClamp :
            dyn.String.ToLowerInvariant() switch
            {
                "linearclamp" => SamplerState.LinearClamp,
                "linearwrap" => SamplerState.LinearWrap,
                "pointwrap" => SamplerState.PointWrap,
                _ => SamplerState.PointClamp
            };

        private static void DrawTileMapInternal(
            string modId, DynValue tilesDyn, DynValue colorCacheDyn,
            DynValue camXDyn, DynValue camYDyn, DynValue tileSizeDyn,
            DynValue worldWDyn, DynValue worldHDyn, DynValue screenWDyn, DynValue screenHDyn,
            DynValue maxLightDyn, DynValue lightMapDyn, DynValue surfaceYDyn,
            DynValue pixelIdDyn, DynValue tileDataDyn)
        {
            int pixelId = (int)pixelIdDyn.Number;
            var pixelTex = TextureManager.Instance.GetTexture(modId, pixelId);

            // Store params for deferred RenderTarget rendering
            DrawManager.Instance.StoreTileMapParams(
                pixelTex,
                tilesDyn.Table,
                colorCacheDyn.IsNil() ? null : colorCacheDyn.Table,
                lightMapDyn.IsNil() ? null : lightMapDyn.Table,
                tileDataDyn.Table,
                (float)camXDyn.Number, (float)camYDyn.Number,
                (int)tileSizeDyn.Number,
                (int)worldWDyn.Number, (int)worldHDyn.Number,
                (int)screenWDyn.Number, (int)screenHDyn.Number,
                (int)maxLightDyn.Number, (int)surfaceYDyn.Number
            );
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
            Color? color = null;
            // There issue with computation sometimes which require to normalize it or it will render weird color, wink, wink
            if (colorDyn != null && colorDyn.Type == DataType.Table)
            {
                var t = colorDyn.Table;
                int r = (int)(t.Get(1).IsNil() ? 255 : t.Get(1).Number);
                int g = (int)(t.Get(2).IsNil() ? 255 : t.Get(2).Number);
                int b = (int)(t.Get(3).IsNil() ? 255 : t.Get(3).Number);
                int a = (int)(t.Get(4).IsNil() ? 255 : t.Get(4).Number);
                color = Color.FromNonPremultiplied(r, g, b, a);
            }
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
