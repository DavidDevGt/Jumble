# Arquitectura de Videojuego 2D Multijugador - LÖVE 11.5 + Lua 5.4

## 1. Visión General

Este proyecto implementa un videojuego 2D multijugador con arquitectura **Cliente-Servidor Autoritativa**, garantizando integridad de datos, prevención de trampas y sincronización de estado en tiempo real.

**Stack Tecnológico:**
- **Motor:** LÖVE 11.5 (Framework 2D Lua)
- **Lenguaje:** Lua 5.4
- **Networking:** sock.lua (UDP/TCP abstracción)
- **Serialización:** bitser.lua (datos binarios eficientes)
- **Protocolo:** UDP con rate limiting y packet resending

---

## 2. Arquitectura Cliente-Servidor Autoritativa

### 2.1 Flujo de Autoridad

```
┌─────────────┐                          ┌─────────────┐
│   CLIENT    │                          │   SERVER    │
│ (Predicción)│                          │(Autoridad)  │
└─────────────┘                          └─────────────┘
      │                                         │
      │ 1. Input del jugador                   │
      │─────────────────────────────────────→  │
      │ (Posición predicha localmente)         │
      │ (Dibujar sin esperar respuesta)        │
      │                                    2. Procesar Input
      │                                       Validar
      │                                       Actualizar estado
      │                                    3. Broadcast estado
      │  ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
      │     (Nuevo estado canónico)           │
      │     (Correcciones si es necesario)    │
      │                                       │
      │ 4. Interpolar hacia nuevo estado      │
      │ (Suavizar movimientos)                │
      │                                       │
      └───────────────────────────────────────┘
```

### 2.2 Responsabilidades

| Componente | Responsabilidad |
|-----------|-----------------|
| **Cliente** | Capturar input, predicción local, renderizado, interpolación |
| **Servidor** | Autoridad del estado, validación, resolución de conflictos, broadcast |
| **Común** | Lógica compartida (colisiones, físicas, entities) |

### 2.3 Ventajas

✅ Imposibilidad de cheats (el servidor valida todo)  
✅ Consistencia entre jugadores  
✅ Escalabilidad (1 servidor → N clientes)  
✅ Seguridad de datos sensibles en el servidor  

---

## 3. Organización de Archivos

```
Jumble/
│
├── common/                          # Código compartido Cliente-Servidor
│   ├── entities/
│   │   ├── Player.lua              # Definición de entidad jugador
│   │   ├── Projectile.lua          # Proyectiles
│   │   └── World.lua               # Gestión de mundo/colisiones
│   ├── physics/
│   │   ├── Collision.lua           # Detección de colisiones AABB
│   │   └── Movement.lua            # Físicas básicas
│   ├── protocol/
│   │   ├── MessageTypes.lua        # Constantes de tipos de mensaje
│   │   └── Serialization.lua       # Serialización/Deserialización
│   ├── config/
│   │   ├── GameConfig.lua          # Constantes del juego
│   │   └── NetworkConfig.lua       # Configuración de red
│   └── utils/
│       ├── Vector2.lua             # Math helper
│       └── Logger.lua              # Sistema de logging
│
├── client/                          # Código del cliente
│   ├── main.lua                     # Punto de entrada LÖVE
│   ├── conf.lua                     # Configuración LÖVE
│   ├── states/
│   │   ├── Connecting.lua          # Estado conectando
│   │   ├── Menu.lua                # Menú principal
│   │   └── InGame.lua              # Juego en curso
│   ├── network/
│   │   ├── Client.lua              # Gestor de conexión cliente
│   │   └── InputManager.lua        # Entrada del usuario
│   ├── render/
│   │   ├── Renderer.lua            # Sistema de renderizado
│   │   └── Camera.lua              # Cámara y viewport
│   ├── interpolation/
│   │   └── EntityInterpolator.lua  # Interpolación de movimientos
│   └── assets/
│       ├── sprites/
│       └── fonts/
│
├── server/                          # Código del servidor
│   ├── main.lua                     # Punto de entrada servidor
│   ├── conf.lua                     # Configuración servidor
│   ├── network/
│   │   ├── Server.lua              # Gestor de conexiones
│   │   ├── ClientManager.lua       # Admin de clientes conectados
│   │   └── PacketHandler.lua       # Procesamiento de paquetes
│   ├── game/
│   │   ├── GameState.lua           # Estado del juego servidor
│   │   ├── GameLogic.lua           # Lógica de juego
│   │   └── TickManager.lua         # Tick del servidor (determinista)
│   └── persistence/
│       └── Database.lua             # (Opcional) Persistencia
│
├── docs/                            # Documentación
├── ARCHITECTURE.md                  # (Este archivo)
├── SETUP.md                         # Guía de instalación
├── README.md                        # Descripción del proyecto
└── conf.lua                         # Config principal LÖVE
```

