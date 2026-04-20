# SETUP.md - Guía de Instalación y Configuración

## Prerrequisitos del Sistema

### Windows
```powershell
# Verificar Python (para algunas herramientas)
python --version

# LÖVE 11.5 - Descargar de https://love2d.org/
# Agregar a PATH si es necesario
love --version
```

### macOS
```bash
brew install love
```

### Linux
```bash
sudo apt-get install love  # Debian/Ubuntu
# o compilar desde fuente
```

## Instalación de Dependencias

### 1. sock.lua (Networking)

```bash
# Navegar a la raíz del proyecto
cd Jumble

# Crear carpeta libs
mkdir -p libs

# Clonar sock.lua
git clone https://github.com/camchenry/sock.lua.git libs/sock

# Verificar instalación
ls libs/sock/sock.lua
```

**Alternativa: enet-lua**
```bash
git clone https://github.com/fnuecke/enet-lua.git libs/enet
```

### 2. bitser (Serialización)

```bash
git clone https://github.com/gvx/bitser.git libs/bitser
```

**Alternativa: MessagePack**
```bash
git clone https://github.com/antirez/lua-cmsgpack.git libs/msgpack
```

### 3. Librerías Opcionales

```bash
# OOP (Classic/Middleclass)
git clone https://github.com/rxi/classic.git libs/classic

# Timer Manager
git clone https://github.com/kikito/tick.lua.git libs/tick

# Debug/Inspect
git clone https://github.com/kikito/inspect.lua.git libs/inspect
```

## Estructura de Carpetas Final

```
Jumble/
├── libs/
│   ├── sock/
│   │   ├── sock.lua
│   │   └── examples/
│   ├── bitser/
│   │   └── bitser.lua
│   ├── classic/
│   │   └── classic.lua
│   └── inspect/
│       └── inspect.lua
├── common/
├── client/
├── server/
├── docs/
├── ARCHITECTURE.md
├── SETUP.md
└── README.md
```

## Configuración del Proyecto

### 1. Conectar Librerías

En `client/main.lua`:
```lua
-- Agregar al inicio
package.path = package.path .. ";libs/?.lua;libs/?/?.lua"

-- Cargar librerías
local sock = require("sock")
local bitser = require("bitser")
```

### 2. Variables de Entorno (Opcional)

```bash
# Windows
set LOVE_DEBUG=1
set LOVE_VSYNC=1

# Linux/macOS
export LOVE_DEBUG=1
export LOVE_VSYNC=1
```

### 3. Configuración de Red

Editar `common/config/NetworkConfig.lua`:

**Desarrollo Local:**
```lua
NetworkConfig.SERVER_HOST = "localhost"
NetworkConfig.SERVER_PORT = 8888
NetworkConfig.DEBUG_LATENCY = 0  -- Sin latencia simulada
```

**Testing con Latencia:**
```lua
NetworkConfig.DEBUG_LATENCY = 50  -- Simular 50ms de latencia
```

**Producción:**
```lua
NetworkConfig.SERVER_HOST = "miservidor.com"
NetworkConfig.SERVER_PORT = 9999
NetworkConfig.DEBUG_LATENCY = 0
NetworkConfig.DEBUG_PACKETS = false
```

## Ejecutar el Proyecto

### Opción 1: Línea de Comandos

```bash
# Terminal 1 - Servidor
cd Jumble/server
love .

# Terminal 2 - Cliente 1
cd Jumble/client
love .

# Terminal 3 - Cliente 2
cd Jumble/client
love .
```

### Opción 2: Script de Inicio (Windows)

Crear `run.bat`:
```batch
@echo off
start cmd /k "cd server && love ."
start cmd /k "cd client && love ."
timeout /t 2
start cmd /k "cd client && love ."
```

Ejecutar:
```bash
run.bat
```

### Opción 3: Script de Inicio (Linux/macOS)

Crear `run.sh`:
```bash
#!/bin/bash

cd "$(dirname "$0")"

# Servidor
gnome-terminal --tab -- bash -c "cd server && love ."

# Cliente 1
gnome-terminal --tab -- bash -c "cd client && love ."

# Cliente 2
gnome-terminal --tab -- bash -c "cd client && love ."
```

Ejecutar:
```bash
chmod +x run.sh
./run.sh
```

## Debugging

### Modo Debug Activado

Editar `common/config/NetworkConfig.lua`:
```lua
NetworkConfig.DEBUG_PACKETS = true
NetworkConfig.DEBUG_LATENCY = 100  -- 100ms
```

### Console Output

```lua
-- Imprimir en consola
print("Debug: " .. variable)
love.debug.setErrorHandler(function(msg) print(msg) end)
```

### Logger Personalizado

```lua
local Logger = require("common.utils.Logger")
Logger:setLevel(Logger.LEVELS.DEBUG)

Logger:debug("COMPONENT", "Mensaje de debug")
Logger:error("COMPONENT", "Error crítico")
```

## Testing

### Test Unitario Simple

Crear `tests/test_vector.lua`:
```lua
local Vector2 = require("common.utils.Vector2")

-- Test 1: Creación
local v = Vector2:new(3, 4)
assert(v.x == 3 and v.y == 4, "Vector creation failed")

-- Test 2: Magnitud
assert(v:magnitude() == 5, "Magnitude calculation failed")

print("✓ Todos los tests pasaron")
```

Ejecutar:
```bash
love tests/
```

## Optimización

### Profiling (FPS)

En `client/main.lua`:
```lua
function love.draw()
    -- ... código
    
    -- Mostrar FPS
    love.graphics.setColor(1, 0, 0)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
end
```

### Reducir Bandwidth

```lua
-- Usar compresión bitser
local bitser = require("bitser")
local compressed = bitser.dumps(largeData)
```

### Recolector de Basura

```lua
-- En servidor (crítico)
collectgarbage("step", 1000)
```

## Solución de Problemas

### "love: not found"
```bash
# Agregar LÖVE a PATH
# Windows: Editar variables de entorno
# Linux: ln -s /usr/bin/love /usr/local/bin/love
```

### "Socket connection refused"
```
- Verificar que servidor está corriendo
- Revisar puerto (predeterminado: 8888)
- Verificar firewall
```

### "Memory leak"
```lua
-- Debugear con:
collectgarbage("collect")
print("Memory: " .. collectgarbage("count") / 1024 .. "MB")
```

### Baja performance
```lua
-- Reducir update rate
-- Desactivar debug
-- Usar delta compression
```

## Próximos Pasos

1. Lee [docs/00_START_HERE.md](00_START_HERE.md) para orientación
2. Lee [docs/01_ARCHITECTURE.md](01_ARCHITECTURE.md) para arquitectura
3. Ejecuta cliente y servidor
4. Revisa logs en consola
5. Implementa lógica de juego personalizada

## Referencias

- [LÖVE Documentation](https://love2d.org/wiki/Main_Page)
- [sock.lua GitHub](https://github.com/camchenry/sock.lua)
- [bitser GitHub](https://github.com/gvx/bitser)
- [Lua 5.4 Manual](https://www.lua.org/manual/5.4/)

