-- server/game/LevelManager.lua
-- Gestiona carga, cambio y lógica de niveles

local LevelManager = {}
LevelManager.__index = LevelManager

local Level = require("common.entities.Level")
local LevelConfig = require("common.config.LevelConfig")
local GameConfig = require("common.config.GameConfig")
local Logger = require("common.utils.Logger")

-- Constructor
function LevelManager:new()
    local self = setmetatable({}, LevelManager)
    
    self.current_level = nil
    self.current_level_id = 0
    self.levels = {}
    self.level_start_time = 0
    self.player_completion_times = {}  -- {playerId -> time}
    
    Logger:info("LEVEL", "LevelManager initialized")
    
    return self
end

-- Registrar un nivel
function LevelManager:registerLevel(level)
    if level.id > 0 and level.id <= LevelConfig.MAX_LEVELS then
        self.levels[level.id] = level
        Logger:info("LEVEL", "Registered level " .. level.id .. ": " .. level.name)
    else
        Logger:error("LEVEL", "Invalid level ID: " .. level.id)
    end
end

-- Cargar un nivel específico
function LevelManager:loadLevel(levelId)
    if not self.levels[levelId] then
        Logger:error("LEVEL", "Level " .. levelId .. " not found")
        return false
    end
    
    self.current_level = self.levels[levelId]
    self.current_level_id = levelId
    self.level_start_time = os.time()
    self.player_completion_times = {}
    
    Logger:info("LEVEL", "Loaded level " .. levelId .. ": " .. self.current_level.name)
    
    return true
end

-- Cargar próximo nivel
function LevelManager:loadNextLevel()
    local nextLevelId = self.current_level_id + 1
    
    if nextLevelId > LevelConfig.MAX_LEVELS then
        Logger:info("LEVEL", "All levels completed!")
        return false
    end
    
    return self:loadLevel(nextLevelId)
end

-- Obtener nivel actual
function LevelManager:getCurrentLevel()
    return self.current_level
end

-- Obtener ID del nivel actual
function LevelManager:getCurrentLevelId()
    return self.current_level_id
end

-- Verificar si jugador completó el nivel
function LevelManager:checkLevelCompletion(player)
    if not self.current_level then
        return false
    end
    
    -- Verificar si ya completó este nivel
    if self.player_completion_times[player.id] then
        return true
    end
    
    -- Verificar si está en la meta
    if self.current_level:isPlayerAtGoal(
        player.position.x,
        player.position.y,
        GameConfig.PLAYER_WIDTH,
        GameConfig.PLAYER_HEIGHT
    ) then
        -- Registrar tiempo de finalización
        local completion_time = os.time() - self.level_start_time
        self.player_completion_times[player.id] = completion_time
        
        Logger:info("LEVEL", "Player " .. player.id .. " completed level " .. self.current_level_id ..
                    " in " .. completion_time .. " seconds")
        
        return true
    end
    
    return false
end

-- Obtener tiempo de finalización de un jugador
function LevelManager:getPlayerCompletionTime(playerId)
    return self.player_completion_times[playerId]
end

-- Obtener jugadores que completaron el nivel
function LevelManager:getCompletedPlayers()
    local completed = {}
    for playerId, time in pairs(self.player_completion_times) do
        table.insert(completed, {
            id = playerId,
            time = time
        })
    end
    
    -- Ordenar por tiempo
    table.sort(completed, function(a, b)
        return a.time < b.time
    end)
    
    return completed
end

-- Obtener tiempo límite del nivel
function LevelManager:getTimeLimit()
    if self.current_level then
        return self.current_level.time_limit
    end
    return 120
end

-- Obtener tiempo transcurrido
function LevelManager:getElapsedTime()
    return os.time() - self.level_start_time
end

-- Verificar si se agotó el tiempo
function LevelManager:isTimeExpired()
    return self:getElapsedTime() >= self:getTimeLimit()
end

-- Obtener información del nivel para serializar
function LevelManager:getLevelInfo()
    if not self.current_level then
        return nil
    end
    
    local spawnX, spawnY = self.current_level:getSpawnPoint()
    local goalX, goalY = self.current_level:getGoalPoint()
    
    return {
        id = self.current_level_id,
        name = self.current_level.name,
        difficulty = self.current_level.difficulty,
        spawn = {x = spawnX, y = spawnY},
        goal = {x = goalX, y = goalY},
        time_limit = self.current_level.time_limit,
        elapsed_time = self:getElapsedTime(),
        platforms_count = #self.current_level:getPlatforms(),
        obstacles_count = #self.current_level:getObstacles()
    }
end

-- Obtener plataformas para renderizar
function LevelManager:getPlatforms()
    if self.current_level then
        return self.current_level:getPlatforms()
    end
    return {}
end

-- Obtener obstáculos para renderizar
function LevelManager:getObstacles()
    if self.current_level then
        return self.current_level:getObstacles()
    end
    return {}
end

-- Obtener todas las plataformas como lista serializable
function LevelManager:getPlatformsData()
    local platforms = {}
    
    for _, platform in ipairs(self:getPlatforms()) do
        table.insert(platforms, {
            x = platform.x,
            y = platform.y,
            width = platform.width,
            height = platform.height,
            type = platform.type or 1
        })
    end
    
    return platforms
end

-- Obtener todos los obstáculos como lista serializable
function LevelManager:getObstaclesData()
    local obstacles = {}
    
    for _, obstacle in ipairs(self:getObstacles()) do
        table.insert(obstacles, {
            x = obstacle.x,
            y = obstacle.y,
            width = obstacle.width,
            height = obstacle.height,
            type = obstacle.type or 1
        })
    end
    
    return obstacles
end

return LevelManager
