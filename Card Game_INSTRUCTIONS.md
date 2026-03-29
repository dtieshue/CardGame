# Balatro-Style Deckbuilder Clone — Claude Code Build Instructions

## Overview

Build a **Balatro-style poker deckbuilder roguelike** using the **LÖVE (Love2D)** framework with **Lua**. The game should capture Balatro's core gameplay loop, retro-arcade visual aesthetic, and satisfying "juice" (animations, screen shake, number popups). This is a mid-polish build — playable core loop with good visuals and feel, but not a fully shipped product.

---

## Tech Stack

- **Engine**: LÖVE 11.4+ (Love2D) — https://love2d.org
- **Language**: Lua 5.1 (LuaJIT bundled with LÖVE)
- **No external dependencies** unless absolutely necessary. Prefer writing systems from scratch over pulling in libraries, with these exceptions:
  - A small class library (e.g., `classic.lua` or a hand-rolled `Class()` function) is fine
  - A tweening library (e.g., `flux` or `timer` from `hump`) is recommended for animations

---

## Project Structure

```
balatro-clone/
├── main.lua                 -- Entry point: love.load, love.update, love.draw, love.keypressed
├── conf.lua                 -- LÖVE config (window size, title, vsync)
├── globals.lua              -- Shared constants and global state references
│
├── lib/                     -- Third-party or utility libraries
│   ├── class.lua            -- Simple OOP class system
│   └── flux.lua             -- Tweening library (or similar)
│
├── src/
│   ├── states/              -- Game state machine
│   │   ├── state_manager.lua
│   │   ├── menu.lua         -- Main menu state
│   │   ├── run.lua          -- Core gameplay state (the "run")
│   │   ├── shop.lua         -- Shop between rounds
│   │   ├── blind_select.lua -- Blind selection screen
│   │   ├── scoring.lua      -- Score animation / resolution state
│   │   └── game_over.lua    -- Run end screen
│   │
│   ├── core/                -- Core game logic (NO rendering code here)
│   │   ├── deck.lua         -- Deck construction, shuffle, draw, discard
│   │   ├── hand_evaluator.lua -- Poker hand detection & ranking
│   │   ├── scoring_engine.lua -- Chips × Mult calculation with Joker pipeline
│   │   ├── card.lua         -- Card data model (suit, rank, enhancements, edition, seal)
│   │   ├── joker.lua        -- Joker data model & effect definitions
│   │   ├── consumable.lua   -- Tarot & Planet card definitions
│   │   ├── blind.lua        -- Blind types, boss effects, score requirements
│   │   └── run_manager.lua  -- Run state: ante, round, money, hands left, discards left
│   │
│   ├── ui/                  -- All rendering and UI components
│   │   ├── card_renderer.lua    -- Draw cards with suits, ranks, enhancements
│   │   ├── hand_area.lua        -- The player's hand (fan of cards at bottom)
│   │   ├── joker_area.lua       -- Joker slots display (top area)
│   │   ├── info_panel.lua       -- Left panel: current blind, score target, hands/discards remaining
│   │   ├── score_display.lua    -- Animated score counter
│   │   ├── shop_ui.lua          -- Shop layout and card buying
│   │   ├── button.lua           -- Reusable button component
│   │   ├── tooltip.lua          -- Hover tooltips for cards and jokers
│   │   └── hud.lua              -- Top bar: money, ante, round info
│   │
│   ├── effects/             -- Visual effects and "juice"
│   │   ├── particles.lua    -- Particle system manager
│   │   ├── screen_shake.lua -- Camera shake effect
│   │   ├── card_animations.lua -- Card flip, slide, fan, hover tilt
│   │   └── number_popup.lua -- Rising damage/score numbers
│   │
│   └── data/                -- Static game data (not code logic)
│       ├── joker_defs.lua   -- Table of all joker definitions
│       ├── tarot_defs.lua   -- Table of all tarot card definitions
│       ├── planet_defs.lua  -- Table of all planet card definitions
│       ├── blind_defs.lua   -- Table of all blind types and boss effects
│       └── hand_types.lua   -- Poker hand type definitions with base chips/mult
│
└── assets/
    ├── images/
    │   ├── cards/           -- Card face sprites (or generate procedurally)
    │   ├── jokers/          -- Joker art (use simple/placeholder pixel art)
    │   ├── ui/              -- Buttons, panels, icons
    │   └── backgrounds/     -- Table felt textures, CRT overlay
    ├── fonts/
    │   └── pixel.ttf        -- A retro pixel font (e.g., Press Start 2P, or similar)
    └── sounds/
        ├── card_play.wav
        ├── card_flip.wav
        ├── chip_score.wav
        ├── mult_trigger.wav
        ├── purchase.wav
        └── ui_click.wav
```

