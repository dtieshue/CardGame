local Class = require("lib.class")

local Button = Class:extend()

function Button:new(text, x, y, w, h, callback)
    self.text = text
    self.x = x
    self.y = y
    self.width = w or 120
    self.height = h or 36
    self.callback = callback
    self.hovered = false
    self.pressed = false
    self.enabled = true
    self.scale = 1
    self.color = {0.2, 0.5, 0.8}
    self.text_color = {1, 1, 1}
    self.disabled_color = {0.4, 0.4, 0.4}
end

function Button:containsPoint(mx, my)
    return mx >= self.x and mx <= self.x + self.width
       and my >= self.y and my <= self.y + self.height
end

function Button:update(dt, mx, my)
    self.hovered = self:containsPoint(mx, my)
    -- Smooth scale
    local target = 1
    if self.hovered and self.enabled then
        target = 1.05
    end
    if self.pressed then
        target = 0.95
    end
    self.scale = self.scale + (target - self.scale) * 12 * dt
end

function Button:mousepressed(mx, my, button)
    if button == 1 and self.hovered and self.enabled then
        self.pressed = true
    end
end

function Button:mousereleased(mx, my, button)
    if button == 1 and self.pressed then
        self.pressed = false
        if self.hovered and self.enabled and self.callback then
            self.callback()
        end
    end
end

function Button:draw()
    local cx = self.x + self.width / 2
    local cy = self.y + self.height / 2

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-self.width / 2, -self.height / 2)

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", 2, 2, self.width, self.height, 6)

    -- Background
    if self.enabled then
        local c = self.color
        if self.hovered then
            love.graphics.setColor(c[1] + 0.1, c[2] + 0.1, c[3] + 0.1)
        else
            love.graphics.setColor(c[1], c[2], c[3])
        end
    else
        local c = self.disabled_color
        love.graphics.setColor(c[1], c[2], c[3])
    end
    love.graphics.rectangle("fill", 0, 0, self.width, self.height, 6)

    -- Border
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", 0, 0, self.width, self.height, 6)

    -- Text
    local font = love.graphics.getFont()
    local tw = font:getWidth(self.text)
    local th = font:getHeight()
    if self.enabled then
        love.graphics.setColor(self.text_color)
    else
        love.graphics.setColor(0.7, 0.7, 0.7)
    end
    love.graphics.print(self.text, (self.width - tw) / 2, (self.height - th) / 2)

    love.graphics.pop()
end

return Button
