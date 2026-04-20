-- client/network/Client.lua
-- Gestor de conexión del cliente

local Client = {}
Client.__index = Client

local MessageTypes = require("common.protocol.MessageTypes")
local NetworkConfig = require("common.config.NetworkConfig")
local Logger = require("common.utils.Logger")

function Client:new()
    local self = setmetatable({}, Client)
    
    self.connected = false
    self.clientId = nil
    self.socket = nil
    self.serverHost = NetworkConfig.SERVER_HOST
    self.serverPort = NetworkConfig.SERVER_PORT
    self.connectionTime = 0
    
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
    
    -- Aquí se conectaría con sock.lua en producción
    -- Por ahora, simular conexión
    if not self.socket then
        Logger:info("CLIENT", "Intentando conectar a " .. 
                             self.serverHost .. ":" .. self.serverPort)
        -- self.socket = require("sock").newClient(...)
    end
end

function Client:isConnected()
    return self.connected
end

function Client:update(dt)
    if not self.connected then return end
    
    -- Procesar paquetes recibidos
    if self.socket then
        -- local data, err = self.socket:receive()
        -- if data then
        --     self:handlePacket(data)
        -- end
    end
end

function Client:sendInput(input)
    if not self.connected then return end
    
    local packet = {
        type = MessageTypes.INPUT,
        inputVector = input,
        timestamp = love.timer.getTime()
    }
    
    -- Enviar al servidor
    -- self.socket:send(packet)
end

function Client:handlePacket(data)
    -- Procesar tipos de mensaje
    if data.type == MessageTypes.CONNECT_RESPONSE then
        self:handleConnectResponse(data)
    elseif data.type == MessageTypes.STATE_UPDATE then
        self:handleStateUpdate(data)
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
    -- Actualizar estado del juego
    if data.entities then
        -- Actualizar posiciones de entidades
    end
end

return Client