---

## Window & Display Configuration

In `conf.lua`:

```lua
function love.conf(t)
    t.window.title = "Poker Roguelike"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.vsync = 1
    t.window.minwidth = 960
    t.window.minheight = 540
end
```

Use a virtual resolution system internally (e.g., render to a canvas at a fixed resolution like 1280×720 and scale it) so the game looks crisp at any window size.

---

## Core Game Loop & Mechanics

### Run Structure

A run consists of **8 Antes**. Each Ante has **3 Blinds**:
1. **Small Blind** — lowest score requirement, can be skipped for a tag reward
2. **Big Blind** — medium score requirement, can be skipped for a tag reward
3. **Boss Blind** — highest score requirement, has a special negative modifier, CANNOT be skipped

After beating or skipping each blind, the player visits a **Shop**.

### Blind Select Screen

Present three blind options vertically:
- Show the blind name, score requirement, and reward
- Small and Big blinds have a "Skip" button that grants a tag bonus
- Boss blind shows its special effect (e.g., "First hand is debuffed", "All Hearts are debuffed")

### Playing a Hand (Core Gameplay)

1. Player starts each blind with **4 hands** and **3 discards** (configurable)
2. Player is dealt **8 cards** from their deck into their hand
3. Player **selects 1–5 cards** from their hand and either:
   - **Plays** them as a poker hand (uses 1 hand)
   - **Discards** them and draws replacements (uses 1 discard)
4. When a hand is played, the **scoring engine** runs (see below)
5. If cumulative score meets/exceeds the blind's target, the blind is beaten
6. If all hands are used and score is insufficient, the **run ends**

### Scoring Engine (Critical — get this right)

The scoring formula is: **Total Score = Chips × Mult**

Scoring proceeds in this exact pipeline order:

```
1. Determine the poker hand type (highest applicable)
2. Start with the hand type's base Chips and base Mult
3. For each SCORED card (cards that are part of the poker hand):
   a. Add the card's chip value to Chips (A=11, K/Q/J=10, others=face value)
   b. Apply any card enhancements (e.g., +30 chips for Bonus card, +4 mult for Mult card)
4. For each Joker (left to right):
   a. Apply the Joker's effect (may add chips, add mult, multiply mult, or trigger conditionally)
   b. Additive mult Jokers ADD to the running mult total
   c. Multiplicative mult Jokers MULTIPLY the running mult total
5. Final score = final Chips × final Mult
```

**Important**: Joker order matters! Jokers trigger left-to-right, and because some add mult while others multiply mult, their position changes the outcome dramatically. The player should be able to **reorder jokers by dragging**.

### Poker Hand Types & Base Values

Implement these hand types (listed from lowest to highest priority):

| Hand             | Base Chips | Base Mult | Level-up Chips | Level-up Mult |
|------------------|-----------|-----------|----------------|---------------|
| High Card        | 5         | 1         | +10            | +1            |
| Pair             | 10        | 2         | +15            | +1            |
| Two Pair         | 20        | 2         | +20            | +1            |
| Three of a Kind  | 30        | 3         | +20            | +2            |
| Straight         | 30        | 4         | +30            | +3            |
| Flush            | 35        | 4         | +15            | +2            |
| Full House       | 40        | 4         | +25            | +2            |
| Four of a Kind   | 60        | 7         | +30            | +3            |
| Straight Flush   | 100       | 8         | +40            | +4            |
| Royal Flush      | 100       | 8         | +40            | +4            |
| Five of a Kind   | 120       | 12        | +35            | +3            |
| Flush House      | 140       | 14        | +40            | +4            |
| Flush Five       | 160       | 16        | +40            | +4            |

