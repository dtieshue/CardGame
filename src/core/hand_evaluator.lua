-- Hand evaluator: detects poker hand types and returns scored cards
-- Checks from highest priority to lowest, returns first match

local hand_types_data = require("src.data.hand_types")

local HandEvaluator = {}

-- Helper: count occurrences of each rank
local function countRanks(cards)
    local counts = {}
    for _, card in ipairs(cards) do
        local r = card.rank
        counts[r] = (counts[r] or 0) + 1
    end
    return counts
end

-- Helper: check if all cards share a suit
local function isFlush(cards)
    if #cards < 5 then return false end
    local suit = cards[1].suit
    for i = 2, #cards do
        -- Wild cards count as any suit
        if cards[i].enhancement ~= "Wild" and cards[i].suit ~= suit then
            return false
        end
    end
    return true
end

-- Helper: check if cards form a straight
local function isStraight(cards)
    if #cards < 5 then return false end

    local orders = {}
    for _, card in ipairs(cards) do
        table.insert(orders, card.rank_order)
    end
    table.sort(orders)

    -- Remove duplicates
    local unique = {orders[1]}
    for i = 2, #orders do
        if orders[i] ~= orders[i - 1] then
            table.insert(unique, orders[i])
        end
    end

    if #unique < 5 then return false end

    -- Check sequential (highest 5)
    local top5 = {}
    for i = #unique - 4, #unique do
        table.insert(top5, unique[i])
    end
    local sequential = true
    for i = 2, 5 do
        if top5[i] - top5[i - 1] ~= 1 then
            sequential = false
            break
        end
    end
    if sequential then return true end

    -- Check Ace-low straight (A-2-3-4-5)
    -- Ace = 14, so check for {2,3,4,5,14}
    local has_ace = false
    local low_set = {}
    for _, v in ipairs(unique) do
        if v == 14 then has_ace = true end
        if v >= 2 and v <= 5 then low_set[v] = true end
    end
    if has_ace and low_set[2] and low_set[3] and low_set[4] and low_set[5] then
        return true, true -- second return = ace_low
    end

    return false
end

-- Helper: check if it's a royal straight (10-J-Q-K-A)
local function isRoyal(cards)
    local orders = {}
    for _, card in ipairs(cards) do
        orders[card.rank_order] = true
    end
    return orders[10] and orders[11] and orders[12] and orders[13] and orders[14]
end

-- Helper: get groups by count
local function getGroups(rank_counts)
    local groups = {}
    for rank, count in pairs(rank_counts) do
        if not groups[count] then groups[count] = {} end
        table.insert(groups[count], rank)
    end
    return groups
end

-- Helper: get cards matching specific ranks
local function getCardsWithRanks(cards, ranks)
    local rank_set = {}
    for _, r in ipairs(ranks) do rank_set[r] = true end
    local result = {}
    for _, card in ipairs(cards) do
        if rank_set[card.rank] then
            table.insert(result, card)
        end
    end
    return result
end

-- Helper: get the highest single card
local function getHighCard(cards)
    local best = cards[1]
    for i = 2, #cards do
        if cards[i].rank_order > best.rank_order then
            best = cards[i]
        end
    end
    return {best}
end

-- Main evaluation function
-- Returns: hand_type_name, scored_cards
function HandEvaluator.evaluate(cards)
    if #cards == 0 then
        return nil, {}
    end

    local rank_counts = countRanks(cards)
    local groups = getGroups(rank_counts)
    local flush = isFlush(cards)
    local straight, ace_low = isStraight(cards)

    -- Check from highest priority to lowest

    -- Flush Five: 5 cards of same rank AND same suit
    if #cards == 5 and groups[5] then
        if flush then
            return "Flush Five", cards
        end
    end

    -- Flush House: Full house + all same suit
    if #cards == 5 and flush and groups[3] and groups[2] then
        return "Flush House", cards
    end

    -- Five of a Kind
    if groups[5] then
        return "Five of a Kind", getCardsWithRanks(cards, groups[5])
    end

    -- Royal Flush
    if #cards == 5 and flush and straight and isRoyal(cards) then
        return "Royal Flush", cards
    end

    -- Straight Flush
    if #cards == 5 and flush and straight then
        return "Straight Flush", cards
    end

    -- Four of a Kind
    if groups[4] then
        return "Four of a Kind", getCardsWithRanks(cards, groups[4])
    end

    -- Full House
    if groups[3] and groups[2] then
        local scored = getCardsWithRanks(cards, groups[3])
        for _, c in ipairs(getCardsWithRanks(cards, groups[2])) do
            table.insert(scored, c)
        end
        return "Full House", scored
    end

    -- Flush
    if flush then
        return "Flush", cards
    end

    -- Straight
    if straight then
        return "Straight", cards
    end

    -- Three of a Kind
    if groups[3] then
        return "Three of a Kind", getCardsWithRanks(cards, groups[3])
    end

    -- Two Pair
    if groups[2] and #groups[2] >= 2 then
        -- Take top two pairs by rank order
        table.sort(groups[2], function(a, b)
            return RANK_ORDER[a] > RANK_ORDER[b]
        end)
        local top_two = {groups[2][1], groups[2][2]}
        return "Two Pair", getCardsWithRanks(cards, top_two)
    end

    -- Pair
    if groups[2] and #groups[2] == 1 then
        return "Pair", getCardsWithRanks(cards, groups[2])
    end

    -- High Card
    return "High Card", getHighCard(cards)
end

-- Get the hand type data for a given hand name
function HandEvaluator.getHandType(name)
    return hand_types_data.lookup[name]
end

return HandEvaluator
