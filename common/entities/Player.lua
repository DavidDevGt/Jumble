-- common/entities/Player.lua
-- Entidad jugador compartida

local Player = {}
Player.__index = Player

local Vector2 = require("common.utils.Vector2")
local GameConfig = require("common.config.GameConfig")

function Player:new(id, name, x, y)
    local self = setmetatable({}, Player)
    
    self.id = id
    self.name = name
    self.position = Vector2:new(x or 0, y or 0)
    self.velocity = Vector2:new(0, 0)
    self.width = GameConfig.PLAYER_WIDTH
    self.height = GameConfig.PLAYER_HEIGHT
    
    -- Estado
    self.isAlive = true
    self.health = 100
    self.state = "idle"  -- idle, running, jumping
    
    -- Control
    self.inputVector = Vector2:new(0, 0)
    self.isGrounded = false
    
    return self
end

function Player:update(dt, gravity)
    if not self.isAlive then return end
    
    -- Aplicar gravedad
    self.velocity.y = self.velocity.y + gravity * dt
    
    -- Aplicar input
    self.velocity.x = self.inputVector.x * GameConfig.PLAYER_SPEED
    
    -- Aplicar velocidad a posición
    self.position.x = self.position.x + self.velocity.x * dt
    self.position.y = self.position.y + self.velocity.y * dt
    
    -- Actualizar estado
    if self.isGrounded and self.inputVector:magnitude() > 0 then
        self.state = "running"
    elseif not self.isGrounded then
        self.state = "jumping"
    else
        self.state = "idle"
    end
end

function Player:getBox()
    return {
        x = self.position.x - self.width / 2,
        y = self.position.y - self.height / 2,
        width = self.width,
        height = self.height
    }
end

function Player:setInput(inputVector)
    self.inputVector = inputVector:clone()
end

function Player:takeDamage(amount)
    self.health = math.max(0, self.health - amount)
    if self.health <= 0 then
        self.isAlive = false
    end
end

function Player:respawn(x, y)
    self.position = Vector2:new(x, y)
    self.velocity = Vector2:new(0, 0)
    self.health = 100
    self.isAlive = true
    self.state = "idle"
end

-- Solo datos mínimos para red (no enviar objeto completo)
function Player:getNetworkState()
    return {
        id = self.id,
        x = math.floor(self.position.x),        -- integer
        y = math.floor(self.position.y),        -- integer
        vx = math.floor(self.velocity.x),    -- integer
        vy = math.floor(self.velocity.y),      -- integer
        state = self.state                    -- enumstring
    }
end

-- Estados para red (enum)
Player.NETWORK_STATES = {
    IDLE = 0,
    RUNNING = 1,
    JUMPING = 2,
    FALLING = 3,
    DEAD = 4
}

function Player:getNetworkStateEnum()
    return Player.NETWORK_STATES[self:state()] or 0
end

return Player
