-- client/interpolation/EntityInterpolator.lua
-- Interpolación suave de entidades

local EntityInterpolator = {}
EntityInterpolator.__index = EntityInterpolator

local Vector2 = require("common.utils.Vector2")
local GameConfig = require("common.config.GameConfig")

function EntityInterpolator:new()
    local self = setmetatable({}, EntityInterpolator)
    
    self.entities = {}
    self.interpolationTime = GameConfig.INTERPOLATION_TIME
    
    return self
end

function EntityInterpolator:updateEntity(entityId, oldPos, newPos, dt)
    local entity = self.entities[entityId]
    
    if not entity then
        entity = {
            currentPos = oldPos:clone(),
            targetPos = newPos:clone(),
            progress = 1.0  -- Ya en el objetivo
        }
        self.entities[entityId] = entity
    else
        -- Nueva actualización
        entity.currentPos = entity.targetPos:clone() or oldPos:clone()
        entity.targetPos = newPos:clone()
        entity.progress = 0
    end
end

function EntityInterpolator:update(dt)
    for entityId, entity in pairs(self.entities) do
        if entity.progress < 1.0 then
            entity.progress = entity.progress + (dt / self.interpolationTime)
            
            if entity.progress >= 1.0 then
                entity.progress = 1.0
                entity.currentPos = entity.targetPos:clone()
            else
                -- Interpolación lineal
                entity.currentPos = entity.currentPos:lerp(
                    entity.targetPos,
                    dt / self.interpolationTime
                )
            end
        end
    end
end

function EntityInterpolator:getInterpolatedPosition(entityId)
    local entity = self.entities[entityId]
    if entity then
        return entity.currentPos:clone()
    end
    return Vector2:new(0, 0)
end

return EntityInterpolator
