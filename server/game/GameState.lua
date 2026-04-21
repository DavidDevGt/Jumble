-- server/game/GameState.lua
-- Estado del juego en el servidor

local GameState = {}
GameState.__index = GameState

local Player = require("common.entities.Player")
local GameConfig = require("common.config.GameConfig")
local Logger = require("common.utils.Logger")

function GameState:new(physicsWorld, config)
    local self = setmetatable({}, GameState)
    
    -- Inyectar dependencias
    self.physicsWorld = physicsWorld or error("GameState requires physics world")
    self.config = config or require("common.config.GameConfig")
    
    self.players = {}
    self.entities = {}
    self.tick = 0
    self.completed_players = {}  -- Jugadores que completaron el nivel
    self.levelManager = nil      -- Se asigna después
    
    return self
end

function GameState:addPlayer(clientId, playerName, x, y)
    local player = Player:new(clientId, playerName, x, y)
    self.players[clientId] = player
    table.insert(self.entities, player)
    
    return player
end

function GameState:removePlayer(clientId)
    if self.players[clientId] then
        local player = self.players[clientId]
        -- Remover de entidades
        for i, entity in ipairs(self.entities) do
            if entity.id == clientId then
                table.remove(self.entities, i)
                break
            end
        end
        self.players[clientId] = nil
    end
end

function GameState:applyInput(clientId, inputVector)
    local player = self.players[clientId]
    if player then
        player:setInput(inputVector)
    end
end

function GameState:tick(dt)
    -- CRITICAL: Usar fixed timestep physics para determinismo
    if self.physicsWorld then
        self.physicsWorld:tick(dt, 8, 3)
    end
    
    -- Actualizar cada entidad
    for _, entity in ipairs(self.entities) do
        if entity.update then
            entity:update(dt, self.config.GRAVITY)
        end
    end
    
    -- Detectar colisiones
    self:updateCollisions()
    
    -- Validar posiciones
    self:validatePositions()
    
    -- Verificar completación de niveles
    self:checkLevelCompletion()
    
    self.tick = self.tick + 1
end

function GameState:updateCollisions()
    -- Lógica de colisiones
    -- Normalmente se detectarían colisiones entre todas las entidades
end

function GameState:validatePositions()
    -- Validar que ningún jugador esté fuera del mapa
    for _, player in pairs(self.players) do
        if player.position.x < 0 then
            player.position.x = 0
        elseif player.position.x > GameConfig.WORLD_WIDTH then
            player.position.x = GameConfig.WORLD_WIDTH
        end
        
        if player.position.y < 0 then
            player.position.y = 0
        elseif player.position.y > GameConfig.WORLD_HEIGHT then
            player.position.y = GameConfig.WORLD_HEIGHT
        end
    end
end

function GameState:checkLevelCompletion()
    -- Verificar si algún jugador completó el nivel
    if not self.levelManager then
        return
    end
    
    for _, player in pairs(self.players) do
        -- Verificar si ya completó
        if not self.completed_players[player.id] then
            -- Verificar si está en la meta
            if self.levelManager:checkLevelCompletion(player) then
                self.completed_players[player.id] = true
                Logger:info("LEVEL", "Servidor: Jugador " .. player.id .. " completó el nivel")
            end
        end
    end
end

function GameState:getCompletedPlayers()
    return self.completed_players
end

function GameState:resetLevelCompletion()
    self.completed_players = {}
end

function GameState:getState()
    -- Retornar estado para enviar a clientes
    return self.entities
end

return GameState
