-- ============================================
-- Terraria2D — Sprite Batch Helper
-- Stride-7 command buffer for Drawing.SpriteBatch
-- ============================================

local Batch = {}
local STRIDE = 7

function Batch.new()  return { data = {}, count = 0 } end
function Batch.clear(b) b.count = 0 end

function Batch.add(b, spriteId, x, y, scaleX, scaleY, color, flags)
    local i = b.count * STRIDE; local d = b.data
    d[i+1]=spriteId; d[i+2]=x; d[i+3]=y
    d[i+4]=scaleX; d[i+5]=scaleY
    d[i+6]=color or 0; d[i+7]=flags or 0
    b.count = b.count + 1
end

function Batch.rect(b, pixelSpriteId, x, y, w, h, color)
    Batch.add(b, pixelSpriteId, x, y, w, h, color, 0)
end

-- Line batch (separate buffer, stride-7: x1,y1,x2,y2,thickness,color,flags)
function Batch.newLines() return { data = {}, count = 0 } end
function Batch.clearLines(b) b.count = 0 end

function Batch.line(b, pixelSpriteId, x1, y1, x2, y2, thickness, color)
    local i = b.count * 7; local d = b.data
    d[i+1]=x1; d[i+2]=y1; d[i+3]=x2; d[i+4]=y2
    d[i+5]=thickness or 1; d[i+6]=color or 0; d[i+7]=0
    b.count = b.count + 1
    b._ps = pixelSpriteId
end

function Batch.flushLines(b)
    if b.count > 0 and b._ps then Drawing.FlushLines(b._ps, b.data, b.count) end
end

function Batch.submitLines(b) Batch.flushLines(b); Batch.clearLines(b) end

function Batch.flush(b)
    if b.count > 0 then Drawing.SpriteBatch(b.data, b.count) end
end

function Batch.submit(b) Batch.flush(b); Batch.clear(b) end

return Batch