---

## 4. Loop Principal y Sincronización

### 4.1 Cliente: love.update() y love.draw()

```lua
-- client/main.lua
function love.update(dt)
    -- 1. Procesar input (predicción local)
    inputManager:update(dt)
    
    -- 2. Actualizar estado local (predicción)
    gameState:updateLocal(dt)
    
    -- 3. Procesar paquetes del servidor
    client:update(dt)  -- Recibir estado canónico
    
    -- 4. Interpolación (suavizar hacia estado servidor)
    entityInterpolator:update(dt)
end

function love.draw()
    -- 1. Limpiar pantalla
    love.graphics.clear(0.1, 0.1, 0.1)
    
    -- 2. Aplicar cámara
    camera:attach()
    
    -- 3. Renderizar entidades (posición interpolada)
    renderer:drawEntities(gameState:getEntities())
    
    -- 4. Renderizar efectos/UI
    renderer:drawEffects()
    
    camera:detach()
    
    -- 5. UI en pantalla (no afectada por cámara)
    ui:draw()
end
```

### 4.2 Servidor: Tick Determinista

```lua
-- server/main.lua
local TICK_RATE = 60  -- 60 updates por segundo
local TICK_TIME = 1 / TICK_RATE

function love.update(dt)
    server:accumulate(dt)
    
    -- Procesar múltiples ticks si es necesario
    while server:shouldTick() do
        gameState:tick()      -- Update determinista
        server:broadcastState() -- Enviar a clientes
    end
end
```

---

## 5. Librerías Recomendadas

| Librería | Propósito | Alternativa |
|----------|----------|------------|
| **sock.lua** | Networking UDP/TCP | enet-lua |
| **bitser** | Serialización binaria | MessagePack |
| **classic** | OOP en Lua | Middleclass |
| **tick.lua** | Timer manager | - |
| **inspect** | Debug/logging | - |

---

## 6. Flujo de Comunicación Detallado

Ver [03_NETWORKING.md](03_NETWORKING.md) para protocolo completo.

---

## 7. Seguridad Anti-Trampas

### 7.1 Validaciones Críticas

```lua
-- ❌ MAL: Confiar en cliente
if client.position.x > 10000 then
    player:takeDamage(100)
end

-- ✅ BIEN: Validar en servidor
if self:isPositionValid(player, newPos) then
    player:move(newPos)
else
    player:teleportBack()  -- Castigo anti-cheat
end
```

### 7.2 Checks Anti-Hack

1. **Detección de velocidad imposible**
2. **Detección de input fuera de sync**
3. **Rate limiting agresivo**

---

## 8. Próximos Pasos de Implementación

1. **Fase 1:** Estructura básica
2. **Fase 2:** Sistema de networking
3. **Fase 3:** Loop principal y sincronización
4. **Fase 4:** Interpolación y predicción
5. **Fase 5:** Validaciones anti-cheat
6. **Fase 6:** Testing y optimización

Ver [07_IMPLEMENTATION_GUIDE.md](07_IMPLEMENTATION_GUIDE.md) para detalles.

---

## 9. Referencias y Recursos

- **LÖVE Documentation:** https://love2d.org/wiki/Main_Page
- **sock.lua:** https://github.com/camchenry/sock.lua
- **bitser:** https://github.com/gvx/bitser
- **GaffeGames Tutorials:** Multiplayer game architecture
- **Valve's Source Engine:** Client-Server model inspiration
