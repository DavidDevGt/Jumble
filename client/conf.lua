-- client/conf.lua
-- Configuración de LÖVE para cliente

function love.conf(t)
    t.title = "Jumble - Multiplayer Game"
    t.version = "11.5"
    
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.vsync = 1
    
    t.modules.joystick = true
    t.modules.keyboard = true
    t.modules.mouse = true
    t.modules.sound = false  -- Desactivar por ahora
    t.modules.video = false
end
