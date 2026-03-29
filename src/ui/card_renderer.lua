local Class = require("lib.class")

local CardRenderer = Class:extend()

function CardRenderer:new()
    self.card_width = CARD_WIDTH
    self.card_height = CARD_HEIGHT
    self.corner_radius = 6
    self.rank_font = love.graphics.newFont(16)
    self.small_font = love.graphics.newFont(11)
end

-- Draw a heart shape centered at cx, cy with given size
function CardRenderer:drawHeart(cx, cy, size, mode)
    mode = mode or "fill"
    local pts = {}
    for i = 0, 30 do
        local t = (i / 30) * math.pi * 2
        local x = 16 * math.sin(t)^3
        local y = -(13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t))
        table.insert(pts, cx + x * size / 16)
        table.insert(pts, cy + y * size / 16)
    end
    if #pts >= 6 then
        love.graphics.polygon(mode, pts)
    end
end

-- Draw a diamond shape centered at cx, cy
function CardRenderer:drawDiamond(cx, cy, size, mode)
    mode = mode or "fill"
    love.graphics.polygon(mode,
        cx, cy - size,
        cx + size * 0.6, cy,
        cx, cy + size,
        cx - size * 0.6, cy)
end

-- Draw a club shape centered at cx, cy
function CardRenderer:drawClub(cx, cy, size, mode)
    mode = mode or "fill"
    local r = size * 0.35
    love.graphics.circle(mode, cx, cy - r * 0.5, r)
    love.graphics.circle(mode, cx - r * 0.9, cy + r * 0.3, r)
    love.graphics.circle(mode, cx + r * 0.9, cy + r * 0.3, r)
    -- Stem
    love.graphics.polygon("fill",
        cx - size * 0.08, cy + r * 0.2,
        cx + size * 0.08, cy + r * 0.2,
        cx + size * 0.12, cy + size,
        cx - size * 0.12, cy + size)
end

-- Draw a spade shape centered at cx, cy
function CardRenderer:drawSpade(cx, cy, size, mode)
    mode = mode or "fill"
    -- Upside-down heart shape
    local pts = {}
    for i = 0, 30 do
        local t = (i / 30) * math.pi * 2
        local x = 16 * math.sin(t)^3
        local y = (13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t))
        table.insert(pts, cx + x * size / 18)
        table.insert(pts, cy + y * size / 18 - size * 0.15)
    end
    if #pts >= 6 then
        love.graphics.polygon(mode, pts)
    end
    -- Stem
    love.graphics.polygon("fill",
        cx - size * 0.08, cy + size * 0.3,
        cx + size * 0.08, cy + size * 0.3,
        cx + size * 0.12, cy + size,
        cx - size * 0.12, cy + size)
end

-- Draw a suit symbol at position
function CardRenderer:drawSuit(suit, cx, cy, size)
    if suit == "Hearts" then
        self:drawHeart(cx, cy, size)
    elseif suit == "Diamonds" then
        self:drawDiamond(cx, cy, size)
    elseif suit == "Clubs" then
        self:drawClub(cx, cy, size)
    elseif suit == "Spades" then
        self:drawSpade(cx, cy, size)
    end
end

function CardRenderer:draw(card, x, y, rotation, scale_x, scale_y, alpha)
    x = x or card.x
    y = y or card.y + card.hover_offset
    rotation = rotation or card.rotation
    scale_x = scale_x or card.scale_x
    scale_y = scale_y or card.scale_y
    alpha = alpha or card.alpha

    local w = self.card_width
    local h = self.card_height

    love.graphics.push()
    love.graphics.translate(x + w / 2, y + h / 2)
    love.graphics.rotate(rotation)
    love.graphics.scale(scale_x, scale_y)
    love.graphics.translate(-w / 2, -h / 2)

    if not card.face_up then
        self:drawCardBack(w, h, alpha)
    else
        self:drawCardFace(card, w, h, alpha)
    end

    love.graphics.pop()
