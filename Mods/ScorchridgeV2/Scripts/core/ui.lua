-- ============================================
-- ScorchridgeV2 — UI Framework
-- Rectangle drawing, buttons, progress bars, tooltips
-- ============================================

local SFX = require("core/sound")

local modId = "ScorchridgeV2"

local UI = {}

local pixelId = nil
local mouseX, mouseY = 0, 0
local mouseDown = false
local mousePressed = false
local mouseReleased = false
local tooltipText = nil

function UI.ResolvePixel()
    if pixelId then return true end
    pixelId = Animation.FrameTextureIdFrom(modId, "scrPixel", "base", "idle", 1)
    return pixelId ~= nil
end

function UI.UpdateInput()
    if Scene.IsInputBlocked() then
        mouseX, mouseY = -9999, -9999
        mouseDown, mousePressed, mouseReleased = false, false, false
        tooltipText = nil
        return
    end
    mouseX = Input.MouseX()
    mouseY = Input.MouseY()
    mouseDown = Input.IsMouseDown("left")
    mousePressed = Input.IsMousePressed("left")
    mouseReleased = Input.IsMouseReleased("left")
    tooltipText = nil
end

function UI.MouseX() return mouseX end
function UI.MouseY() return mouseY end

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

function UI.IsPressed(x, y, w, h)
    return mousePressed and UI.IsHovered(x, y, w, h)
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
        if clicked then SFX.Click() end
    end

    return clicked
end

function UI.IconButton(x, y, size, icon, opts)
    opts = opts or {}
    local baseColor = opts.color or {60, 60, 80, 220}
    local hoverColor = opts.hoverColor or {80, 80, 110, 230}
    local activeColor = opts.activeColor or {50, 50, 70, 240}
    local iconColor = opts.iconColor or {255, 255, 255}
    local iconSize = opts.iconSize or math.floor(size * 0.5)
    local disabled = opts.disabled or false
    local selected = opts.selected or false
    local label = opts.label

    local hovered = UI.IsHovered(x, y, size, size)
    local clicked = false

    if selected then
        UI.Rect(x - 2, y - 2, size + 4, size + 4, {255, 255, 100, 80})
    end

    if disabled then
        UI.Rect(x, y, size, size, {40, 40, 50, 180})
        Text.Draw(icon, x + math.floor((size - #icon * iconSize * 0.55) / 2), y + math.floor((size - iconSize) / 2), iconSize, {80, 80, 80})
    else
        local bg = baseColor
        if hovered and mouseDown then
            bg = activeColor
        elseif hovered then
            bg = hoverColor
        end
        UI.Rect(x, y, size, size, bg)
        Text.Draw(icon, x + math.floor((size - #icon * iconSize * 0.55) / 2), y + math.floor((size - iconSize) / 2), iconSize, iconColor)
        clicked = mouseReleased and hovered
        if clicked then SFX.Click() end
    end

    if label then
        Text.Draw(label, x + math.floor((size - #label * 4) / 2), y + size + 1, 8, hovered and {200, 200, 200} or {120, 120, 120})
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
