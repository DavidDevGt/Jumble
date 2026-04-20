# PROJECT_STRUCTURE.md - Estructura Completa del Proyecto

## Árbol de Directorios

```
Jumble/
│
├── 📄 README.md                    # Descripción general del proyecto
├── 📄 docs/                        # ← DOCUMENTACIÓN (LEER AQUÍ)
│   ├── 00_START_HERE.md           # Punto de entrada
│   ├── 01_ARCHITECTURE.md         # Documentación de arquitectura
│   ├── 02_QUICK_START.md          # Inicio rápido (5 minutos)
│   ├── 03_NETWORKING.md           # Protocolo de comunicación
│   ├── 04_SETUP.md                # Guía de instalación
│   ├── 05_ADVANCED_PATTERNS.md    # Patrones avanzados
│   ├── 06_PROJECT_STRUCTURE.md    # Este archivo
│   └── 07_IMPLEMENTATION_GUIDE.md # Guía de implementación
│
├── 📁 common/                      # CÓDIGO COMPARTIDO (Cliente y Servidor)
│   │
│   ├── 📁 config/
│   │   ├── GameConfig.lua          # Constantes del juego
│   │   └── NetworkConfig.lua       # Configuración de red
│   │
│   ├── 📁 protocol/
│   │   ├── MessageTypes.lua        # Enumeración de tipos de mensaje
│   │   └── Serialization.lua       # Serialización/Deserialización
│   │
│   ├── 📁 entities/
│   │   ├── Player.lua              # Entidad Jugador
│   │   ├── Projectile.lua          # (Ejemplo: Proyectil)
│   │   └── World.lua               # (Futuro: Gestión de mundo)
│   │
│   ├── 📁 physics/
│   │   ├── Collision.lua           # Detección de colisiones (AABB)
│   │   └── Movement.lua            # Física de movimiento
│   │
│   ├── 📁 utils/
│   │   ├── Vector2.lua             # Helper de vectores 2D
│   │   └── Logger.lua              # Sistema de logging
│   │
│   ├── 📁 ecs/                     # (Futuro: Entity Component System)
│   │   ├── Entity.lua
│   │   ├── Component.lua
│   │   └── System.lua
│   │
│   └── 📁 store/                   # (Futuro: State Management)
│       └── Store.lua
│
├── 📁 client/                      # CLIENTE LÖVE
│   │
│   ├── main.lua                    # Punto de entrada (love.load, love.update, love.draw)
│   ├── conf.lua                    # Configuración LÖVE (ventana, módulos)
│   │
│   ├── 📁 network/
│   │   ├── Client.lua              # Gestor de conexión al servidor
│   │   └── InputManager.lua        # Captura de entrada del usuario
│   │
│   ├── 📁 render/
│   │   ├── Renderer.lua            # Sistema de renderizado
│   │   └── Camera.lua              # (Futuro: Control de cámara)
│   │
│   ├── 📁 interpolation/
│   │   └── EntityInterpolator.lua  # Interpolación suave de entidades
│   │
│   ├── 📁 states/                  # (Futuro: State machine)
│   │   ├── Connecting.lua
│   │   ├── Menu.lua
│   │   └── InGame.lua
│   │
│   └── 📁 assets/                  # Recursos
│       ├── sprites/
│       └── fonts/
│
├── 📁 server/                      # SERVIDOR LÖVE (Autoritativo)
│   │
│   ├── main.lua                    # Punto de entrada servidor
│   ├── conf.lua                    # Configuración LÖVE
│   │
│   ├── 📁 network/
│   │   ├── Server.lua              # Gestor de conexiones y sockets
│   │   ├── ClientManager.lua       # (Futuro: Admin de clientes)
│   │   └── PacketHandler.lua       # (Futuro: Procesamiento de paquetes)
│   │
│   ├── 📁 game/
│   │   ├── GameState.lua           # Estado canónico del juego
│   │   ├── GameLogic.lua           # (Futuro: Lógica de juego)
│   │   └── TickManager.lua         # Tick determinista (60 Hz)
│   │
│   ├── 📁 antiCheat/               # (Futuro: Anti-trampas)
│   │   ├── InputValidator.lua
│   │   └── BehaviorAnalyzer.lua
│   │
│   └── 📁 persistence/             # (Futuro: Base de datos)
│       └── Database.lua
│
└── 📁 libs/                        # LIBRERÍAS EXTERNAS (agregar después)
    ├── sock/                       # sock.lua - Networking
    ├── bitser/                     # Serialización binaria
    ├── classic/                    # OOP en Lua (opcional)
    ├── inspect/                    # Debugging (opcional)
    └── tick/                       # Timer manager (opcional)
```

---

## Descripción de Archivos

### Configuración Global

| Archivo | Responsabilidad | Ejemplo de Uso |
|---------|-----------------|-----------------|
| `common/config/GameConfig.lua` | Constantes del juego | `GameConfig.PLAYER_SPEED` |
| `common/config/NetworkConfig.lua` | Parámetros de red | `NetworkConfig.SERVER_HOST` |

