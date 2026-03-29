-- Simple OOP class system
local Class = {}
Class.__index = Class

function Class:new() end

function Class:extend()
    local cls = {}
    cls.__index = cls
    cls.super = self
    setmetatable(cls, {
        __index = self,
        __call = function(c, ...)
            local instance = setmetatable({}, cls)
            if instance.new then
                instance:new(...)
            end
            return instance
        end
    })
    return cls
end

setmetatable(Class, {
    __call = function(c, ...)
        local instance = setmetatable({}, c)
        if instance.new then
            instance:new(...)
        end
        return instance
    end
})

return Class
