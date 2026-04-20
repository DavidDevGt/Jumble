-- common/physics/Movement.lua
-- Lógica básica de movimiento y física

local Movement = {}
local Vector2 = require("common.utils.Vector2")

function Movement:new()
    return {
        velocity = Vector2:new(0, 0),
        acceleration = Vector2:new(0, 0),
        friction = 0.85,
        maxVelocity = 500
    }
end

-- Aplicar input a la aceleración
function Movement:applyInput(inputVector, acceleration)
    self.acceleration = Vector2:new(
        inputVector.x * acceleration,
        inputVector.y * acceleration
    )
end

-- Actualizar velocidad y posición
function Movement:update(position, dt)
    -- Aplicar aceleración a velocidad
    self.velocity.x = self.velocity.x + self.acceleration.x * dt
    self.velocity.y = self.velocity.y + self.acceleration.y * dt
    
    -- Aplicar fricción
    self.velocity.x = self.velocity.x * self.friction
    self.velocity.y = self.velocity.y * self.friction
    
    -- Limitar velocidad máxima
    local mag = self.velocity:magnitude()
    if mag > self.maxVelocity then
        self.velocity = self.velocity:normalize():multiply(self.maxVelocity)
    end
    
    -- Actualizar posición
    position.x = position.x + self.velocity.x * dt
    position.y = position.y + self.velocity.y * dt
    
    return position
end

-- Aplicar gravedad
function Movement:applyGravity(dt, gravity)
    self.acceleration.y = self.acceleration.y + gravity * dt
end

return Movement
