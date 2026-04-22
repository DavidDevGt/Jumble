-- client/conf.lua
-- Configuración de LÖVE para cliente

function love.conf(t)
    t.title = "Jumble - Multiplayer Game"
    t.version = "11.5"

    -- Ventana = dimensiones del mundo (GameConfig.WORLD_WIDTH/HEIGHT = 1600x900).
    -- Sin camera, drawGame pinta en coords de mundo directamente, así que la
    -- ventana tiene que cubrir el mundo o nada se ve (el spawn está en 800, 800).
    t.window.width = 1600
    t.window.height = 900
    t.window.resizable = true
    t.window.vsync = 1

    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.mouse = true
    t.modules.sound = false
    t.modules.video = false
end
