# NETWORKING.md - Protocolo de Comunicación Detallado

## Visión General del Protocolo

El protocolo utiliza **UDP con abstracción TCP** (mediante sock.lua):

- **Port:** 8888 (configurable en NetworkConfig.lua)
- **Frecuencia de Input:** 60/segundo (limitado)
- **Frecuencia de State Update:** 20/segundo (50ms)
- **Serialización:** Binary (bitser) o JSON (fallback)

---

## Tipos de Mensajes (MessageTypes.lua)

```
CONNECT = 1           # Cliente → Servidor (con handshake)
INPUT = 2            # Cliente → Servidor (input de jugador)
STATE_UPDATE = 3     # Servidor → Cliente (estado canónico)
ACTION = 4           # Cliente → Servidor (acciones especiales)
EVENT = 5            # Servidor → Cliente (eventos del juego)
PING = 6             # Ambos (latencia)
PONG = 7             # Ambos (respuesta a PING)
ERROR = 8            # Ambos (errores)
```

---

## 1. Conexión Inicial (Handshake)

```lua
-- CLIENTE envía:
{
    type = MessageTypes.CONNECT,
    clientVersion = "1.0",
    playerName = "Player123",
    timestamp = 1000
}

-- SERVIDOR responde:
{
    type = MessageTypes.CONNECT,
    accepted = true,
    playerId = 42,
    worldState = { ... },
    timestamp = 1010,
    serverTick = 600
}

-- O rechaza:
{
    type = MessageTypes.CONNECT,
    accepted = false,
    reason = "Server full",
    timestamp = 1010
}
```

---

## 2. Input del Jugador

Enviado cada frame (o cuando hay cambios):

```lua
-- CLIENTE envía (WASD, click, etc):
{
    type = MessageTypes.INPUT,
    playerId = 42,
    tick = 601,
    input = {
        movementX = 1,      -- -1, 0, 1
        movementY = 0,      -- -1, 0, 1
        action = nil,       -- "attack", "jump", etc.
    },
    clientTick = 200,       -- Tick del cliente
    timestamp = 1020
}
```

**Server-side validation:**

```lua
-- Validaciones ejecutadas en servidor:
✓ ¿Jugador existe?
✓ ¿Input es de cliente correcto?
✓ ¿No es input duplicado?
✓ ¿Velocidad es posible? (MAX_SPEED)
✓ ¿Input age es válido? (< 500ms)
✓ ¿Rate limit? (max 60/sec)
```

---

## 3. State Update (Broadcast)

Servidor envía **20 veces/segundo** (cada 50ms):

```lua
-- SERVIDOR envía a TODOS los clientes:
{
    type = MessageTypes.STATE_UPDATE,
    tick = 602,
    entities = {
        [42] = {
            id = 42,
            position = {x = 100, y = 200},
            velocity = {x = 50, y = 0},
            state = "moving",
            health = 100
        },
        [43] = {
            id = 43,
            position = {x = 150, y = 220},
            velocity = {x = 0, y = 0},
            state = "idle",
            health = 100
        }
    },
    events = {
        {type = "player_joined", playerId = 44},
        {type = "collision", entity1 = 42, entity2 = 43}
    },
    timestamp = 1030,
    clientTick = 200
}
```

**Client-side processing:**

```lua
-- Cliente recibe state update
-- 1. Valida timestamp (¿es reciente?)
-- 2. Compara con predicción local
-- 3. Si diferencia pequeña: INTERPOLA
-- 4. Si diferencia grande: TELEPORT CORRECCION
-- 5. Renderiza en siguiente frame
```

---

## 4. Acciones Especiales

Para abilidades, ataques, etc.:

```lua
-- CLIENTE envía:
{
    type = MessageTypes.ACTION,
    playerId = 42,
    actionType = "use_ability",
    actionId = "fireball",
    targetPosition = {x = 500, y = 300},
    timestamp = 1040
}

-- SERVIDOR valida y responde con EVENT
```

---

## 5. Eventos

Notificaciones importantes (muertes, asesinatos, etc.):

