local Class = require("lib.class")

local HandArea = Class:extend()

function HandArea:new()
    self.cards = {}
    self.x = 340
    self.y = 460
    self.width = 700
    self.max_fan_angle = 0.3  -- radians total spread
end

function HandArea:setCards(cards)
    self.cards = cards
    self:layoutCards()
end

function HandArea:addCards(new_cards)
    for _, card in ipairs(new_cards) do
        table.insert(self.cards, card)
    end
    self:layoutCards()
end

function HandArea:removeCards(cards_to_remove)
    local remove_set = {}
    for _, c in ipairs(cards_to_remove) do
        remove_set[c] = true
    end
    local remaining = {}
    for _, c in ipairs(self.cards) do
        if not remove_set[c] then
            table.insert(remaining, c)
        end
    end
    self.cards = remaining
    self:layoutCards()
end

function HandArea:layoutCards()
    local n = #self.cards
    if n == 0 then return end

    local total_width = math.min(self.width, n * (CARD_WIDTH + 8))
    local spacing = total_width / n
    local start_x = self.x + (self.width - total_width) / 2

    local center = (n + 1) / 2

    for i, card in ipairs(self.cards) do
        local t = (i - center) / math.max(n - 1, 1)
        card.target_x = start_x + (i - 1) * spacing
        card.target_y = self.y + math.abs(t) * 20  -- slight arc
        card.target_rotation = t * self.max_fan_angle
        card.face_up = true
    end
end

function HandArea:getSelectedCards()
    local selected = {}
    for _, card in ipairs(self.cards) do
        if card.selected then
            table.insert(selected, card)
        end
    end
    return selected
end

function HandArea:getSelectedCount()
    local count = 0
    for _, card in ipairs(self.cards) do
        if card.selected then count = count + 1 end
    end
    return count
end

function HandArea:clearSelection()
    for _, card in ipairs(self.cards) do
        card.selected = false
    end
end

function HandArea:sortByRank()
    table.sort(self.cards, function(a, b)
        if a.rank_order == b.rank_order then
            return a.suit < b.suit
        end
        return a.rank_order < b.rank_order
    end)
    self:layoutCards()
end

function HandArea:sortBySuit()
    table.sort(self.cards, function(a, b)
        if a.suit == b.suit then
            return a.rank_order < b.rank_order
        end
        return a.suit < b.suit
    end)
    self:layoutCards()
end

function HandArea:update(dt)
    for _, card in ipairs(self.cards) do
        card:update(dt)
    end
end

return HandArea
