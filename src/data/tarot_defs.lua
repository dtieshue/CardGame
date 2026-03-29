-- Tarot card definitions (8 minimum)
local tarot_defs = {
    {
        id = "the_fool",
        name = "The Fool",
        description = "Creates a copy of the\nlast Tarot/Planet used",
        cost = 3,
        needs_selection = false,
        max_selected = 0,
        effect = function(ctx)
            -- Creates copy of last used consumable
            if ctx.last_consumable then
                return {create = ctx.last_consumable}
            end
        end,
    },
    {
        id = "the_magician",
        name = "The Magician",
        description = "Enhances 1 selected card\nwith Lucky",
        cost = 3,
        needs_selection = true,
        max_selected = 1,
        effect = function(ctx)
            for _, card in ipairs(ctx.selected_cards or {}) do
                card.enhancement = "Lucky"
            end
        end,
    },
    {
        id = "the_high_priestess",
        name = "High Priestess",
        description = "Creates up to 2\nrandom Planet cards",
        cost = 3,
        needs_selection = false,
        max_selected = 0,
        effect = function(ctx)
            return {create_planets = 2}
        end,
    },
    {
        id = "the_empress",
        name = "The Empress",
        description = "Enhances 2 selected cards\nwith Mult",
        cost = 3,
        needs_selection = true,
        max_selected = 2,
        effect = function(ctx)
            for _, card in ipairs(ctx.selected_cards or {}) do
                card.enhancement = "Mult"
            end
        end,
    },
    {
        id = "the_emperor",
        name = "The Emperor",
        description = "Creates up to 2\nrandom Tarot cards",
        cost = 3,
        needs_selection = false,
        max_selected = 0,
        effect = function(ctx)
            return {create_tarots = 2}
        end,
    },
    {
        id = "the_hierophant",
        name = "The Hierophant",
        description = "Enhances 2 selected cards\nwith Bonus",
        cost = 3,
        needs_selection = true,
        max_selected = 2,
        effect = function(ctx)
            for _, card in ipairs(ctx.selected_cards or {}) do
                card.enhancement = "Bonus"
            end
        end,
    },
    {
        id = "the_lovers",
        name = "The Lovers",
        description = "Enhances 1 selected card\nwith Wild",
        cost = 3,
        needs_selection = true,
        max_selected = 1,
        effect = function(ctx)
            for _, card in ipairs(ctx.selected_cards or {}) do
                card.enhancement = "Wild"
            end
        end,
    },
    {
        id = "the_chariot",
        name = "The Chariot",
        description = "Enhances 1 selected card\nwith Steel",
        cost = 3,
        needs_selection = true,
        max_selected = 1,
        effect = function(ctx)
            for _, card in ipairs(ctx.selected_cards or {}) do
                card.enhancement = "Steel"
            end
        end,
    },
}

return tarot_defs
