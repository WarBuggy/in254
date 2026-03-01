-- ============================================
-- Terraria2D — Particles
-- Block-break particles, damage numbers
-- ============================================

local Camera = require("core/camera")
local UI = require("core/ui")
local floor = math.floor

local Particles = {}

local _DR = Drawing.Rect
local _ps -- pixel sprite id

-- Block break: spawn small colored particles
function Particles.BlockBreak(shared, x, y, color)
    for i = 1, 6 do
        local p = {
            x = x + math.random(-4, 4),
            y = y + math.random(-4, 4),
            vx = math.random(-80, 80),
            vy = math.random(-120, -20),
            size = math.random(2, 4),
            cr = math.min(255, color[1] + math.random(-20, 20)),
            cg = math.min(255, color[2] + math.random(-20, 20)),
            cb = math.min(255, color[3] + math.random(-20, 20)),
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
        cr = color[1], cg = color[2], cb = color[3],
        lifetime = 0,
        maxLife = 1.0,
        type = "text",
    }
    table.insert(shared.particles, p)
end

function Particles.UpdateAll(shared, dt)
    local particles = shared.particles
    local n = #particles
    local i = 1

    while i <= n do
        local p = particles[i]
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
            particles[i] = particles[n]
            particles[n] = nil
            n = n - 1
        else
            i = i + 1
        end
    end
end

function Particles.DrawAll(shared)
    -- Lazy init pixel sprite
    if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

    local camX = Camera.GetX()
    local camY = Camera.GetY()
    local screenW = shared.W
    local screenH = shared.H
    local R = _DR

    for _, p in ipairs(shared.particles) do
        local sx = floor(p.x - camX)
        local sy = floor(p.y - camY)

        local sz = p.size or 12
        if sx + sz >= 0 and sx <= screenW and sy + sz >= 0 and sy <= screenH then
            local alpha = floor(255 * (1 - p.lifetime / p.maxLife))

            if p.type == "block" then
                R(_ps, sx, sy, p.size, p.size, Color.New(p.cr, p.cg, p.cb, alpha))
            elseif p.type == "text" then
                Drawing.Text(p.text, sx, sy, 12, Color.New(p.cr, p.cg, p.cb, alpha))
            end
        end
    end
end

return Particles
