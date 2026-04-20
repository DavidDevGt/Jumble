-- common/protocol/Serialization.lua
-- Serialización y deserialización de datos

local Serialization = {}

-- Función para serializar en formato simple (JSON-like)
-- En producción, usar bitser para compresión
function Serialization:serialize(data)
    return self:toJSON(data)
end

function Serialization:deserialize(data)
    return self:fromJSON(data)
end

-- Convertir tabla a JSON
function Serialization:toJSON(obj, depth)
    depth = depth or 0
    if depth > 10 then return "null" end
    
    local t = type(obj)
    
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return obj and "true" or "false"
    elseif t == "number" then
        return tostring(obj)
    elseif t == "string" then
        return '"' .. obj:gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    elseif t == "table" then
        if obj[1] ~= nil then
            -- Array
            local parts = {}
            for i, v in ipairs(obj) do
                table.insert(parts, self:toJSON(v, depth + 1))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            -- Object
            local parts = {}
            for k, v in pairs(obj) do
                if type(k) == "string" then
                    table.insert(parts, '"' .. k .. '":' .. self:toJSON(v, depth + 1))
                end
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return "null"
    end
end

-- Convertir JSON a tabla (parser básico)
function Serialization:fromJSON(str)
    -- Para producción, usar una librería JSON robusta
    local pos = 1
    
    local function skipWhitespace()
        while pos <= #str and str:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
    end
    
    local function parseValue()
        skipWhitespace()
        local char = str:sub(pos, pos)
        
        if char == "{" then
            return self:parseObject()
        elseif char == "[" then
            return self:parseArray()
        elseif char == '"' then
            return self:parseString()
        elseif char == "t" or char == "f" then
            return self:parseBoolean()
        elseif char == "n" then
            return self:parseNull()
        else
            return self:parseNumber()
        end
    end
    
    -- Llamar parser
    return parseValue()
end

return Serialization
