-- 20 starter joker definitions

local joker_defs = {
    -- ADDITIVE MULT JOKERS
    {
        id = "joker",
        name = "Joker",
        description = "+4 Mult",
        rarity = "common",
        cost = 4,
        effect_type = "add_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                ctx.mult = ctx.mult + 4
            end
        end,
    },
    {
        id = "greedy_joker",
        name = "Greedy Joker",
        description = "+3 Mult for each\nDiamond scored",
        rarity = "common",
        cost = 5,
        effect_type = "add_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                for _, card in ipairs(ctx.scored_cards) do
                    if card.suit == "Diamonds" then
                        ctx.mult = ctx.mult + 3
                    end
                end
            end
        end,
    },
    {
        id = "lusty_joker",
        name = "Lusty Joker",
        description = "+3 Mult for each\nHeart scored",
        rarity = "common",
        cost = 5,
        effect_type = "add_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                for _, card in ipairs(ctx.scored_cards) do
                    if card.suit == "Hearts" then
                        ctx.mult = ctx.mult + 3
                    end
                end
            end
        end,
    },
    {
        id = "wrathful_joker",
        name = "Wrathful Joker",
        description = "+3 Mult for each\nSpade scored",
        rarity = "common",
        cost = 5,
        effect_type = "add_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                for _, card in ipairs(ctx.scored_cards) do
                    if card.suit == "Spades" then
                        ctx.mult = ctx.mult + 3
                    end
                end
            end
        end,
    },
    {
        id = "gluttonous_joker",
        name = "Gluttonous Joker",
        description = "+3 Mult for each\nClub scored",
        rarity = "common",
        cost = 5,
        effect_type = "add_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                for _, card in ipairs(ctx.scored_cards) do
                    if card.suit == "Clubs" then
                        ctx.mult = ctx.mult + 3
                    end
                end
            end
        end,
    },

    -- CHIP JOKERS
    {
        id = "banner",
        name = "Banner",
        description = "+30 Chips for each\ndiscard remaining",
        rarity = "common",
        cost = 5,
        effect_type = "add_chips",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                ctx.chips = ctx.chips + 30 * (ctx.discards_remaining or 0)
            end
        end,
    },
    {
        id = "stencil",
        name = "Stencil",
        description = "+Chips equal to empty\nJoker slots × hand chips",
        rarity = "uncommon",
        cost = 7,
        effect_type = "add_chips",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                local empty = MAX_JOKER_SLOTS - #(ctx.jokers or {})
                if empty > 0 then
                    ctx.chips = ctx.chips + empty * ctx.chips
                end
            end
        end,
    },

    -- MULTIPLICATIVE MULT JOKERS
    {
        id = "blackboard",
        name = "Blackboard",
        description = "×3 Mult if all held\ncards are Spades or Clubs",
        rarity = "uncommon",
        cost = 6,
        effect_type = "mult_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                local all_dark = true
                for _, card in ipairs(ctx.held_cards or {}) do
                    if card.suit ~= "Spades" and card.suit ~= "Clubs" then
                        all_dark = false
                        break
                    end
                end
                if all_dark and #(ctx.held_cards or {}) > 0 then
                    ctx.mult = ctx.mult * 3
                end
            end
        end,
    },
    {
        id = "the_duo",
        name = "The Duo",
        description = "×2 Mult if hand\ncontains a Pair",
        rarity = "rare",
        cost = 8,
        effect_type = "mult_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                local n = ctx.hand_name
                if n == "Pair" or n == "Two Pair" or n == "Full House"
                   or n == "Flush House" or n == "Four of a Kind"
                   or n == "Five of a Kind" or n == "Flush Five" then
                    ctx.mult = ctx.mult * 2
                end
            end
        end,
    },
    {
        id = "the_trio",
        name = "The Trio",
        description = "×3 Mult if hand contains\nThree of a Kind",
        rarity = "rare",
        cost = 8,
        effect_type = "mult_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                local n = ctx.hand_name
                if n == "Three of a Kind" or n == "Full House"
                   or n == "Flush House" or n == "Four of a Kind"
                   or n == "Five of a Kind" or n == "Flush Five" then
                    ctx.mult = ctx.mult * 3
                end
            end
        end,
    },

    -- ECONOMY JOKERS
    {
        id = "delayed_gratification",
        name = "Delayed Grat.",
        description = "Earn $2 per discard\nremaining at end of round\n(if none used)",
        rarity = "common",
        cost = 4,
        effect_type = "economy",
        effect = function(ctx)
            if ctx.phase == "round_end" then
                if ctx.discards_used == 0 then
                    ctx.money = (ctx.money or 0) + 2 * (ctx.discards_remaining or 0)
                end
            end
        end,
    },
    {
        id = "golden_joker",
        name = "Golden Joker",
        description = "Earn $4 at end\nof each round",
        rarity = "common",
        cost = 6,
        effect_type = "economy",
        effect = function(ctx)
            if ctx.phase == "round_end" then
                ctx.money = (ctx.money or 0) + 4
            end
        end,
    },
    {
        id = "egg",
        name = "Egg",
        description = "Gains $3 in sell\nvalue each round",
        rarity = "common",
        cost = 4,
        extra = {sell_bonus = 0},
        effect_type = "economy",
        effect = function(ctx)
            if ctx.phase == "round_end" then
                -- sell_bonus tracked on joker.extra
            end
        end,
    },

    -- CONDITIONAL JOKERS
    {
        id = "scary_face",
        name = "Scary Face",
        description = "+30 Chips if hand\nhas a face card",
        rarity = "common",
        cost = 4,
        effect_type = "add_chips",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                for _, card in ipairs(ctx.scored_cards) do
                    if card:isFaceCard() then
                        ctx.chips = ctx.chips + 30
                        return
                    end
                end
            end
        end,
    },
    {
        id = "smiley_face",
        name = "Smiley Face",
        description = "+5 Mult if hand\nhas a face card",
        rarity = "common",
        cost = 4,
        effect_type = "add_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                for _, card in ipairs(ctx.scored_cards) do
                    if card:isFaceCard() then
                        ctx.mult = ctx.mult + 5
                        return
                    end
                end
            end
        end,
    },
    {
        id = "even_steven",
        name = "Even Steven",
        description = "+4 Mult for each\neven-ranked card scored",
        rarity = "common",
        cost = 4,
        effect_type = "add_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                for _, card in ipairs(ctx.scored_cards) do
                    if card:isEven() then
                        ctx.mult = ctx.mult + 4
                    end
                end
            end
        end,
    },
    {
        id = "odd_todd",
        name = "Odd Todd",
        description = "+30 Chips for each\nodd-ranked card scored",
        rarity = "common",
        cost = 4,
        effect_type = "add_chips",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                for _, card in ipairs(ctx.scored_cards) do
                    if card:isOdd() then
                        ctx.chips = ctx.chips + 30
                    end
                end
            end
        end,
    },

    -- SCALING JOKERS
    {
        id = "ice_cream",
        name = "Ice Cream",
        description = "Starts at +100 Chips,\nloses 5 every hand",
        rarity = "common",
        cost = 5,
        extra = {chips = 100},
        effect_type = "add_chips",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                ctx.chips = ctx.chips + (ctx.joker_extra.chips or 0)
                ctx.joker_extra.chips = math.max(0, (ctx.joker_extra.chips or 0) - 5)
            end
        end,
    },
    {
        id = "supernova",
        name = "Supernova",
        description = "+1 Mult for each time\nhand type was played\nthis run",
        rarity = "common",
        cost = 5,
        effect_type = "add_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                local ht = ctx.hand_type
                if ht then
                    ctx.mult = ctx.mult + (ht.played_count or 0)
                end
            end
        end,
    },
    {
        id = "green_joker",
        name = "Green Joker",
        description = "+1 Mult per hand played,\n-1 Mult per discard used",
        rarity = "common",
        cost = 4,
        extra = {mult = 0},
        effect_type = "add_mult",
        effect = function(ctx)
            if ctx.phase == "scoring" then
                ctx.mult = ctx.mult + math.max(0, ctx.joker_extra.mult or 0)
                ctx.joker_extra.mult = (ctx.joker_extra.mult or 0) + 1
            elseif ctx.phase == "discard" then
                ctx.joker_extra.mult = (ctx.joker_extra.mult or 0) - 1
            end
        end,
    },
}

return joker_defs
