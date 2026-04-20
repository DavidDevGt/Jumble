-- common/utils/Logger.lua
-- Sistema simple de logging

local Logger = {}

Logger.LEVELS = {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3
}

Logger.currentLevel = Logger.LEVELS.INFO

function Logger:debug(tag, message)
    if self.currentLevel <= self.LEVELS.DEBUG then
        print("[DEBUG] [" .. tag .. "] " .. message)
    end
end

function Logger:info(tag, message)
    if self.currentLevel <= self.LEVELS.INFO then
        print("[INFO] [" .. tag .. "] " .. message)
    end
end

function Logger:warn(tag, message)
    if self.currentLevel <= self.LEVELS.WARN then
        print("[WARN] [" .. tag .. "] " .. message)
    end
end

function Logger:error(tag, message)
    if self.currentLevel <= self.LEVELS.ERROR then
        print("[ERROR] [" .. tag .. "] " .. message)
    end
end

function Logger:setLevel(level)
    self.currentLevel = level
end

return Logger