### Protocolo

| Archivo | Responsabilidad |
|---------|-----------------|
| `common/protocol/MessageTypes.lua` | Enumeración de tipos (CONNECT, INPUT, STATE_UPDATE) |
| `common/protocol/Serialization.lua` | Convertir datos a/desde formato transmisible |

### Entidades

| Archivo | Tipo | Propiedades |
|---------|------|-------------|
| `common/entities/Player.lua` | Entidad | position, velocity, health, state |
| `common/entities/Projectile.lua` | (Future) | position, velocity, lifetime |

### Física

| Archivo | Responsabilidad |
|---------|-----------------|
| `common/physics/Collision.lua` | AABB, Circle-Box, Circle-Circle |
| `common/physics/Movement.lua` | Velocity, Acceleration, Friction |

### Cliente - Network

| Archivo | Responsabilidad |
|---------|-----------------|
| `client/network/Client.lua` | Conectar, enviar INPUT, recibir STATE_UPDATE |
| `client/network/InputManager.lua` | Leer teclado, normalizar, rate limit |

### Cliente - Render

| Archivo | Responsabilidad |
|---------|-----------------|
| `client/render/Renderer.lua` | Dibujar entidades, UI |
| `client/interpolation/EntityInterpolator.lua` | Suavizar movimientos entre estados |

### Servidor - Network

| Archivo | Responsabilidad |
|---------|-----------------|
| `server/network/Server.lua` | Socket, aceptar conexiones, broadcast |
| `server/network/ClientManager.lua` | (Future) Track de clientes activos |

### Servidor - Game

| Archivo | Responsabilidad |
|---------|-----------------|
| `server/game/GameState.lua` | Estado canónico: entidades, players |
| `server/game/TickManager.lua` | Tick determinista a 60 Hz |
| `server/game/GameLogic.lua` | (Future) Validación de acciones |

---

## Flujo de Datos

### 1. Startup (Inicio)

```
┌─────────────────┐
│  love.load()    │
└────────┬────────┘
         │
         ├─→ Cargar GameConfig
         ├─→ Cargar NetworkConfig
         ├─→ Inicializar Logger
         │
         ├─ CLIENTE:
         │  ├─→ InputManager:new()
         │  ├─→ Client:new()
         │  └─→ EntityInterpolator:new()
         │
         └─ SERVIDOR:
            ├─→ Server:new()
            ├─→ GameState:new()
            └─→ TickManager:new()
```

### 2. Update Loop (Cada Frame)

**Cliente (60 FPS = 16.67ms/frame):**

```
love.update(0.0167s)
  ├─ InputManager:update()
  │  └─ Leer teclado → normalizar → guardar
  ├─ Client:update()
  │  └─ Recibir paquetes del servidor
  ├─ EntityInterpolator:update()
  │  └─ Suavizar posiciones
  └─ gameState:updateLocal()
     └─ (Predicción local del cliente)

love.draw()
  ├─ Renderer:drawEntities() ← posición interpolada
  └─ UI:draw()
```

**Servidor (60 ticks/segundo = 16.67ms/tick):**

```
love.update(dt)
  ├─ Server:update()
  │  ├─ Aceptar conexiones
  │  └─ Recibir INPUTs
  ├─ Acumular tiempo
  └─ while accumulator >= TICK_TIME:
     ├─ GameState:tick()
     │  ├─ Aplicar inputs validados
     │  ├─ Simular física
     │  ├─ Detectar colisiones
     │  └─ Actualizar estado
     ├─ Server:broadcastState()
     │  └─ Enviar STATE_UPDATE a todos
     └─ accumulator -= TICK_TIME
```

### 3. Message Flow (Ciclo de Input)

```
CLIENTE                              SERVIDOR
   │                                   │
   ├─ Capturar input (WASD)           │
   │                                   │
   ├─ InputManager:getInput()          │
   │  └─ return {x: 1, y: 0}          │
   │                                   │
   ├─ Enviar INPUT                    │
   │  └─ Client:sendInput()            │
   │     └─ client.socket:send()      │
   │         {type: INPUT, ...}       │
   │                                   │
   ├─ Predecir localmente             │
   │  └─ gameState:predictMovement()   │
   │     └─ position += velocity * dt  │
   │                                   │
   ├─ Renderizar predicción            │
   │  └─ Renderer:drawEntities()       │
   │                                   │
   │                          ┌─ Recibir INPUT
   │                          │ InputValidator:validateInput()
   │                          │  └─ Verificar speed, frequency, etc.
   │                          │
   │                          ├─ Aplicar a GameState
   │                          │ GameState:applyInput(clientId, input)
   │                          │
   │                          ├─ Simular física
   │                          │ GameState:tick()
   │                          │
   │                          ├─ Compilar STATE_UPDATE
   │                          │ {tick, entities, events, ...}
   │                          │
   │                          └─ Broadcast a TODOS
   │                             Server:broadcastGameState()
   │
   ├─ Recibir STATE_UPDATE ←──────────┘
   │ Client:handleStateUpdate(data)
   │
   ├─ Comparar predicción vs real
   │ diff = |predicción - data.position|
   │
   ├─ Si diff pequeña: interpolación
   │ EntityInterpolator:updateEntity()
   │
   ├─ Si diff grande: corrección brusca
   │ Teleport a nueva posición
   │
   └─ Renderizar con nueva posición
      (Próximo frame love.draw())
```

