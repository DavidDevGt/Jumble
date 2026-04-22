-- client/network/Client.lua
-- Gestor de conexión del cliente sobre sock.lua (enet UDP).
--
-- La recepción de mensajes se hace vía callbacks registrados con
-- client:on(event, cb). `update()` procesa los eventos enet pendientes
-- y dispara los callbacks correspondientes.

local Client = {}
Client.__index = Client

local NetworkConfig = require("common.config.NetworkConfig")
local Logger        = require("common.utils.Logger")

local sock   = require("sock")
local bitser = require("bitser")

function Client:new()
    local self = setmetatable({}, Client)

    self.connected = false
    self.clientId = nil
    self.socket = nil
    self.serverHost = NetworkConfig.SERVER_HOST
    self.serverPort = NetworkConfig.SERVER_PORT

    -- Buffer de estados de entidades para interpolación.
    self.entityStates = {}

    return self
end

function Client:connect()
    if self.socket then return end

    Logger:info("CLIENT", "Conectando a " .. self.serverHost .. ":" .. self.serverPort .. " (UDP)")

    self.socket = sock.newClient(self.serverHost, self.serverPort)
    self.socket:setSerialization(bitser.dumps, bitser.loads)

    self.socket:on("connect", function()
        -- Nota: esto dispara cuando el transporte enet se conecta. El
        -- estado "connected" de la app se marca al recibir "welcome",
        -- donde el servidor nos asigna un clientId.
        Logger:info("CLIENT", "Transporte conectado al servidor")
    end)

    self.socket:on("disconnect", function()
        Logger:warn("CLIENT", "Desconectado del servidor")
        self.connected = false
        self.clientId = nil
    end)

    self.socket:on("welcome", function(data)
        if data and data.status == "accepted" then
            self.clientId = data.clientId
            self.connected = true
            Logger:info("CLIENT", "Conectado con ID: " .. tostring(self.clientId))
        else
            Logger:warn("CLIENT", "Bienvenida rechazada por el servidor")
        end
    end)

    self.socket:on("state_update", function(data)
        self:handleStateUpdate(data)
    end)

    self.socket:on("pong", function(data)
        -- TODO: calcular latencia a partir de data.timestamp
    end)

    self.socket:connect()
end

function Client:isConnected()
    return self.connected
end

function Client:update(dt)
    if not self.socket then
        self:connect()
        return
    end
    self.socket:update()
end

function Client:sendInput(input)
    if not self.connected or not self.socket then return end

    self.socket:send("input", {
        clientId = self.clientId,
        input = input,
        timestamp = love.timer.getTime(),
    })
end

function Client:ping()
    if not self.connected or not self.socket then return end
    self.socket:send("ping", { timestamp = love.timer.getTime() })
end

function Client:handleStateUpdate(data)
    if not (data and data.tick and data.entities) then return end

    for _, entity in ipairs(data.entities) do
        self.entityStates[entity.id] = {
            x = entity.x,
            y = entity.y,
            vx = entity.vx,
            vy = entity.vy,
            state = entity.state,
            tick = data.tick,
        }
    end
end

function Client:getEntityState(id)
    return self.entityStates[id]
end

return Client
