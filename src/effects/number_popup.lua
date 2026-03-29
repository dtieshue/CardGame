-- Rising number popups (score, money, etc.)
local Class = require("lib.class")

local NumberPopup = Class:extend()

function NumberPopup:new()
    self.popups = {}
end

function NumberPopup:add(text, x, y, color, size)
    table.insert(self.popups, {
        text = text,
        x = x,
        y = y,
        start_y = y,
        alpha = 1,
        time = 0,
        duration = 1.2,
        color = color or {1, 1, 1},
        size = size or 1,
    })
end

function NumberPopup:addScore(chips, x, y)
    self:add("+" .. chips, x, y, {0.3, 0.7, 1}, 1)
end

function NumberPopup:addMult(mult, x, y)
    self:add("×" .. string.format("%.1f", mult), x, y, {1, 0.3, 0.3}, 1.2)
end

function NumberPopup:addMoney(amount, x, y)
    local prefix = amount >= 0 and "+$" or "-$"
    local color = amount >= 0 and {0.2, 0.8, 0.2} or {0.8, 0.2, 0.2}
    self:add(prefix .. math.abs(amount), x, y, color, 1)
end

function NumberPopup:update(dt)
    for i = #self.popups, 1, -1 do
        local p = self.popups[i]
        p.time = p.time + dt
        local progress = p.time / p.duration
        p.y = p.start_y - 40 * progress
        p.alpha = 1 - progress

        if p.time >= p.duration then
            table.remove(self.popups, i)
        end
    end
end

function NumberPopup:draw()
    for _, p in ipairs(self.popups) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.scale(p.size, p.size)
        love.graphics.print(p.text, 0, 0)
        love.graphics.pop()
    end
end

return NumberPopup
