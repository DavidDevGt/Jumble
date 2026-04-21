-- conf.lua
function love.conf(t)
    t.identity = "Jumble"
    t.version = "11.5"
    t.modules.font = true
    t.window = {
        title = "Jumble",
        width = 800,
        height = 600
    }
end