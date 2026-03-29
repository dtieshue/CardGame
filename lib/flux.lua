-- flux.lua - lightweight tweening library
-- Based on rxi/flux (MIT License)

local flux = { _version = "0.1.0" }
flux.__index = flux

local tweens = {}

local easing = {
    linear = function(t) return t end,
    quadIn = function(t) return t * t end,
    quadOut = function(t) return t * (2 - t) end,
    quadInOut = function(t)
        if t < 0.5 then return 2 * t * t end
        return -1 + (4 - 2 * t) * t
    end,
    cubicIn = function(t) return t * t * t end,
    cubicOut = function(t) return (t - 1)^3 + 1 end,
    cubicInOut = function(t)
        if t < 0.5 then return 4 * t * t * t end
        return (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
    end,
    backOut = function(t)
        local s = 1.70158
        t = t - 1
        return t * t * ((s + 1) * t + s) + 1
    end,
    backIn = function(t)
        local s = 1.70158
        return t * t * ((s + 1) * t - s)
    end,
    elasticOut = function(t)
        if t == 0 or t == 1 then return t end
        return 2^(-10 * t) * math.sin((t - 0.075) * (2 * math.pi) / 0.3) + 1
    end,
}

local Tween = {}
Tween.__index = Tween

function Tween:new(obj, duration, target)
    local self = setmetatable({}, Tween)
    self.obj = obj
    self.duration = duration
    self.target = target
    self.start_vals = {}
    self.time = 0
    self.ease_func = easing.quadOut
    self.on_complete = nil
    self.delay_time = 0
    self.stopped = false

    for k, v in pairs(target) do
        self.start_vals[k] = obj[k]
    end

    return self
end

function Tween:ease(name)
    self.ease_func = easing[name] or easing.quadOut
    return self
end

function Tween:oncomplete(fn)
    self.on_complete = fn
    return self
end

function Tween:delay(d)
    self.delay_time = d
    return self
end

function Tween:stop()
    self.stopped = true
    return self
end

function Tween:update(dt)
    if self.stopped then return true end

    if self.delay_time > 0 then
        self.delay_time = self.delay_time - dt
        return false
    end

    self.time = self.time + dt
    local t = math.min(self.time / self.duration, 1)
    local eased = self.ease_func(t)

    for k, target_val in pairs(self.target) do
        local start = self.start_vals[k]
        self.obj[k] = start + (target_val - start) * eased
    end

    if t >= 1 then
        if self.on_complete then self.on_complete() end
        return true
    end
    return false
end

function flux.to(obj, duration, target)
    local tween = Tween:new(obj, duration, target)
    table.insert(tweens, tween)
    return tween
end

function flux.update(dt)
    for i = #tweens, 1, -1 do
        if tweens[i]:update(dt) then
            table.remove(tweens, i)
        end
    end
end

function flux.clear()
    tweens = {}
end

flux.easing = easing

return flux
