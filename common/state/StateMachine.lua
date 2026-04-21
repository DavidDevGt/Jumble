-- common/state/StateMachine.lua
-- Máquina de estados genérica, reutilizable para cliente/servidor
-- Maneja transiciones, cleanup, y validación de estados

local StateMachine = {}
StateMachine.__index = StateMachine

local Logger = require("common.utils.Logger")

--- Crear nueva máquina de estados
-- @param initialState string - Estado inicial (debe existir en stateClasses)
-- @param stateClasses table - Mapa de {stateName = StateClass, ...}
-- @return StateMachine - Instancia de máquina de estados
function StateMachine:new(initialState, stateClasses)
    assert(type(initialState) == "string", "initialState must be string")
    assert(type(stateClasses) == "table", "stateClasses must be table")
    assert(stateClasses[initialState], "Unknown initial state: " .. initialState)
    
    local self = setmetatable({}, StateMachine)
    
    self.currentState = initialState
    self.stateClasses = stateClasses
    self.currentStateInstance = nil
    self.previousState = nil
    self.history = {}  -- Para debugging
    self.maxHistorySize = 20
    
    -- Entrar en estado inicial
    self:transition(initialState)
    
    return self
end

--- Transicionar a un nuevo estado
-- @param newState string - Nombre del nuevo estado
-- @param args table - Argumentos para pasar a enter()
-- @return boolean - true si transición fue exitosa
function StateMachine:transition(newState, args)
    -- Validar que el estado existe
    if not self.stateClasses[newState] then
        error("Invalid state: " .. newState)
    end
    
    -- No transicionar a mismo estado
    if newState == self.currentState and self.currentStateInstance then
        Logger:debug("STATE", "Already in state: " .. newState)
        return false
    end
    
    -- Registrar en historial
    local previousState = self.currentState
    table.insert(self.history, {
        from = previousState,
        to = newState,
        timestamp = love.timer.getTime()
    })
    
    -- Mantener historial manejable
    if #self.history > self.maxHistorySize then
        table.remove(self.history, 1)
    end
    
    -- Exit del estado anterior
    if self.currentStateInstance and self.currentStateInstance.exit then
        local exitSuccess, exitErr = pcall(function()
            self.currentStateInstance:exit()
        end)
        if not exitSuccess then
            Logger:error("STATE", "Error in exit() for state " .. previousState .. ": " .. tostring(exitErr))
        end
    end
    
    -- Cambiar estado
    self.previousState = previousState
    self.currentState = newState
    self.currentStateInstance = self.stateClasses[newState]:new()
    
    Logger:info("STATE", "Transitioned: " .. previousState .. " → " .. newState)
    
    -- Enter del nuevo estado
    if self.currentStateInstance and self.currentStateInstance.enter then
        local enterSuccess, enterErr = pcall(function()
            if args then
                self.currentStateInstance:enter(args)
            else
                self.currentStateInstance:enter()
            end
        end)
        if not enterSuccess then
            Logger:error("STATE", "Error in enter() for state " .. newState .. ": " .. tostring(enterErr))
            -- Si enter() falla, intentar volver al estado anterior
            if previousState then
                self:transition(previousState)
            end
            return false
        end
    end
    
    return true
end

--- Actualizar estado actual
-- @param dt number - Delta time en segundos
-- @return string|nil - Nuevo estado si la transición es solicitada, nil si no
function StateMachine:update(dt)
    if not self.currentStateInstance then return end
    
    if self.currentStateInstance.update then
        local success, result = pcall(function()
            return self.currentStateInstance:update(dt)
        end)
        
        if not success then
            Logger:error("STATE", "Error in update() for state " .. self.currentState .. ": " .. tostring(result))
            return nil
        end
        
        -- Si update() retorna un estado, transicionar
        if type(result) == "string" then
            self:transition(result)
            return result
        end
        
        return result
    end
end

--- Dibujar estado actual
function StateMachine:draw()
    if not self.currentStateInstance then return end
    
    if self.currentStateInstance.draw then
        local success, err = pcall(function()
            self.currentStateInstance:draw()
        end)
        
        if not success then
            Logger:error("STATE", "Error in draw() for state " .. self.currentState .. ": " .. tostring(err))
        end
    end
end

--- Manejar input (keypressed)
-- @param key string - Tecla presionada
-- @param scancode string - Scancode
-- @param isrepeat boolean - Si es repetición
-- @return string|nil - Nuevo estado si la transición es solicitada
function StateMachine:handleInput(key, scancode, isrepeat)
    if not self.currentStateInstance then return end
    
    if self.currentStateInstance.handleInput then
        local success, result = pcall(function()
            return self.currentStateInstance:handleInput(key, scancode, isrepeat)
        end)
        
        if not success then
            Logger:error("STATE", "Error in handleInput() for state " .. self.currentState .. ": " .. tostring(result))
            return nil
        end
        
        if type(result) == "string" then
            self:transition(result)
            return result
        end
        
        return result
    end
end

--- Manejar evento genérico (para mousepressed, filedropped, etc.)
-- @param eventName string - Nombre del evento (mousepressed, etc.)
-- @param args table - Argumentos del evento
-- @return string|nil - Nuevo estado
function StateMachine:handleEvent(eventName, args)
    if not self.currentStateInstance then return end
    
    local handlerName = "handle" .. eventName:sub(1, 1):upper() .. eventName:sub(2)
    
    if self.currentStateInstance[handlerName] then
        local success, result = pcall(function()
            if args then
                return self.currentStateInstance[handlerName](self.currentStateInstance, args)
            else
                return self.currentStateInstance[handlerName](self.currentStateInstance)
            end
        end)
        
        if not success then
            Logger:error("STATE", "Error in " .. handlerName .. "() for state " .. self.currentState .. ": " .. tostring(result))
            return nil
        end
        
        if type(result) == "string" then
            self:transition(result)
            return result
        end
        
        return result
    end
end

--- Obtener estado actual
-- @return string - Nombre del estado actual
function StateMachine:getCurrentState()
    return self.currentState
end

--- Obtener estado anterior
-- @return string|nil - Nombre del estado anterior
function StateMachine:getPreviousState()
    return self.previousState
end

--- Obtener instancia del estado actual (para acceso directo a propiedades)
-- @return table - Instancia del estado actual
function StateMachine:getCurrentStateInstance()
    return self.currentStateInstance
end

--- Obtener historial de transiciones (para debugging)
-- @return table - Lista de transiciones con timestamps
function StateMachine:getHistory()
    return self.history
end

--- Verificar si está en un estado específico
-- @param stateName string - Nombre del estado
-- @return boolean
function StateMachine:isInState(stateName)
    return self.currentState == stateName
end

--- Reset a estado inicial
-- @param initialState string - Estado a resetear
function StateMachine:reset(initialState)
    self.history = {}
    self.previousState = nil
    self:transition(initialState)
end

return StateMachine
