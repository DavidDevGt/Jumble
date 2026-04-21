# 🎮 SYSTEM DE NIVELES - RESUMEN RÁPIDO

## ✨ ¿Qué se Implementó?

### Archivos Nuevos Creados (8)
```
✓ common/entities/Level.lua                - Clase base de nivel
✓ common/config/LevelConfig.lua            - Configuración global
✓ server/game/LevelManager.lua             - Gestor de niveles (servidor)
✓ server/levels/Level1.lua                 - Tutorial (Fácil)
✓ server/levels/Level2.lua                 - Saltos Precisos (Normal)
✓ server/levels/Level3.lua                 - Timing (Difícil)
✓ server/levels/Level4.lua                 - Velocidad (Extremo)
✓ server/levels/Level5.lua                 - Maestría (Insane)
✓ docs/LEVEL_SYSTEM.md                     - Documentación completa
```

### Archivos Modificados (4)
```
~ common/protocol/MessageTypes.lua         + 4 tipos de mensajes
~ common/state/PlayingState.lua            + Lógica de niveles, HUD
~ server/main.lua                          + Inicialización de niveles
~ server/game/GameState.lua                + Verificación de completación
```

---

## 🎯 Características Principales

### 1. **5 Niveles Progresivos**

| Nivel | Nombre | Dif. | Tiempo | Plataformas | Obstáculos |
|-------|--------|------|--------|-------------|-----------|
| 1 | Tutorial | ⭐ | 120s | 8 | 0 |
| 2 | Saltos Precisos | ⭐⭐ | 150s | 9 | 0 |
| 3 | Timing | ⭐⭐⭐ | 180s | 9 | 4 |
| 4 | Velocidad | ⭐⭐⭐⭐ | 200s | 10 | 4 |
| 5 | Maestría | ⭐⭐⭐⭐⭐ | 300s | 11 | 6 |

### 2. **Mecánicas de Nivel**

✅ **Spawn Point** - Posición inicial del jugador  
✅ **Goal Point** - Meta a alcanzar (círculo amarillo)  
✅ **Plataformas** - Estáticas o móviles (futuro)  
✅ **Obstáculos** - Picos, sierras, lava (tipos definidos)  
✅ **Time Limit** - Contador de tiempo regresivo  
✅ **Completion Tracking** - Registro de tiempos  

### 3. **Interfaz de Usuario**

```
┌─ Nivel 1: Tutorial - Primeros Pasos    Tiempo: 95s ─┐
│                                                      │
│  [Jugador verde]                                     │
│          ╱╲                                          │
│         ╱  ╲                                         │
│   [════════]═════                    [Meta ○]        │
│                    ╲                    ╱            │
│                     ╲╱═════════╲═════╱              │
│                                                      │
│                 P: Pausar | ESC: Menú               │
└──────────────────────────────────────────────────────┘
```

### 4. **Sistema de Completación**

```lua
Jugador toca META (AABB collision 64x64)
    ↓
LevelManager:checkLevelCompletion() = true
    ↓
PlayingState pausa juego
    ↓
Muestra tiempo de completación
    ↓
Opciones: [R]eintentar | [N]ext | [ESC]Menú
```

---

## 🔧 Cómo Funciona

### Cliente (common/state/PlayingState.lua)

```lua
-- Carga el nivel
self.currentLevel = self.levelManager:getCurrentLevel()

-- Cada frame: verifica si llegó a la meta
if self.levelManager:checkLevelCompletion(self.localPlayer) then
    self.levelCompletionTime = tiempo
    self.paused = true
end

-- Dibuja información del nivel
draw_level_name()
draw_time_remaining()
draw_goal_position()
```

### Servidor (server/game/LevelManager.lua)

```lua
-- Registra niveles
levelManager:registerLevel(Level1)
levelManager:registerLevel(Level2)
-- ...

-- Carga nivel actual
levelManager:loadLevel(1)

-- Verifica completación cada tick
levelManager:checkLevelCompletion(player)

-- Obtiene datos para serializar
info = levelManager:getLevelInfo()
```

