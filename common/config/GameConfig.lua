-- common/config/GameConfig.lua
-- Constantes compartidas entre cliente y servidor

local GameConfig = {}

-- DIMENSIONES DEL MUNDO
GameConfig.WORLD_WIDTH = 1600
GameConfig.WORLD_HEIGHT = 900

-- PROPIEDADES DEL JUGADOR
GameConfig.PLAYER_WIDTH = 32
GameConfig.PLAYER_HEIGHT = 32
GameConfig.PLAYER_SPEED = 200       -- píxeles/segundo
GameConfig.PLAYER_MAX_SPEED = 250

-- FÍSICA
GameConfig.GRAVITY = 800            -- píxeles/segundo² hacia abajo
GameConfig.JUMP_FORCE = 150000         -- fuerza de salto para Box2D (depende de masa)

-- NETWORKING
GameConfig.TICK_RATE = 60           -- Updates por segundo
GameConfig.TICK_TIME = 1 / GameConfig.TICK_RATE
GameConfig.MAX_PLAYERS = 32
GameConfig.INTERPOLATION_TIME = 0.1 -- 100ms de interpolación

-- SEGURIDAD
GameConfig.MAX_INPUT_RATE = 60      -- Inputs máximos por segundo
GameConfig.MAX_VELOCITY = 500       -- Velocidad máxima permitida
GameConfig.POSITION_TOLERANCE = 50  -- Tolerance para correcciones

return GameConfig
