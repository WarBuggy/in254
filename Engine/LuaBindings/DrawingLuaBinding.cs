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

            // SetTileMap — one-time tile config from a table
            drawTable["SetTileMap"] = (Action<DynValue>)((optsDyn) =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                var opts = optsDyn.Table;
                int pixelId = (int)opts.Get("pixelId").Number;
                var pixelTex = TextureManager.Instance.GetTexture(modId, pixelId);
                TileRendererManager.Instance.SetConfig(
                    pixelTex,
                    opts.Get("tiles").Table,
                    opts.Get("tileData").Table,
                    (int)opts.Get("tileSize").Number,
                    (int)opts.Get("worldW").Number,
                    (int)opts.Get("worldH").Number,
                    (int)opts.Get("maxLight").Number,
                    (int)opts.Get("surfaceY").Number
                );
                // Optional tile renderer config
                var marginDyn = opts.Get("tileMargin");
                var cooldownDyn = opts.Get("rebuildCooldown");
                if (!marginDyn.IsNil() || !cooldownDyn.IsNil())
                {
                    TileRendererManager.Instance.Configure(
                        marginDyn.IsNil() ? null : (int?)marginDyn.Number,
                        cooldownDyn.IsNil() ? null : (int?)cooldownDyn.Number
                    );
                }
            });

            // DrawTileMap — per-frame camera + lightMap (5 params)
            drawTable["DrawTileMap"] = (Action<DynValue, DynValue, DynValue, DynValue, DynValue>)(
                (camXDyn, camYDyn, screenWDyn, screenHDyn, lightMapDyn) =>
            {
                TileRendererManager.Instance.SetFrameParams(
                    (float)camXDyn.Number, (float)camYDyn.Number,
                    (int)screenWDyn.Number, (int)screenHDyn.Number,
                    lightMapDyn.IsNil() ? null : lightMapDyn.Table
                );
            });

            // InvalidateTileCache — mark tile RenderTarget as dirty for next frame
            drawTable["RefreshTileMap"] = (Action)(() => TileRendererManager.Instance.InvalidateTileCache());

            // InvalidateTileColors — lighter refresh (reuses cached tile IDs, only re-reads colors)
            drawTable["RefreshTileColors"] = (Action)(() => TileRendererManager.Instance.InvalidateTileColors());

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

            // RegisterSprite(textureId, srcX, srcY, srcW, srcH) → spriteId
            drawTable["RegisterSprite"] = (Func<DynValue, int, int, int, int, int>)(
                (textureIdDyn, srcX, srcY, srcW, srcH) =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                int textureId = (int)textureIdDyn.Number;
                var texture = TextureManager.Instance.GetTexture(modId, textureId);
                return DrawManager.Instance.RegisterSprite(texture, srcX, srcY, srcW, srcH);
            });

            // RegisterPixelSprite(textureId) → spriteId
            drawTable["RegisterPixelSprite"] = (Func<DynValue, int>)((textureIdDyn) =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                int textureId = (int)textureIdDyn.Number;
                var texture = TextureManager.Instance.GetTexture(modId, textureId);
                return DrawManager.Instance.RegisterPixelSprite(texture);
            });

            // SpriteBatch(flatTable, count) — stride-7 command buffer
            drawTable["SpriteBatch"] = (Action<DynValue, DynValue>)((dataDyn, countDyn) =>
            {
                int count = (int)countDyn.Number;
                DrawManager.Instance.AddSpriteBatch(dataDyn.Table, count);
            });

            // Rect(spriteId, x, y, w, h, packedColor) — single rect, auto-batched in pool
            drawTable["Rect"] = (Action<int, float, float, float, float, int>)(
                (spriteId, x, y, w, h, packedColor) =>
                    DrawManager.Instance.AddRect(spriteId, x, y, w, h, packedColor));

            // Line(spriteId, x1, y1, x2, y2, thickness, packedColor) — single line, auto-batched
            drawTable["Line"] = (Action<int, float, float, float, float, float, int>)(
                (spriteId, x1, y1, x2, y2, thickness, packedColor) =>
                    DrawManager.Instance.AddLine(spriteId, x1, y1, x2, y2, thickness, packedColor));

            // FlushLines(spriteId, flatTable, count) — stride-7 batch (x1,y1,x2,y2,thickness,color,flags)
            drawTable["FlushLines"] = (Action<int, DynValue, int>)(
                (spriteId, dataDyn, count) =>
                    DrawManager.Instance.AddLineBatch(spriteId, dataDyn.Table, count));

            // FlushRects(spriteId, flatTable, count) — stride-5 batch (x,y,w,h,packedColor)
            // Single spriteId resolved once for all rects. Core batch path for UI.
            drawTable["FlushRects"] = (Action<int, DynValue, int>)(
                (spriteId, dataDyn, count) =>
                    DrawManager.Instance.AddRectBatchPacked(spriteId, dataDyn.Table, count));

            // ConfigureTileMap({ tileMargin = N, rebuildCooldown = N })
            drawTable["ConfigureTileMap"] = (Action<DynValue>)((optsDyn) =>
            {
                var opts = optsDyn.Table;
                int? tileMargin = null;
                int? rebuildCooldown = null;
                var marginDyn = opts.Get("tileMargin");
                if (!marginDyn.IsNil()) tileMargin = (int)marginDyn.Number;
                var cooldownDyn = opts.Get("rebuildCooldown");
                if (!cooldownDyn.IsNil()) rebuildCooldown = (int)cooldownDyn.Number;
                TileRendererManager.Instance.Configure(tileMargin, rebuildCooldown);
            });

            // Text(text, x, y, size?, {r,g,b,a}?, "fontName"?)
            drawTable["Text"] = (Action<string, DynValue, DynValue, DynValue, DynValue, DynValue>)(
                (text, xDyn, yDyn, sizeDyn, colorDyn, fontDyn) =>
            {
                float x = (float)(xDyn.IsNil() ? 0 : xDyn.Number);
                float y = (float)(yDyn.IsNil() ? 0 : yDyn.Number);
                int size = (int)(sizeDyn.IsNil() ? 16 : sizeDyn.Number);

                Color color = Color.White;
                if (colorDyn != null && colorDyn.Type == DataType.Number)
                {
                    color = ColorLuaBinding.ToColor((int)colorDyn.Number);
                }
                else if (colorDyn != null && colorDyn.Type == DataType.Table)
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

            // FlushText(flatTable, count) — stride-5 batch (text,x,y,size,packedColor)
            drawTable["FlushText"] = (Action<DynValue, int>)(
                (dataDyn, count) =>
                    DrawManager.Instance.AddTextBatch(dataDyn.Table, count));

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
