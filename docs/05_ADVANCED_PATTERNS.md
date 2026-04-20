# ADVANCED_PATTERNS.md - Patrones Avanzados

## Tabla de Contenidos

1. [Event System](#event-system)
2. [Entity Component System (ECS)](#entity-component-system)
3. [State Management](#state-management)
4. [Performance Optimization](#performance-optimization)
5. [Anti-Cheat Patterns](#anti-cheat-patterns)

---

## Event System

### Event Bus Global

```lua
-- common/EventSystem.lua
local EventSystem = {}
EventSystem.__index = EventSystem

function EventSystem:new()
    local self = setmetatable({}, EventSystem)
    self.listeners = {}
    self.queue = {}
    return self
end

function EventSystem:on(eventType, callback)
    if not self.listeners[eventType] then
        self.listeners[eventType] = {}
    end
    table.insert(self.listeners[eventType], callback)
end

function EventSystem:off(eventType, callback)
    if self.listeners[eventType] then
        for i, cb in ipairs(self.listeners[eventType]) do
            if cb == callback then
                table.remove(self.listeners[eventType], i)
                break
            end
        end
    end
end

function EventSystem:emit(eventType, data)
    if self.listeners[eventType] then
        for _, callback in ipairs(self.listeners[eventType]) do
            callback(data)
        end
    end
end

function EventSystem:queueEvent(eventType, data)
    table.insert(self.queue, {type = eventType, data = data})
end

function EventSystem:processQueue()
    for _, event in ipairs(self.queue) do
        self:emit(event.type, event.data)
    end
    self.queue = {}
end

return EventSystem
```

### Uso en Servidor

```lua
-- server/main.lua
_G.eventSystem = require("common.EventSystem"):new()

-- Escuchar eventos
eventSystem:on("player_joined", function(data)
    Logger:info("SERVER", "Jugador entró: " .. data.playerName)
    broadcastChatMessage(data.playerName .. " se unió al juego")
end)

eventSystem:on("player_died", function(data)
    Logger:info("SERVER", data.playerName .. " fue asesinado por " .. data.killerName)
end)

-- En GameState:tick()
local events = gameState:getEvents()  -- Eventos de física, colisiones, etc.

for _, event in ipairs(events) do
    if event.type == "collision" then
        eventSystem:emit("entity_collision", event)
    elseif event.type == "out_of_bounds" then
        eventSystem:emit("entity_out_of_bounds", event)
    end
end

-- Procesar cola de eventos
eventSystem:processQueue()
```

---

## Entity Component System (ECS)

### Arquitectura ECS Simple

```lua
-- common/ecs/Component.lua
local Component = {}

function Component:new(componentType)
    return {
        type = componentType,
        enabled = true
    }
end

return Component
```

```lua
-- common/ecs/TransformComponent.lua
local Component = require("common.ecs.Component")

local TransformComponent = setmetatable({}, {__index = Component})
TransformComponent.__index = TransformComponent

function TransformComponent:new()
    local self = Component:new("transform")
    self.position = {x = 0, y = 0}
    self.rotation = 0
    self.scale = {x = 1, y = 1}
    self.velocity = {x = 0, y = 0}
    return self
end

return TransformComponent
```

```lua
-- common/ecs/HealthComponent.lua
local Component = require("common.ecs.Component")

local HealthComponent = setmetatable({}, {__index = Component})
HealthComponent.__index = HealthComponent

function HealthComponent:new(maxHealth)
    local self = Component:new("health")
    self.maxHealth = maxHealth
    self.currentHealth = maxHealth
    self.isDead = false
    return self
end

function HealthComponent:takeDamage(amount)
    self.currentHealth = math.max(0, self.currentHealth - amount)
    if self.currentHealth <= 0 then
        self.isDead = true
    end
end

function HealthComponent:heal(amount)
    self.currentHealth = math.min(self.maxHealth, self.currentHealth + amount)
end

return HealthComponent
```

```lua
-- common/ecs/Entity.lua
local Entity = {}
Entity.__index = Entity

function Entity:new(id, entityType)
    local self = setmetatable({}, Entity)
    self.id = id
    self.type = entityType
    self.components = {}
    self.active = true
    return self
end

function Entity:addComponent(component)
    self.components[component.type] = component
    return self
end

function Entity:getComponent(componentType)
    return self.components[componentType]
end

function Entity:hasComponent(componentType)
    return self.components[componentType] ~= nil
end

function Entity:removeComponent(componentType)
    self.components[componentType] = nil
end

function Entity:update(dt)
    for _, component in pairs(self.components) do
        if component.enabled and component.update then
            component:update(dt, self)
        end
    end
end

return Entity
```

### Uso en Juego

```lua
-- server/game/GameState.lua
local Entity = require("common.ecs.Entity")
local TransformComponent = require("common.ecs.TransformComponent")
local HealthComponent = require("common.ecs.HealthComponent")

function GameState:createPlayer(id, name, x, y)
    local entity = Entity:new(id, "player")
    
    -- Agregar componentes
    local transform = TransformComponent:new()
    transform.position = {x = x, y = y}
    entity:addComponent(transform)
    
    local health = HealthComponent:new(100)
    entity:addComponent(health)
    
    -- Meta información
    entity.name = name
    entity.playerData = {
        kills = 0,
        deaths = 0
    }
    
    return entity
end

function GameState:tick(dt)
    for _, entity in ipairs(self.entities) do
        if entity.active then
            entity:update(dt)
            
            -- Lógica específica de tipo
            if entity.type == "player" then
                local health = entity:getComponent("health")
                if health and health.isDead then
                    self:handlePlayerDeath(entity)
                end
            end
        end
    end
end
```

---

## State Management

### Redux-Like Pattern

```lua
-- common/store/Store.lua
local Store = {}
Store.__index = Store

function Store:new(initialState)
    local self = setmetatable({}, Store)
    self.state = initialState or {}
    self.listeners = {}
    self.history = {}
    return self
end

function Store:subscribe(listener)
    table.insert(self.listeners, listener)
end

function Store:unsubscribe(listener)
    for i, l in ipairs(self.listeners) do
        if l == listener then
            table.remove(self.listeners, i)
            break
        end
    end
end

function Store:dispatch(action)
    local newState = self:reducer(self.state, action)
    self.state = newState
    
    -- Guardar en historial para debugging
    table.insert(self.history, {
        action = action,
        state = self:deepCopy(newState)
    })
    
    -- Notificar listeners
    for _, listener in ipairs(self.listeners) do
        listener(newState)
    end
end

function Store:getState()
    return self.state
end

function Store:reducer(state, action)
    -- Override en subclases
    return state
end

function Store:deepCopy(obj)
    if type(obj) ~= "table" then return obj end
    
    local result = {}
    for k, v in pairs(obj) do
        result[k] = self:deepCopy(v)
    end
    return result
end

return Store
```

```lua
-- server/game/GameStore.lua
local Store = require("common.store.Store")

local GameStore = setmetatable({}, {__index = Store})
GameStore.__index = GameStore

function GameStore:new()
    local initialState = {
        tick = 0,
        players = {},
        entities = {},
        events = {}
    }
    return Store.new(self, initialState)
end

function GameStore:reducer(state, action)
    if action.type == "PLAYER_JOINED" then
        state.players[action.playerId] = {
            name = action.playerName,
            position = {x = 0, y = 0}
        }
    elseif action.type == "PLAYER_MOVED" then
        if state.players[action.playerId] then
            state.players[action.playerId].position = action.newPosition
        end
    elseif action.type == "TICK" then
        state.tick = state.tick + 1
    end
    
    return state
end

return GameStore
```

### Uso

```lua
-- server/main.lua
local GameStore = require("server.game.GameStore")

_G.gameStore = GameStore:new()

-- Escuchar cambios de estado
gameStore:subscribe(function(state)
    Logger:debug("STORE", "Estado actualizado: tick " .. state.tick)
end)

-- Actualizar estado
gameStore:dispatch({
    type = "PLAYER_JOINED",
    playerId = 1,
    playerName = "JohnDoe"
})

gameStore:dispatch({
    type = "PLAYER_MOVED",
    playerId = 1,
    newPosition = {x = 100, y = 200}
})
```

---

## Performance Optimization

### Object Pool Pattern

```lua
-- common/ObjectPool.lua
local ObjectPool = {}
ObjectPool.__index = ObjectPool

function ObjectPool:new(objectType, initialSize)
    local self = setmetatable({}, ObjectPool)
    self.objectType = objectType
    self.available = {}
    self.inUse = {}
    
    for i = 1, initialSize do
        table.insert(self.available, objectType:new())
    end
    
    return self
end

function ObjectPool:acquire()
    local obj
    
    if #self.available > 0 then
        obj = table.remove(self.available)
    else
        obj = self.objectType:new()
    end
    
    self.inUse[obj.id] = obj
    obj:reset()
    return obj
end

function ObjectPool:release(obj)
    self.inUse[obj.id] = nil
    table.insert(self.available, obj)
end

function ObjectPool:getStats()
    return {
        available = #self.available,
        inUse = #self.inUse,
        total = #self.available + #self.inUse
    }
end

return ObjectPool
```

### Uso con Proyectiles

```lua
-- common/entities/Projectile.lua
local Projectile = {}
Projectile.__index = Projectile

local id_counter = 0

function Projectile:new()
    id_counter = id_counter + 1
    return setmetatable({id = id_counter}, Projectile)
end

function Projectile:reset()
    self.active = true
    self.position = {x = 0, y = 0}
    self.velocity = {x = 0, y = 0}
    self.lifetime = 10
end

function Projectile:update(dt)
    self.position.x = self.position.x + self.velocity.x * dt
    self.position.y = self.position.y + self.velocity.y * dt
    self.lifetime = self.lifetime - dt
    
    if self.lifetime <= 0 then
        self.active = false
    end
end

return Projectile
```

```lua
-- server/game/ProjectileManager.lua
local ObjectPool = require("common.ObjectPool")
local Projectile = require("common.entities.Projectile")

local ProjectileManager = {}
ProjectileManager.__index = ProjectileManager

function ProjectileManager:new()
    local self = setmetatable({}, ProjectileManager)
    self.pool = ObjectPool:new(Projectile, 100)  -- Pool de 100 proyectiles
    return self
end

function ProjectileManager:fire(position, velocity)
    local projectile = self.pool:acquire()
    projectile.position = {x = position.x, y = position.y}
    projectile.velocity = {x = velocity.x, y = velocity.y}
    return projectile
end

function ProjectileManager:update(dt)
    local toRemove = {}
    
    for objId, projectile in pairs(self.pool.inUse) do
        projectile:update(dt)
        
        if not projectile.active then
            table.insert(toRemove, projectile)
        end
    end
    
    for _, projectile in ipairs(toRemove) do
        self.pool:release(projectile)
    end
end

function ProjectileManager:getStats()
    return self.pool:getStats()
end

return ProjectileManager
```

### Spatial Partitioning

```lua
-- common/SpatialGrid.lua
local SpatialGrid = {}
SpatialGrid.__index = SpatialGrid

function SpatialGrid:new(cellSize, width, height)
    local self = setmetatable({}, SpatialGrid)
    self.cellSize = cellSize
    self.gridWidth = math.ceil(width / cellSize)
    self.gridHeight = math.ceil(height / cellSize)
    self.cells = {}
    return self
end

function SpatialGrid:getCellCoordinates(x, y)
    return math.floor(x / self.cellSize) + 1,
           math.floor(y / self.cellSize) + 1
end

function SpatialGrid:insert(entity)
    local gx, gy = self:getCellCoordinates(entity.position.x, entity.position.y)
    
    if gx > 0 and gx <= self.gridWidth and gy > 0 and gy <= self.gridHeight then
        local cellKey = gx .. "," .. gy
        
        if not self.cells[cellKey] then
            self.cells[cellKey] = {}
        end
        
        table.insert(self.cells[cellKey], entity)
    end
end

function SpatialGrid:query(position, range)
    local results = {}
    local minGx, minGy = self:getCellCoordinates(position.x - range, position.y - range)
    local maxGx, maxGy = self:getCellCoordinates(position.x + range, position.y + range)
    
    for gx = minGx, maxGx do
        for gy = minGy, maxGy do
            local cellKey = gx .. "," .. gy
            if self.cells[cellKey] then
                for _, entity in ipairs(self.cells[cellKey]) do
                    local dx = entity.position.x - position.x
                    local dy = entity.position.y - position.y
                    if dx*dx + dy*dy <= range*range then
                        table.insert(results, entity)
                    end
                end
            end
        end
    end
    
    return results
end

function SpatialGrid:clear()
    self.cells = {}
end

return SpatialGrid
```

---

## Anti-Cheat Patterns

### Input Validation Framework

```lua
-- server/antiCheat/InputValidator.lua
local InputValidator = {}

function InputValidator:validatePlayerInput(player, input, deltaTime)
    local validations = {
        self:checkSpeed(player, input, deltaTime),
        self:checkFeasibility(player, input),
        self:checkFrequency(player),
        self:checkBounds(player)
    }
    
    for _, validation in ipairs(validations) do
        if not validation.valid then
            Logger:warn("ANTICHEAT", validation.reason)
            return false, validation.reason
        end
    end
    
    return true, "OK"
end

function InputValidator:checkSpeed(player, input, dt)
    local currentPos = player:getComponent("transform").position
    local predictedPos = {
        x = currentPos.x + input.velocity.x * dt,
        y = currentPos.y + input.velocity.y * dt
    }
    
    local distance = math.sqrt(
        (predictedPos.x - currentPos.x)^2 +
        (predictedPos.y - currentPos.y)^2
    )
    
    local maxDistance = GameConfig.PLAYER_MAX_SPEED * dt
    
    if distance > maxDistance then
        return {
            valid = false,
            reason = "Speed exploit: " .. distance .. " > " .. maxDistance
        }
    end
    
    return {valid = true}
end

function InputValidator:checkFeasibility(player, input)
    -- ¿Se podría alcanzar esta posición legalmente?
    local health = player:getComponent("health")
    
    if health.isDead then
        return {
            valid = false,
            reason = "Dead players cannot move"
        }
    end
    
    return {valid = true}
end

function InputValidator:checkFrequency(player)
    if not player.lastInputTime then
        player.lastInputTime = love.timer.getTime()
        return {valid = true}
    end
    
    local timeSinceLastInput = love.timer.getTime() - player.lastInputTime
    if timeSinceLastInput < (1 / GameConfig.MAX_INPUT_RATE) then
        player.inputsPerSecond = (player.inputsPerSecond or 0) + 1
        
        if player.inputsPerSecond > GameConfig.MAX_INPUT_RATE then
            return {
                valid = false,
                reason = "Input rate limit exceeded"
            }
        end
    end
    
    player.lastInputTime = love.timer.getTime()
    return {valid = true}
end

function InputValidator:checkBounds(player)
    local transform = player:getComponent("transform")
    
    if transform.position.x < 0 or 
       transform.position.x > GameConfig.WORLD_WIDTH or
       transform.position.y < 0 or
       transform.position.y > GameConfig.WORLD_HEIGHT then
        return {
            valid = false,
            reason = "Player out of bounds"
        }
    end
    
    return {valid = true}
end

return InputValidator
```

### Behavior Anomaly Detection

```lua
-- server/antiCheat/BehaviorAnalyzer.lua
local BehaviorAnalyzer = {}
BehaviorAnalyzer.__index = BehaviorAnalyzer

function BehaviorAnalyzer:new()
    local self = setmetatable({}, BehaviorAnalyzer)
    self.suspiciousPlayers = {}
    return self
end

function BehaviorAnalyzer:analyzePlayer(playerId, stats)
    local suspicion = 0
    
    -- Tasa de acierto anormalmente alta
    if stats.headshotRatio > 0.8 then
        suspicion = suspicion + 30
    end
    
    -- Reacción imposiblemente rápida
    if stats.averageReactionTime < 50 then  -- 50ms es muy bajo
        suspicion = suspicion + 25
    end
    
    -- Movimiento perfectamente predecible
    if stats.predictionAccuracy > 0.95 then
        suspicion = suspicion + 20
    end
    
    -- Nunca muere a entidades específicas
    if stats.deathsToPlayer < stats.deathsToOthers * 0.1 then
        suspicion = suspicion + 15
    end
    
    self.suspiciousPlayers[playerId] = {
        suspicion = suspicion,
        stats = stats,
        timestamp = love.timer.getTime()
    }
    
    if suspicion > 70 then
        return "high"
    elseif suspicion > 40 then
        return "medium"
    elseif suspicion > 20 then
        return "low"
    end
    
    return "none"
end

function BehaviorAnalyzer:getSuspicionLevel(playerId)
    return self.suspiciousPlayers[playerId]
end

return BehaviorAnalyzer
```

---

## Conclusión

Estos patrones proporcionan una base sólida para:
- ✅ Escalabilidad
- ✅ Mantenibilidad
- ✅ Rendimiento
- ✅ Seguridad

Adapta según tus necesidades específicas.

