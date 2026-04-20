-- client/render/Renderer.lua
-- Sistema de renderizado

local Renderer = {}
Renderer.__index = Renderer

function Renderer:new()
    local self = setmetatable({}, Renderer)
    return self
end

function Renderer:drawEntities(entities)
    if not entities then return end
    
    for _, entity in ipairs(entities) do
        self:drawEntity(entity)
    end
end

function Renderer:drawEntity(entity)
    if not entity.position then return end
    
    love.graphics.setColor(0.2, 0.5, 1)
    
    local x = entity.position.x - entity.width / 2
    local y = entity.position.y - entity.height / 2
    
    love.graphics.rectangle("fill", x, y, entity.width, entity.height)
    
    -- Dibujar nombre del jugador
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(entity.name or "Player", x, y - 20, entity.width, "center")
end

function Renderer:drawEffects()
    -- Efectos visuales
end

return Renderer
