-- common/state/ConnectingState.lua
-- Estado de conexión al servidor

local ConnectingState = {}
ConnectingState.__index = ConnectingState

local Logger = require("common.utils.Logger")
local NetworkConfig = require("common.config.NetworkConfig")

function ConnectingState:new()
    local self = setmetatable({}, ConnectingState)
    self.client = nil
    self.connectionStartTime = nil
    self.elapsed = 0
    self.animationCounter = 0
    self.dotCount = 0
    return self
end

function ConnectingState:enter()
    Logger:info("CONNECTING", "Intentando conexión a servidor")
    
    self.client = require("client.network.Client"):new()
    self.connectionStartTime = love.timer.getTime()
    self.elapsed = 0
    self.animationCounter = 0
    self.dotCount = 0
end

function ConnectingState:update(dt)
    self.elapsed = self.elapsed + dt
    self.animationCounter = self.animationCounter + dt
    
    -- Animar puntos
    if self.animationCounter > 0.3 then
        self.dotCount = (self.dotCount % 3) + 1
        self.animationCounter = 0
    end
    
    -- Procesar conexión
    if self.client then
        self.client:update(dt)
        
        -- Verificar si conectó
        if self.client:isConnected() then
            Logger:info("CONNECTING", "Conexión exitosa")
            return "playing"
        end
        
        -- Verificar timeout
        if self.elapsed > NetworkConfig.CONNECTION_TIMEOUT then
            Logger:warn("CONNECTING", "Timeout de conexión")
            return "connection_failed"
        end
    end
end

function ConnectingState:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Título
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("CONECTANDO", 0, h * 0.3, w, "center")
    
    -- Puntos de animación
    love.graphics.setColor(0.2, 1, 0.2)
    local dots = string.rep(".", self.dotCount)
    love.graphics.printf("Conectando" .. dots, 0, h * 0.4, w, "center")
    
    -- Información de servidor
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Servidor: " .. NetworkConfig.SERVER_HOST .. ":" .. NetworkConfig.SERVER_PORT, 
                        0, h * 0.5, w, "center")
    
    -- Tiempo transcurrido
    local elapsedStr = string.format("%.1f segundos", self.elapsed)
    love.graphics.printf(elapsedStr, 0, h * 0.6, w, "center")
    
    -- Instrucciones
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("ESC para cancelar", 0, h - 40, w, "center")
end

function ConnectingState:handleInput(key, scancode, isrepeat)
    if key == "escape" then
        Logger:info("CONNECTING", "Cancelado por usuario")
        if self.client then
            self.client:disconnect()
        end
        return "menu"
    end
end

function ConnectingState:exit()
    Logger:info("CONNECTING", "Saliendo estado de conexión")
    -- Limpiar si fué cancelado
    if self.client and not self.client:isConnected() then
        self.client:disconnect()
    end
end

return ConnectingState
