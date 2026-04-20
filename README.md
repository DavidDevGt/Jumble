-- README.md
# Jumble - Videojuego 2D Multijugador

[![Lua](https://img.shields.io/badge/Lua-5.4-blue.svg)](https://www.lua.org/)
[![LÖVE](https://img.shields.io/badge/LÖVE-11.5-red.svg)](https://love2d.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Jumble es un videojuego 2D multijugador de código abierto construido con **Lua 5.4** y **LÖVE 11.5**. Utiliza una arquitectura **Cliente-Servidor Autoritativa** para garantizar competencia justa y sincronización en tiempo real.

## Características

✨ **Multiplayer Real-Time:** Soporta hasta 32 jugadores simultáneamente  
🔒 **Anti-Trampas:** Validación server-side de todos los inputs  
⚡ **Baja Latencia:** Interpolación suave e input prediction  
📡 **Networking Eficiente:** Serialización binaria con bitser  
🎮 **Fácil de Extender:** Arquitectura modular y bien documentada  

## Requisitos

- **LÖVE 11.5+** - https://love2d.org/wiki/11.5
- **Lua 5.4** (incluido en LÖVE)
- **sock.lua** - Para networking
- **bitser** - Para serialización

## Instalación Rápida

```bash
# 1. Clonar repositorio
git clone https://github.com/tu-usuario/jumble.git
cd jumble

# 2. Descargar dependencias
mkdir libs
cd libs
git clone https://github.com/camchenry/sock.lua.git sock
git clone https://github.com/gvx/bitser.git bitser
cd ..

# 3. Ejecutar servidor (terminal 1)
love server/

# 4. Ejecutar cliente (terminal 2)
love client/

# 5. Conectarse a localhost:8888
```

## Estructura del Proyecto

```
Jumble/
├── common/              # Código compartido
├── client/              # Código del cliente LÖVE
├── server/              # Código del servidor LÖVE
├── ARCHITECTURE.md      # Documentación detallada
└── README.md            # Este archivo
```

Ver [ARCHITECTURE.md](ARCHITECTURE.md) para detalles técnicos completos.

## Desarrollo

### Agregar una Nueva Entidad

```lua
-- common/entities/Enemy.lua
local Enemy = {}
Enemy.__index = Enemy

function Enemy:new(id, x, y)
    local self = setmetatable({}, Enemy)
    self.id = id
    self.position = Vector2:new(x, y)
    self.health = 50
    return self
end

function Enemy:update(dt, gravity)
    -- Lógica de actualización
end

return Enemy
```

### Procesar Input Personalizado

```lua
-- server/game/GameLogic.lua
function GameLogic:handleSpecialAbility(playerId, abilityId)
    local player = gameState.players[playerId]
    if not player or not self:canUseAbility(player, abilityId) then
        return false
    end
    
    -- Aplicar lógica de habilidad
    -- Broadcast a clientes
    
    return true
end
```

## Debugging

### Logs del Servidor
```bash
love server/ 2>&1 | grep "\[ERROR\]"
```

### Latencia Simulada
En [common/config/NetworkConfig.lua](common/config/NetworkConfig.lua):
```lua
NetworkConfig.DEBUG_LATENCY = 100  -- 100ms de latencia simulada
```

### Packet Inspector
```lua
NetworkConfig.DEBUG_PACKETS = true  -- Log de todos los paquetes
```

## Benchmarks

| Métrica | Valor |
|---------|-------|
| Tick Rate | 60 Hz |
| Max Players | 32 |
| State Update Rate | 20 Hz |
| Packet Size (avg) | ~256 bytes |
| Latency (local) | 1-5ms |

## Roadmap

- [ ] Sistema de lobby
- [ ] Persistencia de datos
- [ ] Sala de espera
- [ ] Ranking y estadísticas
- [ ] Sistema de chat
- [ ] Efectos visuales
- [ ] Sonido y música
- [ ] Mapas dinámicos

## Contribuir

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo licencia MIT - ver [LICENSE](LICENSE) para detalles.

## Autores

- **Tu Nombre** - *Arquitecto principal*

## Agradecimientos

- LÖVE Community
- sock.lua - Networking en Lua
- bitser - Serialización binaria
- GaffeGames - Recursos de multiplayer

## Soporte

Para issues, preguntas o sugerencias:
- Abre un issue en GitHub
- Contacta a través de Discord
- Lee la documentación en [ARCHITECTURE.md](ARCHITECTURE.md)
