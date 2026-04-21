# 🎮 Sistema de Niveles - Jumble

## Descripción General

El sistema de niveles implementa una arquitectura completa para gestionar múltiples desafíos con dificultad progresiva. Incluye 5 niveles distintos, cada uno con plataformas, obstáculos y límites de tiempo.

## Arquitectura

### 1. **Level.lua** (common/entities/)

Clase base que representa un nivel del juego.

```lua
local level = Level:new(id, name, difficulty)

-- Agregar elementos
level:addPlatform({x=100, y=200, width=150, height=32})
level:addObstacle({x=300, y=150, width=50, height=50})

-- Puntos especiales
level:setSpawnPoint(100, 750)    -- Punto de inicio
level:setGoalPoint(1500, 150)    -- Meta a alcanzar
level:setTimeLimit(120)          -- Límite en segundos
```

**Métodos principales:**
- `getPlatforms()` - Lista de plataformas
- `getObstacles()` - Lista de obstáculos
- `getSpawnPoint()` / `getGoalPoint()` - Puntos especiales
- `isPlayerAtGoal(x, y, w, h)` - Detectar colisión con meta

### 2. **LevelManager.lua** (server/game/)

Gestor centralizado del servidor para cargar, cambiar y verificar niveles.

```lua
local levelManager = LevelManager:new()

-- Registrar niveles
levelManager:registerLevel(require("server.levels.Level1"))
levelManager:registerLevel(require("server.levels.Level2"))

-- Cargar nivel
levelManager:loadLevel(1)

-- Verificar completación
if levelManager:checkLevelCompletion(player) then
    print("¡Nivel completado!")
end

-- Obtener información
local info = levelManager:getLevelInfo()
local platforms = levelManager:getPlatformsData()
local obstacles = levelManager:getObstaclesData()
```

**Métodos principales:**
- `loadLevel(id)` - Cargar nivel específico
- `loadNextLevel()` - Cargar próximo nivel
- `getCurrentLevel()` - Obtener nivel actual
- `checkLevelCompletion(player)` - Verificar si jugador llegó a meta
- `getCompletedPlayers()` - Ranking de completación
- `getElapsedTime()` - Tiempo transcurrido
- `isTimeExpired()` - Verificar si se agotó tiempo
- `getPlatformsData()` / `getObstaclesData()` - Para serializar

### 3. **LevelConfig.lua** (common/config/)

Configuración centralizada de todas las constantes de niveles.

```lua
LevelConfig.MAX_LEVELS = 5
LevelConfig.TIME_LIMITS = {120, 150, 180, 200, 300}
LevelConfig.DIFFICULTY_MULTIPLIER = {1.0, 1.1, 1.3, 1.5, 2.0}
```

## Niveles Implementados

### Level 1: Tutorial - Primeros Pasos
- **Dificultad:** 1 (Fácil)
- **Tiempo:** 120 segundos
- **Características:** Escalera progresiva, plataformas generosas
- **Objetivo:** Aprender mecánicas básicas

```
[SPAWN]
   ↓
  [P1]        [P2]        [P3]
        ↓            ↓
        [P4] grande [P5]
                      ↓
                    [META]
```

### Level 2: Saltos Precisos
- **Dificultad:** 2 (Normal)
- **Tiempo:** 150 segundos
- **Características:** Plataformas pequeñas, zig-zag
- **Objetivo:** Dominar precisión de saltos

### Level 3: Desafío de Timing
- **Dificultad:** 3 (Difícil)
- **Tiempo:** 180 segundos
- **Características:** Picos/obstáculos, timing crítico
- **Objetivo:** Evitar obstáculos mientras avanza

### Level 4: Velocidad Extrema
- **Dificultad:** 4 (Extremo)
- **Tiempo:** 200 segundos
- **Características:** Carrera rápida, muchos picos
- **Objetivo:** Velocidad y reflejos

### Level 5: Maestría - El Desafío Final
- **Dificultad:** 5 (Insane)
- **Tiempo:** 300 segundos
- **Características:** Combinación de todo, densidad máxima
- **Objetivo:** Maestría absoluta

## Integración en el Código

### En server/main.lua

```lua
-- Inicializar sistema de niveles
_G.levelManager = require("server.game.LevelManager"):new()

-- Registrar todos los niveles
_G.levelManager:registerLevel(require("server.levels.Level1"))
_G.levelManager:registerLevel(require("server.levels.Level2"))
-- ... etc

-- Cargar nivel inicial
_G.levelManager:loadLevel(1)

-- Vincular a GameState
_G.gameState.levelManager = _G.levelManager
```

### En common/state/PlayingState.lua

```lua
-- Obtener nivel del cliente
self.levelManager = _G.levelManager
self.currentLevel = self.levelManager:getCurrentLevel()

-- En update()
if self.levelManager:checkLevelCompletion(self.localPlayer) then
    print("¡Completaste el nivel!")
end

-- En draw()
love.graphics.printf("Nivel " .. self.currentLevel.id .. ": " .. self.currentLevel.name, 10, 10)
love.graphics.printf("Tiempo: " .. math.ceil(self.levelTimeRemaining) .. "s", 10, 35)

-- Dibujar meta
local goalX, goalY = self.currentLevel:getGoalPoint()
love.graphics.circle("fill", goalX, goalY, 32)
```

### En server/game/GameState.lua

```lua
-- En tick()
self:checkLevelCompletion()

-- Método para verificar
function GameState:checkLevelCompletion()
    for _, player in pairs(self.players) do
        if self.levelManager:checkLevelCompletion(player) then
            print("Jugador " .. player.id .. " completó el nivel")
        end
    end
end
```

