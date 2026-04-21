-- client/network/InputManager.lua
-- Gestor de entrada del usuario

local InputManager = {}
InputManager.__index = InputManager

local Vector2 = require("common.utils.Vector2")
local NetworkConfig = require("common.config.NetworkConfig")

function InputManager:new()
    local self = setmetatable({}, InputManager)
    
    self.currentInput = Vector2:new(0, 0)
    self.lastInputTime = 0
    self.inputRateLimit = 1 / NetworkConfig.INPUT_RATE_LIMIT
    
    -- Input como botones (más compacto para red)
    self.inputState = {
        left = false,
        right = false,
        up = false,
        down = false,
        jump = false,
        escape = false
    }
    self.lastInputState = {}
    
    return self
end

function InputManager:update(dt)
    self.lastInputTime = self.lastInputTime + dt
    
    -- Leer input como booleanos
    self.inputState.left = love.keyboard.isDown("a") or love.keyboard.isDown("left")
    self.inputState.right = love.keyboard.isDown("d") or love.keyboard.isDown("right")
    self.inputState.up = love.keyboard.isDown("w") or love.keyboard.isDown("up")
    self.inputState.down = love.keyboard.isDown("s") or love.keyboard.isDown("down")
    self.inputState.jump = love.keyboard.isDown("space") or love.keyboard.isDown("w") or love.keyboard.isDown("up")
    
    -- Calcular vector para movimiento local (opcional)
    local inputX = 0
    local inputY = 0
    
    if self.inputState.left then inputX = inputX - 1 end
    if self.inputState.right then inputX = inputX + 1 end
    if self.inputState.up then inputY = inputY - 1 end
    if self.inputState.down then inputY = inputY + 1 end
    
    self.currentInput = Vector2:new(inputX, inputY)
    
    -- Normalizar si es diagonal
    if self.currentInput:magnitude() > 1 then
        self.currentInput = self.currentInput:normalize()
    end
end

function InputManager:getInput()
    return self.currentInput:clone()
end

-- Retorna estructura compacta para red
function InputManager:getNetworkInput()
    return {
        x = self.currentInput.x,
        y = self.currentInput.y,
        jump = self.inputState.jump
    }
end

function InputManager:shouldSendInput()
    -- Siempre enviar si hubo cambio en input
    if self:hasInputChanged() then
        self.lastInputTime = 0
        self:saveInputState()
        return true
    end
    
    -- O si pasó el tiempo máximo
    if self.lastInputTime >= self.inputRateLimit then
        self.lastInputTime = 0
        return true
    end
    
    return false
end

function InputManager:hasInputChanged()
    return self.inputState.left ~= (self.lastInputState.left or false)
        or self.inputState.right ~= (self.lastInputState.right or false)
        or self.inputState.up ~= (self.lastInputState.up or false)
        or self.inputState.down ~= (self.lastInputState.down or false)
        or self.inputState.jump ~= (self.lastInputState.jump or false)
end

function InputManager:saveInputState()
    self.lastInputState = {
        left = self.inputState.left,
        right = self.inputState.right,
        up = self.inputState.up,
        down = self.inputState.down,
        jump = self.inputState.jump
    }
end

return InputManager
