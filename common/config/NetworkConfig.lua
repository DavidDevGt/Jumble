-- common/config/NetworkConfig.lua
-- Configuración de red

local NetworkConfig = {}

-- CONEXIÓN
NetworkConfig.SERVER_HOST = "localhost"
NetworkConfig.SERVER_PORT = 8888
NetworkConfig.CONNECTION_TIMEOUT = 30     -- segundos
NetworkConfig.HEARTBEAT_INTERVAL = 5      -- segundos

-- PAQUETES
NetworkConfig.MAX_PACKET_SIZE = 65536
NetworkConfig.PACKET_RESEND_TIME = 0.5    -- segundos
NetworkConfig.PACKET_MAX_RETRIES = 3

-- BANDWIDTH
NetworkConfig.STATE_UPDATE_RATE = 20      -- Updates por segundo
NetworkConfig.INPUT_RATE_LIMIT = 60       -- Inputs por segundo

-- DEBUGGING
NetworkConfig.DEBUG_PACKETS = false        -- Log de paquetes
NetworkConfig.DEBUG_LATENCY = 0           -- ms de latencia simulada (0 = off)

return NetworkConfig