## Flujo de Completación de Nivel

```
1. Jugador llega a la META (goalX, goalY)
                ↓
2. PlayingState.update() llama levelManager:checkLevelCompletion()
                ↓
3. LevelManager verifica AABB collision (64x64 área)
                ↓
4. Si colisiona, registra tiempo de completación
                ↓
5. PlayingState pausa y muestra "¡NIVEL COMPLETADO!"
                ↓
6. Opciones:
   - R: Reintentar mismo nivel
   - N: Próximo nivel
   - ESC: Volver a menú
```

## Cambio de Nivel

### Opción A: Presionar 'N' (Cliente)

```lua
-- En PlayingState:handleInput()
elseif key == "n" and self.paused and self.levelCompletionTime then
    if self.levelManager:loadNextLevel() then
        return "playing"  -- Reiniciar PlayingState
    end
end
```

### Opción B: Desde Servidor (Futuro)

```lua
-- En server/main.lua update()
if allPlayersCompleted then
    levelManager:loadNextLevel()
    broadcastLevelChange()
end
```

## Serialización para Red

### Datos del Nivel

```lua
local levelInfo = {
    id = 1,
    name = "Tutorial - Primeros Pasos",
    difficulty = 1,
    spawn = {x = 100, y = 750},
    goal = {x = 1500, y = 150},
    time_limit = 120,
    elapsed_time = 45,
    platforms_count = 10,
    obstacles_count = 0
}
```

### Plataformas (Comprimidas)

```lua
local platforms = {
    {x = 50, y = 800, width = 200, height = 32, type = 1},
    {x = 300, y = 750, width = 150, height = 32, type = 1},
    -- ... más plataformas
}
```

## Agregar Nuevo Nivel

### Paso 1: Crear archivo

```bash
# server/levels/Level6.lua
```

### Paso 2: Implementar

```lua
local Level = require("common.entities.Level")

local level = Level:new(6, "Mi Nuevo Nivel", 2)

level:setSpawnPoint(100, 750)
level:setGoalPoint(1500, 100)
level:setTimeLimit(180)

level:addPlatform({x = 100, y = 800, width = 200, height = 32})
level:addPlatform({x = 400, y = 700, width = 150, height = 32})
-- ... más plataformas

level:addObstacle({x = 300, y = 600, width = 50, height = 50, type = 1})
-- ... más obstáculos

return level
```

### Paso 3: Registrar

```lua
-- En server/main.lua
_G.levelManager:registerLevel(require("server.levels.Level6"))

-- Actualizar MAX_LEVELS en LevelConfig.lua
LevelConfig.MAX_LEVELS = 6
```

## Tipos de Plataformas

```lua
LevelConfig.PLATFORM = {
    NORMAL = 1,      -- Estática normal
    MOVING = 2,      -- Se mueve (futuro)
    BREAKABLE = 3,   -- Se rompe (futuro)
    BOUNCE = 4,      -- Rebota (futuro)
    ICE = 5          -- Resbaladiza (futuro)
}
```

## Tipos de Obstáculos

```lua
LevelConfig.OBSTACLE = {
    SPIKE = 1,       -- Pico
    SAW = 2,         -- Sierra giratoria
    LAVA = 3,        -- Lava
    WIND = 4         -- Viento
}
```

## HUD del Nivel

El cliente muestra:

```
┌────────────────────────────────────────────────────┐
│ Nivel 1: Tutorial - Primeros Pasos        Tiempo: 95s│
│                                                    │
│ [GAME AREA]                                        │
│ - Jugador (verde)                                 │
│ - Plataformas (marrón)                            │
│ - Meta (amarillo, círculo brillante)              │
│                                                    │
└────────────────────────────────────────────────────┘
```

### Durante Completación

```
┌────────────────────────────────────────────────────┐
│                                                    │
│            ¡NIVEL COMPLETADO!                     │
│            Tiempo: 45 segundos                    │
│                                                    │
│    P: Reanudar | N: Siguiente | ESC: Menú        │
│                                                    │
└────────────────────────────────────────────────────┘
```

## Características Futuras

- [ ] Plataformas móviles
- [ ] Plataformas frágiles (se rompen)
- [ ] Plataformas de rebote
- [ ] Obstáculos dañinos (game over)
- [ ] Powerups (velocidad, salto)
- [ ] Checkpoints/respawn points
- [ ] Clasificación/leaderboard
- [ ] Editor de niveles
- [ ] Niveles procedurales
- [ ] Replays

## Debugging

### Logs del Sistema de Niveles

```bash
# Ver solo logs de LEVEL
love server/ 2>&1 | grep "LEVEL"

# Ver completación
love server/ 2>&1 | grep "completó"
```

### Estadísticas

```lua
-- Obtener información del nivel
local stats = levelManager:getCurrentLevel():getStats()
-- {id=1, name="...", difficulty=1, platforms=10, obstacles=0, time_limit=120}

-- Ranking de completación
local completed = levelManager:getCompletedPlayers()
-- {{id=1, time=45}, {id=2, time=52}, ...}
```

## Rendimiento

- **Carga de nivel:** O(1) - Se registran al inicio
- **Verificación de meta:** O(1) - Simple AABB check
- **Memoria:** ~10KB por nivel (con ~10 plataformas)
- **CPU:** Negligible (<0.1ms por tick)

---

**Sistema de Niveles - Jumble v1.0** 🎮
