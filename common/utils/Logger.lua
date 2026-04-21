-- common/utils/Logger.lua
-- Logger estructurado con timestamps, niveles y colores ANSI

local Logger = {}

Logger.LEVELS = {
    DEBUG = 0,
    INFO  = 1,
    WARN  = 2,
    ERROR = 3
}

local LEVEL_NAMES = { [0] = "DEBUG", [1] = "INFO ", [2] = "WARN ", [3] = "ERROR" }
local LEVEL_COLORS = {
    [0] = "\27[36m",  -- cyan
    [1] = "\27[32m",  -- green
    [2] = "\27[33m",  -- yellow
    [3] = "\27[31m",  -- red
}
local RESET = "\27[0m"

Logger.currentLevel = Logger.LEVELS.INFO
Logger.useColors = true

function Logger:setLevel(level)
    self.currentLevel = level
end

function Logger:setColorsEnabled(enabled)
    self.useColors = enabled
end

function Logger:log(level, tag, message)
    if level < self.currentLevel then return end

    local color = self.useColors and LEVEL_COLORS[level] or ""
    local reset = self.useColors and RESET or ""
    local name  = LEVEL_NAMES[level] or "UNKN "

    print(string.format(
        "%s[%s] [%s] %-12s: %s%s",
        color, os.date("%H:%M:%S"), name, tag, message, reset
    ))
end

function Logger:debug(tag, message) self:log(self.LEVELS.DEBUG, tag, message) end
function Logger:info(tag, message)  self:log(self.LEVELS.INFO,  tag, message) end
function Logger:warn(tag, message)  self:log(self.LEVELS.WARN,  tag, message) end
function Logger:error(tag, message) self:log(self.LEVELS.ERROR, tag, message) end

return Logger
