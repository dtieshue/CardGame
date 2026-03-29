-- Score requirements per ante
local ante_scaling = {
    { small = 300,   big = 450,   boss = 600 },
    { small = 800,   big = 1200,  boss = 1600 },
    { small = 2000,  big = 3000,  boss = 4000 },
    { small = 5000,  big = 7500,  boss = 10000 },
    { small = 11000, big = 16000, boss = 22000 },
    { small = 20000, big = 30000, boss = 40000 },
    { small = 35000, big = 50000, boss = 70000 },
    { small = 50000, big = 75000, boss = 100000 },
}

local boss_blinds = {
    {
        name = "The Hook",
        description = "Discards 2 random cards each hand",
        effect = function(context)
            if context.event == "hand_start" and context.hand_area then
                local cards = context.hand_area.cards
                local to_discard = {}
                for i = 1, math.min(2, #cards) do
                    local idx = love.math.random(1, #cards)
                    table.insert(to_discard, table.remove(cards, idx))
                end
                if context.deck then
                    context.deck:discard(to_discard)
                end
                context.hand_area:layoutCards()
            end
        end,
    },
    {
        name = "The Wall",
        description = "Score requirement is doubled",
        score_mult = 2,
    },
    {
        name = "The Wheel",
        description = "1/7 chance each card is face-down",
        effect = function(context)
            if context.event == "deal" then
                for _, card in ipairs(context.cards or {}) do
                    if love.math.random(1, 7) == 1 then
                        card.face_up = false
                    end
                end
            end
        end,
    },
    {
        name = "The Plant",
        description = "All face cards are debuffed",
        effect = function(context)
            if context.event == "deal" or context.event == "blind_start" then
                for _, card in ipairs(context.cards or {}) do
                    if card:isFaceCard() then
                        card.debuffed = true
                    end
                end
            end
        end,
    },
    {
        name = "The Goad",
        description = "All Spades are debuffed",
        effect = function(context)
            if context.event == "deal" or context.event == "blind_start" then
                for _, card in ipairs(context.cards or {}) do
                    if card.suit == "Spades" then
                        card.debuffed = true
                    end
                end
            end
        end,
    },
    {
        name = "The Water",
        description = "Start with 0 discards",
        effect = function(context)
            if context.event == "blind_start" then
                context.run.discards_remaining = 0
            end
        end,
    },
    {
        name = "The Eye",
        description = "Cannot play the same hand type twice",
        played_hands = {},
        effect = function(context)
            -- Tracked in run state
        end,
    },
    {
        name = "The Psychic",
        description = "Must play exactly 5 cards",
        effect = function(context)
            -- Enforced in play validation
        end,
    },
}

return {
    ante_scaling = ante_scaling,
    boss_blinds = boss_blinds,

    getScoreRequirement = function(ante, blind_type)
        local ante_data = ante_scaling[math.min(ante, #ante_scaling)]
        return ante_data[blind_type] or ante_data.small
    end,

    getRandomBoss = function()
        return boss_blinds[love.math.random(1, #boss_blinds)]
    end,
}