---

## 🚀 Uso Rápido

### Para Desarrolladores

**Agregar nuevo nivel:**

```lua
-- 1. Crear server/levels/Level6.lua
local Level = require("common.entities.Level")
local level = Level:new(6, "Mi Nivel", 2)

level:setSpawnPoint(100, 750)
level:setGoalPoint(1500, 100)
level:setTimeLimit(180)

level:addPlatform({x=100, y=800, width=200, height=32})
level:addObstacle({x=300, y=600, width=50, height=50})

return level

-- 2. Registrar en server/main.lua
_G.levelManager:registerLevel(require("server.levels.Level6"))

-- 3. Actualizar LevelConfig.MAX_LEVELS = 6
```

**Cambiar dificultad:**

```lua
-- En Level.lua constructor
local level = Level:new(1, "Tutorial", 0.5)  -- 0.5x difficulty

-- En LevelConfig.lua
LevelConfig.DIFFICULTY_MULTIPLIER[1] = 0.5  -- Más fácil
```

**Aumentar tiempo límite:**

```lua
-- En el archivo de nivel
level:setTimeLimit(300)  -- 5 minutos en vez de 2

-- O en LevelConfig.lua
LevelConfig.TIME_LIMITS[1] = 300
```

---

## 📊 Estadísticas

```
Archivos creados:        8
Líneas de código:        ~1,100
Módulos:                 3 (Level, LevelManager, LevelConfig)
Niveles:                 5
Documentación:           LEVEL_SYSTEM.md (400+ líneas)
Commit:                  a6e56ec
```

---

## 🎮 Pruebas

### Para Probar el Sistema

```bash
# 1. Iniciar servidor
cd C:\apps\Jumble
love server/

# 2. En otra terminal, iniciar cliente
love client/

# 3. Conectar al localhost:8888

# 4. Llegar a la meta (círculo amarillo)

# 5. Ver pantalla de completación con tiempo
```

**Controles:**
- `→` ← Mover izquierda/derecha
- `SPACE` Saltar
- `R` Reintentar (después de completar)
- `N` Siguiente nivel
- `P` Pausar
- `ESC` Menú

---

## 🔮 Próximas Mejoras

- [ ] Plataformas móviles que se mueven en patrones
- [ ] Plataformas frágiles que se rompen
- [ ] Plataformas de rebote para saltos extra
- [ ] Obstáculos que infligen daño (game over)
- [ ] Powerups (velocidad, altura de salto)
- [ ] Checkpoints dentro de niveles
- [ ] Leaderboard/clasificación
- [ ] Editor visual de niveles
- [ ] Niveles procedurales
- [ ] Replays y spectator mode

---

## 📚 Referencia Rápida

### Métodos Clave

```lua
-- Crear nivel
local level = Level:new(id, name, difficulty)

-- Agregar elementos
level:addPlatform({x, y, width, height})
level:addObstacle({x, y, width, height})

-- Puntos especiales
level:setSpawnPoint(x, y)
level:setGoalPoint(x, y)
level:setTimeLimit(segundos)

-- Consultar
level:getPlatforms()
level:getObstacles()
level:getSpawnPoint()
level:getGoalPoint()
level:isPlayerAtGoal(x, y, w, h)

-- LevelManager
levelManager:registerLevel(level)
levelManager:loadLevel(id)
levelManager:getCurrentLevel()
levelManager:checkLevelCompletion(player)
levelManager:getCompletedPlayers()
levelManager:getElapsedTime()
levelManager:isTimeExpired()
```

---

✅ **Sistema de Niveles Completo e Integrado**

El juego ahora tiene una progresión clara de dificultad con 5 niveles
distintos, cada uno con su propio diseño, obstáculos y límite de tiempo.

🎮 **¡Listo para jugar!**
