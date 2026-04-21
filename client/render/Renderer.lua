-- client/render/Renderer.lua
-- Sistema de renderizado con interpolación y cámara

local Renderer = {}
Renderer.__index = Renderer

local GameConfig = require("common.config.GameConfig")
local Logger = require("common.utils.Logger")

function Renderer:new()
    local self = setmetatable({}, Renderer)
    
    -- Interpolador
    local EntityInterpolator = require("client.interpolation.EntityInterpolator")
    self.interpolator = EntityInterpolator:new()
    
    -- Cámara
    self.camera = {x = 0, y = 0}
    self.zoom = 1.0
    
    -- Referencias a jugadores
    self.players = {}
    self.localPlayerId = 1
    
    return self
end

function Renderer:update(dt)
    self.interpolator:update(dt)
    
    -- Actualizar cámara siguiendo jugador local
    if self.players[self.localPlayerId] then
        local player = self.players[self.localPlayerId]
        if player.body then
            local px, py = player.body:getPosition()
            -- Centrar cámara en el jugador
            self.camera.x = px - 400  -- Assume 800x600, center horizontally
            self.camera.y = py - 250  -- Assume 800x600, center vertically
        end
    end
end

function Renderer:drawEntities(entities)
    if not entities then return end
    
    for _, entity in ipairs(entities) do
        self:drawEntity(entity)
    end
end

function Renderer:drawEntity(entity)
    if not entity.id then return end
    
    -- Usar posición interpolada
    local pos = self.interpolator:getInterpolatedPosition(entity.id)
    
    -- Si no hay interpolación, usar posición directa
    if pos:x() == 0 and pos:y() == 0 then
        pos = self.interpolator:getOrCreatePosition(entity)
    end
    
    love.graphics.setColor(0.2, 0.5, 1)
    
    local width = entity.width or 32
    local height = entity.height or 32
    
    local x = pos:x() - width / 2
    local y = pos:y() - height / 2
    
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Dibujar nombre del jugador
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(entity.name or "Player" .. entity.id, x, y - 20, width, "center")
end

-- Actualizar interpolación con nuevos datos del servidor
function Renderer:updateEntityState(entityId, serverState)
    if not serverState then return end
    
    local oldPos = self.interpolator:getInterpolatedPosition(entityId)
    if oldPos:x() == 0 and oldPos:y() == 0 then
        --Primera actualización
        self.interpolator:updateEntity(entityId, 
            require("common.utils.Vector2"):new(serverState.x or 0, serverState.y or 0),
            require("common.utils.Vector2"):new(serverState.x or 0, serverState.y or 0),
            0.016
        )
    else
        self.interpolator:updateEntity(entityId,
            oldPos,
            require("common.utils.Vector2"):new(serverState.x or 0, serverState.y or 0),
            0.016
        )
    end
end

function Renderer:drawEffects()
    -- Efectos visuales
end

function Renderer:draw()
    -- Método principal de renderizado (llamado desde PlayingState)
    love.graphics.push()
    
    -- Aplicar transformación de cámara
    love.graphics.translate(-self.camera.x, -self.camera.y)
    love.graphics.scale(self.zoom)
    
    -- Dibujar mundo
    self:drawWorld()
    
    -- Dibujar entidades
    if self.players then
        for id, player in pairs(self.players) do
            if player.body then
                self:drawPlayer(id, player)
            end
        end
    end
    
    self:drawEffects()
    
    love.graphics.pop()
    
    -- HUD (sin transformación de cámara)
    self:drawHUD()
end

function Renderer:drawWorld()
    -- Fondo
    love.graphics.setColor(0.3, 0.4, 0.5)
    love.graphics.rectangle("fill", 0, 0, GameConfig.WORLD_WIDTH, GameConfig.WORLD_HEIGHT)
    
    -- Suelo
    love.graphics.setColor(0.2, 0.6, 0.2)
    love.graphics.rectangle("fill", 0, GameConfig.WORLD_HEIGHT - 20, GameConfig.WORLD_WIDTH, 20)
    
    -- Bordes
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", 0, 0, GameConfig.WORLD_WIDTH, GameConfig.WORLD_HEIGHT)
end

function Renderer:drawPlayer(id, player)
    local px, py = player.body:getPosition()
    local color = player.color or {1, 1, 1}
    
    love.graphics.setColor(unpack(color))
    love.graphics.rectangle("fill", px - player.width/2, py - player.height/2, 
                          player.width, player.height)
    
    -- Borde
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", px - player.width/2, py - player.height/2, 
                          player.width, player.height)
end

function Renderer:drawHUD()
    love.graphics.setColor(1, 1, 1)
    
    -- FPS
    love.graphics.printf("FPS: " .. love.timer.getFPS(), 10, 10, 100, "left")
    
    -- Memory
    local memory = math.floor(collectgarbage("count") / 1024)
    love.graphics.printf("MEM: " .. memory .. "MB", 10, 30, 100, "left")
    
    -- Jugadores conectados
    local playerCount = 0
    for _, _ in pairs(self.players) do
        playerCount = playerCount + 1
    end
    love.graphics.printf("JUGADORES: " .. playerCount, 10, 50, 200, "left")
    
    -- Estado de conexión
    if _G.client then
        local status = _G.client:isConnected() and "✓ CONECTADO" or "✗ DESCONECTADO"
        local color = _G.client:isConnected() and {0.3, 1, 0.3} or {1, 0.3, 0.3}
        love.graphics.setColor(unpack(color))
        local width = love.graphics.getWidth()
        love.graphics.printf(status, width - 200, 10, 190, "right")
    end
end

function Renderer:addPlayer(id, player)
    self.players[id] = player
    Logger:debug("RENDERER", "Jugador agregado: " .. id)
end

function Renderer:removePlayer(id)
    self.players[id] = nil
end

function Renderer:clearPlayers()
    self.players = {}
end

return Renderer
