-- Blind selection screen
local Class = require("lib.class")
local Button = require("src.ui.button")
local blind_defs = require("src.data.blind_defs")

local BlindSelect = Class:extend()

function BlindSelect:new(state_manager)
    self.state_manager = state_manager
    self.run = nil
    self.run_state = nil
    self.blinds = {}
end

function BlindSelect:enter(params)
    self.run = params.run
    self.run_state = params.run_state

    -- Build blind options
    self.blinds = {}
    local types = {"small", "big", "boss"}
    local names = {"Small Blind", "Big Blind", "Boss Blind"}

    for i, bt in ipairs(types) do
        local score = blind_defs.getScoreRequirement(self.run.ante, bt)
        local blind = {
            type = bt,
            name = names[i],
            score = score,
            can_skip = (bt ~= "boss"),
            reward = ({3, 4, 5})[i],
        }
        if bt == "boss" then
            self.run.current_boss = self.run.current_boss or blind_defs.getRandomBoss()
            blind.name = self.run.current_boss.name
            blind.description = self.run.current_boss.description
        end
        table.insert(self.blinds, blind)
    end
end

function BlindSelect:update(dt)
end

function BlindSelect:draw()
    love.graphics.setColor(0.04, 0.1, 0.05)
    love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.printf("SELECT BLIND", 0, 30, GAME_WIDTH, "center")

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.printf("Ante " .. self.run.ante, 0, 60, GAME_WIDTH, "center")

    for i, blind in ipairs(self.blinds) do
        local bx = 200 + (i - 1) * 300
        local by = 150
        local bw = 250
        local bh = 350

        -- Highlight current round's blind
        local is_current = (i == self.run.round)

        if is_current then
            love.graphics.setColor(0.15, 0.25, 0.15)
        else
            love.graphics.setColor(0.1, 0.14, 0.1)
        end
        love.graphics.rectangle("fill", bx, by, bw, bh, 10)

        if is_current then
            love.graphics.setColor(0.4, 0.9, 0.4)
        else
            love.graphics.setColor(0.25, 0.35, 0.25)
        end
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", bx, by, bw, bh, 10)

        -- Name
        if blind.type == "boss" then
            love.graphics.setColor(1, 0.3, 0.3)
        else
            love.graphics.setColor(1, 0.9, 0.6)
        end
        love.graphics.printf(blind.name, bx, by + 20, bw, "center")

        -- Score requirement
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Score: " .. blind.score, bx, by + 60, bw, "center")

        -- Reward
        love.graphics.setColor(0.2, 0.7, 0.2)
        love.graphics.printf("Reward: $" .. blind.reward, bx, by + 90, bw, "center")

        -- Boss description
        if blind.description then
            love.graphics.setColor(0.9, 0.5, 0.5)
            love.graphics.printf(blind.description, bx + 15, by + 130, bw - 30, "center")
        end

        -- Buttons
        if is_current then
            -- Play button
            love.graphics.setColor(0.2, 0.6, 0.3)
            love.graphics.rectangle("fill", bx + 30, by + bh - 90, bw - 60, 35, 6)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("PLAY", bx + 30, by + bh - 82, bw - 60, "center")

            -- Skip button
            if blind.can_skip then
                love.graphics.setColor(0.5, 0.4, 0.2)
                love.graphics.rectangle("fill", bx + 30, by + bh - 45, bw - 60, 35, 6)
                love.graphics.setColor(1, 1, 0.8)
                love.graphics.printf("SKIP", bx + 30, by + bh - 37, bw - 60, "center")
            end
        end
    end
end

function BlindSelect:keypressed(key)
    if key == "return" or key == "space" then
        self:playBlind()
    elseif key == "s" then
        self:skipBlind()
    end
end

function BlindSelect:playBlind()
    self.run_state:startBlind()
    self.state_manager:switch("run", {continuing = true})
end

function BlindSelect:skipBlind()
    local blind = self.blinds[self.run.round]
    if blind and blind.can_skip then
        -- Give skip reward (tag bonus)
        self.run.money = self.run.money + 3
        self.run:advanceRound()
        if self.run.run_won then
            self.state_manager:switch("game_over", {won = true, run = self.run})
        else
            -- After skipping, go to shop (per Balatro: shop after every blind, even skipped)
            self.state_manager:switch("shop", {run = self.run, run_state = self.run_state})
        end
    end
end

function BlindSelect:mousepressed(x, y, button)
    if button ~= 1 then return end

    local i = self.run.round
    local blind = self.blinds[i]
    if not blind then return end

    local bx = 200 + (i - 1) * 300
    local by = 150
    local bw = 250
    local bh = 350

    -- Play button hit
    if x >= bx + 30 and x <= bx + bw - 30
       and y >= by + bh - 90 and y <= by + bh - 55 then
        self:playBlind()
    end

    -- Skip button hit
    if blind.can_skip and x >= bx + 30 and x <= bx + bw - 30
       and y >= by + bh - 45 and y <= by + bh - 10 then
        self:skipBlind()
    end
end

return BlindSelect
