-- server/main.lua
-- Punto de entrada del servidor

function love.load()
    -- GC tuning: trigger earlier (pause=110) and step aggressively to
    -- smooth frame times. See docs/QUICK_WINS.md QW#5.
    collectgarbage("setpause", 110)
    collectgarbage("setstepmul", 200)

    -- Cargar configuración
    local GameConfig = require("common.config.GameConfig")
    local Logger = require("common.utils.Logger")
    
    Logger:info("SERVER", "Inicializando servidor...")
    
    -- Estado global del servidor
    SERVER_STATE = {
        running = true,
        tick = 0,
        accumulator = 0,
        clients = {}
    }
    
    -- Módulos del servidor
    _G.server = require("server.network.Server"):new()
    _G.gameState = require("server.game.GameState"):new()
    _G.tickManager = require("server.game.TickManager"):new()
    
    Logger:info("SERVER", "Servidor listo en puerto " .. 
                          require("common.config.NetworkConfig").SERVER_PORT)
end

function love.update(dt)
    if not SERVER_STATE.running then
        love.event.quit()
        return
    end
    
    -- Procesar conexiones
    server:update(dt)
    
    -- Actualizar física y lógica (solo el servidor tiene autoridad)
    SERVER_STATE.accumulator = SERVER_STATE.accumulator + dt
    
    local GameConfig = require("common.config.GameConfig")
    while SERVER_STATE.accumulator >= GameConfig.TICK_TIME do
        SERVER_STATE.accumulator = SERVER_STATE.accumulator - GameConfig.TICK_TIME
        
        -- Tick determinista del servidor (ÚNICA autoridad de física)
        gameState:tick(GameConfig.TICK_TIME)
        
        -- Broadcast estado cada 3 ticks (20Hz)
        server:broadcastGameState(gameState:getState(), SERVER_STATE.tick)
        
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
