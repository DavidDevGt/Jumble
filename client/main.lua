-- client/main.lua
-- Punto de entrada del cliente

function love.load()
    -- Cargar configuración
    local GameConfig = require("common.config.GameConfig")
    local Logger = require("common.utils.Logger")
    
    Logger:info("CLIENT", "Inicializando cliente...")
    
    -- Estado global
    GAME_STATE = {
        connected = false,
        players = {},
        localPlayerId = nil,
        gameTime = 0
    }
    
    -- Módulos
    _G.inputManager = require("client.network.InputManager"):new()
    _G.gameState = {}
    _G.client = require("client.network.Client"):new()
    
    Logger:info("CLIENT", "Cliente listo")
end

function love.update(dt)
    GAME_STATE.gameTime = GAME_STATE.gameTime + dt
    
    -- Actualizar input
    inputManager:update(dt)
    
    -- Conectar/procesar red
    if client:isConnected() then
        -- Procesar paquetes
        client:update(dt)
    else
        -- Intentar conectar
        client:connect()
    end
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    
    if not client:isConnected() then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Conectando al servidor...", 0, 360, 1280, "center")
    else
        -- Renderizar juego
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.print("Conectado", 10, 10)
        love.graphics.print("Players: " .. tostring(#GAME_STATE.players), 10, 30)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
