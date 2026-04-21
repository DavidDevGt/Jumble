-- common/utils/Logger.lua
-- Sistema de logging estructurado con timestamps

local Logger = {}

Logger.LEVEL_DEBUG = 0
Logger.LEVEL_INFO = 1
Logger.LEVEL_WARN = 2
Logger.LEVEL_ERROR = 3

Logger.LEVELS = {
    DEBUG = Logger.LEVEL_DEBUG,
    INFO = Logger.LEVEL_INFO,
    WARN = Logger.LEVEL_WARN,
    ERROR = Logger.LEVEL_ERROR
}

Logger.minLevel = Logger.LEVEL_INFO

-- Alias para compatibilidad
function Logger:setLevel(level)
    self.minLevel = level
end

--- Función interna para loguear
-- @param level number - Nivel de log (0-3)
-- @param tag string - Etiqueta/componente
-- @param message string - Mensaje
local function log(level, tag, message)
    if level < Logger.minLevel then return end
    
    local levelNames = {"DEBUG", "INFO ", "WARN ", "ERROR"}
    local levelName = levelNames[level + 1] or "UNKN"
    local timestamp = os.date("%H:%M:%S")
    
    -- Formato: [HH:MM:SS] [LEVEL] [TAG]: message
    print(string.format("[%s] [%-5s] %-12s: %s", timestamp, levelName, tag, message))
end

function Logger:debug(tag, message)
    log(self.LEVEL_DEBUG, tag, message)
end

function Logger:info(tag, message)
    log(self.LEVEL_INFO, tag, message)
end

function Logger:warn(tag, message)
    log(self.LEVEL_WARN, tag, message)
end

function Logger:error(tag, message)
    log(self.LEVEL_ERROR, tag, message)
end

--- Obtener nivel mínimo actual
-- @return number - Nivel mínimo
function Logger:getMinLevel()
    return self.minLevel
end

return Logger
