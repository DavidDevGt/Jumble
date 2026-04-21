-- client/network/Client.lua
-- Gestor de conexión del cliente con error handling robusto

local Client = {}
Client.__index = Client

local MessageTypes = require("common.protocol.MessageTypes")
local NetworkConfig = require("common.config.NetworkConfig")
local Logger = require("common.utils.Logger")

-- Cargar bitser para serialización compacta
local bitser = require("libs.bitser")

-- Estados de conexión
Client.STATE_IDLE = "idle"
Client.STATE_CONNECTING = "connecting"
Client.STATE_CONNECTED = "connected"
Client.STATE_FAILED = "failed"
Client.STATE_DISCONNECTED = "disconnected"

function Client:new()
    local self = setmetatable({}, Client)
    
    -- Conexión
    self.connected = false
    self.clientId = nil
    self.socket = nil
    self.serverHost = NetworkConfig.SERVER_HOST
    self.serverPort = NetworkConfig.SERVER_PORT
    
    -- Estado de conexión (para error handling)
    self.connectionState = self.STATE_IDLE
    self.connectionAttempts = 0
    self.maxConnectionAttempts = 3
    self.connectionStartTime = nil
    self.retryDelay = 1  -- Exponential backoff
    self.lastAttemptTime = 0
    self.errorMessage = nil
    
    -- Heartbeat / keep-alive
    self.lastHeartbeatTime = 0
    self.heartbeatInterval = NetworkConfig.HEARTBEAT_INTERVAL or 5
    self.heartbeatTimeout = 10  -- segundos
    
    -- Buffer de datos
    self.entityStates = {}
    self.pendingInputs = {}
    
    return self
end

--- Obtener estado actual de conexión
-- @return string - Estado (idle, connecting, connected, failed, disconnected)
function Client:getConnectionState()
    return self.connectionState
end

--- Obtener mensaje de error (si falla conexión)
-- @return string|nil - Mensaje de error
function Client:getErrorMessage()
    return self.errorMessage
end

--- Obtener número de intentos de conexión
-- @return number
function Client:getConnectionAttempts()
    return self.connectionAttempts
end

--- Cambiar estado de conexión con logging
-- @param newState string - Nuevo estado
-- @param errorMsg string - Mensaje de error (si aplica)
local function setConnectionState(self, newState, errorMsg)
    if newState == self.connectionState then return end
    
    self.connectionState = newState
    self.errorMessage = errorMsg
    
    if newState == self.STATE_CONNECTED then
        Logger:info("CLIENT", "✓ Conectado exitosamente")
        self.connected = true
    elseif newState == self.STATE_FAILED then
        Logger:error("CLIENT", "✗ Conexión fallida: " .. tostring(errorMsg))
        self.connected = false
        -- Preparar para reintentar con backoff
        self.retryDelay = math.min(self.retryDelay * 2, 10)  -- Max 10s backoff
    elseif newState == self.STATE_DISCONNECTED then
        Logger:warn("CLIENT", "⚠ Desconectado: " .. tostring(errorMsg))
        self.connected = false
    elseif newState == self.STATE_CONNECTING then
        Logger:debug("CLIENT", "→ Conectando (intento " .. self.connectionAttempts .. "/" .. 
                              self.maxConnectionAttempts .. ")")
    end
end

--- Conectar al servidor (con reintentos y backoff exponencial)
function Client:connect()
    -- Si ya está conectado, no hacer nada
    if self.connectionState == self.STATE_CONNECTED then return end
    
    -- Si falló permanentemente, no reintentar
    if self.connectionState == self.STATE_FAILED then return end
    
    local currentTime = love.timer.getTime()
    
    -- Si ya estamos intentando, esperar a que se complete
    if self.connectionState == self.STATE_CONNECTING then
        local elapsed = currentTime - self.connectionStartTime
        
        if elapsed > NetworkConfig.CONNECTION_TIMEOUT then
            -- Timeout en este intento
            Logger:warn("CLIENT", "Timeout en intento " .. self.connectionAttempts)
            self.socket = nil
            self.connectionState = self.STATE_IDLE  -- Permitir reintentar
        end
        
        return
    end
    
    -- Esperar backoff entre intentos
    if currentTime - self.lastAttemptTime < self.retryDelay then
        return
    end
    
    -- Iniciar nuevo intento
    self.connectionAttempts = self.connectionAttempts + 1
    
    if self.connectionAttempts > self.maxConnectionAttempts then
        setConnectionState(self, self.STATE_FAILED, 
            "Max connection attempts exceeded (" .. self.maxConnectionAttempts .. ")")
        return
    end
    
    -- Cambiar a estado "conectando"
    setConnectionState(self, self.STATE_CONNECTING)
    self.connectionStartTime = currentTime
    self.lastAttemptTime = currentTime
    
    -- Crear socket
    if not self.socket then
        local success, err = pcall(function()
            self.socket = require("sock").newClient(self.serverHost, self.serverPort)
            if self.socket then
                self.socket:setTimeout(0)
            end
        end)
        
        if not success then
            Logger:error("CLIENT", "Failed to create socket: " .. tostring(err))
            self.connectionState = self.STATE_IDLE
            return
        end
        
        if not self.socket then
            Logger:error("CLIENT", "Socket creation returned nil")
            self.connectionState = self.STATE_IDLE
            return
        end
    end
    
    -- Enviar CONNECT packet
    local connectPacket = {
        type = MessageTypes.CONNECT,
        version = 1,  -- Protocol version
        timestamp = currentTime
    }
    
    local success, err = pcall(function()
        self.socket:send(bitser.serialize(connectPacket))
    end)
    
    if not success then
        Logger:warn("CLIENT", "Failed to send CONNECT: " .. tostring(err))
        self.socket = nil
        self.connectionState = self.STATE_IDLE
        return
    end
    
    Logger:debug("CLIENT", "CONNECT packet sent to " .. self.serverHost .. ":" .. self.serverPort)
