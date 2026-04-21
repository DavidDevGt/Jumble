-- client/network/Client.lua
-- Gestor de conexión del cliente

local Client = {}
Client.__index = Client

local MessageTypes = require("common.protocol.MessageTypes")
local NetworkConfig = require("common.config.NetworkConfig")
local Logger = require("common.utils.Logger")

-- Cargar bitser para serialización compacta
local bitser = require("libs.bitser")

function Client:new()
    local self = setmetatable({}, Client)
    
    self.connected = false
    self.clientId = nil
    self.socket = nil
    self.serverHost = NetworkConfig.SERVER_HOST
    self.serverPort = NetworkConfig.SERVER_PORT
    self.connectionTime = 0
    self.lastSendTime = 0
    
    -- Buffer de interpolación
    self.entityStates = {}
    self.pendingInputs = {}
    
    return self
end

function Client:connect()
    if self.connected then return end
    
    self.connectionTime = self.connectionTime + love.timer.getDelta()
    
    if self.connectionTime > NetworkConfig.CONNECTION_TIMEOUT then
        Logger:warn("CLIENT", "Timeout de conexión")
        self.connectionTime = 0
        return
    end
    
    if not self.socket then
        Logger:info("CLIENT", "Conectando a " .. 
                             self.serverHost .. ":" .. self.serverPort .. " (UDP)")
        
        -- Forzar UDP con sock.lua
        self.socket = require("sock").newClient(self.serverHost, self.serverPort)
        self.socket:setTimeout(0)
        self.socket:setBroadcast(true)
    end
    
    -- Intentar handshake
    local connectPacket = {
        type = MessageTypes.CONNECT,
        timestamp = love.timer.getTime()
    }
    
    local success, err = self.socket:send(bitser.serialize(connectPacket))
    if not success then
        Logger:warn("CLIENT", "Error al enviar CONNECT: " .. tostring(err))
    end
end

function Client:isConnected()
    return self.connected
end

function Client:update(dt)
    if not self.connected then 
        self:connect()
        return 
    end
    
    if not self.socket then return end
    
    -- Procesar paquetes recibidos
    local data, msg = self.socket:receive()
    if data then
        local ok, packet = pcall(bitser.deserialize, data)
        if ok and packet then
            self:handlePacket(packet)
        end
    end
    
    -- Reenviar inputs pendientes si no hay ack
    self:resendPendingInputs()
end

function Client:sendInput(input)
    if not self.connected then return end
    
    if not self.socket then return end
    
    -- Serializar input compacto (booleanos, no vector)
    local packet = {
        type = MessageTypes.INPUT,
        clientId = self.clientId,
        input = input,  -- Vector2 o tabla {x, y, jump}
        timestamp = love.timer.getTime()
    }
    
    local serialized = bitser.serialize(packet)
    self.socket:send(serialized)
end

function Client:handlePacket(data)
    local msgType = data.type or data[1]
    
    if msgType == MessageTypes.CONNECT_RESPONSE then
        self:handleConnectResponse(data)
    elseif msgType == MessageTypes.STATE_UPDATE then
        self:handleStateUpdate(data)
    elseif msgType == MessageTypes.PONG then
        -- Actualizar latencia
    end
end

function Client:handleConnectResponse(data)
    if data.status == "accepted" then
        self.clientId = data.clientId
        self.connected = true
        Logger:info("CLIENT", "Conectado con ID: " .. self.clientId)
    end
end

function Client:handleStateUpdate(data)
    -- Guardar estado para interpolación
    if data.tick and data.entities then
        for _, entity in ipairs(data.entities) do
            self.entityStates[entity.id] = {
                x = entity.x,
                y = entity.y,
                vx = entity.vx,
                vy = entity.vy,
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

return Client
