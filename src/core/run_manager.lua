local Class = require("lib.class")
local Deck = require("src.core.deck")
local blind_defs = require("src.data.blind_defs")
local hand_types_data = require("src.data.hand_types")

local RunManager = Class:extend()

function RunManager:new()
    self:reset()
end

function RunManager:reset()
    self.ante = 1
    self.round = 1 -- 1=small, 2=big, 3=boss
    self.money = STARTING_MONEY
    self.hands_remaining = STARTING_HANDS
    self.discards_remaining = STARTING_DISCARDS
    self.score = 0
    self.score_target = 0
    self.deck = Deck()
    self.jokers = {}
    self.consumables = {}
    self.current_boss = nil
    self.hands_played_this_blind = {}
    self.game_over = false
    self.run_won = false

    hand_types_data.resetAll()
end

function RunManager:getBlindType()
    if self.round == 1 then return "small"
    elseif self.round == 2 then return "big"
    else return "boss"
    end
end

function RunManager:getBlindName()
    local bt = self:getBlindType()
    if bt == "boss" and self.current_boss then
        return self.current_boss.name
    end
    if bt == "small" then return "Small Blind" end
    if bt == "big" then return "Big Blind" end
    return "Boss Blind"
end

function RunManager:startBlind()
    local blind_type = self:getBlindType()
    self.score = 0
    self.hands_remaining = STARTING_HANDS
    self.discards_remaining = STARTING_DISCARDS
    self.hands_played_this_blind = {}

    -- Get score target
    self.score_target = blind_defs.getScoreRequirement(self.ante, blind_type)

    -- Boss blind setup
    if blind_type == "boss" then
        if not self.current_boss then
            self.current_boss = blind_defs.getRandomBoss()
        end
        -- Apply boss score multiplier
        if self.current_boss.score_mult then
            self.score_target = self.score_target * self.current_boss.score_mult
        end
        -- Apply blind start effects
        if self.current_boss.effect then
            self.current_boss.effect({
                event = "blind_start",
                run = self,
            })
        end
    end

    self.deck:resetAndShuffle()
end

function RunManager:addScore(amount)
    self.score = self.score + amount
end

function RunManager:useHand()
    self.hands_remaining = self.hands_remaining - 1
end

function RunManager:useDiscard()
    self.discards_remaining = self.discards_remaining - 1
end

function RunManager:isBlindBeaten()
    return self.score >= self.score_target
end

function RunManager:isRunOver()
    return self.hands_remaining <= 0 and not self:isBlindBeaten()
end

function RunManager:beatBlind()
    -- Money rewards
    local blind_type = self:getBlindType()
    local reward = 3
    if blind_type == "big" then reward = 4
    elseif blind_type == "boss" then reward = 5 end

    -- Bonus for unused hands
    reward = reward + self.hands_remaining

    -- Interest: $1 per $5 held, capped at $5
    local interest = math.min(math.floor(self.money / 5), 5)
    reward = reward + interest

    self.money = self.money + reward

    return reward, interest
end

function RunManager:advanceRound()
    self.round = self.round + 1
    if self.round > 3 then
        self.round = 1
        self.ante = self.ante + 1
        self.current_boss = nil
        if self.ante > 8 then
            self.run_won = true
        end
    end
    if self.round == 3 then
        self.current_boss = blind_defs.getRandomBoss()
    end
end

function RunManager:canAddJoker()
    return #self.jokers < MAX_JOKER_SLOTS
end

function RunManager:addJoker(joker)
    if self:canAddJoker() then
        table.insert(self.jokers, joker)
        return true
    end
    return false
end

function RunManager:removeJoker(index)
    local joker = table.remove(self.jokers, index)
    if joker then
        self.money = self.money + math.floor((joker.cost or 4) / 2)
    end
    return joker
end

function RunManager:canAfford(cost)
    return self.money >= cost
end

function RunManager:spend(amount)
    self.money = self.money - amount
end

return RunManager
