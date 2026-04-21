-- common/protocol/MessageTypes.lua
-- Tipos de mensajes para la comunicación red

local MessageTypes = {}

-- CONEXIÓN
MessageTypes.CONNECT = 1
MessageTypes.CONNECT_RESPONSE = 2
MessageTypes.DISCONNECT = 3

-- GAME
MessageTypes.INPUT = 10
MessageTypes.STATE_UPDATE = 11
MessageTypes.ACTION = 12
MessageTypes.EVENT = 13

-- NIVELES
MessageTypes.LEVEL_CHANGE = 30
MessageTypes.LEVEL_INFO = 31
MessageTypes.LEVEL_COMPLETE = 32
MessageTypes.PLAYER_COMPLETED_LEVEL = 33

-- SINCRONIZACIÓN
MessageTypes.PING = 20
MessageTypes.PONG = 21
MessageTypes.RESYNC = 22

-- ERRORES
MessageTypes.ERROR = 99

-- Mapeo inverso para debugging
MessageTypes.NAMES = {
    [1] = "CONNECT",
    [2] = "CONNECT_RESPONSE",
    [3] = "DISCONNECT",
    [10] = "INPUT",
    [11] = "STATE_UPDATE",
    [12] = "ACTION",
    [13] = "EVENT",
    [20] = "PING",
    [21] = "PONG",
    [22] = "RESYNC",
    [30] = "LEVEL_CHANGE",
    [31] = "LEVEL_INFO",
    [32] = "LEVEL_COMPLETE",
    [33] = "PLAYER_COMPLETED_LEVEL",
    [99] = "ERROR"
}

function MessageTypes:getName(typeId)
    return self.NAMES[typeId] or "UNKNOWN"
end

return MessageTypes
