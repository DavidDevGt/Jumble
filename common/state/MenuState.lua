-- common/state/MenuState.lua
-- Estado del menú principal

local MenuState = {}
MenuState.__index = MenuState

local Logger = require("common.utils.Logger")

function MenuState:new()
    local self = setmetatable({}, MenuState)
    self.selection = 1
    self.options = {"JUGAR", "SETTINGS", "SALIR"}
    self.hoveredOption = 1
    self.transitionTime = 0
    return self
end

function MenuState:enter()
    Logger:info("MENU", "Entrando al menú")
    self.selection = 1
    self.hoveredOption = 1
    self.transitionTime = 0
end

function MenuState:update(dt)
    self.transitionTime = self.transitionTime + dt
    -- Sin lógica especial en update, todo en input
end

function MenuState:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Título
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("JUMBLE", 0, h * 0.2, w, "center")
    love.graphics.printf("Pico Park Clone", 0, h * 0.25, w, "center")
    
    -- Subtítulo
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Plataformer Multijugador", 0, h * 0.3, w, "center")
    
    -- Opciones del menú
    local optionY = h * 0.5
    local optionSpacing = 50
    
    for i, option in ipairs(self.options) do
        local y = optionY + (i - 1) * optionSpacing
        
        if i == self.selection then
            love.graphics.setColor(0.2, 1, 0.2)
            love.graphics.rectangle("fill", w/2 - 80, y - 15, 160, 40)
            love.graphics.setColor(0, 0, 0)
        else
            love.graphics.setColor(1, 1, 1)
        end
        
        love.graphics.printf(option, 0, y, w, "center")
    end
    
    -- Instrucciones
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Arriba/Abajo para navegar | Enter para seleccionar", 0, h - 40, w, "center")
end

function MenuState:handleInput(key, scancode, isrepeat)
    if key == "up" then
        self.selection = math.max(1, self.selection - 1)
    elseif key == "down" then
        self.selection = math.min(#self.options, self.selection + 1)
    elseif key == "return" then
        if self.selection == 1 then
            Logger:info("MENU", "Seleccionado: JUGAR")
            return "connecting"
        elseif self.selection == 2 then
            Logger:info("MENU", "Seleccionado: SETTINGS")
            return "settings"
        elseif self.selection == 3 then
            Logger:info("MENU", "Seleccionado: SALIR")
            love.event.quit()
        end
    end
end

function MenuState:exit()
    Logger:info("MENU", "Saliendo del menú")
end

return MenuState
