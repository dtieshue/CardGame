local Class = require("lib.class")
local Card = require("src.core.card")

local Deck = Class:extend()

function Deck:new()
    self.cards = {}
    self.draw_pile = {}
    self.discard_pile = {}
    self:buildStandardDeck()
end

function Deck:buildStandardDeck()
    self.cards = {}
    for _, suit in ipairs(SUITS) do
        for _, rank in ipairs(RANKS) do
            table.insert(self.cards, Card(suit, rank))
        end
    end
end

function Deck:resetAndShuffle()
    self.draw_pile = {}
    self.discard_pile = {}
    for _, card in ipairs(self.cards) do
        card.debuffed = false
        table.insert(self.draw_pile, card)
    end
    self:shuffle()
end

function Deck:shuffle()
    local pile = self.draw_pile
    for i = #pile, 2, -1 do
        local j = love.math.random(1, i)
        pile[i], pile[j] = pile[j], pile[i]
    end
end

function Deck:draw(count)
    local drawn = {}
    for i = 1, count do
        if #self.draw_pile == 0 then
            self:reshuffleDiscard()
        end
        if #self.draw_pile > 0 then
            local card = table.remove(self.draw_pile)
            table.insert(drawn, card)
        end
    end
    return drawn
end

function Deck:reshuffleDiscard()
    for _, card in ipairs(self.discard_pile) do
        table.insert(self.draw_pile, card)
    end
    self.discard_pile = {}
    self:shuffle()
end

function Deck:discard(cards)
    for _, card in ipairs(cards) do
        card.selected = false
        table.insert(self.discard_pile, card)
    end
end

function Deck:drawPileCount()
    return #self.draw_pile
end

function Deck:discardPileCount()
    return #self.discard_pile
end

return Deck
