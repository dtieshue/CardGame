-- Shared constants and global state references

GAME_WIDTH = 1280
GAME_HEIGHT = 720

SUITS = {"Hearts", "Diamonds", "Clubs", "Spades"}
SUIT_SYMBOLS = {
    Hearts = "♥",
    Diamonds = "♦",
    Clubs = "♣",
    Spades = "♠",
}
SUIT_COLORS = {
    Hearts = {0.85, 0.1, 0.15},
    Diamonds = {0.85, 0.1, 0.15},
    Clubs = {0.15, 0.15, 0.2},
    Spades = {0.15, 0.15, 0.2},
}

RANKS = {"2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"}
RANK_VALUES = {
    ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6,
    ["7"] = 7, ["8"] = 8, ["9"] = 9, ["10"] = 10,
    ["J"] = 10, ["Q"] = 10, ["K"] = 10, ["A"] = 11,
}
RANK_ORDER = {
    ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6,
    ["7"] = 7, ["8"] = 8, ["9"] = 9, ["10"] = 10,
    ["J"] = 11, ["Q"] = 12, ["K"] = 13, ["A"] = 14,
}

CARD_WIDTH = 71
CARD_HEIGHT = 95
MAX_HAND_SIZE = 8
MAX_SELECTED = 5
MAX_JOKER_SLOTS = 5
MAX_CONSUMABLE_SLOTS = 2

STARTING_MONEY = 4
STARTING_HANDS = 4
STARTING_DISCARDS = 3
