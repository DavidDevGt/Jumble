-- common/physics/DeterministicPhysics.lua
-- Motor de física determinista con fixed timestep
-- Garantiza sincronización cliente-servidor

local DeterministicPhysics = {}
DeterministicPhysics.__index = DeterministicPhysics

local Logger = require("common.utils.Logger")

--- Crear nuevo motor de física determinista
-- @param gravity number - Aceleración gravitatoria en píxeles/segundo²
-- @param sleepingAllowed boolean - Si los bodies pueden dormirse (false para determinismo)
-- @return DeterministicPhysics - Instancia del motor
function DeterministicPhysics:new(gravity, sleepingAllowed)
    local self = setmetatable({}, DeterministicPhysics)
    
    gravity = gravity or 800
    sleepingAllowed = sleepingAllowed == nil and false or sleepingAllowed
    
    -- Crear mundo Box2D
    self.world = love.physics.newWorld(0, gravity, sleepingAllowed)
    self.world:setSleepingAllowed(sleepingAllowed)
    
    -- Tracking para debugging
    self.tick = 0
    self.totalTime = 0
    
    Logger:debug("PHYSICS", "Initialized deterministic physics: gravity=" .. gravity .. 
                            ", sleeping=" .. tostring(sleepingAllowed))
    
    return self
end

--- Actualizar física con timestep FIJO
-- CRÍTICO: SIEMPRE usar dt constante, NUNCA variable
-- 
-- @param dt number - Delta time en segundos (DEBE SER CONSTANTE)
-- @param velocityIterations number - Iteraciones de velocidad (default 8)
-- @param positionIterations number - Iteraciones de posición (default 3)
function DeterministicPhysics:tick(dt, velocityIterations, positionIterations)
    assert(type(dt) == "number" and dt > 0, 
           "DeterministicPhysics:tick() requires positive numeric dt, got: " .. tostring(dt))
    
    velocityIterations = velocityIterations or 8
    positionIterations = positionIterations or 3
    
    -- Actualizar mundo con dt fijo
    self.world:update(dt, velocityIterations, positionIterations)
    
    self.tick = self.tick + 1
    self.totalTime = self.totalTime + dt
end

--- Obtener referencias al mundo Box2D
-- @return Userdata - Box2D world object
function DeterministicPhysics:getWorld()
    return self.world
end

--- Crear nuevo body (delegado a love.physics)
-- @param x number - Posición X
-- @param y number - Posición Y
-- @param bodyType string - "static", "dynamic", "kinematic"
-- @return Userdata - Box2D body
function DeterministicPhysics:newBody(x, y, bodyType)
    return love.physics.newBody(self.world, x, y, bodyType or "static")
end

--- Crear nueva shape circular
-- @param radius number - Radio en píxeles
-- @return Userdata - Box2D circle shape
function DeterministicPhysics:newCircleShape(radius)
    return love.physics.newCircleShape(radius)
end

--- Crear nueva shape rectangular
-- @param x number - Posición X (relativa al body)
-- @param y number - Posición Y
-- @param width number - Ancho
-- @param height number - Alto
-- @return Userdata - Box2D rectangle shape
function DeterministicPhysics:newRectangleShape(x, y, width, height)
    if not width then
        -- Versión simplificada: newRectangleShape(width, height)
        return love.physics.newRectangleShape(x, y)
    end
    return love.physics.newRectangleShape(x, y, width, height)
end

--- Crear nuevo fixture
-- @param body Userdata - Box2D body
-- @param shape Userdata - Box2D shape
-- @param density number - Densidad (default 1)
-- @return Userdata - Box2D fixture
function DeterministicPhysics:newFixture(body, shape, density)
    return love.physics.newFixture(body, shape, density or 1)
end

--- Raycast para colisión
-- @param x1 number - Inicio X
-- @param y1 number - Inicio Y
-- @param x2 number - Fin X
-- @param y2 number - Fin Y
-- @param callback function - Función callback
-- @return boolean - Si hit algo
function DeterministicPhysics:rayCast(x1, y1, x2, y2, callback)
    return self.world:rayCast(x1, y1, x2, y2, callback)
end

--- Obtener todos los bodies en un área (AABB)
-- @param x number - Esquina X
-- @param y number - Esquina Y
-- @param w number - Ancho
-- @param h number - Alto
-- @param callback function - Callback por cada fixture
function DeterministicPhysics:queryAABB(x, y, w, h, callback)
    return self.world:queryAABB(x, y, x+w, y+h, callback)
end

--- Obtener cuerpos que se traslapan (overlap)
-- @param fixture1 Userdata - Primer fixture
-- @param fixture2 Userdata - Segundo fixture
-- @return boolean - Si se traslapan
function DeterministicPhysics:getDistance(fixture1, fixture2)
    return love.physics.getDistance(fixture1, fixture2)
end

--- Destruir world (limpiar)
function DeterministicPhysics:destroy()
    if self.world then
        self.world:destroy()
        self.world = nil
    end
end

--- Obtener estadísticas (para debugging)
-- @return table - Estadísticas del motor
function DeterministicPhysics:getStats()
    return {
        tick = self.tick,
        totalTime = self.totalTime,
        bodyCount = self.world:getBodyCount(),
        fixtureCount = self.world:getFixtureCount(),
        jointCount = self.world:getJointCount(),
    }
end

return DeterministicPhysics
