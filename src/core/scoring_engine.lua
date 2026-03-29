-- Scoring engine: Chips × Mult with Joker pipeline
local hand_types_data = require("src.data.hand_types")
local HandEvaluator = require("src.core.hand_evaluator")

local ScoringEngine = {}

-- Score a played hand
-- cards: the cards played
-- jokers: ordered list of joker objects (left to right)
-- context: {hands_remaining, discards_remaining, held_cards, ...}
-- Returns: total_score, breakdown table
function ScoringEngine.score(cards, jokers, context)
    jokers = jokers or {}
    context = context or {}

    -- Step 1: Determine hand type
    local hand_name, scored_cards = HandEvaluator.evaluate(cards)
    if not hand_name then
        return 0, {hand_name = "Nothing", chips = 0, mult = 0, scored_cards = {}}
    end

    local hand_type = hand_types_data.lookup[hand_name]

    -- Step 2: Base chips and mult from hand type (including level)
    local chips = hand_types_data.getChips(hand_type)
    local mult = hand_types_data.getMult(hand_type)

    -- Build a set of scored cards for quick lookup
    local scored_set = {}
    for _, c in ipairs(scored_cards) do
        scored_set[c] = true
    end

    -- Step 3: Add chip values from scored cards + card enhancements
    local card_details = {}
    for _, card in ipairs(scored_cards) do
        if not card.debuffed then
            local card_chips = card:getChipValue()
            chips = chips + card_chips

            -- Card enhancement effects
            if card.enhancement == "Bonus" then
                chips = chips + 30
            elseif card.enhancement == "Mult" then
                mult = mult + 4
            elseif card.enhancement == "Stone" then
                chips = chips + 50
            end

            -- Card edition effects
            if card.edition == "Foil" then
                chips = chips + 50
            elseif card.edition == "Holographic" then
                mult = mult + 10
            elseif card.edition == "Polychrome" then
                mult = mult * 1.5
            end

            table.insert(card_details, {
                card = card,
                chip_value = card_chips,
            })
        end
    end

    -- Step 4: Joker pipeline (left to right)
    local joker_details = {}
    for _, joker in ipairs(jokers) do
        local before_chips = chips
        local before_mult = mult

        if joker.effect then
            local joker_context = {
                phase = "scoring",
                chips = chips,
                mult = mult,
                played_cards = cards,
                scored_cards = scored_cards,
                hand_name = hand_name,
                hand_type = hand_type,
                jokers = jokers,
                hands_remaining = context.hands_remaining or 0,
                discards_remaining = context.discards_remaining or 0,
                held_cards = context.held_cards or {},
                joker_extra = joker.extra or {},
            }
            joker.effect(joker_context)
            chips = joker_context.chips
            mult = joker_context.mult
        end

        table.insert(joker_details, {
            joker = joker,
            chips_added = chips - before_chips,
            mult_added = mult - before_mult,
        })
    end

    -- Step 5: Final score
    local total = math.floor(chips * mult)

    -- Track hand played count
    hand_type.played_count = hand_type.played_count + 1

    return total, {
        hand_name = hand_name,
        chips = chips,
        mult = mult,
        scored_cards = card_details,
        joker_details = joker_details,
        total = total,
    }
end

return ScoringEngine
