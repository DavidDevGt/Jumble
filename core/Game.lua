local Game = {}

Game.config = require("core.conf")
Game.callbacks = require("core.callbacks")
Game.input = require("core.input")
Game.graphics = require("core.graphics")
Game.audio = require("core.audio")
Game.physics = require("core.physics")
Game.window = require("core.window")
Game.utils = require("core.utils")

Game.state = "menu"
Game.paused = false

function love.load(arg)
    Game.callbacks.init(arg)
    
    if arg and #arg > 0 then
        for i, v in ipairs(arg) do
            print("Arg " .. i .. ": " .. tostring(v))
        end
    end
    
    print("Jumble v" .. Game.config.t.version .. " loaded")
end

function love.update(dt)
    if Game.paused then return end
    Game.callbacks.update(dt)
end

function love.draw()
    Game.callbacks.draw()
end

function love.quit()
    print("Shutting down Jumble...")
    return false
end

function love.run()
    love.timer.step()
    
    local dt = 0
    local updateFunc = love.update
    local drawFunc = love.draw
    
    if love.load then
        love.load(love.arg, love.unfilteredArg)
    end
    
    if love.get then love.graphics.reset() end
    
    if love.threaderror then
        love.threaderrorerror = function(thread, errstr)
            love.threaderror(thread, errstr)
        end
    end
    
    while true do
        love.timer.step()
        dt = love.timer.getDelta()
        
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" then
                if not love.quit or not love.quit() then
                    if love.audio then love.audio.stop() end
                    return
                end
            elseif name == "resize" then
                if love.resize then love.resize(a, b) end
            elseif name == "joystickadded" then
                if love.joystickadded then love.joystickadded(a) end
            elseif name == "joystickremoved" then
                if love.joystickremoved then love.joystickremoved(a) end
            elseif name == "gamepadpressed" then
                if love.gamepadpressed then love.gamepadpressed(a, b) end
            elseif name == "gamepadreleased" then
                if love.gamepadreleased then love.gamepadreleased(a, b) end
            elseif name == "gamepadaxis" then
                if love.gamepadaxis then love.gamepadaxis(a, b, c) end
            elseif name == "joystickpressed" then
                if love.joystickpressed then love.joystickpressed(a, b) end
            elseif name == "joystickreleased" then
                if love.joystickreleased then love.joystickreleased(a, b) end
            elseif name == "joystickaxis" then
                if love.joystickaxis then love.joystickaxis(a, b, c) end
            elseif name == "joystickhat" then
                if love.joystickhat then love.joystickhat(a, b, c) end
            elseif name == "keypressed" then
                if love.keypressed then love.keypressed(a, b, c) end
            elseif name == "keyreleased" then
                if love.keyreleased then love.keyreleased(a, b) end
            elseif name == "textedited" then
                if love.textedited then love.textedited(a, b, c) end
            elseif name == "textinput" then
                if love.textinput then love.textinput(a) end
            elseif name == "mousepressed" then
                if love.mousepressed then love.mousepressed(a, b, c, d, e) end
            elseif name == "mousereleased" then
                if love.mousereleased then love.mousereleased(a, b, c, d, e) end
            elseif name == "mousemoved" then
                if love.mousemoved then love.mousemoved(a, b, c, d, e) end
            elseif name == "mousefocus" then
                if love.mousefocus then love.mousefocus(a) end
            elseif name == "wheelmoved" then
                if love.wheelmoved then love.wheelmoved(a, b) end
            elseif name == "touchpressed" then
                if love.touchpressed then love.touchpressed(a, b, c, d, e, f) end
            elseif name == "touchreleased" then
                if love.touchreleased then love.touchreleased(a, b, c, d, e, f) end
            elseif name == "touchmoved" then
                if love.touchmoved then love.touchmoved(a, b, c, d, e, f) end
            elseif name == "visible" then
                if love.visible then love.visible(a) end
            elseif name == "focus" then
                if love.focus then love.focus(a) end
            elseif name == "filedropped" then
                if love.filedropped then love.filedropped(a) end
            elseif name == "directorydropped" then
                if love.directorydropped then love.directorydropped(a) end
            elseif name == "lowmemory" then
                if love.lowmemory then love.lowmemory() end
            elseif name == "threaderror" then
                if love.threaderror then love.threaderror(a, b) end
            elseif name == "displayrotated" then
                if love.displayrotated then love.displayrotated(a, b) end
            end
        end
        
        if updateFunc then
            updateFunc(dt)
        end
        
        if love.graphics and love.graphics.isActive() then
            love.graphics.clear(love.graphics.getBackgroundColor())
            if drawFunc then drawFunc() end
            love.graphics.present()
        end
        
        if love.timer then
            love.timer.sleep(0.001)
        end
    end
end

return Game