-- ============================================
-- ExtractOrDie — Camera
-- Thin wrapper around C# GameCamera binding
-- ============================================

local Config = require("eod/core/config")

local Camera = {}

setmetatable(Camera, {
    __index = function(_, k)
        if k == "zoom" then return GameCamera.GetZoom() end
    end,
    __newindex = function(t, k, v)
        if k == "zoom" then GameCamera.SetZoom(v)
        else rawset(t, k, v) end
    end,
})

function Camera.Init(x, y)
    GameCamera.Snap(x or 0, y or 0)
end

function Camera.GetX() return GameCamera.GetX() end
function Camera.GetY() return GameCamera.GetY() end

function Camera.Follow(entityX, entityY, screenW, screenH)
    GameCamera.Follow(entityX, entityY, screenW, screenH)
    local viewW = screenW / Camera.zoom
    local viewH = screenH / Camera.zoom
    local maxX = Config.MAP_PX_W - viewW
    local maxY = Config.MAP_PX_H - viewH
    GameCamera.ClampTarget(0, 0, maxX, maxY)
end

function Camera.Update(dt)
    GameCamera.Update(dt)
end

function Camera.Snap(x, y)
    GameCamera.Snap(x, y)
end

function Camera.ScreenToWorldX(sx)
    return GameCamera.ScreenToWorldX(sx)
end

function Camera.ScreenToWorldY(sy)
    return GameCamera.ScreenToWorldY(sy)
end

function Camera.WorldToScreenX(wx)
    return GameCamera.WorldToScreenX(wx)
end

function Camera.WorldToScreenY(wy)
    return GameCamera.WorldToScreenY(wy)
end

function Camera.GetWorldBounds(screenW, screenH)
    return GameCamera.GetWorldBounds(screenW, screenH)
end

return Camera
