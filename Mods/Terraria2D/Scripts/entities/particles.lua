-- ============================================
-- Terraria2D — Particles
-- Block-break particles, damage numbers
-- ============================================

local Camera = require("core/camera")
local UI = require("core/ui")

local floor = math.floor

local Particles = {}

-- Reusable color table for draw (avoids allocation per particle per frame)
local _drawColor = { 0, 0, 0, 255 }

-- Block break: spawn small colored particles
function Particles.BlockBreak(shared, x, y, color)
    for i = 1, 6 do
        local p = {
            x = x + math.random(-4, 4),
            y = y + math.random(-4, 4),
            vx = math.random(-80, 80),
            vy = math.random(-120, -20),
            size = math.random(2, 4),
            color = {
                math.min(255, color[1] + math.random(-20, 20)),
                math.min(255, color[2] + math.random(-20, 20)),
                math.min(255, color[3] + math.random(-20, 20)),
                255,
            },
            lifetime = 0,
            maxLife = 0.5 + math.random() * 0.5,
            type = "block",
        }
        table.insert(shared.particles, p)
    end
end

-- Damage number: floating text
function Particles.DamageNumber(shared, x, y, amount, color)
    local p = {
        x = x + math.random(-8, 8),
        y = y - 10,
        vy = -40,
        text = tostring(amount),
        color = color,
        lifetime = 0,
        maxLife = 1.0,
        type = "text",
    }
    table.insert(shared.particles, p)
end

function Particles.UpdateAll(shared, dt)
    local toRemove = {}

    for i, p in ipairs(shared.particles) do
        p.lifetime = p.lifetime + dt

        if p.type == "block" then
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.vy = p.vy + 300 * dt -- gravity
        elseif p.type == "text" then
            p.y = p.y + p.vy * dt
            p.vy = p.vy * 0.95
        end

        if p.lifetime >= p.maxLife then
            table.insert(toRemove, i)
        end
    end

    for i = #toRemove, 1, -1 do
        table.remove(shared.particles, toRemove[i])
    end
end

function Particles.DrawAll(shared)
    local camX = Camera.GetX()
    local camY = Camera.GetY()
    local dc = _drawColor

    for _, p in ipairs(shared.particles) do
        local sx = floor(p.x - camX)
        local sy = floor(p.y - camY)
        local alpha = floor(255 * (1 - p.lifetime / p.maxLife))

        if p.type == "block" then
            local c = p.color
            dc[1] = c[1]; dc[2] = c[2]; dc[3] = c[3]; dc[4] = alpha
            UI.Rect(sx, sy, p.size, p.size, dc)
        elseif p.type == "text" then
            local c = p.color
            dc[1] = c[1]; dc[2] = c[2]; dc[3] = c[3]; dc[4] = alpha
            Text.Draw(p.text, sx, sy, 12, dc)
        end
    end
end

return Particles
