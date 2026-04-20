-- server/game/TickManager.lua
-- Gestor de ticks determinista del servidor

local TickManager = {}
TickManager.__index = TickManager

local GameConfig = require("common.config.GameConfig")

function TickManager:new()
    local self = setmetatable({}, TickManager)
    
    self.tickRate = GameConfig.TICK_RATE
    self.tickTime = GameConfig.TICK_TIME
    self.currentTick = 0
    self.accumulator = 0
    
    return self
end

function TickManager:accumulate(dt)
    self.accumulator = self.accumulator + dt
end

function TickManager:shouldTick()
    return self.accumulator >= self.tickTime
end

function TickManager:tick()
    self.accumulator = self.accumulator - self.tickTime
    self.currentTick = self.currentTick + 1
    return self.currentTick
end

function TickManager:getTickRate()
    return self.tickRate
end

function TickManager:getCurrentTick()
    return self.currentTick
end

return TickManager
