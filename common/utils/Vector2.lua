-- common/utils/Vector2.lua
-- Helper para vectores 2D

local Vector2 = {}
Vector2.__index = Vector2

function Vector2:new(x, y)
    return setmetatable({x = x or 0, y = y or 0}, Vector2)
end

function Vector2:add(other)
    return Vector2:new(self.x + other.x, self.y + other.y)
end

function Vector2:subtract(other)
    return Vector2:new(self.x - other.x, self.y - other.y)
end

function Vector2:multiply(scalar)
    return Vector2:new(self.x * scalar, self.y * scalar)
end

function Vector2:divide(scalar)
    return Vector2:new(self.x / scalar, self.y / scalar)
end

function Vector2:magnitude()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vector2:normalize()
    local mag = self:magnitude()
    if mag == 0 then return Vector2:new(0, 0) end
    return self:divide(mag)
end

function Vector2:dot(other)
    return self.x * other.x + self.y * other.y
end

function Vector2:distance(other)
    return self:subtract(other):magnitude()
end

function Vector2:lerp(other, t)
    return Vector2:new(
        self.x + (other.x - self.x) * t,
        self.y + (other.y - self.y) * t
    )
end

function Vector2:clone()
    return Vector2:new(self.x, self.y)
end

function Vector2:x()
    return self.x
end

function Vector2:y()
    return self.y
end

function Vector2:__tostring()
    return string.format("Vector2(%.1f, %.1f)", self.x, self.y)
end

return Vector2
