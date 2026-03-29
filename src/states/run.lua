-- Core gameplay state: playing hands against blinds
local Class = require("lib.class")
local RunManager = require("src.core.run_manager")
local HandEvaluator = require("src.core.hand_evaluator")
local ScoringEngine = require("src.core.scoring_engine")
local CardRenderer = require("src.ui.card_renderer")
local HandArea = require("src.ui.hand_area")
local InfoPanel = require("src.ui.info_panel")
local Button = require("src.ui.button")
local ScreenShake = require("src.effects.screen_shake")
local NumberPopup = require("src.effects.number_popup")
local Particles = require("src.effects.particles")
local flux = require("lib.flux")

local RunState = Class:extend()

function RunState:new(state_manager)
    self.state_manager = state_manager
    self.run = RunManager()
    self.card_renderer = CardRenderer()
    self.hand_area = HandArea()
    self.info_panel = InfoPanel()
    self.screen_shake = ScreenShake()
    self.popups = NumberPopup()
    self.particles = Particles()

    self.played_cards = {}
    self.hand_label = ""
    self.scoring_display = nil
    self.phase = "playing" -- "playing", "scoring", "round_end", "blind_won"

    -- Score animation
    self.score_anim = {chips = 0, mult = 0, total = 0, alpha = 0}

    -- Buttons
    self.btn_play = Button("Play Hand", 420, 650, 130, 36, function() self:playHand() end)
    self.btn_play.color = {0.2, 0.6, 0.3}
    self.btn_discard = Button("Discard", 560, 650, 110, 36, function() self:discardCards() end)
    self.btn_discard.color = {0.7, 0.3, 0.2}
    self.btn_sort_rank = Button("Sort Rank", 680, 650, 100, 36, function() self.hand_area:sortByRank() end)
    self.btn_sort_rank.color = {0.4, 0.4, 0.55}
    self.btn_sort_suit = Button("Sort Suit", 788, 650, 100, 36, function() self.hand_area:sortBySuit() end)
    self.btn_sort_suit.color = {0.4, 0.4, 0.55}
    self.btn_continue = Button("Continue", 550, 400, 140, 40, function() self:onContinue() end)
    self.btn_continue.color = {0.2, 0.6, 0.3}

    self.buttons = {self.btn_play, self.btn_discard, self.btn_sort_rank, self.btn_sort_suit}
end

function RunState:enter(params)
    if params and params.continuing then
        -- Returning from blind_select, blind already started
        return
    end
    -- New run: reset everything and go to blind select
    self.run:reset()
    self.state_manager:switch("blind_select", {run = self.run, run_state = self})
end

function RunState:startBlind()
    self.run:startBlind()
    self.phase = "playing"
    self.played_cards = {}
    self.scoring_display = nil
    self.score_anim = {chips = 0, mult = 0, total = 0, alpha = 0}

    -- Deal hand
    local cards = self.run.deck:draw(MAX_HAND_SIZE)

    -- Apply boss blind deal effects
    if self.run:getBlindType() == "boss" and self.run.current_boss then
        local boss = self.run.current_boss
        if boss.effect then
            boss.effect({event = "deal", cards = cards, run = self.run})
        end
    end

    self.hand_area:setCards(cards)
end

