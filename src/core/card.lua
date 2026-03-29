local Class = require("lib.class")

local Card = Class:extend()

function Card:new(suit, rank)
    self.suit = suit
    self.rank = rank
    self.chip_value = RANK_VALUES[rank]
    self.rank_order = RANK_ORDER[rank]

    -- Modifiers (Phase 3+)
    self.enhancement = nil
    self.edition = nil
    self.seal = nil
    self.debuffed = false

    -- Visual state
    self.x = 0
    self.y = 0
    self.target_x = 0
    self.target_y = 0
    self.rotation = 0
    self.target_rotation = 0
    self.scale_x = 1
    self.scale_y = 1
    self.alpha = 1
    self.selected = false
    self.hovered = false
    self.face_up = true

    -- Animation state
    self.hover_offset = 0
    self.select_offset = 0
end

function Card:getChipValue()
    if self.debuffed then return 0 end
    return self.chip_value
end

function Card:isRed()
    return self.suit == "Hearts" or self.suit == "Diamonds"
end

function Card:isFaceCard()
    return self.rank == "J" or self.rank == "Q" or self.rank == "K"
end

function Card:isEven()
    local v = RANK_ORDER[self.rank]
    return v % 2 == 0
end

function Card:isOdd()
    local v = RANK_ORDER[self.rank]
    return v % 2 == 1
end

function Card:getDisplayString()
    return self.rank .. SUIT_SYMBOLS[self.suit]
end

function Card:update(dt)
    -- Smooth movement toward target
    local speed = 12
    self.x = self.x + (self.target_x - self.x) * speed * dt
    self.y = self.y + (self.target_y - self.y) * speed * dt
    self.rotation = self.rotation + (self.target_rotation - self.rotation) * speed * dt

    -- Hover / select offset
    local target_offset = 0
    if self.selected then
        target_offset = -30
    elseif self.hovered then
        target_offset = -15
    end
    self.hover_offset = self.hover_offset + (target_offset - self.hover_offset) * 10 * dt
end

return Card
