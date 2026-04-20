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
    
    return self
end

function InputManager:update(dt)
    self.lastInputTime = self.lastInputTime + dt
    
    -- Leer input
    local inputX = 0
    local inputY = 0
    
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        inputY = inputY - 1
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        inputY = inputY + 1
    end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        inputX = inputX - 1
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        inputX = inputX + 1
    end
    
    self.currentInput = Vector2:new(inputX, inputY)
    
    -- Normalizar si es diagonal
    if self.currentInput:magnitude() > 1 then
        self.currentInput = self.currentInput:normalize()
    end
end

function InputManager:getInput()
    return self.currentInput:clone()
end

function InputManager:shouldSendInput()
    if self.lastInputTime >= self.inputRateLimit then
        self.lastInputTime = 0
        return true
    end
    return false
end

return InputManager