function RunState:playHand()
    if self.phase ~= "playing" then return end
    local selected = self.hand_area:getSelectedCards()
    if #selected == 0 or #selected > MAX_SELECTED then return end
    if self.run.hands_remaining <= 0 then return end

    -- Boss blind: The Psychic requires exactly 5
    if self.run:getBlindType() == "boss" and self.run.current_boss
       and self.run.current_boss.name == "The Psychic" and #selected ~= 5 then
        return
    end

    -- Boss blind: The Eye - can't repeat hand types
    local hand_name = HandEvaluator.evaluate(selected)
    if self.run:getBlindType() == "boss" and self.run.current_boss
       and self.run.current_boss.name == "The Eye" then
        if self.run.hands_played_this_blind[hand_name] then
            return
        end
    end

    -- Move selected cards to play area
    self.played_cards = selected
    self.hand_area:removeCards(selected)
    self.run:useHand()

    -- Track hand type for The Eye
    if hand_name then
        self.run.hands_played_this_blind[hand_name] = true
    end

    -- Score
    local context = {
        hands_remaining = self.run.hands_remaining,
        discards_remaining = self.run.discards_remaining,
        held_cards = self.hand_area.cards,
    }
    local total, breakdown = ScoringEngine.score(selected, self.run.jokers, context)

    self.scoring_display = breakdown
    self.run:addScore(total)

    -- Animate scoring
    self.phase = "scoring"
    self.score_anim = {chips = 0, mult = 0, total = 0, alpha = 0}

    -- Position played cards in center
    local total_w = #self.played_cards * (CARD_WIDTH + 10) - 10
    local start_x = 210 + (GAME_WIDTH - 220 - total_w) / 2
    for i, card in ipairs(self.played_cards) do
        card.selected = false
        card.target_x = start_x + (i - 1) * (CARD_WIDTH + 10)
        card.target_y = 260
        card.target_rotation = 0
    end

    -- Animate the score reveal
    flux.to(self.score_anim, 0.4, {chips = breakdown.chips}):ease("cubicOut")
    flux.to(self.score_anim, 0.4, {mult = breakdown.mult}):ease("cubicOut"):delay(0.3)
    flux.to(self.score_anim, 0.3, {total = breakdown.total, alpha = 1}):delay(0.7)
        :ease("backOut")
        :oncomplete(function()
            -- Screen shake and particles on score
            self.screen_shake:triggerFromScore(total)
            self.particles:scoreBurst(GAME_WIDTH / 2, 200)
            if breakdown.mult > 5 then
                self.particles:multBurst(GAME_WIDTH / 2 + 60, 200)
            end
            -- Popup
            self.popups:add("+" .. total, GAME_WIDTH / 2 - 30, 170, {1, 1, 0.3}, 1.5)
            -- After scoring animation, check win/lose
            self:afterScoring()
        end)
end

function RunState:afterScoring()
    -- Discard played cards
    self.run.deck:discard(self.played_cards)

    if self.run:isBlindBeaten() then
        self.phase = "blind_won"
        self.particles:confetti(GAME_WIDTH / 2, 300)
    elseif self.run:isRunOver() then
        self.phase = "round_end"
        self.run.game_over = true
    else
        -- Draw replacements and continue playing
        self.phase = "playing"
        self.played_cards = {}
        self.scoring_display = nil

        local need = MAX_HAND_SIZE - #self.hand_area.cards
        if need > 0 then
            local new_cards = self.run.deck:draw(need)

            -- Apply boss blind effects to new cards
            if self.run:getBlindType() == "boss" and self.run.current_boss then
                local boss = self.run.current_boss
                if boss.effect then
                    boss.effect({event = "deal", cards = new_cards, run = self.run})
                end
            end

            -- Apply boss blind hand_start effects
            if self.run:getBlindType() == "boss" and self.run.current_boss then
                local boss = self.run.current_boss
                if boss.effect then
                    boss.effect({
                        event = "hand_start",
                        hand_area = self.hand_area,
                        deck = self.run.deck,
                    })
                end
            end

            self.hand_area:addCards(new_cards)
        end
    end
end