Higher-tier hands always take priority. A hand that qualifies as both Three of a Kind and a Pair is always scored as Three of a Kind.

### Hand Evaluator Logic

The hand evaluator must check hands in descending priority order and return the FIRST match:

```
1. Count occurrences of each rank
2. Check if all cards share a suit (flush)
3. Check for sequential ranks (straight) — Ace can be high (10-J-Q-K-A) or low (A-2-3-4-5)
4. Match against hand types from highest to lowest priority
5. Return: hand_type, list of scored_cards (only cards that contribute)
```

### Card Enhancements, Editions, and Seals

Each playing card can have up to three modifiers:

- **Enhancement** (one of): Bonus (+30 chips), Mult (+4 mult), Wild (counts as any suit), Glass (×2 mult but 1/4 chance to destroy), Steel (+0.5× mult while in hand), Stone (+50 chips, no rank/suit), Gold (+3$ when held at end of round), Lucky (1/5 chance for +20 mult, 1/15 chance for +20$)
- **Edition** (one of): Base (none), Foil (+50 chips), Holographic (+10 mult), Polychrome (×1.5 mult)
- **Seal** (one of): None, Gold (earn $3 on scoring), Red (retrigger this card once), Blue (creates a Planet card), Purple (creates a Tarot card)

### Money & Economy

- Start each run with **$4**
- Earn **$3–5** for beating a blind (scaling with blind type)
- **Interest**: Earn $1 per $5 held, up to $5 max (at $25)
- Earn bonus money for having hands remaining when blind is beaten ($1 per unused hand)
- Cards in the shop cost **$2–$8** depending on rarity
- Jokers cost more ($4–$20)
- Player can sell owned Jokers and consumables for half their buy price

### Shop Phase

After each blind, present a shop with:
- **2 card slots**: Can contain Jokers, Tarot cards, or Planet cards
- **2 booster pack slots**: Packs that let you choose from a set of cards
- **1 voucher slot** (every other ante): Permanent passive upgrades
- A **reroll** button (costs $5, increases by $1 each use per shop visit)
- Buttons to open your **Run Info** (hand level list) and **Deck View** (browse full deck)

---

## Joker System

### Data Structure

Each Joker definition should be a Lua table:

```lua
{
    id = "joker_mult",
    name = "Joker",
    description = "+4 Mult",
    rarity = "common",       -- common, uncommon, rare, legendary
    cost = 4,
    effect_type = "add_mult", -- used for categorization
    -- The effect function receives the full game context
    effect = function(context)
        if context.phase == "scoring" then
            context.mult = context.mult + 4
        end
    end,
}
```

### Implement These Jokers (Starter Set — 20 minimum)

Start with a manageable set that covers the major effect categories:

**Additive Mult Jokers:**
1. Joker — +4 Mult
2. Greedy Joker — +3 Mult for each Diamond scored
3. Lusty Joker — +3 Mult for each Heart scored
4. Wrathful Joker — +3 Mult for each Spade scored
5. Gluttonous Joker — +3 Mult for each Club scored

**Chip Jokers:**
6. Stencil — +Chips equal to number of empty Joker slots × (base hand chips)
7. Banner — +30 Chips for each discard remaining

**Multiplicative Mult Jokers:**
8. Blackboard — ×3 Mult if all held cards are Spades or Clubs
9. The Duo — ×2 Mult if played hand contains a Pair
10. The Trio — ×3 Mult if played hand contains Three of a Kind

**Economy Jokers:**
11. Delayed Gratification — Earn $2 per discard remaining at end of round (if none used)
12. Golden Joker — Earn $4 at end of each round
13. Egg — Gains $3 in sell value each round

