function love.conf(t)
    t.identity = "Jumble"
    t.version = "11.5"
    
    t.window = {
        title = "Jumble",
        width = 1280,
        height = 720,
        borderless = false,
        resizable = true,
        minwidth = 640,
        minheight = 360,
        fullscreen = false,
        fullscreentype = "desktop",
        vsync = 1,
        msaa = 0,
        display = 1,
        highdpi = false
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
    
    t.audio = {
        mic = false,
        mixwithsystem = true
    }
    
    t.console = false
    t.accelerometerjoystick = true
    t.externalstorage = false
    t.gammacorrect = false
    t.appendidentity = false
end