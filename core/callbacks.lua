local Callbacks = {}

function Callbacks.init(arg)
    if love.load then love.load(arg) end
end

function Callbacks.update(dt)
    if love.update then love.update(dt) end
end

function Callbacks.draw()
    love.graphics.clear(0.1, 0.1, 0.1, 1)
    if love.draw then love.draw() end
end

function Callbacks.keypressed(key, scancode, isrepeat)
    if love.keypressed then love.keypressed(key, scancode, isrepeat) end
end

function Callbacks.keyreleased(key, scancode)
    if love.keyreleased then love.keyreleased(key, scancode) end
end

function Callbacks.textedited(text, start, length)
    if love.textedited then love.textedited(text, start, length) end
end

function Callbacks.textinput(text)
    if love.textinput then love.textinput(text) end
end

function Callbacks.mousepressed(x, y, button, istouch, presses)
    if love.mousepressed then love.mousepressed(x, y, button, istouch, presses) end
end

function Callbacks.mousereleased(x, y, button, istouch, presses)
    if love.mousereleased then love.mousereleased(x, y, button, istouch, presses) end
end

function Callbacks.mousemoved(x, y, dx, dy, istouch)
    if love.mousemoved then love.mousemoved(x, y, dx, dy, istouch) end
end

function Callbacks.mousefocus(focus)
    if love.mousefocus then love.mousefocus(focus) end
end

function Callbacks.wheelmoved(x, y)
    if love.wheelmoved then love.wheelmoved(x, y) end
end

function Callbacks.touchpressed(id, x, y, dx, dy, pressure)
    if love.touchpressed then love.touchpressed(id, x, y, dx, dy, pressure) end
end

function Callbacks.touchreleased(id, x, y, dx, dy, pressure)
    if love.touchreleased then love.touchreleased(id, x, y, dx, dy, pressure) end
end

function Callbacks.touchmoved(id, x, y, dx, dy, pressure)
    if love.touchmoved then love.touchmoved(id, x, y, dx, dy, pressure) end
end

function Callbacks.joystickpressed(joystick, button)
    if love.joystickpressed then love.joystickpressed(joystick, button) end
end

function Callbacks.joystickreleased(joystick, button)
    if love.joystickreleased then love.joystickreleased(joystick, button) end
end

function Callbacks.joystickaxis(joystick, axis, value)
    if love.joystickaxis then love.joystickaxis(joystick, axis, value) end
end

function Callbacks.joystickhat(joystick, hat, direction)
    if love.joystickhat then love.joystickhat(joystick, hat, direction) end
end

function Callbacks.joystickadded(joystick)
    if love.joystickadded then love.joystickadded(joystick) end
end

function Callbacks.joystickremoved(joystick)
    if love.joystickremoved then love.joystickremoved(joystick) end
end

function Callbacks.gamepadpressed(joystick, button)
    if love.gamepadpressed then love.gamepadpressed(joystick, button) end
end

function Callbacks.gamepadreleased(joystick, button)
    if love.gamepadreleased then love.gamepadreleased(joystick, button) end
end

function Callbacks.gamepadaxis(joystick, axis, value)
    if love.gamepadaxis then love.gamepadaxis(joystick, axis, value) end
end

function Callbacks.resize(w, h)
    if love.resize then love.resize(w, h) end
end

function Callbacks.visible(visible)
    if love.visible then love.visible(visible) end
end

function Callbacks.focus(focus)
    if love.focus then love.focus(focus) end
end

function Callbacks.filedropped(file)
    if love.filedropped then love.filedropped(file) end
end

function Callbacks.directorydropped(path)
    if love.directorydropped then love.directorydropped(path) end
end

function Callbacks.lowmemory()
    if love.lowmemory then love.lowmemory() end
end

function Callbacks.threaderror(thread, errorstr)
    if love.threaderror then love.threaderror(thread, errorstr) end
end

function Callbacks.displayrotated(index, orientation)
    if love.displayrotated then love.displayrotated(index, orientation) end
end

return Callbacks