**Conditional Jokers:**
14. Scary Face — +30 Chips if played hand has a face card (J, Q, K)
15. Smiley Face — +5 Mult if played hand has a face card
16. Even Steven — +4 Mult for each even-ranked card scored
17. Odd Todd — +30 Chips for each odd-ranked card scored

**Scaling Jokers:**
18. Ice Cream — Starts at +100 Chips, loses 5 every hand played
19. Supernova — +1 Mult for each time the played hand type has been played this run
20. Green Joker — +1 Mult per hand played, -1 Mult per discard used

### Joker Slots

- Default: **5 Joker slots**
- Jokers display in a horizontal row at the top of the play area
- Player must be able to **drag and reorder** jokers (order affects scoring)
- When hovering a joker, show a **tooltip** with its name, description, rarity, and current sell value

---

## Consumables: Tarot & Planet Cards

### Tarot Cards (implement 8 minimum)

Tarot cards are single-use and modify your playing cards:

1. **The Fool** — Creates a copy of the last Tarot/Planet used (excluding The Fool)
2. **The Magician** — Enhances 1 selected card (gives it Lucky enhancement)
3. **The High Priestess** — Creates up to 2 random Planet cards
4. **The Empress** — Enhances 2 selected cards with Mult enhancement
5. **The Emperor** — Creates up to 2 random Tarot cards
6. **The Hierophant** — Enhances 2 selected cards with Bonus enhancement
7. **The Lovers** — Enhances 1 selected card with Wild enhancement
8. **The Chariot** — Enhances 1 selected card with Steel enhancement

### Planet Cards (one per hand type)

Each planet card levels up one hand type, increasing its base chips and mult:

- Mercury → High Card
- Venus → Pair
- Earth → Two Pair
- Mars → Three of a Kind
- Jupiter → Flush
- Saturn → Straight
- Uranus → Full House
- Neptune → Straight Flush
- Pluto → (reserved for secret hands)

### Consumable Slots

- Player has **2 consumable slots**
- Consumables appear in shops and booster packs
- Using a consumable destroys it

---

## Visual Design & Polish

### Art Direction — Retro Arcade Aesthetic

Balatro's look is defined by a few key elements. Replicate these:

1. **CRT screen effect**: Apply a subtle barrel distortion and scanline overlay to the entire screen via a post-processing shader. This is a fullscreen shader applied to the final rendered canvas.

2. **Color palette**: Deep greens and teals for the table background, with vibrant card colors. The background should feel like a casino card table.

3. **Pixelated text**: Use a pixel/bitmap font for ALL game text. No smooth anti-aliased fonts. Try "Press Start 2P" or a similar retro font.

4. **Card design**: Cards should look like stylized playing cards with clear rank and suit indicators. Use bold, saturated colors for suits (red hearts/diamonds, dark spades/clubs). Keep art simple — this isn't about photorealism.

5. **Background**: The play area background should be a dark green felt texture. During boss blinds and special events, the background color and pattern should change dynamically (pulsing, color shifts).

### CRT Shader (GLSL for LÖVE)

Implement a post-processing shader with these effects:
- **Scanlines**: Thin horizontal lines with slight darkening
- **Barrel distortion**: Subtle outward curvature at edges
- **Vignette**: Slight darkening at screen corners
- **Chromatic aberration**: Very subtle RGB channel offset (1-2px)

```glsl
// Example shader structure (implement in a .glsl file or inline string)
extern vec2 screen_size;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    // Barrel distortion
    vec2 centered = tc - 0.5;
    float dist = dot(centered, centered);
    vec2 distorted = tc + centered * dist * 0.05;

    // Scanlines
    float scanline = sin(distorted.y * screen_size.y * 3.14159) * 0.04;

    // Vignette
    float vignette = 1.0 - dist * 0.5;

    vec4 pixel = Texel(tex, distorted);
    pixel.rgb -= scanline;
    pixel.rgb *= vignette;

    return pixel * color;
}
```

### Animation System — "Juice" Is Everything

This is what makes the game FEEL good. Implement all of these:

