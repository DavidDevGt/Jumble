-- server/network/Server.lua
-- Gestor de conexiones del servidor

local Server = {}
Server.__index = Server

local MessageTypes = require("common.protocol.MessageTypes")
local NetworkConfig = require("common.config.NetworkConfig")
local Logger = require("common.utils.Logger")

-- Cargar bitser para serialización compacta (resuelto via package.path extendido en server/main.lua)
local bitser = require("bitser")

function Server:new()
    local self = setmetatable({}, Server)
    
    self.socket = nil
    self.clients = {}
    self.nextClientId = 1
    self.lastBroadcastTick = 0
    
    return self
end

function Server:start()
    Logger:info("SERVER", "Iniciando socket UDP en puerto " .. NetworkConfig.SERVER_PORT)
    
    -- Forzar UDP con sock.lua
    self.socket = require("sock").newServer("*", NetworkConfig.SERVER_PORT)
    self.socket:setTimeout(0)
end

function Server:update(dt)
    if not self.socket then
        self:start()
        return
    end
    
    -- Procesar conexiones entrantes
    local clientSocket = self.socket:accept()
    if clientSocket then
        self:handleNewClient(clientSocket)
    end
    
    -- Procesar paquetes de clientes
    for clientId, client in pairs(self.clients) do
        local data = client.socket:receive()
        while data do
            local ok, packet = pcall(bitser.deserialize, data)
            if ok and packet then
                self:handleClientPacket(clientId, packet)
            end
            data = client.socket:receive()
        end
    end
end

function Server:handleNewClient(socket)
    local clientId = self.nextClientId
    self.nextClientId = self.nextClientId + 1
    
    local client = {
        id = clientId,
        socket = socket,
        player = nil,
        lastInputTime = 0,
        lastInputTick = 0
    }
    
    self.clients[clientId] = client
    Logger:info("SERVER", "Cliente conectado: " .. clientId)
end

function Server:handleClientPacket(clientId, data)
    local client = self.clients[clientId]
    if not client then return end
    
    local msgType = data.type or data[1]
    
    if msgType == MessageTypes.CONNECT then
        self:handleConnect(clientId, data)
    elseif msgType == MessageTypes.INPUT then
        self:handleInput(clientId, data)
    elseif msgType == MessageTypes.PING then
        self:handlePing(clientId, data)
    end
end

function Server:handleConnect(clientId, data)
    Logger:info("SERVER", "Cliente " .. clientId .. " conectado")
    
    -- Asignar ID único
    local client = self.clients[clientId]
    client.playerId = clientId
    
    -- Responder con accepted
    local response = {
        type = MessageTypes.CONNECT_RESPONSE,
        clientId = clientId,
        status = "accepted"
    }
    
    self:sendToClient(clientId, bitser.serialize(response))
end

function Server:handleInput(clientId, data)
    local client = self.clients[clientId]
    if not client then return end
    
    -- Rate limiting: max 60 inputs por segundo
    local currentTick = SERVER_STATE.tick
    if currentTick - client.lastInputTick < 1 then
        -- Ignorar input si viene muy rápido
        return
    end
    
    client.lastInputTick = currentTick
    
    -- Enviar input al GameState para procesamiento
    if data.input and gameState then
        gameState:applyInput(clientId, data.input)
    end
end

function Server:handlePing(clientId, data)
    local response = {
        type = MessageTypes.PONG,
        timestamp = data.timestamp,
        serverTick = SERVER_STATE.tick
    }
    self:sendToClient(clientId, bitser.serialize(response))
end

-- Enviar STATE_UPDATE cada 3 ticks (20Hz cuando tick=60)
function Server:broadcastGameState(state, tick)
    -- Solo enviar cada 3 ticks = 20Hz
    if tick % 3 ~= 0 then
        return
    end
    
    -- Serializar solo datos mínimos
    local minimalEntities = {}
    for _, entity in ipairs(state) do
        if entity.getNetworkState then
            table.insert(minimalEntities, entity:getNetworkState())
        end
    end
    
    local packet = {
        type = MessageTypes.STATE_UPDATE,
        tick = tick,
        entities = minimalEntities
    }
    
    local serialized = bitser.serialize(packet)
    
    for clientId, _ in pairs(self.clients) do
        self:sendToClient(clientId, serialized)
    end
end

function Server:sendToClient(clientId, data)
    local client = self.clients[clientId]
    if client and client.socket then
        client.socket:send(data)
    end
end

function Server:disconnectClient(clientId)
    Logger:info("SERVER", "Cliente desconectado: " .. clientId)
    self.clients[clientId] = nil
end

return Server
