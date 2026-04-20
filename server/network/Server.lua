-- server/network/Server.lua
-- Gestor de conexiones del servidor

local Server = {}
Server.__index = Server

local MessageTypes = require("common.protocol.MessageTypes")
local NetworkConfig = require("common.config.NetworkConfig")
local Logger = require("common.utils.Logger")

function Server:new()
    local self = setmetatable({}, Server)
    
    self.socket = nil
    self.clients = {}
    self.nextClientId = 1
    
    return self
end

function Server:start()
    Logger:info("SERVER", "Iniciando socket en puerto " .. NetworkConfig.SERVER_PORT)
    
    -- En producción, usar sock.lua
    -- self.socket = require("sock").newServer(...)
end

function Server:update(dt)
    if not self.socket then
        self:start()
        return
    end
    
    -- Procesar conexiones entrantes
    -- local client, err = self.socket:accept()
    -- if client then
    --     self:handleNewClient(client)
    -- end
    
    -- Procesar paquetes de clientes
    for clientId, client in pairs(self.clients) do
        -- local data, err = client:receive()
        -- if data then
        --     self:handleClientPacket(clientId, data)
        -- end
    end
end

function Server:handleNewClient(socket)
    local clientId = self.nextClientId
    self.nextClientId = self.nextClientId + 1
    
    local client = {
        id = clientId,
        socket = socket,
        player = nil,
        lastInputTime = love.timer.getTime()
    }
    
    self.clients[clientId] = client
    Logger:info("SERVER", "Cliente conectado: " .. clientId)
end

function Server:handleClientPacket(clientId, data)
    local client = self.clients[clientId]
    if not client then return end
    
    if data.type == MessageTypes.CONNECT then
        self:handleConnect(clientId, data)
    elseif data.type == MessageTypes.INPUT then
        self:handleInput(clientId, data)
    end
end

function Server:handleConnect(clientId, data)
    Logger:info("SERVER", "Cliente " .. clientId .. " intentando conectar")
    
    local response = {
        type = MessageTypes.CONNECT_RESPONSE,
        clientId = clientId,
        status = "accepted"
    }
    
    self:sendToClient(clientId, response)
end

function Server:handleInput(clientId, data)
    -- Validar input
    local client = self.clients[clientId]
    if not client then return end
    
    -- Validar rate limiting
    local now = love.timer.getTime()
    if (now - client.lastInputTime) < (1 / NetworkConfig.MAX_INPUT_RATE) then
        Logger:warn("SERVER", "Input rate limit excedido para cliente " .. clientId)
        return
    end
    
    client.lastInputTime = now
    
    -- Procesar input en el servidor
    -- gameState:applyInput(clientId, data.inputVector)
end

function Server:broadcastGameState(state)
    local packet = {
        type = MessageTypes.STATE_UPDATE,
        tick = SERVER_STATE.tick,
        entities = state
    }
    
    for clientId, _ in pairs(self.clients) do
        self:sendToClient(clientId, packet)
    end
end

function Server:sendToClient(clientId, data)
    local client = self.clients[clientId]
    if client and client.socket then
        -- client.socket:send(data)
    end
end

function Server:disconnectClient(clientId)
    Logger:info("SERVER", "Cliente desconectado: " .. clientId)
    self.clients[clientId] = nil
end

return Server