```lua
-- SERVIDOR envía a TODOS:
{
    type = MessageTypes.EVENT,
    eventType = "player_died",
    data = {
        victimId = 42,
        killerId = 43,
        weapon = "sword"
    }
}
```

---

## 6. Latencia y Timing

### 6.1 Round-Trip Time (RTT)

```
Cliente envía PING: T0
    ↓ (red latency = L)
Servidor recibe: T0+L
Servidor envía PONG: T0+L
    ↓ (red latency = L)
Cliente recibe: T0+2L

RTT = 2L (reporte = (T0+2L) - T0)
```

```lua
-- CLIENTE envía:
{
    type = MessageTypes.PING,
    clientTimestamp = 1000
}

-- SERVIDOR responde:
{
    type = MessageTypes.PONG,
    clientTimestamp = 1000,
    serverTimestamp = 1005
}

-- Cliente calcula RTT:
local rtt = love.timer.getTime() - clientTimestamp
Logger:debug("PING", "RTT: " .. rtt .. "ms")
```

### 6.2 Interpolation

```lua
-- State Update llega cada 50ms (20 Hz)
-- Cliente interpola suavemente en 100ms (2 updates)

-- Frame 0: Recibe state en posición X=100
-- Frame 1-5: Interpola desde X=100 hacia X=150
-- Frame 6: Recibe nuevo state en posición X=150
-- Frame 7-11: Interpola desde X=150 hacia X=200
```

---

## 7. Flujo Completo de Gameplay

```
T=0ms:    CLIENTE envía INPUT (movimiento derecha)
          LOCAL: Predice movimiento de cliente

T=5ms:    SERVIDOR recibe INPUT
          Valida: ✓ Speed, ✓ Position, ✓ Rate limit

T=10ms:   SERVIDOR aplica movimiento a jugador
          Calcula nuevas posiciones de TODOS

T=15ms:   SERVIDOR prepara STATE_UPDATE

T=20ms:   SERVIDOR envía STATE_UPDATE

T=25ms:   CLIENTE recibe STATE_UPDATE
          Compara predicción vs real
          Si diff pequeña: interpola
          Si diff grande: corrección

T=30ms:   CLIENTE renderiza con nueva posición

LATENCIA PERCIBIDA: ~25-50ms
(Sin latencia real, la predicción siente 0ms porque es local)
```

---

## 8. Manejo de Errores

```lua
-- Si error en servidor:
{
    type = MessageTypes.ERROR,
    errorCode = 1001,
    errorMessage = "Invalid position",
    timestamp = 1050
}

-- Códigos comunes:
1001 = Invalid position (out of bounds)
1002 = Speed exploit detected
1003 = Rate limit exceeded
1004 = Input too old
1005 = Player not found
```

---

## 9. Optimizaciones

### Delta Updates (Próximas versiones)

```lua
-- Completo (actual):
{
    type = MessageTypes.STATE_UPDATE,
    entities = {
        [42] = {x=100, y=200, vel_x=50, vel_y=0, ...}
    }
}

-- Delta (futuro):
{
    type = MessageTypes.STATE_UPDATE,
    delta = {
        entities = {
            [42] = {x=101}  -- Solo campos cambiados
        }
    }
}
```

Ahorra ~70% ancho de banda.

---

## 10. Testing del Protocolo

### Habilitar Debug Mode

En `common/config/NetworkConfig.lua`:

```lua
NetworkConfig.DEBUG_PACKETS = true   -- Log de todos los paquetes
NetworkConfig.DEBUG_LATENCY = 100    -- Simular 100ms de latencia
```

### Inspeccionar Paquetes

```lua
-- En server/main.lua o client/main.lua:
Logger:debug("PACKET", "Sent: " .. inspect(packet))
```

---

## 11. Referencias

- LÖVE Networking: https://love2d.org/wiki/love.socket
- sock.lua Docs: https://github.com/camchenry/sock.lua
- UDP vs TCP: https://en.wikipedia.org/wiki/Comparison_of_transport_protocols

