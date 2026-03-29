-- Card animation helpers
local flux = require("lib.flux")

local CardAnimations = {}

function CardAnimations.dealToHand(card, target_x, target_y, delay)
    -- Start from deck position (top-left)
    card.x = 100
    card.y = 50
    card.target_x = target_x
    card.target_y = target_y
end

function CardAnimations.playToCenter(cards, center_x, center_y, on_complete)
    local total_width = #cards * (CARD_WIDTH + 10) - 10
    local start_x = center_x - total_width / 2

    for i, card in ipairs(cards) do
        card.selected = false
        card.target_x = start_x + (i - 1) * (CARD_WIDTH + 10)
        card.target_y = center_y
        card.target_rotation = 0
    end
end

function CardAnimations.discardOffScreen(cards)
    for i, card in ipairs(cards) do
        card.target_x = GAME_WIDTH + 100
        card.target_y = card.y
        card.target_rotation = 0.3
    end
end

return CardAnimations
