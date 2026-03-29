-- Screen shake effect
local Class = require("lib.class")

local ScreenShake = Class:extend()

function ScreenShake:new()
    self.amount = 0
    self.duration = 0
    self.time = 0
    self.offset_x = 0
    self.offset_y = 0
end

function ScreenShake:trigger(amount, duration)
    self.amount = amount
    self.duration = duration or 0.3
    self.time = self.duration
end

function ScreenShake:triggerFromScore(score)
    local amount = math.min(math.log(score + 1) * 1.5, 15)
    local duration = math.min(0.1 + score / 50000, 0.5)
    self:trigger(amount, duration)
end

function ScreenShake:update(dt)
    if self.time > 0 then
        self.time = self.time - dt
        local progress = self.time / self.duration
        local intensity = self.amount * progress
        self.offset_x = (love.math.random() * 2 - 1) * intensity
        self.offset_y = (love.math.random() * 2 - 1) * intensity
    else
        self.offset_x = 0
        self.offset_y = 0
    end
end

function ScreenShake:apply()
    love.graphics.translate(self.offset_x, self.offset_y)
end

return ScreenShake