#### Card Animations
- **Hover**: When the mouse hovers over a card in hand, it rises slightly (translate Y by -15px) and tilts toward the cursor. Use easing (ease-out-back).
- **Selection**: Selected cards rise higher (Y - 30px) and have a bright highlight border.
- **Playing cards**: Selected cards fly from hand to the center "play area" with a smooth arc (use a bezier curve or simple lerp). Stagger each card's arrival by ~80ms.
- **Card flip**: When revealing cards (e.g., in booster packs), cards start face-down and flip over with a scale-X animation (scale X from 1→0→1, swapping the texture at the midpoint).
- **Card fan**: Hand cards should be arranged in a curved fan, not a flat row. Cards slightly overlap and rotate based on their position in the fan.
- **Discard**: Discarded cards slide off-screen to the right with slight rotation and fade.
- **Draw**: New cards slide in from the deck (top-left) to their hand position with staggered timing.

#### Scoring Animations (Most Important!)
This is Balatro's signature feel. When a hand is scored:

1. Cards in the played hand flip face-up one at a time (if not already visible), left to right, with ~150ms delay between each.
2. As each card scores, a **chip value popup** rises from the card (e.g., "+10") with a bounce.
3. The running **Chips counter** on the left panel rapidly ticks up (use a number-rolling animation, not an instant set).
4. When each Joker triggers, it **pulses/bounces** in its slot, and the mult/chip contribution appears as a popup.
5. For multiplicative mult Jokers, the **Mult counter** should have a dramatic scaling effect — the number grows large briefly and settles back, with a screen shake.
6. The final score reveal should be a big, satisfying moment: the Chips and Mult numbers slam together with a "×" symbol, screen shakes, and the total appears with a scale-up-and-settle animation.
7. **Screen shake intensity scales with score magnitude** — a 500-point score gets a small shake, a 50,000-point score gets a big one.

#### UI Animations
- **Buttons**: Scale up slightly on hover (1.05×), press down on click (0.95×). Use ease-out transitions (~0.1s).
- **Panel transitions**: Panels (shop, blind select) should slide in from the side or fade in, not pop instantly.
- **Money changes**: When money changes, show a "+$5" or "-$3" popup near the money counter that rises and fades. The money counter itself should tick to its new value.
- **Number counters**: ALL number changes should animate. Never set a number display instantly — always tween from old value to new value over ~0.3–0.5 seconds.

### Particle Effects

- **Card scoring**: Small burst of particles (stars/sparkles) when a card contributes to scoring
- **Mult triggers**: Larger burst with warm colors (orange/red) when multiplicative mult fires
- **Round win**: Confetti-like particle shower
- **Purchase**: Small coin particle effect

---

## UI Layout Specification

The main gameplay screen has these regions:

```
┌──────────────────────────────────────────────────────┐
│  [Joker 1] [Joker 2] [Joker 3] [Joker 4] [Joker 5] │  ← Joker area (top)
├──────────┬───────────────────────────────────────────┤
│          │                                           │
│  BLIND   │         (played cards appear here)        │  ← Play area (center)
│  INFO    │                                           │
│          │                                           │
│  Target: │                                           │
│  300     ├───────────────────────────────────────────┤
│          │                                           │
│  Score:  │    [card] [card] [card] [card] [card]     │  ← Hand area (bottom)
│  0       │        [card] [card] [card]               │    (curved fan layout)
│          │                                           │
│  Hands:4 ├───────────────────────────────────────────┤
│  Disc: 3 │  [Play Hand]  [Discard]   [Sort]  [$: 7] │  ← Action bar
│          │  [Consumable1] [Consumable2]              │
└──────────┴───────────────────────────────────────────┘
```

### Info Panel (Left Side)
- Current blind name and type
- Score target (e.g., "300")
- Current accumulated score with animated counter
- Hands remaining (with icon)
- Discards remaining (with icon)
- Current Ante and Round number

### Joker Area (Top)
- Horizontal row of joker slots
- Empty slots shown as dotted outlines
- Jokers are draggable for reordering
- Hover shows tooltip with full description

