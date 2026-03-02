-- ============================================
-- ExtractOrDie — Particles
-- Sparks, damage numbers, death bursts
-- ============================================

local Camera = require("eod/core/camera")
local UI = require("eod/core/ui")
local floor = math.floor

local Particles = {}

local _DR = Drawing.Rect
local _ps -- pixel sprite id

-- Spark: small white/yellow particles on wall hit
function Particles.Spark(shared, x, y)
    for i = 1, 3 do
        local p = {
            x = x + math.random(-3, 3),
            y = y + math.random(-3, 3),
            vx = math.random(-100, 100),
            vy = math.random(-100, 100),
            size = math.random(1, 2),
            cr = 255, cg = math.random(200, 255), cb = math.random(100, 200),
            lifetime = 0,
            maxLife = 0.2 + math.random() * 0.2,
            type = "spark",
        }
        table.insert(shared.particles, p)
    end
end

-- Damage number: floating text
function Particles.DamageNumber(shared, x, y, amount, color)
    local p = {
        x = x + math.random(-6, 6),
        y = y - 8,
        vy = -30,
        text = tostring(amount),
        cr = color[1], cg = color[2], cb = color[3],
        lifetime = 0,
        maxLife = 0.8,
        type = "text",
    }
    table.insert(shared.particles, p)
end

-- Death burst: colored particles spray
function Particles.DeathBurst(shared, x, y, color)
    for i = 1, 8 do
        local p = {
            x = x + math.random(-4, 4),
            y = y + math.random(-4, 4),
            vx = math.random(-120, 120),
            vy = math.random(-120, 120),
            size = math.random(2, 4),
            cr = math.min(255, color[1] + math.random(-30, 30)),
            cg = math.min(255, color[2] + math.random(-30, 30)),
            cb = math.min(255, color[3] + math.random(-30, 30)),
            lifetime = 0,
            maxLife = 0.4 + math.random() * 0.4,
            type = "spark",
        }
        table.insert(shared.particles, p)
    end
end

-- Shockwave: expanding ring of particles for brute ground slam
function Particles.Shockwave(shared, cx, cy, radius)
    local numParticles = 12
    for i = 1, numParticles do
        local angle = (i / numParticles) * math.pi * 2
        local speed = radius * 3
        local p = {
            x = cx,
            y = cy,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = math.random(3, 5),
            cr = 255, cg = math.random(80, 140), cb = 30,
            lifetime = 0,
            maxLife = 0.3,
            type = "spark",
        }
        table.insert(shared.particles, p)
    end
end

-- Ghost trail: semi-transparent afterimage during dodge roll
function Particles.GhostTrail(shared, x, y)
    local p = {
        x = x + math.random(-2, 2),
        y = y + math.random(-2, 2),
        vx = 0,
        vy = 0,
        size = 6,
        cr = 60, cg = 140, cb = 80,
        lifetime = 0,
        maxLife = 0.15,
        type = "ghost",
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

        if p.type == "spark" then
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            -- Friction
            p.vx = p.vx * 0.95
            p.vy = p.vy * 0.95
        elseif p.type == "text" then
            p.y = p.y + p.vy * dt
            p.vy = p.vy * 0.92
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
    if not _ps then _ps = Drawing.RegisterPixelSprite(UI.GetPixelId()) end

    local b = shared.camBounds
    if not b then return end
    local R = _DR

    for _, p in ipairs(shared.particles) do
        local sz = p.size or 12
        if p.x + sz >= b.x and p.x <= b.x + b.w and p.y + sz >= b.y and p.y <= b.y + b.h then
            local alpha = floor(255 * (1 - p.lifetime / p.maxLife))

            if p.type == "spark" then
                R(_ps, floor(p.x), floor(p.y), p.size, p.size, Color.New(p.cr, p.cg, p.cb, alpha))
            elseif p.type == "ghost" then
                local ga = floor(120 * (1 - p.lifetime / p.maxLife))
                R(_ps, floor(p.x) - 3, floor(p.y) - 5, p.size, 8, Color.New(p.cr, p.cg, p.cb, ga))
            elseif p.type == "text" then
                Drawing.SetLayer("ui")
                local zoom = Camera.zoom
                local uiX = floor(Camera.WorldToScreenX(p.x))
                local uiY = floor(Camera.WorldToScreenY(p.y))
                Drawing.Text(p.text, uiX, uiY, floor(12 * zoom), Color.New(p.cr, p.cg, p.cb, alpha))
                Drawing.SetLayer("particles")
            end
        end
    end
end

return Particles
