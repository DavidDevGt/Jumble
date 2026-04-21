-- client/main.lua
-- Punto de entrada del cliente - Jumble
-- Arquitectura: State Machine + Separación de responsabilidades

local GameConfig = require("common.config.GameConfig")
local Logger = require("common.utils.Logger")

-- Referencias globales (inicializadas en love.load)
_G.client = nil
_G.inputManager = nil
_G.renderer = nil
_G.gameStateMachine = nil

-- Para logging estructurado
Logger:setMinLevel(Logger.LEVEL_DEBUG)

function love.conf(t)
    t.identity = "Jumble-Client"
    t.version = "11.5"
    
    t.window = {
        title = "JUMBLE - Cliente",
        width = 1280,
        height = 720,
        borderless = false,
        resizable = true,
        minwidth = 640,
        minheight = 360,
        fullscreen = false,
        vsync = 1,
        msaa = 0,
    }
    
    t.modules = {
        audio = true,
        event = true,
        graphics = true,
        image = true,
        joystick = false,
        keyboard = true,
        math = true,
        mouse = true,
        physics = true,
        sound = true,
        system = true,
        timer = true,
        touch = true,
        video = true,
        window = true,
        thread = true
    }
end

function love.load()
    Logger:info("JUMBLE", "Inicializando cliente Jumble...")
    
    -- GC tuning para smooth gameplay
    collectgarbage("setpause", 110)
    collectgarbage("setstepmul", 200)
    Logger:debug("GC", "GC tuned: pause=110, stepmul=200")
    
    -- Inicializar sistemas globales
    _G.client = require("client.network.Client"):new()
    _G.inputManager = require("client.network.InputManager"):new()
    _G.renderer = require("client.render.Renderer"):new()
    
    -- Inicializar State Machine
    local StateMachine = require("common.state.StateMachine")
    local MenuState = require("common.state.MenuState")
    local ConnectingState = require("common.state.ConnectingState")
    local PlayingState = require("common.state.PlayingState")
    local DisconnectedState = require("common.state.DisconnectedState")
    
    _G.gameStateMachine = StateMachine:new("menu", {
        menu = MenuState,
        connecting = ConnectingState,
        playing = PlayingState,
        disconnected = DisconnectedState,
    })
    
    Logger:info("JUMBLE", "✓ Cliente inicializado en " .. GameConfig.WORLD_WIDTH .. 
                          "x" .. GameConfig.WORLD_HEIGHT)
end

function love.update(dt)
    -- Limitar dt para evitar grandes saltos
    dt = math.min(dt, 0.05)
    
    -- Actualizar máquina de estados
    if _G.gameStateMachine then
        local nextState = _G.gameStateMachine:update(dt)
        if nextState then
            _G.gameStateMachine:transition(nextState)
        end
    end
end

function love.draw()
    -- Renderizar estado actual
    if _G.gameStateMachine then
        _G.gameStateMachine:draw()
    else
        -- Fallback si algo falló
        love.graphics.setColor(1, 0, 0)
        love.graphics.printf("ERROR: StateMachine no inicializado", 0, 300, 800, "center")
    end
end

function love.keypressed(key, scancode, isrepeat)
    if _G.gameStateMachine then
        local nextState = _G.gameStateMachine:handleInput(key, scancode, isrepeat)
        if nextState then
            _G.gameStateMachine:transition(nextState)
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if _G.gameStateMachine then
        _G.gameStateMachine:handleEvent("mousepressed", {x = x, y = y, button = button})
    end
end

function love.quit()
    Logger:info("JUMBLE", "Cliente cerrando...")
    
    -- Limpiar conexión
    if _G.client then
        _G.client:disconnect()
    end
    
    return false  -- Permitir que Love2D cierre
end