### Hand Area (Bottom Center)
- Cards in a curved fan layout
- Cards are clickable to select/deselect
- Selected cards raise up visually
- Maximum 5 cards can be selected at once
- Show hand type label when valid selection is made (e.g., "Pair" appears above selected cards)

### Action Bar (Bottom)
- "Play Hand" button (highlighted when valid hand selected)
- "Discard" button (active when cards selected and discards remain)
- Sort button (sort hand by rank or by suit)
- Money display
- Consumable slots

---

## Input & Controls

### Mouse (Primary)
- **Click** cards to select/deselect
- **Click** buttons to activate
- **Hover** for tooltips and visual feedback
- **Drag** jokers to reorder them

### Keyboard Shortcuts
- **1–8**: Toggle card selection by position
- **Space** or **Enter**: Play selected hand
- **D**: Discard selected cards
- **S**: Sort hand
- **Escape**: Pause/menu
- **R**: Reroll (in shop)

---

## State Machine

The game flows through these states:

```
MAIN_MENU → BLIND_SELECT → PLAY_HAND ↔ SCORING → SHOP → BLIND_SELECT → ...
                                                              ↓
                                                         GAME_OVER
```

Each state should implement:
```lua
function State:enter(params)  -- Called when entering this state
function State:exit()         -- Called when leaving this state
function State:update(dt)     -- Called every frame
function State:draw()         -- Called every frame
function State:keypressed(key)
function State:mousepressed(x, y, button)
function State:mousereleased(x, y, button)
function State:mousemoved(x, y, dx, dy)
```

Use a simple state stack or state machine manager — no need for a complex framework.

---

## Implementation Order

Build the game in this order, making sure each phase is working and playable before moving to the next:

### Phase 1: Foundation
1. Set up LÖVE project with conf.lua and main.lua
2. Implement the class system and state machine
3. Create the Card data model (rank, suit, chip value)
4. Implement deck creation, shuffle, and draw
5. Render cards on screen (simple rectangles with rank/suit text is fine initially)
6. Implement card selection (click to select, visual feedback)

### Phase 2: Core Gameplay
7. Implement the hand evaluator (detect poker hand types)
8. Implement the scoring engine (Chips × Mult with base values)
9. Create the info panel with score target and current score
10. Implement "Play Hand" action — evaluate, score, accumulate
11. Implement "Discard" action — remove and redraw cards
12. Implement win/lose conditions for a single blind
13. Implement the blind structure (small, big, boss with increasing targets)

### Phase 3: Jokers & Economy
14. Create the Joker data model and slot system
15. Implement the Joker effect pipeline in the scoring engine
16. Add the 20 starter Jokers with their effects
17. Implement the money system (earnings, interest, costs)
18. Build the Shop UI (buy jokers, reroll)
19. Implement consumable cards (Tarot and Planet)
20. Implement hand leveling from Planet cards

### Phase 4: Visual Polish ("Juice")
21. Replace simple rectangles with proper card sprites
22. Implement the card fan layout for the hand
23. Add card hover and selection animations (tween library)
24. Implement the scoring animation sequence (the big one!)
25. Add screen shake system (scaled by score magnitude)
26. Add number popup system (rising score/money indicators)
27. Add particle effects for scoring, mult triggers, round wins
28. Add the CRT post-processing shader

### Phase 5: Menus & Flow
29. Build the main menu screen
30. Build the blind selection screen with skip option
31. Build the game over screen with run stats
32. Build the deck viewer overlay
33. Build the run info overlay (hand levels)
34. Add transitions between states (slides, fades)

### Phase 6: Audio
35. Add sound effects for card play, flip, score tick, purchase, UI clicks
36. Add background music loop (or ambient casino sounds)
37. Tie sound effect pitch/volume to score magnitude for extra juice

---

## Key Technical Notes

### Random Number Generation
- Seed the RNG at the start of each run: `love.math.setRandomSeed(os.time())`
- Use `love.math.random()` for all game randomness (deck shuffling, shop generation, joker effects)

### Delta Time
- ALL animations and movements must use `dt` (delta time) for frame-rate independence
- Never hardcode frame counts — always use time-based calculations

