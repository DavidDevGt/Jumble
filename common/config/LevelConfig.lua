-- common/config/LevelConfig.lua
-- Configuración de niveles del juego

local LevelConfig = {}

-- CONSTANTES DE NIVELES
LevelConfig.MAX_LEVELS = 5
LevelConfig.DIFFICULTY_MULTIPLIER = {
    [1] = 1.0,      -- Easy
    [2] = 1.1,      -- Normal
    [3] = 1.3,      -- Hard
    [4] = 1.5,      -- Extreme
    [5] = 2.0       -- Insane
}

-- TIEMPO LÍMITE POR NIVEL (segundos)
LevelConfig.TIME_LIMITS = {
    [1] = 120,      -- Level 1: 2 minutos
    [2] = 150,      -- Level 2: 2.5 minutos
    [3] = 180,      -- Level 3: 3 minutos
    [4] = 200,      -- Level 4: 3.3 minutos
    [5] = 300       -- Level 5: 5 minutos
}

-- PROPIEDADES DE PLATAFORMAS
LevelConfig.PLATFORM = {
    NORMAL = 1,
    MOVING = 2,
    BREAKABLE = 3,
    BOUNCE = 4,
    ICE = 5
}

-- PROPIEDADES DE OBSTÁCULOS
LevelConfig.OBSTACLE = {
    SPIKE = 1,
    SAW = 2,
    LAVA = 3,
    WIND = 4
}

-- TAMAÑOS ESTÁNDAR
LevelConfig.BLOCK_SIZE = 32
LevelConfig.PLATFORM_MIN_WIDTH = 32
LevelConfig.PLATFORM_MAX_WIDTH = 256

-- PUNTOS DE SPAWN/META
LevelConfig.SPAWN_OFFSET_Y = 50    -- Offset vertical desde la meta
LevelConfig.META_SIZE = 64

return LevelConfig
