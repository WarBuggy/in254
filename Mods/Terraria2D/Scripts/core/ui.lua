-- ============================================
-- Terraria2D — UI Framework
-- Rectangle drawing, buttons, progress bars
-- ============================================

local modId = "Terraria2D"

local UI = {}

local pixelId = nil
local mouseX, mouseY = 0, 0
local mouseDown = false
local mousePressed = false
local mouseReleased = false
local rightDown = false
local rightPressed = false
local rightReleased = false
local tooltipText = nil

function UI.ResolvePixel()
    if pixelId then return true end
    pixelId = Animation.FrameTextureIdFrom(modId, "scrPixel", "base", "idle", 1)
    return pixelId ~= nil
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
    mouseX = Input.MouseX()
    mouseY = Input.MouseY()
    mouseDown = Input.IsMouseDown("left")
    mousePressed = Input.IsMousePressed("left")
    mouseReleased = Input.IsMouseReleased("left")
    rightDown = Input.IsMouseDown("right")
    rightPressed = Input.IsMousePressed("right")
    rightReleased = Input.IsMouseReleased("right")
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

function UI.Rect(x, y, w, h, color)
    if not pixelId then return end
    Drawing.AddRequest(pixelId, {x, y}, 0, {w, h}, color, 0, 1, 1, 0, 0, false, false)
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
    local baseColor = opts.color or {60, 60, 80, 220}
    local hoverColor = opts.hoverColor or {80, 80, 110, 230}
    local activeColor = opts.activeColor or {50, 50, 70, 240}
    local textColor = opts.textColor or {255, 255, 255}
    local textSize = opts.textSize or 14
    local disabled = opts.disabled or false

    local hovered = UI.IsHovered(x, y, w, h)
    local clicked = false

    if disabled then
        UI.Rect(x, y, w, h, {40, 40, 50, 180})
        Text.Draw(label, x + 8, y + math.floor((h - textSize) / 2), textSize, {100, 100, 100})
    else
        local bg = baseColor
        if hovered and mouseDown then
            bg = activeColor
        elseif hovered then
            bg = hoverColor
        end
        UI.Rect(x, y, w, h, bg)
        Text.Draw(label, x + 8, y + math.floor((h - textSize) / 2), textSize, textColor)
        clicked = mouseReleased and hovered
    end

    return clicked
end

function UI.ProgressBar(x, y, w, h, value, max, fgColor, bgColor)
    bgColor = bgColor or {30, 30, 40, 200}
    fgColor = fgColor or {80, 200, 80}
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
    local tx = math.min(mouseX + 12, Screen.Width() - tw - 4)
    local ty = math.max(mouseY - th - 4, 4)
    UI.Rect(tx, ty, tw, th, {20, 20, 30, 230})
    Text.Draw(tooltipText, tx + 8, ty + 4, 14, {220, 220, 220})
end

return UI
