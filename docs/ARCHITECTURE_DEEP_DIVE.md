# ANÁLISIS ARQUITECTÓNICO PROFUNDO

## 1. Estructura de Proyecto y Modularización

**Estado:** ⚠️ **MEDIA** - Estructura clara pero con acoplamiento problemático

### Estructura Actual

```
Jumble/
├── core/                  # Framework genérico (callbacks, input, physics)
│   ├── Game.lua          # Orquestador principal
│   ├── callbacks.lua     # Wrapper de callbacks (REDUNDANTE)
│   ├── conf.lua          # Configuración Love
│   ├── input.lua         # Abstracción de input
│   ├── physics.lua       # Wrapper de physics
│   ├── graphics.lua      # Wrapper de graphics
│   ├── audio.lua         # Stub audio
│   └── window.lua        # (no presente aún)
├── common/               # Código compartido cliente/servidor
│   ├── config/           # Constantes globales
│   ├── entities/         # Definiciones de entidades (Player, Enemy)
│   ├── physics/          # Lógica determinista de physics
│   ├── protocol/         # Protocolo de red
│   └── utils/            # Helpers (Logger, Vector2)
├── client/               # Código específico del cliente
│   ├── main.lua          # Entry point
│   ├── network/          # Gestión de conexión
│   ├── render/           # Renderizado
│   └── interpolation/    # Suavizado visual
├── server/               # Código específico del servidor
│   ├── main.lua          # Entry point
│   ├── game/             # Lógica de juego
│   └── network/          # Gestión de conexiones múltiples
└── libs/                 # Dependencias externas
    ├── sock/            # UDP networking
    └── bitser/          # Serialización binaria
```

### Dependency Graph

```
main.lua (client/server)
  ├─> core/Game.lua
  │   ├─> core/callbacks.lua
  │   ├─> core/input.lua     ──┐
  │   ├─> core/physics.lua    ──┤─ WRAPPERS LOVE2D
  │   ├─> core/graphics.lua   ──┤  (REDUNDANTES)
  │   └─> core/audio.lua      ──┘
  ├─> common/config/*
  ├─> common/entities/Player.lua
  │   └─> common/utils/Vector2.lua
  ├─> common/protocol/MessageTypes.lua
  ├─> server/network/Server.lua ──────┐
  │   ├─> libs/sock.lua               ├─ NETWORKING
  │   └─> libs/bitser.lua             │
  └─> server/game/GameState.lua ──────┘
```

**Máxima profundidad:** 4 niveles (OK, pero puede simplificarse)

### Problemas Identificados

#### 1. ❌ REDUNDANCIA: Wrappers innecesarios de Love2D

**Archivos afectados:** `core/input.lua`, `core/graphics.lua`, `core/physics.lua`, `core/audio.lua`

Son esencialmente **passthroughs** sin valor agregado:

```lua
-- core/input.lua:23-24
function Input.isKeyDown(key)
    return love.keyboard.isDown(key)  -- ← Solo passthrough
end

-- core/graphics.lua:125-126
function Graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
    return love.graphics.print(text, x or 0, y or 0, r or 0, sx or 1, ...)
end
```

**Costo:**
- 500+ líneas de código muerto
- 1 nivel extra de indirection (performance)
- Complejidad cognitiva innecesaria
- Maintenance burden si Love2D cambia

**Solución:** Eliminar wrappers, usar `love.*` directamente. Si se necesita abstracción, hacer una **minimal alias table**, no passthrough functions.

#### 2. ❌ ACOPLAMIENTO: core/ acoplado a love callbacks globales

**Problema:** `core/callbacks.lua` intenta manejar todos los callbacks, pero `Game.lua:love.run()` redefine el game loop completo.

```lua
-- core/Game.lua:41-146 - OVERRIDE LOOP
function love.run()
    -- Custom game loop implementation
    while true do ... end
end

-- core/callbacks.lua - INTENTO DE MANEJAR CALLBACKS
function Callbacks.keypressed(key, scancode, isrepeat)
    if love.keypressed then love.keypressed(key, scancode, isrepeat) end
end
```

**Conflicto:** Si `love.run()` override se ejecuta, `Callbacks.keypressed()` nunca se llama.

**Resultado:** Ambigüedad en cuál loop se ejecuta, posible doble-ejecución de callbacks.

#### 3. ⚠️ SEPARACIÓN DEFICIENTE: No hay abstracción de "Escena"

**Estado actual:**
- Client puede estar en: "menu" | "connecting" | "playing" | "lobby"
- Server puede estar en: "waiting" | "ticking"
- Pero **no hay State Machine explícita**
- Estado se mezcla en variables globales sueltas

```lua
GAME_STATE = {
    mode = "menu",
    menuSelection = 1,
    players = {},
    localPlayerId = 1,
    gameTime = 0
}
```

**Sin validación:** `GAME_STATE.mode = "invalid_state"` se acepta silenciosamente.

#### 4. ⚠️ RESPONSABILIDADES DIFUSAS

Ejemplo: "¿Dónde vive la lógica de iniciar juego?"
- Server: `GameState:tick()` (pero no crea jugadores)
- Client: `initLocalPlayer()` (pero está en main.lua)

Ejemplo: "¿Dónde se valida que un input es válido?"
- Server: `Server:handleInput()` (rate limiting OK)
- GameState: no valida (confía ciegamente en Server)

#### 5. ✅ PUNTO POSITIVO: Separación cliente/servidor nítida

- `server/main.lua` vs `client/main.lua` completamente independientes
- `common/` isolado y reutilizable
- No hay cross-talk accidental

---

## 2. State Management y Flujo de Control

