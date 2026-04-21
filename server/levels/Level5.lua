-- server/levels/Level5.lua
-- Insane Level - Maestría absoluta

local Level = require("common.entities.Level")

local level = Level:new(5, "Maestría - El Desafío Final", 5)

-- Configurar spawn y meta
level:setSpawnPoint(80, 750)
level:setGoalPoint(1500, 50)
level:setTimeLimit(300)

-- Piso inicial
level:addPlatform({x = 0, y = 820, width = 80, height = 32, type = 1})

-- ZONA 1: Carrera de precisión extrema
level:addPlatform({x = 200, y = 770, width = 60, height = 32, type = 1})
level:addPlatform({x = 380, y = 740, width = 60, height = 32, type = 1})
level:addPlatform({x = 560, y = 710, width = 60, height = 32, type = 1})
level:addPlatform({x = 740, y = 680, width = 60, height = 32, type = 1})

-- Obstáculos densos
level:addObstacle({x = 250, y = 700, width = 40, height = 40, type = 1})
level:addObstacle({x = 430, y = 670, width = 40, height = 40, type = 1})
level:addObstacle({x = 610, y = 640, width = 40, height = 40, type = 1})
level:addObstacle({x = 790, y = 610, width = 40, height = 40, type = 1})

-- ZONA 2: Saltos en altura
level:addPlatform({x = 300, y = 500, width = 100, height = 32, type = 1})
level:addPlatform({x = 550, y = 400, width = 100, height = 32, type = 1})
level:addPlatform({x = 800, y = 300, width = 100, height = 32, type = 1})

-- ZONA 3: Malla de obstáculos
level:addObstacle({x = 400, y = 350, width = 35, height = 35, type = 1})
level:addObstacle({x = 500, y = 300, width = 35, height = 35, type = 1})
level:addObstacle({x = 600, y = 250, width = 35, height = 35, type = 1})
level:addObstacle({x = 700, y = 200, width = 35, height = 35, type = 1})
level:addObstacle({x = 900, y = 350, width = 35, height = 35, type = 1})
level:addObstacle({x = 1000, y = 280, width = 35, height = 35, type = 1})

-- ZONA 4: Plataformas finales - carrera contra tiempo
level:addPlatform({x = 1000, y = 150, width = 70, height = 32, type = 1})
level:addPlatform({x = 1200, y = 120, width = 70, height = 32, type = 1})
level:addPlatform({x = 1380, y = 80, width = 120, height = 32, type = 1})

-- META - punto de culminación
level:addPlatform({x = 1420, y = 30, width = 100, height = 32, type = 1})

-- Piso inferior
level:addPlatform({x = 0, y = 870, width = 1600, height = 30, type = 1})

return level
