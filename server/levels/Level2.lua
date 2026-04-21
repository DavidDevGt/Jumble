-- server/levels/Level2.lua
-- Intermediate Level - Saltos precisos

local Level = require("common.entities.Level")

local level = Level:new(2, "Saltos Precisos", 2)

-- Configurar spawn y meta
level:setSpawnPoint(80, 750)
level:setGoalPoint(1500, 100)
level:setTimeLimit(150)

-- Piso inicial
level:addPlatform({x = 0, y = 820, width = 200, height = 32, type = 1})

-- Plataformas pequeñas - requieren precisión
level:addPlatform({x = 300, y = 750, width = 80, height = 32, type = 1})
level:addPlatform({x = 500, y = 700, width = 80, height = 32, type = 1})
level:addPlatform({x = 700, y = 650, width = 80, height = 32, type = 1})

-- Zona ancha - descanso
level:addPlatform({x = 350, y = 500, width = 300, height = 32, type = 1})

-- Plataformas en zig-zag hacia arriba
level:addPlatform({x = 900, y = 450, width = 100, height = 32, type = 1})
level:addPlatform({x = 700, y = 350, width = 100, height = 32, type = 1})
level:addPlatform({x = 1100, y = 300, width = 100, height = 32, type = 1})
level:addPlatform({x = 900, y = 200, width = 100, height = 32, type = 1})

-- Meta final
level:addPlatform({x = 1400, y = 150, width = 150, height = 32, type = 1})

-- Piso inferior
level:addPlatform({x = 0, y = 870, width = 1600, height = 30, type = 1})

return level
