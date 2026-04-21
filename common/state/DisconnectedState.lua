-- common/state/DisconnectedState.lua
-- Estado cuando se pierde conexión con el servidor

local DisconnectedState = {}
DisconnectedState.__index = DisconnectedState

local Logger = require("common.utils.Logger")

function DisconnectedState:new()
    local self = setmetatable({}, DisconnectedState)
    self.reason = "Conexión perdida"
    self.timeDisconnected = 0
    self.selection = 1
    self.options = {"REINTENTAR", "MENU"}
    return self
end

function DisconnectedState:enter(args)
    Logger:warn("DISCONNECTED", "Conexión perdida con servidor")
    
    if args and args.reason then
        self.reason = args.reason
    end
    
    self.timeDisconnected = 0
    self.selection = 1
end

function DisconnectedState:update(dt)
    self.timeDisconnected = self.timeDisconnected + dt
end

function DisconnectedState:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Fondo
    love.graphics.setColor(0.1, 0.05, 0.05)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Título
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.printf("DESCONECTADO", 0, h * 0.2, w, "center")
    
    -- Razón
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(self.reason, 0, h * 0.3, w, "center")
    
    -- Tiempo desconectado
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.printf("Desconectado hace: " .. string.format("%.1f", self.timeDisconnected) .. "s", 
                        0, h * 0.4, w, "center")
    
    -- Opciones
    local optionY = h * 0.55
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

function DisconnectedState:handleInput(key, scancode, isrepeat)
    if key == "up" then
        self.selection = math.max(1, self.selection - 1)
    elseif key == "down" then
        self.selection = math.min(#self.options, self.selection + 1)
    elseif key == "return" then
        if self.selection == 1 then
            Logger:info("DISCONNECTED", "Retentando conexión")
            return "connecting"
        elseif self.selection == 2 then
            Logger:info("DISCONNECTED", "Volviendo a menú")
            return "menu"
        end
    end
end

function DisconnectedState:exit()
    Logger:info("DISCONNECTED", "Saliendo estado desconectado")
end

return DisconnectedState
