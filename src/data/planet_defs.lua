-- Planet card definitions (one per hand type)
local hand_types_data = require("src.data.hand_types")

local planet_defs = {
    {id = "mercury", name = "Mercury",  hand = "High Card",      cost = 3},
    {id = "venus",   name = "Venus",    hand = "Pair",           cost = 3},
    {id = "earth",   name = "Earth",    hand = "Two Pair",       cost = 3},
    {id = "mars",    name = "Mars",     hand = "Three of a Kind",cost = 3},
    {id = "jupiter", name = "Jupiter",  hand = "Flush",          cost = 3},
    {id = "saturn",  name = "Saturn",   hand = "Straight",       cost = 3},
    {id = "uranus",  name = "Uranus",   hand = "Full House",     cost = 3},
    {id = "neptune", name = "Neptune",  hand = "Straight Flush", cost = 3},
}

-- Add descriptions and effect
for _, planet in ipairs(planet_defs) do
    planet.description = "Levels up\n" .. planet.hand
    planet.effect = function(ctx)
        local ht = hand_types_data.lookup[planet.hand]
        if ht then
            hand_types_data.levelUp(ht)
        end
    end
end

return planet_defs