end

function Client:isConnected()
    return self.connected
end

--- Procesar update de conexión
-- @param dt number - Delta time
function Client:update(dt)
    -- Si no está conectado, intentar conectar
    if not self.connected then
        self:connect()
        return
    end
    
    if not self.socket then return end
    
    -- Procesar paquetes recibidos
    local success, data = pcall(function()
        return self.socket:receive()
    end)
    
    if success and data then
        local ok, packet = pcall(bitser.deserialize, data)
        if ok and packet then
            self:handlePacket(packet)
        else
            Logger:warn("CLIENT", "Failed to deserialize packet")
        end
    end
    
    -- Enviar heartbeat cada 5 segundos
    self.lastHeartbeatTime = self.lastHeartbeatTime + dt
    if self.lastHeartbeatTime > self.heartbeatInterval then
        self:sendHeartbeat()
        self.lastHeartbeatTime = 0
    end
    
    -- Reenviar inputs pendientes si es necesario
    self:resendPendingInputs()
end

--- Enviar heartbeat/ping
function Client:sendHeartbeat()
    if not self.connected or not self.socket then return end
    
    local packet = {
        type = MessageTypes.PING,
        clientId = self.clientId,
        timestamp = love.timer.getTime()
    }
    
    local success, err = pcall(function()
        self.socket:send(bitser.serialize(packet))
    end)
    
    if not success then
        Logger:warn("CLIENT", "Failed to send heartbeat: " .. tostring(err))
        setConnectionState(self, self.STATE_DISCONNECTED, "Heartbeat failed: " .. tostring(err))
    end
end

function Client:sendInput(input)
    if not self.connected or not self.socket then return end
    
    local packet = {
        type = MessageTypes.INPUT,
        clientId = self.clientId,
        input = input,
        timestamp = love.timer.getTime()
    }
    
    local success, err = pcall(function()
        self.socket:send(bitser.serialize(packet))
    end)
    
    if not success then
        Logger:warn("CLIENT", "Failed to send input: " .. tostring(err))
    end
end

function Client:handlePacket(data)
    local msgType = data.type or data[1]
    
    if msgType == MessageTypes.CONNECT_RESPONSE then
        self:handleConnectResponse(data)
    elseif msgType == MessageTypes.STATE_UPDATE then
        self:handleStateUpdate(data)
    elseif msgType == MessageTypes.PONG then
        -- Actualizar latencia
        if data.timestamp then
            local latency = (love.timer.getTime() - data.timestamp) * 1000
            Logger:debug("CLIENT", "Latency: " .. string.format("%.1fms", latency))
        end
    elseif msgType == MessageTypes.ERROR then
        Logger:error("CLIENT", "Server error: " .. tostring(data.message))
        setConnectionState(self, self.STATE_DISCONNECTED, data.message)
    end
end

function Client:handleConnectResponse(data)
    if data.status == "accepted" then
        self.clientId = data.clientId
        setConnectionState(self, self.STATE_CONNECTED)
        self.connectionAttempts = 0  -- Reset attempts on success
        self.retryDelay = 1  -- Reset backoff
    else
        setConnectionState(self, self.STATE_DISCONNECTED, "Connection rejected: " .. tostring(data.status))
    end
end

function Client:handleStateUpdate(data)
    -- Guardar estado para interpolación
    if data.tick and data.entities then
        for _, entity in ipairs(data.entities) do
            self.entityStates[entity.id] = {
                x = entity.x,
                y = entity.y,
                vx = entity.vx or 0,
                vy = entity.vy or 0,
                state = entity.state,
                tick = data.tick
            }
        end
    end
end

function Client:getEntityState(id)
    return self.entityStates[id]
end

function Client:resendPendingInputs()
    -- Implementar si necesitamos reliable delivery para inputs
end

--- Desconectar del servidor
function Client:disconnect()
    if self.socket then
        pcall(function()
            self.socket:destroy()
        end)
        self.socket = nil
    end
    
    self.connected = false
    self.clientId = nil
    setConnectionState(self, self.STATE_IDLE)
end

--- Reset para nuevo intento de conexión
function Client:reset()
    self.connectionState = self.STATE_IDLE
    self.connectionAttempts = 0
    self.retryDelay = 1
    self.socket = nil
    self.errorMessage = nil
    self.connected = false
end

return Client
