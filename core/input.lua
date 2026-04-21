local Input = {}

Input.keys = {}
Input.mouse = {}
Input.touch = {}
Input.joystick = {}
Input.gamepad = {}

Input.keysPressed = {}
Input.keysReleased = {}
Input.mousePressed = {}
Input.mouseReleased = {}
Input.touchesActive = {}
Input.joysticksActive = {}

local function clearTable(t)
    for k in pairs(t) do t[k] = nil end
end

function Input.update(dt)
    clearTable(Input.keysPressed)
    clearTable(Input.keysReleased)
    clearTable(Input.mousePressed)
    clearTable(Input.mouseReleased)
end

function Input.isKeyDown(key)
    return love.keyboard.isDown(key)
end

function Input.wasKeyPressed(key)
    return Input.keysPressed[key]
end

function Input.wasKeyReleased(key)
    return Input.keysReleased[key]
end

function Input.isMouseDown(button)
    button = button or 1
    return love.mouse.isDown(button)
end

function Input.isMousePressed(button)
    button = button or 1
    return Input.mousePressed[button]
end

function Input.getMouseX()
    return love.mouse.getX()
end

function Input.getMouseY()
    return love.mouse.getY()
end

function Input.getMousePosition()
    return love.mouse.getPosition()
end

function Input.getTouches()
    return love.touch.getTouches()
end

function Input.getTouchPosition(id)
    return love.touch.getPosition(id)
end

function Input.getTouchPressure(id)
    return love.touch.getPressure(id)
end

function Input.getJoysticks()
    return love.joystick.getJoysticks()
end

function Input.isJoystickDown(joystick, button)
    return joystick:isDown(button)
end

function Input.getGamepadAxis(joystick, axis)
    return joystick:getGamepadAxis(axis)
end

function Input.isGamepadDown(joystick, button)
    return joystick:isGamepadDown(button)
end

function Input.getScancodeFromKey(key)
    return love.keyboard.getScancodeFromKey(key)
end

function Input.getKeyFromScancode(scancode)
    return love.keyboard.getKeyFromScancode(scancode)
end

function Input.hasScreenKeyboard()
    return love.keyboard.hasScreenKeyboard()
end

function Input.setTextInput(enable, x, y, w, h)
    if enable and type(enable) == "boolean" then
        love.keyboard.setTextInput(enable)
    else
        love.keyboard.setTextInput(enable or false, x or 0, y or 0, w or 0, h or 0)
    end
end

function Input.setKeyRepeat(enable)
    love.keyboard.setKeyRepeat(enable)
end

function Input.setMousePosition(x, y)
    love.mouse.setPosition(x, y)
end

function Input.setMouseVisible(visible)
    love.mouse.setVisible(visible)
end

function Input.setMouseGrabbed(grab)
    love.mouse.setGrabbed(grab)
end

function Input.setRelativeMode(enable)
    love.mouse.setRelativeMode(enable)
end

Input.Key = {
    BACKSPACE = "backspace",
    TAB = "tab",
    CLEAR = "clear",
    RETURN = "return",
    ESCAPE = "escape",
    SPACE = "space",
    EXCLAIM = "!",
    QUOTEDBL = "\"",
    HASH = "#",
    DOLLAR = "$",
    PERCENT = "%",
    AMPERSAND = "&",
    QUOTE = "'",
    LEFTPAREN = "(",
    RIGHTPAREN = ")",
    ASTERISK = "*",
    PLUS = "+",
    COMMA = ",",
    MINUS = "-",
    PERIOD = ".",
    SLASH = "/",
    DIGIT_0 = "0",
    DIGIT_1 = "1",
    DIGIT_2 = "2",
    DIGIT_3 = "3",
    DIGIT_4 = "4",
    DIGIT_5 = "5",
    DIGIT_6 = "6",
    DIGIT_7 = "7",
    DIGIT_8 = "8",
    DIGIT_9 = "9",
    COLON = ":",
    SEMICOLON = ";",
    LESS = "<",
    EQUALS = "=",
    GREATER = ">",
    QUESTION = "?",
    AT = "@",
    LEFTBRACKET = "[",
    BACKSLASH = "\\",
    RIGHTBRACKET = "]",
    CARET = "^",
    UNDERSCORE = "_",
    BACKQUOTE = "`",
    A = "a",
    B = "b",
    C = "c",
    D = "d",
    E = "e",
    F = "f",
    G = "g",
    H = "h",
    I = "i",
    J = "j",
    K = "k",
    L = "l",
    M = "m",
    N = "n",
    O = "o",
    P = "p",
    Q = "q",
    R = "r",
    S = "s",
    T = "t",
    U = "u",
    V = "v",
    W = "w",
    X = "x",
    Y = "y",
    Z = "z",
    UP = "up",
    DOWN = "down",
    RIGHT = "right",
    LEFT = "left",
    F1 = "f1",
    F2 = "f2",
    F3 = "f3",
    F4 = "f4",
    F5 = "f5",
    F6 = "f6",
    F7 = "f7",
    F8 = "f8",
    F9 = "f9",
    F10 = "f10",
    F11 = "f11",
    F12 = "f12"
}

Input.Mouse = {
    LEFT = 1,
    RIGHT = 2,
    MIDDLE = 3
}

Input.Gamepad = {
    A = "a",
    B = "b",
    X = "x",
    Y = "y",
    BACK = "back",
    GUIDE = "guide",
    START = "start",
    LEFTSTICK = "leftstick",
    RIGHTSTICK = "rightstick",
    LEFTSHOULDER = "leftshoulder",
    RIGHTSHOULDER = "rightshoulder",
    DPAD_UP = "dpup",
    DPAD_DOWN = "dpdown",
    DPAD_LEFT = "dpleft",
    DPAD_RIGHT = "dpright",
    LEFTX = "leftx",
    LEFTY = "lefty",
    RIGHTX = "rightx",
    RIGHTY = "righty",
    LEFTTRIGGER = "lefttrigger",
    RIGHT_TRIGGER = "righttrigger"
}

return Input