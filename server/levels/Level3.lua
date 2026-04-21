-- server/levels/Level3.lua
-- Hard Level - Obstáculos y timing

local Level = require("common.entities.Level")

local level = Level:new(3, "Desafío de Timing", 3)

-- Configurar spawn y meta
level:setSpawnPoint(80, 750)
level:setGoalPoint(1500, 150)
level:setTimeLimit(180)

-- Piso inicial
level:addPlatform({x = 0, y = 820, width = 150, height = 32, type = 1})

-- Primera sección - plataformas normales
level:addPlatform({x = 300, y = 700, width = 120, height = 32, type = 1})
level:addPlatform({x = 600, y = 650, width = 120, height = 32, type = 1})

-- Zona de obstáculos con picos
level:addObstacle({x = 200, y = 600, width = 50, height = 50, type = 1})
level:addObstacle({x = 450, y = 550, width = 50, height = 50, type = 1})

-- Plataforma ancha de descanso
level:addPlatform({x = 400, y = 450, width = 400, height = 32, type = 1})

-- Sección superior - plataformas estrechas
level:addPlatform({x = 800, y = 400, width = 80, height = 32, type = 1})
level:addPlatform({x = 1050, y = 330, width = 80, height = 32, type = 1})

-- Más obstáculos
level:addObstacle({x = 900, y = 280, width = 50, height = 50, type = 1})
level:addObstacle({x = 1200, y = 250, width = 50, height = 50, type = 1})

-- Plataformas finales
level:addPlatform({x = 1350, y = 200, width = 150, height = 32, type = 1})
level:addPlatform({x = 1450, y = 100, width = 100, height = 32, type = 1})

-- Piso inferior
level:addPlatform({x = 0, y = 870, width = 1600, height = 30, type = 1})

return level
