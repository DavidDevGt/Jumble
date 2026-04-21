-- server/main.lua
-- Punto de entrada del servidor
-- Arquitectura: Physics determinista + Fixed timestep

local GameConfig = require("common.config.GameConfig")
local Logger = require("common.utils.Logger")

-- Para logging estructurado
Logger:setMinLevel(Logger.LEVEL_DEBUG)

function love.conf(t)
    t.identity = "Jumble-Server"
    t.version = "11.5"
    
    -- El servidor no necesita gráficos, pero los mantenemos para logging
    t.window = {
        title = "JUMBLE - Server",
        width = 1280,
        height = 720,
        vsync = 1,
    }
    
    t.modules = {
        audio = false,
        graphics = true,
        window = true,
        event = true,
        keyboard = true,
        math = true,
        physics = true,
        system = true,
        timer = true,
        thread = true,
        joystick = false,
        image = false,
        font = false,
        sound = false,
        touch = false,
        video = false,
        mouse = false
    }
end

function love.load()
    Logger:info("SERVER", "Inicializando servidor...")
    
    -- GC tuning para server (más agresivo)
    collectgarbage("setpause", 105)
    collectgarbage("setstepmul", 250)
    Logger:debug("GC", "GC tuned for server: pause=105, stepmul=250")
    
    -- Estado global del servidor
    SERVER_STATE = {
        running = true,
        tick = 0,
        accumulator = 0,
        clients = {}
    }
    
    -- Inicializar física determinista (server is authoritative)
    local DeterministicPhysics = require("common.physics.DeterministicPhysics")
    _G.physicsWorld = DeterministicPhysics:new(GameConfig.GRAVITY, false)
    Logger:debug("PHYSICS", "Server physics initialized with fixed timestep")
    
    -- Módulos del servidor
    _G.server = require("server.network.Server"):new()
    _G.gameState = require("server.game.GameState"):new(_G.physicsWorld, GameConfig)
    _G.tickManager = require("server.game.TickManager"):new()
    
    Logger:info("SERVER", "✓ Servidor listo en puerto " .. 
                          require("common.config.NetworkConfig").SERVER_PORT)
end

function love.update(dt)
    if not SERVER_STATE.running then
        love.event.quit()
        return
    end
    
    -- Limitar dt para evitar jumps
    dt = math.min(dt, 0.05)
    
    -- Procesar conexiones y inputs
    if _G.server then
        _G.server:update(dt)
    end
    
    -- CRITICAL: Física y lógica con fixed timestep (solo servidor tiene autoridad)
    SERVER_STATE.accumulator = SERVER_STATE.accumulator + dt
    
    while SERVER_STATE.accumulator >= GameConfig.TICK_TIME do
        SERVER_STATE.accumulator = SERVER_STATE.accumulator - GameConfig.TICK_TIME
        
        -- Tick determinista del servidor (ÚNICA autoridad de física)
        if _G.gameState then
            _G.gameState:tick(GameConfig.TICK_TIME)
        end
        
        -- Broadcast estado cada 3 ticks (20Hz)
        if _G.server and _G.gameState then
            _G.server:broadcastGameState(_G.gameState:getState(), SERVER_STATE.tick)
        end
        
        SERVER_STATE.tick = SERVER_STATE.tick + 1
    end
end

function love.draw()
    -- El servidor no renderiza
    love.graphics.clear(0.05, 0.05, 0.05)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("SERVER MODE - Tick: " .. tostring(SERVER_STATE.tick), 0, 360, 1280, "center")
end

function love.keypressed(key)
    if key == "escape" then
        SERVER_STATE.running = false
    end
end
