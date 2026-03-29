-- Poker Roguelike - A Balatro-style Deckbuilder
-- Entry point

require("globals")
local flux = require("lib.flux")
local StateManager = require("src.states.state_manager")
local Menu = require("src.states.menu")
local RunState = require("src.states.run")
local Shop = require("src.states.shop")
local BlindSelect = require("src.states.blind_select")
local GameOver = require("src.states.game_over")

local state_manager
local canvas
local crt_shader
local show_debug = false
local crt_enabled = true

-- CRT Post-processing shader
local crt_shader_code = [[
extern vec2 screen_size;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    // Barrel distortion
    vec2 centered = tc - 0.5;
    float dist = dot(centered, centered);
    vec2 distorted = tc + centered * dist * 0.04;

    // Clamp to avoid sampling outside texture
    if (distorted.x < 0.0 || distorted.x > 1.0 || distorted.y < 0.0 || distorted.y > 1.0) {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }

    // Chromatic aberration
    float aberration = 0.001;
    float r = Texel(tex, distorted + vec2(aberration, 0.0)).r;
    float g = Texel(tex, distorted).g;
    float b = Texel(tex, distorted - vec2(aberration, 0.0)).b;

    vec3 pixel = vec3(r, g, b);

    // Scanlines
    float scanline = sin(distorted.y * screen_size.y * 3.14159) * 0.04;
    pixel -= scanline;

    // Vignette
    float vignette = 1.0 - dist * 0.6;
    pixel *= vignette;

    // Slight brightness boost to compensate
    pixel *= 1.05;

    return vec4(pixel, 1.0) * color;
}
]]

function love.load()
    love.math.setRandomSeed(os.time())

    -- Use nearest-neighbor filtering for crisp pixel art look
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Create render canvas for virtual resolution
    canvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)

    -- Create CRT shader
    local ok, shader = pcall(love.graphics.newShader, crt_shader_code)
    if ok then
        crt_shader = shader
        crt_shader:send("screen_size", {GAME_WIDTH, GAME_HEIGHT})
    else
        print("CRT shader failed to compile, running without it")
        crt_enabled = false
    end

    -- Set up default font
    local font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    -- Initialize state manager
    state_manager = StateManager()
    state_manager:register("menu", Menu(state_manager))
    state_manager:register("run", RunState(state_manager))
    state_manager:register("shop", Shop(state_manager))
    state_manager:register("blind_select", BlindSelect(state_manager))
    state_manager:register("game_over", GameOver(state_manager))
    state_manager:switch("menu")
end

function love.update(dt)
    -- Cap dt to avoid spiral of death
    dt = math.min(dt, 1 / 30)
    flux.update(dt)
    state_manager:update(dt)
end

function love.draw()
    -- Render to canvas at virtual resolution
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)
    state_manager:draw()

    -- Debug overlay
    if show_debug then
        drawDebug()
    end

    love.graphics.setCanvas()

    -- Draw canvas scaled to window with CRT shader
    local ww, wh = love.graphics.getDimensions()
    local scale = math.min(ww / GAME_WIDTH, wh / GAME_HEIGHT)
    local ox = (ww - GAME_WIDTH * scale) / 2
    local oy = (wh - GAME_HEIGHT * scale) / 2

    love.graphics.setColor(1, 1, 1)
    if crt_enabled and crt_shader then
        love.graphics.setShader(crt_shader)
    end
    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
    if crt_enabled and crt_shader then
        love.graphics.setShader()
    end
end

function love.keypressed(key)
    if key == "f1" then
        show_debug = not show_debug
        return
    end
    if key == "f2" then
        crt_enabled = not crt_enabled
        return
    end
    if key == "escape" then
        if state_manager.current_name ~= "menu" then
            state_manager:switch("menu")
            return
        end
    end
    state_manager:keypressed(key)
end

function love.mousepressed(x, y, button)
    x, y = screenToGame(x, y)
    state_manager:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    x, y = screenToGame(x, y)
    state_manager:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    x, y = screenToGame(x, y)
    state_manager:mousemoved(x, y, dx, dy)
end

-- Transform screen coordinates to game (virtual) coordinates
function screenToGame(sx, sy)
    local ww, wh = love.graphics.getDimensions()
    local scale = math.min(ww / GAME_WIDTH, wh / GAME_HEIGHT)
    local ox = (ww - GAME_WIDTH * scale) / 2
    local oy = (wh - GAME_HEIGHT * scale) / 2
    return (sx - ox) / scale, (sy - oy) / scale
end

-- Override love.mouse.getPosition to return game coordinates
local original_getPosition = love.mouse.getPosition
love.mouse.getPosition = function()
    local sx, sy = original_getPosition()
    return screenToGame(sx, sy)
end

function drawDebug()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", GAME_WIDTH - 220, 0, 220, 100)
    love.graphics.setColor(0, 1, 0)
    love.graphics.print("FPS: " .. love.timer.getFPS(), GAME_WIDTH - 210, 5)
    love.graphics.print("State: " .. (state_manager.current_name or "none"), GAME_WIDTH - 210, 20)
    love.graphics.print("Memory: " .. string.format("%.1f MB", collectgarbage("count") / 1024), GAME_WIDTH - 210, 35)
    love.graphics.print("F1: Debug | F2: CRT", GAME_WIDTH - 210, 50)
    love.graphics.print("CRT: " .. (crt_enabled and "ON" or "OFF"), GAME_WIDTH - 210, 65)
end
