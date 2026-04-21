-- common/state/PlayingState.lua
-- Estado de juego en progreso

local PlayingState = {}
PlayingState.__index = PlayingState

local Logger = require("common.utils.Logger")
local GameConfig = require("common.config.GameConfig")

function PlayingState:new()
    local self = setmetatable({}, PlayingState)
    self.gameTime = 0
    self.client = nil
    self.inputManager = nil
    self.renderer = nil
    self.paused = false
    self.player = nil
    return self
end

function PlayingState:enter()
    Logger:info("PLAYING", "Entrando al estado de juego")
    
    -- Obtener referencia del cliente (asumiendo que está disponible globalmente)
    self.client = _G.client
    self.inputManager = _G.inputManager
    self.renderer = _G.renderer
    
    if not self.client or not self.client:isConnected() then
        Logger:warn("PLAYING", "Cliente no conectado, volviendo a menu")
        return "menu"
    end
    
    self.gameTime = 0
    self.paused = false
    
    Logger:info("PLAYING", "Juego iniciado")
end

function PlayingState:update(dt)
    -- Limitar dt para evitar jumps
    dt = math.min(dt, 0.05)
    
    if not self.paused then
        self.gameTime = self.gameTime + dt
        
        -- Procesar input
        if self.inputManager then
            self.inputManager:update(dt)
        end
        
        -- Actualizar cliente (network)
        if self.client then
            self.client:update(dt)
            
            -- Verificar desconexión
            if not self.client:isConnected() then
                Logger:warn("PLAYING", "Cliente desconectado")
                return "disconnected"
            end
        end
    end
end

function PlayingState:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Fondo
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Renderizar mundo de juego
    if self.renderer then
        self.renderer:draw()
    else
        -- Fallback si no hay renderer
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("Esperando renderer...", 0, h/2, w, "center")
    end
    
    -- HUD - Esquina superior izquierda
    love.graphics.setColor(0.3, 1, 0.3)
    love.graphics.print("TIEMPO: " .. string.format("%.1f", self.gameTime), 10, 10)
    
    -- HUD - Esquina superior derecha
    if self.client then
        local status = self.client:isConnected() and "CONECTADO" or "DESCONECTADO"
        love.graphics.setColor(self.client:isConnected() and {0.3, 1, 0.3} or {1, 0.3, 0.3})
        love.graphics.printf(status, w - 150, 10, 140, "right")
    end
    
    -- Pause overlay
    if self.paused then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("PAUSADO", 0, h/2 - 20, w, "center")
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("P para reanudar | ESC para menú", 0, h/2 + 20, w, "center")
    end
end

function PlayingState:handleInput(key, scancode, isrepeat)
    -- Teclas globales
    if key == "escape" then
        Logger:info("PLAYING", "Retornando al menú")
        return "menu"
    elseif key == "p" then
        self.paused = not self.paused
        Logger:info("PLAYING", self.paused and "PAUSADO" or "REANUDADO")
    end
    
    -- Input del juego (si no está pausado)
    if not self.paused and self.inputManager then
        self.inputManager:handleInput(key)
    end
end

function PlayingState:exit()
    Logger:info("PLAYING", "Saliendo del estado de juego")
    -- No desconectar aquí, dejar que el siguiente estado maneje
end

return PlayingState
