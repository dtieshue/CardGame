local Class = require("lib.class")
local Button = require("src.ui.button")

local GameOver = Class:extend()

function GameOver:new(state_manager)
    self.state_manager = state_manager
    self.won = false
    self.ante = 1
    self.round = 1
    self.btn_menu = Button("Main Menu", 540, 450, 200, 50, function()
        self.state_manager:switch("menu")
    end)
    self.btn_menu.color = {0.4, 0.4, 0.55}
end

function GameOver:enter(params)
    self.won = params.won or false
    if params.run then
        self.ante = params.run.ante
        self.round = params.run.round
    end
end

function GameOver:update(dt)
    local mx, my = love.mouse.getPosition()
    self.btn_menu:update(dt, mx, my)
end

function GameOver:draw()
    love.graphics.setColor(0.03, 0.05, 0.03)
    love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

    if self.won then
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.printf("YOU WIN!", 0, 200, GAME_WIDTH, "center")
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Congratulations! You beat all 8 Antes!", 0, 260, GAME_WIDTH, "center")
    else
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.printf("GAME OVER", 0, 200, GAME_WIDTH, "center")
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Reached Ante " .. self.ante .. ", Round " .. self.round, 0, 260, GAME_WIDTH, "center")
    end

    self.btn_menu:draw()
end

function GameOver:keypressed(key)
    if key == "return" or key == "space" then
        self.state_manager:switch("menu")
    end
end

function GameOver:mousepressed(x, y, button)
    self.btn_menu:mousepressed(x, y, button)
end

function GameOver:mousereleased(x, y, button)
    self.btn_menu:mousereleased(x, y, button)
end

return GameOver
