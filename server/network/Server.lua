-- server/network/Server.lua
-- Gestor de conexiones del servidor sobre sock.lua (enet UDP).
--
-- sock.lua es event-driven (no LuaSocket): el socket no expone accept/
-- receive bloqueantes. Las conexiones llegan como callbacks registrados
-- con server:on(event, cb) y cada update() del server procesa los eventos
-- pendientes de enet.

local Server = {}
Server.__index = Server

local GameConfig    = require("common.config.GameConfig")
local NetworkConfig = require("common.config.NetworkConfig")
local Logger        = require("common.utils.Logger")

local sock   = require("sock")
local bitser = require("bitser")

function Server:new()
    local self = setmetatable({}, Server)

    self.socket = nil
    self.clients = {}          -- [peerIndex] = { id, client, lastInputTick }
    self.lastBroadcastTick = 0
    -- Buffer reutilizado en broadcastGameState para evitar 1 alloc por broadcast.
    self.broadcastBuffer = {}

    return self
end

function Server:start()
    Logger:info("SERVER", "Iniciando socket UDP en puerto " .. NetworkConfig.SERVER_PORT)

    self.socket = sock.newServer("*", NetworkConfig.SERVER_PORT, GameConfig.MAX_PLAYERS)
    self.socket:setSerialization(bitser.dumps, bitser.loads)

    self.socket:on("connect", function(_, client)
        self:handleConnect(client)
    end)

    self.socket:on("disconnect", function(_, client)
        self:handleDisconnect(client)
    end)

    self.socket:on("input", function(data, client)
        self:handleInput(client, data)
    end)

    self.socket:on("ping", function(data, client)
        self:handlePing(client, data)
    end)
end

function Server:update(dt)
    if not self.socket then
        self:start()
        return
    end
    self.socket:update()
end

function Server:handleConnect(client)
    local id = client:getIndex()

    self.clients[id] = {
        id = id,
        client = client,
        lastInputTick = 0,
    }

    Logger:info("SERVER", "Cliente conectado: " .. id)

    -- Respuesta de bienvenida con el ID asignado (reemplaza el viejo
    -- MessageTypes.CONNECT_RESPONSE; sock maneja el handshake de transporte,
    -- solo necesitamos decirle al cliente qué ID le tocó).
    client:send("welcome", {
        clientId = id,
        status = "accepted",
    })
end

function Server:handleDisconnect(client)
    local id = client:getIndex()
    Logger:info("SERVER", "Cliente desconectado: " .. id)
    self.clients[id] = nil
end

function Server:handleInput(client, data)
    local id = client:getIndex()
    local entry = self.clients[id]
    if not entry then return end

    -- Rate limit: max 1 input cada MIN_TICKS_BETWEEN_INPUTS ticks del servidor.
    local currentTick = SERVER_STATE.tick
    local ticksSinceLastInput = currentTick - entry.lastInputTick
    if ticksSinceLastInput < NetworkConfig.MIN_TICKS_BETWEEN_INPUTS then
        return
    end
    entry.lastInputTick = currentTick

    if data and gameState then
        gameState:applyInput(id, data)
    end
end

function Server:handlePing(client, data)
    client:send("pong", {
        timestamp = data and data.timestamp,
        serverTick = SERVER_STATE.tick,
    })
end

-- Enviar STATE_UPDATE cada 3 ticks (20Hz cuando tick=60)
function Server:broadcastGameState(state, tick)
    if tick % 3 ~= 0 then return end
    if not self.socket then return end

    -- Serializar solo datos mínimos reutilizando el buffer.
    local buffer = self.broadcastBuffer
    for i = #buffer, 1, -1 do buffer[i] = nil end

    local n = 0
    for _, entity in ipairs(state) do
        if entity.getNetworkState then
            n = n + 1
            buffer[n] = entity:getNetworkState()
        end
    end

    self.socket:sendToAll("state_update", {
        tick = tick,
        entities = buffer,
    })
end

function Server:disconnectClient(id)
    local entry = self.clients[id]
    if entry and entry.client then
        entry.client:disconnect()
    end
    self.clients[id] = nil
    Logger:info("SERVER", "Cliente desconectado: " .. id)
end

return Server
