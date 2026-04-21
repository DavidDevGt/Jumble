-- server/levels/Level4.lua
-- Extreme Level - Coordinación y velocidad

local Level = require("common.entities.Level")

local level = Level:new(4, "Velocidad Extrema", 4)

-- Configurar spawn y meta
level:setSpawnPoint(80, 750)
level:setGoalPoint(1500, 50)
level:setTimeLimit(200)

-- Piso inicial
level:addPlatform({x = 0, y = 820, width = 100, height = 32, type = 1})

-- Primera carrera - plataformas pequeñas consecutivas
level:addPlatform({x = 250, y = 750, width = 70, height = 32, type = 1})
level:addPlatform({x = 450, y = 700, width = 70, height = 32, type = 1})
level:addPlatform({x = 650, y = 650, width = 70, height = 32, type = 1})
level:addPlatform({x = 850, y = 600, width = 70, height = 32, type = 1})

-- Zona de picos
level:addObstacle({x = 300, y = 600, width = 50, height = 40, type = 1})
level:addObstacle({x = 500, y = 550, width = 50, height = 40, type = 1})
level:addObstacle({x = 700, y = 500, width = 50, height = 40, type = 1})
level:addObstacle({x = 900, y = 450, width = 50, height = 40, type = 1})

-- Puente medio
level:addPlatform({x = 400, y = 350, width = 300, height = 32, type = 1})

-- Sección final - espiral ascendente
level:addPlatform({x = 1050, y = 400, width = 80, height = 32, type = 1})
level:addPlatform({x = 1250, y = 300, width = 80, height = 32, type = 1})
level:addPlatform({x = 1050, y = 200, width = 80, height = 32, type = 1})
level:addPlatform({x = 1350, y = 100, width = 150, height = 32, type = 1})

-- Meta muy alta
level:addPlatform({x = 1400, y = 30, width = 150, height = 32, type = 1})

-- Piso inferior
level:addPlatform({x = 0, y = 870, width = 1600, height = 30, type = 1})

return level
