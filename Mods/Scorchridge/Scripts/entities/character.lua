-- ============================================
-- Scorchridge — Character Entity
-- Event-driven game entity with onClick, onHover, etc.
-- ============================================

local UI = require("core/ui")

local Character = {}
Character.__index = Character

function Character.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Character)
    self.x = opts.x or 0
    self.y = opts.y or 0
    self.w = opts.w or 16
    self.h = opts.h or 24
    self.scale = opts.scale or 2
    self.data = opts.data
    self.textureId = opts.textureId
    self.visible = opts.visible ~= false
    self.tag = opts.tag or ""
    self._handlers = {}
    return self
end

function Character:on(event, fn)
    self._handlers[event] = self._handlers[event] or {}
    table.insert(self._handlers[event], fn)
    return self
end

function Character:off(event)
    self._handlers[event] = nil
    return self
end

function Character:fire(event, ...)
    local fns = self._handlers[event]
    if fns then
        for _, fn in ipairs(fns) do fn(self, ...) end
    end
end

function Character:hitbox()
    return self.x, self.y, self.w * self.scale, self.h * self.scale
end

function Character:isHovered()
    return self.visible and UI.IsHovered(self:hitbox())
end

function Character:update(dt)
    if not self.visible then return end
    if self:isHovered() then
        self:fire("onHover")
        if UI.IsClicked(self:hitbox()) then
            self:fire("onClick")
        end
    end
    self:fire("onUpdate", dt)
end

function Character:draw()
    if not self.visible then return end
    self:fire("onDraw")
end

function Character:setPosition(x, y)
    self.x = x
    self.y = y
end

function Character:setTexture(id)
    self.textureId = id
end

return Character
