local Class = require("lib.class")

local Consumable = Class:extend()

function Consumable:new(def)
    self.id = def.id
    self.name = def.name
    self.description = def.description
    self.cost = def.cost or 3
    self.sell_value = math.floor(self.cost / 2)
    self.card_type = def.card_type or "tarot" -- "tarot" or "planet"
    self.effect = def.effect
    self.needs_selection = def.needs_selection or false
    self.max_selected = def.max_selected or 0
end

return Consumable
