-- Simple particle system
local Class = require("lib.class")

local Particles = Class:extend()

function Particles:new()
    self.particles = {}
end

function Particles:burst(x, y, count, color, spread, speed)
    count = count or 8
    color = color or {1, 1, 0.5}
    spread = spread or 30
    speed = speed or 80

    for i = 1, count do
        local angle = love.math.random() * math.pi * 2
        local vel = speed * (0.5 + love.math.random() * 0.5)
        table.insert(self.particles, {
            x = x + (love.math.random() - 0.5) * spread,
            y = y + (love.math.random() - 0.5) * spread,
            vx = math.cos(angle) * vel,
            vy = math.sin(angle) * vel - 30,
            size = 2 + love.math.random() * 3,
            alpha = 1,
            life = 0.5 + love.math.random() * 0.8,
            time = 0,
            color = {
                color[1] + (love.math.random() - 0.5) * 0.2,
                color[2] + (love.math.random() - 0.5) * 0.2,
                color[3] + (love.math.random() - 0.5) * 0.2,
            },
            gravity = 100,
        })
    end
end

function Particles:scoreBurst(x, y)
    self:burst(x, y, 12, {1, 0.9, 0.3}, 20, 100)
end

function Particles:multBurst(x, y)
    self:burst(x, y, 16, {1, 0.4, 0.2}, 25, 120)
end

function Particles:confetti(x, y)
    local colors = {{1, 0.3, 0.3}, {0.3, 1, 0.3}, {0.3, 0.3, 1}, {1, 1, 0.3}, {1, 0.3, 1}}
    for _, c in ipairs(colors) do
        self:burst(x, y, 6, c, 80, 150)
    end
end

function Particles:coinBurst(x, y)
    self:burst(x, y, 6, {1, 0.85, 0.2}, 15, 60)
end

function Particles:update(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.time = p.time + dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + p.gravity * dt
        p.alpha = 1 - (p.time / p.life)
        p.size = p.size * (1 - dt * 0.5)

        if p.time >= p.life then
            table.remove(self.particles, i)
        end
    end
end

function Particles:draw()
    for _, p in ipairs(self.particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
        love.graphics.circle("fill", p.x, p.y, math.max(p.size, 0.5))
    end
end

return Particles
