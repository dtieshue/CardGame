-- Poker hand type definitions with base chips/mult and level-up values
-- Priority order: higher index = higher priority

local hand_types = {
    {
        name = "High Card",
        base_chips = 5,
        base_mult = 1,
        level_chips = 10,
        level_mult = 1,
        level = 1,
        played_count = 0,
    },
    {
        name = "Pair",
        base_chips = 10,
        base_mult = 2,
        level_chips = 15,
        level_mult = 1,
        level = 1,
        played_count = 0,
    },
    {
        name = "Two Pair",
        base_chips = 20,
        base_mult = 2,
        level_chips = 20,
        level_mult = 1,
        level = 1,
        played_count = 0,
    },
    {
        name = "Three of a Kind",
        base_chips = 30,
        base_mult = 3,
        level_chips = 20,
        level_mult = 2,
        level = 1,
        played_count = 0,
    },
    {
        name = "Straight",
        base_chips = 30,
        base_mult = 4,
        level_chips = 30,
        level_mult = 3,
        level = 1,
        played_count = 0,
    },
    {
        name = "Flush",
        base_chips = 35,
        base_mult = 4,
        level_chips = 15,
        level_mult = 2,
        level = 1,
        played_count = 0,
    },
    {
        name = "Full House",
        base_chips = 40,
        base_mult = 4,
        level_chips = 25,
        level_mult = 2,
        level = 1,
        played_count = 0,
    },
    {
        name = "Four of a Kind",
        base_chips = 60,
        base_mult = 7,
        level_chips = 30,
        level_mult = 3,
        level = 1,
        played_count = 0,
    },
    {
        name = "Straight Flush",
        base_chips = 100,
        base_mult = 8,
        level_chips = 40,
        level_mult = 4,
        level = 1,
        played_count = 0,
    },
    {
        name = "Royal Flush",
        base_chips = 100,
        base_mult = 8,
        level_chips = 40,
        level_mult = 4,
        level = 1,
        played_count = 0,
    },
    {
        name = "Five of a Kind",
        base_chips = 120,
        base_mult = 12,
        level_chips = 35,
        level_mult = 3,
        level = 1,
        played_count = 0,
    },
    {
        name = "Flush House",
        base_chips = 140,
        base_mult = 14,
        level_chips = 40,
        level_mult = 4,
        level = 1,
        played_count = 0,
    },
    {
        name = "Flush Five",
        base_chips = 160,
        base_mult = 16,
        level_chips = 40,
        level_mult = 4,
        level = 1,
        played_count = 0,
    },
}

-- Build a lookup by name
local hand_type_lookup = {}
for i, ht in ipairs(hand_types) do
    ht.priority = i
    hand_type_lookup[ht.name] = ht
end

return {
    types = hand_types,
    lookup = hand_type_lookup,

    getChips = function(ht)
        return ht.base_chips + (ht.level - 1) * ht.level_chips
    end,

    getMult = function(ht)
        return ht.base_mult + (ht.level - 1) * ht.level_mult
    end,

    levelUp = function(ht)
        ht.level = ht.level + 1
    end,

    resetAll = function()
        for _, ht in ipairs(hand_types) do
            ht.level = 1
            ht.played_count = 0
        end
    end,
}