function RunState:discardCards()
    if self.phase ~= "playing" then return end
    local selected = self.hand_area:getSelectedCards()
    if #selected == 0 then return end
    if self.run.discards_remaining <= 0 then return end

    self.run:useDiscard()
    self.hand_area:removeCards(selected)
    self.run.deck:discard(selected)

    -- Draw replacements
    local new_cards = self.run.deck:draw(#selected)

    -- Apply boss blind effects
    if self.run:getBlindType() == "boss" and self.run.current_boss then
        local boss = self.run.current_boss
        if boss.effect then
            boss.effect({event = "deal", cards = new_cards, run = self.run})
        end
    end

    self.hand_area:addCards(new_cards)
end

function RunState:onContinue()
    if self.phase == "blind_won" then
        local reward, interest = self.run:beatBlind()
        -- Don't advance round yet — shop does that via blind_select
        -- But we do need to advance before going to shop so the round counter is right
        self.run:advanceRound()

        if self.run.run_won then
            self.state_manager:switch("game_over", {won = true, run = self.run})
            return
        end

        -- Go to shop, then shop goes to blind_select
        self.state_manager:switch("shop", {run = self.run, run_state = self})
    elseif self.phase == "round_end" and self.run.game_over then
        self.state_manager:switch("game_over", {won = false, run = self.run})
    end
end

function RunState:update(dt)
    local mx, my = love.mouse.getPosition()
    self.hand_area:update(dt)
    self.info_panel:update(dt, self.run)
    self.screen_shake:update(dt)
    self.popups:update(dt)
    self.particles:update(dt)

    -- Update played cards animation
    for _, card in ipairs(self.played_cards) do
        card:update(dt)
    end

    -- Update buttons
    if self.phase == "playing" then
        local selected_count = self.hand_area:getSelectedCount()
        self.btn_play.enabled = selected_count > 0 and selected_count <= MAX_SELECTED and self.run.hands_remaining > 0
        self.btn_discard.enabled = selected_count > 0 and self.run.discards_remaining > 0

        for _, btn in ipairs(self.buttons) do
            btn:update(dt, mx, my)
        end
    elseif self.phase == "blind_won" or (self.phase == "round_end" and self.run.game_over) then
        self.btn_continue:update(dt, mx, my)
    end

    -- Update hand label
    if self.phase == "playing" then
        local selected = self.hand_area:getSelectedCards()
        if #selected > 0 then
            local hand_name = HandEvaluator.evaluate(selected)
            self.hand_label = hand_name or ""
        else
            self.hand_label = ""
        end
    end

    -- Card hover detection
    if self.phase == "playing" then
        local hover_idx, hover_card = self.card_renderer:getCardAt(self.hand_area.cards, mx, my)
        for _, card in ipairs(self.hand_area.cards) do
            card.hovered = false
        end
        if hover_card then
            hover_card.hovered = true
        end
    end
end

function RunState:draw()
    love.graphics.push()
    self.screen_shake:apply()

    -- Background - casino felt
    love.graphics.setColor(0.05, 0.18, 0.08)
    love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

    -- Subtle felt pattern
    love.graphics.setColor(0.06, 0.2, 0.09, 0.5)
    for i = 0, GAME_WIDTH, 20 do
        love.graphics.line(i, 0, i, GAME_HEIGHT)
    end
    for i = 0, GAME_HEIGHT, 20 do
        love.graphics.line(0, i, GAME_WIDTH, i)
    end

    -- Info panel
    self.info_panel:draw(self.run)

    -- Joker area background
    love.graphics.setColor(0.08, 0.12, 0.08)
    love.graphics.rectangle("fill", 210, 10, GAME_WIDTH - 220, 80)
    love.graphics.setColor(0.15, 0.25, 0.15)
    love.graphics.rectangle("line", 210, 10, GAME_WIDTH - 220, 80)

    -- Joker slots
    love.graphics.setColor(0.15, 0.2, 0.15)
    for i = 1, MAX_JOKER_SLOTS do
        local jx = 220 + (i - 1) * (CARD_WIDTH + 15)
        love.graphics.rectangle("line", jx, 18, CARD_WIDTH, 65, 4)
    end

    -- Draw jokers
    for i, joker in ipairs(self.run.jokers) do
        local jx = 220 + (i - 1) * (CARD_WIDTH + 15)
        -- Rarity color
        local rc = {0.3, 0.2, 0.5}
        if joker.rarity == "uncommon" then rc = {0.2, 0.4, 0.3}
        elseif joker.rarity == "rare" then rc = {0.4, 0.2, 0.2}
        elseif joker.rarity == "legendary" then rc = {0.5, 0.4, 0.1} end
        love.graphics.setColor(rc)
        love.graphics.rectangle("fill", jx, 18, CARD_WIDTH, 65, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(joker.name or "?", jx + 2, 28, CARD_WIDTH - 4, "center")
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf(joker.description or "", jx + 2, 44, CARD_WIDTH - 4, "center")
    end

    -- Play area
    love.graphics.setColor(0.07, 0.15, 0.07)
    love.graphics.rectangle("fill", 210, 100, GAME_WIDTH - 220, 340)

    -- Played cards
    for _, card in ipairs(self.played_cards) do
        self.card_renderer:draw(card)
    end

    -- Scoring display
    if self.scoring_display and (self.phase == "scoring" or self.phase == "blind_won") then
        self:drawScoringAnimation()
    end

    -- Hand type label
    if self.hand_label ~= "" and self.phase == "playing" then
        love.graphics.setColor(1, 0.9, 0.3)
        love.graphics.printf(self.hand_label, 340, 435, 700, "center")
    end

    -- Hand cards
    for _, card in ipairs(self.hand_area.cards) do
        self.card_renderer:draw(card)
    end

    -- Buttons
    if self.phase == "playing" then
        for _, btn in ipairs(self.buttons) do
            btn:draw()
        end
    end

    -- Consumable slots
    love.graphics.setColor(0.15, 0.2, 0.15)
    for i = 1, MAX_CONSUMABLE_SLOTS do
        local cx = 900 + (i - 1) * 60
        love.graphics.rectangle("line", cx, 650, 50, 30, 3)
    end
    for i, cons in ipairs(self.run.consumables) do
        local cx = 900 + (i - 1) * 60
        love.graphics.setColor(0.2, 0.4, 0.5)
        love.graphics.rectangle("fill", cx, 650, 50, 30, 3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(cons.name, cx + 1, 657, 48, "center")
    end

    -- Blind won overlay
    if self.phase == "blind_won" then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.printf("BLIND BEATEN!", 0, 300, GAME_WIDTH, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Score: " .. self.run.score .. " / " .. self.run.score_target, 0, 340, GAME_WIDTH, "center")
        self.btn_continue:draw()
    end

    -- Game over overlay
    if self.phase == "round_end" and self.run.game_over then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.printf("GAME OVER", 0, 300, GAME_WIDTH, "center")
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("Reached Ante " .. self.run.ante .. " Round " .. self.run.round, 0, 340, GAME_WIDTH, "center")
        self.btn_continue:draw()
    end

    -- Money display in action bar
    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.print("$" .. self.run.money, 350, 658)

    -- Effects overlay
    self.particles:draw()
    self.popups:draw()

    love.graphics.pop()
end

function RunState:drawScoringAnimation()
    local sa = self.score_anim
    local cx = 210 + (GAME_WIDTH - 220) / 2

    -- Chips display
    love.graphics.setColor(0.3, 0.6, 1, 1)
    love.graphics.printf(math.floor(sa.chips), cx - 150, 140, 100, "right")

    -- X symbol
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("x", cx - 40, 140, 80, "center")

    -- Mult display
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.printf(string.format("%.1f", sa.mult), cx + 50, 140, 100, "left")

    -- Total
    if sa.alpha > 0 then
        love.graphics.setColor(1, 1, 0.3, sa.alpha)
        local scale = 1 + (1 - sa.alpha) * 0.5
        love.graphics.push()
        love.graphics.translate(cx, 170)
        love.graphics.scale(scale, scale)
        love.graphics.printf("= " .. math.floor(sa.total), -100, 0, 200, "center")
        love.graphics.pop()
    end
end

function RunState:keypressed(key)
    if self.phase == "playing" then
        -- Number keys to toggle card selection
        local num = tonumber(key)
        if num and num >= 1 and num <= #self.hand_area.cards then
            local card = self.hand_area.cards[num]
            if card.selected then
                card.selected = false
            elseif self.hand_area:getSelectedCount() < MAX_SELECTED then
                card.selected = true
            end
        end

        if key == "space" or key == "return" then
            self:playHand()
        elseif key == "d" then
            self:discardCards()
        elseif key == "s" then
            self.hand_area:sortByRank()
        end
    elseif key == "return" or key == "space" then
        self:onContinue()
    end
end

function RunState:mousepressed(x, y, button)
    if button ~= 1 then return end

    if self.phase == "playing" then
        -- Check card clicks
        local idx, card = self.card_renderer:getCardAt(self.hand_area.cards, x, y)
        if card then
            if card.selected then
                card.selected = false
            elseif self.hand_area:getSelectedCount() < MAX_SELECTED then
                card.selected = true
            end
        end

        for _, btn in ipairs(self.buttons) do
            btn:mousepressed(x, y, button)
        end
    elseif self.phase == "blind_won" or (self.phase == "round_end" and self.run.game_over) then
        self.btn_continue:mousepressed(x, y, button)
    end
end

function RunState:mousereleased(x, y, button)
    if button ~= 1 then return end
    if self.phase == "playing" then
        for _, btn in ipairs(self.buttons) do
            btn:mousereleased(x, y, button)
        end
    elseif self.phase == "blind_won" or (self.phase == "round_end" and self.run.game_over) then
        self.btn_continue:mousereleased(x, y, button)
    end
end

function RunState:mousemoved(x, y, dx, dy)
end

return RunState
