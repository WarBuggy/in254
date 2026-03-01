-- ============================================
-- Terraria2D — UI Framework
-- Rectangle drawing, buttons, progress bars
-- All rects batched via UI.Flush() — 1 C# crossing per layer
-- ============================================

local modId = "Terraria2D"

local UI = {}

local pixelId = nil
local _ps = nil -- registered pixel sprite for batch
local mouseX, mouseY = 0, 0
local mouseDown = false
local mousePressed = false
local mouseReleased = false
local rightDown = false
local rightPressed = false
local rightReleased = false
local tooltipText = nil
local screenW = 0

-- (rect buffer removed — UI.Rect now calls Drawing.Rect directly)

-- Cached default colors
local _cBtnBase     = Color.New(60, 60, 80, 220)
local _cBtnHover    = Color.New(80, 80, 110, 230)
local _cBtnActive   = Color.New(50, 50, 70, 240)
local _cBtnText     = Color.New(255, 255, 255)
local _cBtnDisBg    = Color.New(40, 40, 50, 180)
local _cBtnDisText  = Color.New(100, 100, 100)
local _cBarBg       = Color.New(30, 30, 40, 200)
local _cBarFg       = Color.New(80, 200, 80)
local _cTipBg       = Color.New(20, 20, 30, 230)
local _cTipText     = Color.New(220, 220, 220)

function UI.ResolvePixel()
    if pixelId then return true end
    pixelId = Animation.FrameTextureIdFrom(modId, "scrPixel", "base", "idle", 1)
    if not pixelId then return false end
    _ps = Drawing.RegisterPixelSprite(pixelId)
    return true
end

function UI.GetPixelId()
    return pixelId
end

function UI.UpdateInput()
    if Scene.IsInputBlocked and Scene.IsInputBlocked() then
        mouseX, mouseY = -9999, -9999
        mouseDown, mousePressed, mouseReleased = false, false, false
        rightDown, rightPressed, rightReleased = false, false, false
        tooltipText = nil
        return
    end
    -- These are now pure Lua reads via input.lua (zero C# crossings)
    mouseX = Input.MouseX()
    mouseY = Input.MouseY()
    mouseDown = Input.IsMouseDown("left")
    mousePressed = Input.IsMousePressed("left")
    mouseReleased = Input.IsMouseReleased("left")
    rightDown = Input.IsMouseDown("right")
    rightPressed = Input.IsMousePressed("right")
    rightReleased = Input.IsMouseReleased("right")
    screenW = Screen.Width()
    tooltipText = nil
end

function UI.MouseX() return mouseX end
function UI.MouseY() return mouseY end
function UI.IsMouseDown() return mouseDown end
function UI.IsMousePressed() return mousePressed end
function UI.IsMouseReleased() return mouseReleased end
function UI.IsRightDown() return rightDown end
function UI.IsRightPressed() return rightPressed end
function UI.IsRightReleased() return rightReleased end

-- Direct auto-batched rect — goes straight to DrawManager pool (strongly-typed, no DynValue boxing)
function UI.Rect(x, y, w, h, color)
    if not _ps then return end
    Drawing.Rect(_ps, x, y, w, h, color or 0)
end

-- Accumulate line into line batch buffer (stride-7: x1,y1,x2,y2,thickness,color,flags)
local _lbuf = {}
local _ln = 0

function UI.Line(x1, y1, x2, y2, thickness, color)
    if not _ps then return end
    _lbuf[_ln+1]=x1; _lbuf[_ln+2]=y1; _lbuf[_ln+3]=x2; _lbuf[_ln+4]=y2
    _lbuf[_ln+5]=thickness or 1; _lbuf[_ln+6]=color or 0; _lbuf[_ln+7]=0
    _ln = _ln + 7
end

-- Flush accumulated lines to C# (rects are now auto-batched via Drawing.Rect)
function UI.Flush()
    if _ln > 0 then
        Drawing.FlushLines(_ps, _lbuf, _ln / 7)
        _ln = 0
    end
end

function UI.Panel(x, y, w, h, color)
    UI.Rect(x, y, w, h, color)
end

function UI.IsHovered(x, y, w, h)
    return mouseX >= x and mouseX < x + w and mouseY >= y and mouseY < y + h
end

function UI.IsClicked(x, y, w, h)
    return mouseReleased and UI.IsHovered(x, y, w, h)
end

function UI.Button(x, y, w, h, label, opts)
    opts = opts or {}
    local baseColor = opts.color or _cBtnBase
    local hoverColor = opts.hoverColor or _cBtnHover
    local activeColor = opts.activeColor or _cBtnActive
    local textColor = opts.textColor or _cBtnText
    local textSize = opts.textSize or 14
    local disabled = opts.disabled or false

    local hovered = UI.IsHovered(x, y, w, h)
    local clicked = false

    if disabled then
        UI.Rect(x, y, w, h, _cBtnDisBg)
        Drawing.Text(label, x + 8, y + math.floor((h - textSize) / 2), textSize, _cBtnDisText)
    else
        local bg = baseColor
        if hovered and mouseDown then
            bg = activeColor
        elseif hovered then
            bg = hoverColor
        end
        UI.Rect(x, y, w, h, bg)
        Drawing.Text(label, x + 8, y + math.floor((h - textSize) / 2), textSize, textColor)
        clicked = mouseReleased and hovered
    end

    return clicked
end

function UI.ProgressBar(x, y, w, h, value, max, fgColor, bgColor)
    bgColor = bgColor or _cBarBg
    fgColor = fgColor or _cBarFg
    UI.Rect(x, y, w, h, bgColor)
    local fill = math.max(0, math.min(value / max, 1))
    if fill > 0 then
        UI.Rect(x, y, math.floor(w * fill), h, fgColor)
    end
end

function UI.Tooltip(text)
    tooltipText = text
end

function UI.DrawTooltip()
    if not tooltipText then return end
    local tw = #tooltipText * 7 + 16
    local th = 24
    local tx = math.min(mouseX + 12, screenW - tw - 4)
    local ty = math.max(mouseY - th - 4, 4)
    UI.Rect(tx, ty, tw, th, _cTipBg)
    Drawing.Text(tooltipText, tx + 8, ty + 4, 14, _cTipText)
end

return UI