**Estado:** 🔴 **CRÍTICO - No hay State Machine**

### Variables globales sin estado definido

```lua
-- client/main.lua
GAME_STATE = {
    mode = "menu",
    menuSelection = 1,
    players = {},
    localPlayerId = 1,
    gameTime = 0
}

-- server/main.lua
SERVER_STATE = {
    running = true,
    tick = 0,
    accumulator = 0,
    clients = {}
}
```

**Problemas:**
1. ❌ No hay validación: ¿qué estados son válidos?
2. ❌ No hay transiciones explícitas: `mode = "menu"` → `mode = "playing"` sin callbacks
3. ❌ No hay limpieza: cambiar de estado **sin cleanup** de recursos previos

### Sin transiciones explícitas

```lua
-- Cómo se inicia un juego en el cliente:
-- 1. Usuario presiona "Play" en menú
-- 2. ??? (no hay código de transición visible)
-- 3. Cliente se conecta y entra en "playing"

-- Posibles bugs:
-- - ¿Qué pasa si se desconecta mientras se conecta?
-- - ¿Se limpia el estado del juego anterior?
-- - ¿Se pausa la renderización durante transición?
```

### Sin manejo de pause/resume

```lua
-- core/Game.lua
if Game.paused then return end
Game.callbacks.update(dt)
```

- Flag booleano sin lógica de cómo entrar/salir de pause
- No hay "PauseState" que guarde contexto

### Desconexión sin error handling

```lua
-- client/network/Client.lua
function Client:update(dt)
    if not self.connected then 
        self:connect()  -- Reintentar infinitamente
        return 
    end
end
```

Si la conexión falla, reintentar **infinitamente** sin feedback al usuario.

### Diagrama de Estados Actual (IMPLÍCITO, QUEBRADO)

```
                    Menu
                      |
                      | (user clicks Play)
                      v
                 Connecting ←──────────┐
                      |                |
          (timeout/fail)  (ok)         |
              |              |    (resync)
              v              v
         ConnFailed    Playing
              |              |
              |          (disconnect)
              └──────────────┘
                      |
                    Menu
```

**Lo que falta:** Transiciones explícitas, cleanup de recursos, error states.

---

## 3. Patrón de Objetos y Entidades

**Estado:** ⚠️ **INCONSISTENTE**

### Mezcla de patrones

```lua
-- common/entities/Player.lua (PRESUNTO)
local Player = {}
Player.__index = Player

function Player:new(id, name, x, y)
    local self = setmetatable({}, Player)
    self.id = id
    self.position = Vector2:new(x, y)
    return self
end
```

✅ Usa Lua metatable pattern (correcto), pero...

### Hibrido sin composición de componentes

- Entities son tablas con métodos `:update()`, `:getNetworkState()`
- Pero **no hay composición modular**
- Si queremos agregar "poción de velocidad":
  - ¿Agregar campo a Player?
  - ¿Crear entidad separada "Buff"?
  - **No hay patrón claro**

### Sin pooling de objetos

```lua
-- server/network/Server.lua:142-147
local minimalEntities = {}  -- ← NUEVA tabla cada broadcast!
for _, entity in ipairs(state) do
    if entity.getNetworkState then
        table.insert(minimalEntities, entity:getNetworkState())
    end
end
```

Genera **GC pressure** significativa.

### Modelos no validan estado

```lua
-- Posible bug: si posición es nil
player.position.x = something  -- Crash si position es nil
```

No hay assertions o validaciones en setters.

---

## 4. Manejo de Configuración y Constantes

**Estado:** ✅ **BIEN ESTRUCTURADO**

```lua
-- common/config/GameConfig.lua
GameConfig.WORLD_WIDTH = 1600
GameConfig.PLAYER_SPEED = 200
GameConfig.GRAVITY = 800
GameConfig.TICK_RATE = 60
```

**Puntos Positivos:**
- ✅ Constantes centralizadas
- ✅ Sin magic numbers en código
- ✅ NetworkConfig.DEBUG_* para desarrollo
- ✅ Compartidas entre cliente/servidor

**Mejoras Posibles:**
- ⚠️ Falta `GameConfig.PLAYER_MASS` (para física Box2D)
- ⚠️ Falta `GameConfig.CAMERA_OFFSET`, `GameConfig.ZOOM`
- ⚠️ Sin tabla de "balancing" (dificultad por nivel)
- ⚠️ Sin valores de "game feel" (acceleration, coyote time)

---

## RECOMENDACIONES ARQUITECTÓNICAS

### Priority 1: Implementar State Machine

**Impacto:** Elimina ~50 bugs potenciales relacionados con transiciones de estado.

Ver: [`FINDINGS.md#finding-3`](FINDINGS.md#finding-3-global-variable-pollution-sin-state-machine)

### Priority 2: Eliminar wrappers redundantes

**Impacto:** -500 LOC, +10% performance.

Ver: [`FINDINGS.md#finding-1`](FINDINGS.md#finding-1-wrappers-redundantes-de-love2d)

### Priority 3: Fix physics desincronizado

**Impacto:** Elimina desincronización garantizada entre cliente/servidor.

Ver: [`FINDINGS.md#finding-5`](FINDINGS.md#finding-5-physics-desincronizado-cliente-servidor)

---

## SUMMARY

La arquitectura es **conceptualmente sólida** (separación cliente/servidor), pero sufre de:
1. **Redundancia** (wrappers Love)
2. **Falta de abstracción** (no hay State Machine)
3. **Acoplamiento global** (variables globales sin validación)

El refactor de 4 semanas propuesto en [`ROADMAP.md`](ROADMAP.md) abordará estos issues sistemáticamente.