---

## Dependency Graph

```
┌────────────────────────────────────────────────────────┐
│                  CAPA COMPARTIDA (common/)             │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐   │
│  │ GameConfig  │  │ NetworkConfig│  │MessageTypes│   │
│  └──────┬──────┘  └──────┬───────┘  └──────┬─────┘   │
│         │                │                │          │
│  ┌──────▼──────────────────────────────────▼─────┐    │
│  │         Serialization (Protocol)             │    │
│  └──────────────┬────────────────────────────────┘    │
│                 │                                      │
│  ┌──────────────▼──────┐      ┌──────────────────┐   │
│  │   Vector2, Logger  │      │  Collision,      │   │
│  │   (Utils)          │      │  Movement        │   │
│  │                    │      │  (Physics)       │   │
│  └────────────────────┘      └────────┬─────────┘   │
│                                       │              │
│                              ┌────────▼─────────┐   │
│                              │   Player Entity  │   │
│                              │   (entities/)    │   │
│                              └──────────────────┘   │
│                                                     │
└─────────────────────┬──────────────────────┬────────┘
                      │                      │
        ┌─────────────▼────────┐  ┌──────────▼────────┐
        │   CLIENT (client/)   │  │  SERVER (server/) │
        │                      │  │                   │
        │ ┌─────────────────┐  │  │ ┌──────────────┐  │
        │ │ InputManager    │  │  │ │ Server       │  │
        │ │ Client          │  │  │ │ GameState    │  │
        │ │ Renderer        │  │  │ │ TickManager  │  │
        │ │ EntityInterp.   │  │  │ │ GameLogic    │  │
        │ └─────────────────┘  │  │ └──────────────┘  │
        │                      │  │                   │
        └──────────────────────┘  └───────────────────┘
                      │                      │
                      └──────────┬───────────┘
                                 │
                          [NETWORK UDP/TCP]
```

---

## Cómo Navegar el Código

### Para Entender la Arquitectura:
1. Lee docs/01_ARCHITECTURE.md
2. Revisa common/config/GameConfig.lua
3. Estudia server/main.lua y client/main.lua

### Para Modificar Constantes:
- common/config/GameConfig.lua - Velocidades, tamaños, física
- common/config/NetworkConfig.lua - Puertos, rates, timeouts

### Para Agregar Lógica de Juego:
- server/game/GameState.lua - Lógica principal
- common/entities/Player.lua - Comportamiento de jugador

### Para Mejorar Networking:
- server/network/Server.lua - Lado servidor
- client/network/Client.lua - Lado cliente
- common/protocol/MessageTypes.lua - Definir nuevos mensajes

### Para Optimizar Rendimiento:
- client/interpolation/EntityInterpolator.lua - Suavidad
- client/render/Renderer.lua - Dibujo eficiente
- docs/05_ADVANCED_PATTERNS.md - Patrones avanzados

---

## Checklist de Desarrollo

### Setup Inicial
- [ ] Clonar repositorio
- [ ] Instalar LÖVE 11.5
- [ ] Descargar librerías (sock, bitser)
- [ ] Ejecutar servidor y cliente

### Entender el Código
- [ ] Leer docs/01_ARCHITECTURE.md
- [ ] Ejecutar con DEBUG_PACKETS = true
- [ ] Revisar logs de servidor

### Agregar Feature
- [ ] Diseñar arquitectura
- [ ] Implementar en común/ (si aplica)
- [ ] Implementar en servidor/
- [ ] Implementar en cliente/
- [ ] Validar contra trampas
- [ ] Optimizar si es necesario

### Testing
- [ ] Test local (1 server + 3 clients)
- [ ] Test con latencia simulada (50ms, 100ms)
- [ ] Test stress (muchos jugadores)
- [ ] Test de cheats (verificar validaciones)

### Deployment
- [ ] Compilar con love --fused
- [ ] Crear ejecutable
- [ ] Distribuir

---

## Próximas Mejoras Sugeridas

| Prioridad | Feature | Ubicación | Complejidad |
|-----------|---------|-----------|------------|
| 🔴 Alta | Lobby/Matchmaking | client/states/Menu | Media |
| 🟡 Media | Chat system | server/game + client/ui | Baja |
| 🟡 Media | Inventory | common/entities | Media |
| 🟢 Baja | Particle effects | client/render/Effects | Media |
| 🟢 Baja | Sound/Music | client/assets | Baja |
| 🔴 Alta | Persistencia BD | server/persistence | Alta |
| 🟡 Media | Ranking | server/persistence | Media |

