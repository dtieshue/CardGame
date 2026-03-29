-- Shop state: buy jokers, consumables, reroll
local Class = require("lib.class")
local Button = require("src.ui.button")
local Joker = require("src.core.joker")
local Consumable = require("src.core.consumable")
local joker_defs = require("src.data.joker_defs")
local tarot_defs = require("src.data.tarot_defs")
local planet_defs = require("src.data.planet_defs")

local Shop = Class:extend()

function Shop:new(state_manager)
    self.state_manager = state_manager
    self.run = nil
    self.run_state = nil
    self.items = {}       -- shop item slots
    self.reroll_cost = 5
    self.selected_item = nil

    self.btn_reroll = Button("Reroll $5", 900, 550, 120, 36, function() self:reroll() end)
    self.btn_reroll.color = {0.6, 0.5, 0.2}
    self.btn_next = Button("Next Round", 900, 600, 120, 36, function() self:nextRound() end)
    self.btn_next.color = {0.2, 0.6, 0.3}
end

function Shop:enter(params)
    self.run = params.run
    self.run_state = params.run_state
    self.reroll_cost = 5
    self.selected_item = nil
    self:generateItems()
end

function Shop:generateItems()
    self.items = {}

    -- 2 card slots (joker, tarot, or planet)
    for i = 1, 2 do
        local roll = love.math.random(1, 10)
        if roll <= 5 then
            -- Joker
            local def = joker_defs[love.math.random(1, #joker_defs)]
            table.insert(self.items, {
                type = "joker",
                def = def,
                name = def.name,
                description = def.description,
                cost = def.cost,
                sold = false,
            })
        elseif roll <= 8 then
            -- Tarot
            local def = tarot_defs[love.math.random(1, #tarot_defs)]
            table.insert(self.items, {
                type = "tarot",
                def = def,
                name = def.name,
                description = def.description,
                cost = def.cost or 3,
                sold = false,
            })
        else
            -- Planet
            local def = planet_defs[love.math.random(1, #planet_defs)]
            table.insert(self.items, {
                type = "planet",
                def = def,
                name = def.name,
                description = def.description,
                cost = def.cost or 3,
                sold = false,
            })
        end
    end

    -- 2 more slots (mix)
    for i = 1, 2 do
        local roll = love.math.random(1, 10)
        if roll <= 4 then
            local def = joker_defs[love.math.random(1, #joker_defs)]
            table.insert(self.items, {
                type = "joker",
                def = def,
                name = def.name,
                description = def.description,
                cost = def.cost,
                sold = false,
            })
        elseif roll <= 7 then
            local def = tarot_defs[love.math.random(1, #tarot_defs)]
            table.insert(self.items, {
                type = "tarot",
                def = def,
                name = def.name,
                description = def.description,
                cost = def.cost or 3,
                sold = false,
            })
        else
            local def = planet_defs[love.math.random(1, #planet_defs)]
            table.insert(self.items, {
                type = "planet",
                def = def,
                name = def.name,
                description = def.description,
                cost = def.cost or 3,
                sold = false,
            })
        end
    end
end

function Shop:buyItem(index)
    local item = self.items[index]
    if not item or item.sold then return end
    if not self.run:canAfford(item.cost) then return end

    if item.type == "joker" then
        if not self.run:canAddJoker() then return end
        self.run:spend(item.cost)
        local joker = Joker(item.def)
        self.run:addJoker(joker)
        item.sold = true
    elseif item.type == "tarot" or item.type == "planet" then
        if #self.run.consumables >= MAX_CONSUMABLE_SLOTS then return end
        self.run:spend(item.cost)
        local consumable = Consumable(item.def)
        consumable.card_type = item.type
        table.insert(self.run.consumables, consumable)
        item.sold = true
    end
end

function Shop:reroll()
    if not self.run:canAfford(self.reroll_cost) then return end
    self.run:spend(self.reroll_cost)
    self.reroll_cost = self.reroll_cost + 1
    self:generateItems()
end

function Shop:nextRound()
    -- Go to blind select screen, where the player chooses to play or skip
    self.state_manager:switch("blind_select", {run = self.run, run_state = self.run_state})
end

function Shop:update(dt)
    local mx, my = love.mouse.getPosition()
    self.btn_reroll.text = "Reroll $" .. self.reroll_cost
    self.btn_reroll.enabled = self.run:canAfford(self.reroll_cost)
    self.btn_reroll:update(dt, mx, my)
    self.btn_next:update(dt, mx, my)

    -- Detect hover on items
    self.selected_item = nil
    for i, item in ipairs(self.items) do
        if not item.sold then
            local ix = 120 + (i - 1) * 200
            local iy = 200
            if mx >= ix and mx <= ix + 160 and my >= iy and my <= iy + 220 then
                self.selected_item = i
            end
        end
    end
end

function Shop:draw()
    -- Background
    love.graphics.setColor(0.06, 0.1, 0.06)
    love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

    -- Title
    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.printf("SHOP", 0, 30, GAME_WIDTH, "center")

    -- Money
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.printf("$" .. self.run.money, 0, 60, GAME_WIDTH, "center")

    -- Ante/Round info
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.printf("Ante " .. self.run.ante .. " - Round " .. self.run.round .. "/3", 0, 85, GAME_WIDTH, "center")

    -- Shop items
    for i, item in ipairs(self.items) do
        local ix = 120 + (i - 1) * 200
        local iy = 200
        local selected = (self.selected_item == i)

        if item.sold then
            love.graphics.setColor(0.15, 0.15, 0.15)
            love.graphics.rectangle("fill", ix, iy, 160, 220, 8)
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.printf("SOLD", ix, iy + 100, 160, "center")
        else
            -- Card background
            if selected then
                love.graphics.setColor(0.2, 0.3, 0.2)
            else
                love.graphics.setColor(0.12, 0.18, 0.12)
            end
            love.graphics.rectangle("fill", ix, iy, 160, 220, 8)

            -- Border
            local can_afford = self.run:canAfford(item.cost)
            if selected and can_afford then
                love.graphics.setColor(0.3, 0.9, 0.3)
            elseif can_afford then
                love.graphics.setColor(0.3, 0.5, 0.3)
            else
                love.graphics.setColor(0.5, 0.2, 0.2)
            end
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", ix, iy, 160, 220, 8)

            -- Type badge
            if item.type == "joker" then
                love.graphics.setColor(0.5, 0.3, 0.7)
            elseif item.type == "tarot" then
                love.graphics.setColor(0.3, 0.5, 0.7)
            else
                love.graphics.setColor(0.2, 0.6, 0.4)
            end
            love.graphics.rectangle("fill", ix + 10, iy + 10, 140, 20, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(item.type:upper(), ix + 10, iy + 12, 140, "center")

            -- Name
            love.graphics.setColor(1, 0.95, 0.8)
            love.graphics.printf(item.name, ix + 5, iy + 40, 150, "center")

            -- Description
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.printf(item.description, ix + 8, iy + 70, 144, "center")

            -- Cost
            if can_afford then
                love.graphics.setColor(0.2, 0.8, 0.2)
            else
                love.graphics.setColor(0.8, 0.2, 0.2)
            end
            love.graphics.printf("$" .. item.cost, ix, iy + 190, 160, "center")
        end
    end

    -- Joker area (show current jokers)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Your Jokers:", 80, 470)
    for i, joker in ipairs(self.run.jokers) do
        local jx = 80 + (i - 1) * 90
        love.graphics.setColor(0.3, 0.2, 0.5)
        love.graphics.rectangle("fill", jx, 490, 80, 45, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(joker.name, jx + 2, 498, 76, "center")
    end

    -- Consumable area
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Consumables:", 80, 550)
    for i, cons in ipairs(self.run.consumables) do
        local cx = 80 + (i - 1) * 90
        love.graphics.setColor(0.2, 0.4, 0.5)
        love.graphics.rectangle("fill", cx, 570, 80, 45, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(cons.name, cx + 2, 578, 76, "center")
    end

    -- Buttons
    self.btn_reroll:draw()
    self.btn_next:draw()
end

function Shop:keypressed(key)
    if key == "return" or key == "space" then
        self:nextRound()
    elseif key == "r" then
        self:reroll()
    end
end

function Shop:mousepressed(x, y, button)
    if button == 1 then
        -- Check item clicks
        if self.selected_item then
            self:buyItem(self.selected_item)
        end

        self.btn_reroll:mousepressed(x, y, button)
        self.btn_next:mousepressed(x, y, button)
    end
end

function Shop:mousereleased(x, y, button)
    self.btn_reroll:mousereleased(x, y, button)
    self.btn_next:mousereleased(x, y, button)
end

return Shop
