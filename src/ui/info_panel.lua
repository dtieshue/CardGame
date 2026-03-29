local Class = require("lib.class")

local InfoPanel = Class:extend()

function InfoPanel:new()
    self.x = 0
    self.y = 0
    self.width = 200
    self.height = GAME_HEIGHT

    -- Animated display values
    self.display_score = 0
    self.display_target = 0
end

function InfoPanel:update(dt, run)
    -- Animate score counter
    local speed = 8
    if self.display_score < run.score then
        self.display_score = self.display_score + (run.score - self.display_score) * speed * dt
        if math.abs(self.display_score - run.score) < 1 then
            self.display_score = run.score
        end
    end
    self.display_target = run.score_target
end

function InfoPanel:draw(run)
    -- Panel background
    love.graphics.setColor(0.08, 0.12, 0.08)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(0.15, 0.25, 0.15)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    local x = self.x + 15
    local y = 20

    -- Blind name
    love.graphics.setColor(1, 0.85, 0.3)
    love.graphics.print(run:getBlindName(), x, y)
    y = y + 25

    -- Ante / Round
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Ante " .. run.ante, x, y)
    y = y + 18
    love.graphics.print("Round " .. run.round .. "/3", x, y)
    y = y + 35

    -- Score target
    love.graphics.setColor(0.9, 0.4, 0.4)
    love.graphics.print("TARGET", x, y)
    y = y + 18
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self:formatNumber(self.display_target), x, y)
    y = y + 30

    -- Current score
    love.graphics.setColor(0.4, 0.8, 0.4)
    love.graphics.print("SCORE", x, y)
    y = y + 18

    -- Score bar
    local bar_w = self.width - 30
    local bar_h = 16
    local progress = math.min(self.display_score / math.max(self.display_target, 1), 1)

    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", x, y, bar_w, bar_h, 4)
    if progress > 0 then
        love.graphics.setColor(0.3, 0.8, 0.3)
        love.graphics.rectangle("fill", x, y, bar_w * progress, bar_h, 4)
    end
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", x, y, bar_w, bar_h, 4)
    y = y + 22

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self:formatNumber(math.floor(self.display_score)), x, y)
    y = y + 35

    -- Hands remaining
    love.graphics.setColor(0.3, 0.6, 1)
    love.graphics.print("HANDS", x, y)
    y = y + 18
    love.graphics.setColor(1, 1, 1)
    for i = 1, STARTING_HANDS do
        if i <= run.hands_remaining then
            love.graphics.setColor(0.3, 0.6, 1)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
        end
        love.graphics.rectangle("fill", x + (i - 1) * 22, y, 18, 12, 3)
    end
    y = y + 22
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(run.hands_remaining, x, y)
    y = y + 30

    -- Discards remaining
    love.graphics.setColor(0.9, 0.4, 0.3)
    love.graphics.print("DISCARDS", x, y)
    y = y + 18
    love.graphics.setColor(1, 1, 1)
    for i = 1, STARTING_DISCARDS do
        if i <= run.discards_remaining then
            love.graphics.setColor(0.9, 0.4, 0.3)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
        end
        love.graphics.rectangle("fill", x + (i - 1) * 22, y, 18, 12, 3)
    end
    y = y + 22
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(run.discards_remaining, x, y)
    y = y + 40

    -- Money
    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.print("MONEY", x, y)
    y = y + 18
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.print("$" .. run.money, x, y)
    y = y + 30

    -- Deck info
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Deck: " .. run.deck:drawPileCount(), x, y)
    y = y + 18
    love.graphics.print("Discard: " .. run.deck:discardPileCount(), x, y)
end

function InfoPanel:formatNumber(n)
    n = math.floor(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 10000 then
        return string.format("%.1fK", n / 1000)
    else
        return tostring(n)
    end
end

return InfoPanel
