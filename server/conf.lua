-- server/conf.lua
-- Configuración LÖVE para servidor

function love.conf(t)
    t.title = "Jumble Server"
    t.version = "11.5"
    
    -- Servidor de headless es mejor, pero para testing usamos LÖVE
    t.window.width = 1280
    t.window.height = 720
    
    -- Desactivar módulos innecesarios para servidor
    t.modules.audio = false
    t.modules.graphics = false  -- En producción, no se necesita gráficos
    t.modules.image = false
    t.modules.sound = false
    t.modules.video = false
    
    t.modules.event = true
    t.modules.timer = true
    t.modules.thread = true
end