end

function CardRenderer:drawCardBack(w, h, alpha)
    -- Card back - dark blue pattern
    love.graphics.setColor(0.15, 0.2, 0.4, alpha)
    love.graphics.rectangle("fill", 0, 0, w, h, self.corner_radius)
    love.graphics.setColor(0.2, 0.3, 0.55, alpha)
    love.graphics.rectangle("fill", 3, 3, w - 6, h - 6, self.corner_radius - 1)

    -- Diamond pattern
    love.graphics.setColor(0.25, 0.35, 0.6, alpha)
    for row = 0, 5 do
        for col = 0, 3 do
            local cx = 8 + col * 16
            local cy = 10 + row * 14
            love.graphics.polygon("fill",
                cx, cy - 4,
                cx + 4, cy,
                cx, cy + 4,
                cx - 4, cy)
        end
    end

    -- Border
    love.graphics.setColor(0.3, 0.4, 0.7, alpha)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", 0, 0, w, h, self.corner_radius)
end

function CardRenderer:drawCardFace(card, w, h, alpha)
    -- Card shadow
    love.graphics.setColor(0, 0, 0, 0.3 * alpha)
    love.graphics.rectangle("fill", 2, 2, w, h, self.corner_radius)

    -- Card background
    if card.selected then
        love.graphics.setColor(0.95, 0.95, 0.8, alpha)
    elseif card.hovered then
        love.graphics.setColor(1, 1, 0.95, alpha)
    else
        love.graphics.setColor(0.95, 0.93, 0.88, alpha)
    end
    love.graphics.rectangle("fill", 0, 0, w, h, self.corner_radius)

    -- Selection highlight border
    if card.selected then
        love.graphics.setColor(0.3, 0.7, 1, alpha)
        love.graphics.setLineWidth(2.5)
        love.graphics.rectangle("line", -1, -1, w + 2, h + 2, self.corner_radius)
    end

    -- Card border
    love.graphics.setColor(0.4, 0.4, 0.4, alpha)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", 0, 0, w, h, self.corner_radius)

    -- Suit color
    local suit_color = SUIT_COLORS[card.suit]
    local r, g, b = suit_color[1], suit_color[2], suit_color[3]

    -- Debuffed overlay
    if card.debuffed then
        r, g, b = 0.4, 0.4, 0.4
    end

    love.graphics.setColor(r, g, b, alpha)

    -- Rank text (top-left)
    local prev_font = love.graphics.getFont()
    love.graphics.setFont(self.rank_font)
    love.graphics.print(card.rank, 5, 2)

    -- Small suit symbol (top-left, below rank)
    self:drawSuit(card.suit, 12, 24, 5)

    -- Bottom-right (rotated)
    love.graphics.push()
    love.graphics.translate(w - 5, h - 2)
    love.graphics.rotate(math.pi)
    love.graphics.print(card.rank, 0, 0)
    love.graphics.pop()
    -- Small suit bottom-right
    self:drawSuit(card.suit, w - 12, h - 24, 5)

    -- Center suit symbol (large)
    love.graphics.setColor(r, g, b, alpha * 0.85)
    self:drawSuit(card.suit, w / 2, h / 2, 14)

    -- Restore font
    love.graphics.setFont(prev_font)

    -- Enhancement indicator
    if card.enhancement then
        love.graphics.setColor(0.3, 0.8, 0.3, alpha)
        love.graphics.circle("fill", w / 2, h - 8, 3)
    end
end

function CardRenderer:getCardAt(cards, mx, my)
    -- Check cards in reverse order (topmost first)
    for i = #cards, 1, -1 do
        local card = cards[i]
        local cx = card.x
        local cy = card.y + card.hover_offset
        if mx >= cx and mx <= cx + self.card_width
           and my >= cy and my <= cy + self.card_height then
            return i, card
        end
    end
    return nil, nil
end

return CardRenderer
