-- server/game/GameState.lua
-- Estado del juego en el servidor

local GameState = {}
GameState.__index = GameState

local Player = require("common.entities.Player")
local GameConfig = require("common.config.GameConfig")

function GameState:new()
    local self = setmetatable({}, GameState)
    
    self.players = {}
    self.entities = {}
    -- Contador de ticks completados. Renombrado desde self.tick para no
    -- chocar con GameState:tick() (el método quedaba sombreado tras la
    -- primera llamada, ya que Lua busca campo en la instancia antes que
    -- método en la metatable).
    self.tickCount = 0

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
    -- Actualizar cada entidad
    for _, entity in ipairs(self.entities) do
        if entity.update then
            entity:update(dt, GameConfig.GRAVITY)
        end
    end
    
    -- Detectar colisiones
    self:updateCollisions()
    
    -- Validar posiciones
    self:validatePositions()
    
    self.tickCount = self.tickCount + 1
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

function GameState:getState()
    -- Retornar estado para enviar a clientes
    return self.entities
end

return GameState
