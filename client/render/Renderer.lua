-- client/render/Renderer.lua
-- Sistema de renderizado con interpolación

local Renderer = {}
Renderer.__index = Renderer

local EntityInterpolator = require("client.interpolation.EntityInterpolator")

function Renderer:new()
    local self = setmetatable({}, Renderer)
    
    self.interpolator = EntityInterpolator:new()
    
    return self
end

function Renderer:update(dt)
    self.interpolator:update(dt)
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

return Renderer
