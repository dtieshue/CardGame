local Class = require("lib.class")

local Joker = Class:extend()

function Joker:new(def)
    self.id = def.id
    self.name = def.name
    self.description = def.description
    self.rarity = def.rarity or "common"
    self.cost = def.cost or 4
    self.sell_value = math.floor(self.cost / 2)
    self.effect = def.effect
    self.effect_type = def.effect_type or ""

    -- Mutable state for scaling jokers
    self.extra = {}
    if def.extra then
        for k, v in pairs(def.extra) do
            self.extra[k] = v
        end
    end

    -- Visual state
    self.x = 0
    self.y = 0
    self.scale = 1
    self.pulse = 0
end

function Joker:getSellValue()
    return self.sell_value + (self.extra.sell_bonus or 0)
end

return Joker
