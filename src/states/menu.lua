local Class = require("lib.class")
local Button = require("src.ui.button")

local Menu = Class:extend()

function Menu:new(state_manager)
    self.state_manager = state_manager
    self.btn_play = Button("New Run", 540, 380, 200, 50, function()
        self.state_manager:switch("run")
    end)
    self.btn_play.color = {0.2, 0.6, 0.3}

    self.title_y = -50
    self.title_target_y = 180
end

function Menu:enter(params)
    self.title_y = -50
end

function Menu:update(dt)
    local mx, my = love.mouse.getPosition()
    self.btn_play:update(dt, mx, my)

    -- Animate title
    self.title_y = self.title_y + (self.title_target_y - self.title_y) * 3 * dt
end

function Menu:draw()
    -- Background
    love.graphics.setColor(0.03, 0.1, 0.05)
    love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

    -- Decorative lines
    love.graphics.setColor(0.08, 0.2, 0.1, 0.3)
    for i = 0, GAME_WIDTH, 30 do
        love.graphics.line(i, 0, i, GAME_HEIGHT)
    end

    -- Title
    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.printf("POKER ROGUELIKE", 0, self.title_y, GAME_WIDTH, "center")

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("A Balatro-style Deckbuilder", 0, self.title_y + 50, GAME_WIDTH, "center")

    -- Version
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.printf("v0.1 - Phase 1", 0, self.title_y + 80, GAME_WIDTH, "center")

    self.btn_play:draw()

    -- Controls hint
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Click cards to select | Space to play | D to discard | S to sort", 0, 500, GAME_WIDTH, "center")
end

function Menu:keypressed(key)
    if key == "return" or key == "space" then
        self.state_manager:switch("run")
    end
end

function Menu:mousepressed(x, y, button)
    self.btn_play:mousepressed(x, y, button)
end

function Menu:mousereleased(x, y, button)
    self.btn_play:mousereleased(x, y, button)
end

return Menu