### Save/Load (Optional but Recommended)
- Use `love.filesystem.write()` and `love.filesystem.read()` to save/load run state
- Save format: serialize Lua tables to JSON or a Lua string
- At minimum, save settings (volume, controls) between sessions

### Performance
- Don't create new tables every frame in update/draw loops
- Object pool particles instead of creating/destroying them constantly
- Use sprite batches if drawing many similar sprites (cards)
- Profile with `love.timer.getTime()` if things get slow

### Debugging
- Build a simple debug overlay (toggled with F1) that shows:
  - FPS counter
  - Current state name
  - Number of active particles
  - Current score breakdown (chips, mult, each joker contribution)
- Add a debug console (toggled with `` ` ``) for testing:
  - Add specific jokers
  - Set money amount
  - Skip to specific ante
  - Force specific cards in hand

---

## Boss Blind Effects (Implement 8 minimum)

Boss blinds add challenge with unique negative modifiers:

1. **The Hook** — Discards 2 random cards from hand each turn
2. **The Wall** — Score requirement is doubled
3. **The Wheel** — 1/7 chance for each card to be drawn face-down (unknown until played)
4. **The Plant** — All face cards are debuffed (don't score)
5. **The Goad** — All Spades are debuffed
6. **The Water** — Start with 0 discards this blind
7. **The Eye** — Cannot play the same hand type twice
8. **The Psychic** — Must play exactly 5 cards every hand

---

## Scaling & Balance

The score requirements should scale roughly as follows:

| Ante | Small Blind | Big Blind | Boss Blind |
|------|-------------|-----------|------------|
| 1    | 300         | 450       | 600        |
| 2    | 800         | 1,200     | 1,600      |
| 3    | 2,000       | 3,000     | 4,000      |
| 4    | 5,000       | 7,500     | 10,000     |
| 5    | 11,000      | 16,000    | 22,000     |
| 6    | 20,000      | 30,000    | 40,000     |
| 7    | 35,000      | 50,000    | 70,000     |
| 8    | 50,000      | 75,000    | 100,000    |

These values ensure the player NEEDS joker synergies and hand upgrades to progress — raw poker hands alone won't cut it past Ante 3-4.

---

## What NOT to Build (Scope Cuts)

To keep this manageable, explicitly skip these features:
- ~~Multiple deck types (just use the standard deck)~~ — add later
- ~~Vouchers~~ — complex passive system, add later
- ~~Spectral cards~~ — add later alongside edition system
- ~~Sticker system~~ — endgame feature, add later
- ~~Challenge runs~~ — add later
- ~~Achievements/unlocks~~ — add later
- ~~Online features~~ — not needed
- ~~Controller support~~ — mouse + keyboard only for now

---

## Testing Checklist

Before considering any phase "done," verify:

- [ ] All 13 poker hand types are correctly detected
- [ ] Hands are ranked in correct priority (Four of a Kind beats Flush even if Flush has higher level)
- [ ] Scoring engine matches expected output: hand base + card chips + joker effects, then Chips × Mult
- [ ] Jokers trigger in left-to-right order
- [ ] Additive and multiplicative jokers interact correctly (add first, then multiply)
- [ ] Money calculations are correct (earnings + interest, capped at $5)
- [ ] Cards properly shuffle, draw, discard, and reshuffle
- [ ] Boss blind effects correctly modify gameplay
- [ ] Card enhancements properly affect scoring
- [ ] All animations play smoothly without hitching
- [ ] No crashes when edge cases occur (empty hand, empty deck, max money)

---

## Summary for Claude Code

When working with Claude Code, give it one phase at a time. For each phase:

1. Share this document for context
2. Specify which phase you're working on
3. Ask Claude Code to implement one system at a time (e.g., "Implement the hand evaluator based on the spec in the instructions")
4. Test each piece before moving on
5. If something doesn't work, share the error output with Claude Code

Start with: **"Read the attached instructions document. Set up the LÖVE project foundation (Phase 1, steps 1-6) with the project structure described."**

Good luck, and have fun building it!
