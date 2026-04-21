-- server/levels/Level1.lua
-- Tutorial Level - Plataformas básicas

local Level = require("common.entities.Level")

local level = Level:new(1, "Tutorial - Primeros Pasos", 1)

-- Configurar spawn y meta
level:setSpawnPoint(100, 750)
level:setGoalPoint(1500, 150)
level:setTimeLimit(120)

-- Plataforma de inicio
level:addPlatform({x = 50, y = 800, width = 200, height = 32, type = 1})

-- Escalera de plataformas hacia la derecha
level:addPlatform({x = 300, y = 750, width = 150, height = 32, type = 1})
level:addPlatform({x = 550, y = 700, width = 150, height = 32, type = 1})
level:addPlatform({x = 800, y = 650, width = 150, height = 32, type = 1})

-- Plataforma ancha en medio
level:addPlatform({x = 400, y = 500, width = 250, height = 32, type = 1})

-- Plataformas finales hacia meta
level:addPlatform({x = 900, y = 450, width = 150, height = 32, type = 1})
level:addPlatform({x = 1150, y = 400, width = 150, height = 32, type = 1})
level:addPlatform({x = 1400, y = 300, width = 150, height = 32, type = 1})

-- Piso inferior
level:addPlatform({x = 0, y = 870, width = 1600, height = 30, type = 1})

return level
