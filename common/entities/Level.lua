-- common/entities/Level.lua
-- Representa un nivel del juego con plataformas y obstáculos

local Level = {}
Level.__index = Level

-- Constructor
function Level:new(id, name, difficulty)
    local self = setmetatable({}, Level)
    
    self.id = id
    self.name = name
    self.difficulty = difficulty or 1
    self.platforms = {}         -- Lista de plataformas
    self.obstacles = {}         -- Lista de obstáculos
    self.spawn_point = {x = 0, y = 0}
    self.goal_point = {x = 0, y = 0}
    self.time_limit = 120
    
    return self
end

-- Agregar plataforma
function Level:addPlatform(platform)
    table.insert(self.platforms, platform)
end

-- Agregar obstáculo
function Level:addObstacle(obstacle)
    table.insert(self.obstacles, obstacle)
end

-- Establecer punto de spawn
function Level:setSpawnPoint(x, y)
    self.spawn_point.x = x
    self.spawn_point.y = y
end

-- Establecer punto de meta
function Level:setGoalPoint(x, y)
    self.goal_point.x = x
    self.goal_point.y = y
end

-- Establecer límite de tiempo
function Level:setTimeLimit(seconds)
    self.time_limit = seconds
end

-- Obtener todas las plataformas
function Level:getPlatforms()
    return self.platforms
end

-- Obtener todos los obstáculos
function Level:getObstacles()
    return self.obstacles
end

-- Obtener punto de spawn
function Level:getSpawnPoint()
    return self.spawn_point.x, self.spawn_point.y
end

-- Obtener punto de meta
function Level:getGoalPoint()
    return self.goal_point.x, self.goal_point.y
end

-- Verificar si un jugador está en la meta
function Level:isPlayerAtGoal(playerX, playerY, playerWidth, playerHeight)
    local goalX, goalY = self:getGoalPoint()
    
    -- Considerar meta como un área de 64x64 píxeles
    local GOAL_SIZE = 64
    local goalLeft = goalX - GOAL_SIZE / 2
    local goalRight = goalX + GOAL_SIZE / 2
    local goalTop = goalY - GOAL_SIZE / 2
    local goalBottom = goalY + GOAL_SIZE / 2
    
    local playerLeft = playerX
    local playerRight = playerX + playerWidth
    local playerTop = playerY
    local playerBottom = playerY + playerHeight
    
    -- AABB collision
    return not (playerRight < goalLeft or 
               playerLeft > goalRight or 
               playerBottom < goalTop or 
               playerTop > goalBottom)
end

-- Obtener estadísticas del nivel
function Level:getStats()
    return {
        id = self.id,
        name = self.name,
        difficulty = self.difficulty,
        platforms = #self.platforms,
        obstacles = #self.obstacles,
        time_limit = self.time_limit
    }
end

return Level
