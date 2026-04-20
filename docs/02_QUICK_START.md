# QUICK_START.md - Inicio Rápido (5 Minutos)

## Objetivo: Ver el juego funcionando en 5 minutos

---

## Paso 1: Verificar Requisitos (1 minuto)

```powershell
# Windows - Verificar que LÖVE está instalado
love --version

# macOS
brew install love

# Linux
sudo apt-get install love
```

Si no tienes LÖVE:
- Descargar: https://love2d.org/wiki/11.5
- Instalar normalmente

---

## Paso 2: Descargar Librerías (2 minutos)

Navega a la carpeta del proyecto:

```bash
cd c:\apps\Jumble
```

Crear carpeta `libs`:

```bash
mkdir libs
cd libs
```

Descargar sock.lua (networking):

```bash
git clone https://github.com/camchenry/sock.lua.git sock
```

Descargar bitser (serialización):

```bash
git clone https://github.com/gvx/bitser.git bitser
```

Resultado esperado:

```
Jumble/
├── libs/
│   ├── sock/
│   │   ├── sock.lua
│   │   └── examples/
│   └── bitser/
│       └── bitser.lua
├── common/
├── client/
├── server/
└── ...
```

---

## Paso 3: Ejecutar Servidor (1 minuto)

Abre **Terminal 1**:

```bash
cd c:\apps\Jumble\server
love .
```

Esperarás ver:

```
[INFO] Server iniciado en puerto 8888
[INFO] Esperando conexiones...
```

✅ **Servidor corriendo**

---

## Paso 4: Ejecutar Cliente (1 minuto)

Abre **Terminal 2** (mientras servidor sigue corriendo):

```bash
cd c:\apps\Jumble\client
love .
```

Verás una ventana con:
- Fondo oscuro
- Posiblemente un cuadrado azul (tu jugador)
- Logs de conexión

✅ **Cliente conectado**

---

## Paso 5: Agregar Más Clientes (Opcional)

Abre **Terminal 3, 4, etc.:**

```bash
cd c:\apps\Jumble\client
love .
```

Ahora tendrás múltiples jugadores que puedes controlar con **WASD**.

---

## Primeras Pruebas

### Test 1: Movimiento
- Presiona **W, A, S, D** en el cliente
- Verás el cuadrado azul moverse
- Verás el movimiento suavizado (interpolación)

### Test 2: Múltiples Jugadores
- Abre 2-3 clientes
- Mueve a cada uno con WASD
- Verás a otros jugadores desde perspectiva de cada cliente

### Test 3: Validación Anti-Hack
- Intenta modificar client/main.lua para teleportear:
  ```lua
  player.position.x = 5000  -- Posición imposible
  ```
- El servidor lo rechazará y te devolverá a posición válida

---

## Primer Cambio: Modificar Velocidad

Abre [common/config/GameConfig.lua](../common/config/GameConfig.lua):

```lua
-- Cambiar esta línea:
GameConfig.PLAYER_SPEED = 300  -- Original

-- A esto:
GameConfig.PLAYER_SPEED = 600  -- 2x más rápido
```

Reinicia servidor y cliente → ¡Verás que es 2x más rápido!

---

## Segundo Cambio: Cambiar Color de Jugador

Abre [client/render/Renderer.lua](../client/render/Renderer.lua):

```lua
-- Encuentra esta línea:
love.graphics.setColor(0, 0, 1)  -- Azul

-- Cambia a:
love.graphics.setColor(1, 0, 0)  -- Rojo
```

Reinicia → ¡Tu jugador es rojo!

---

## Troubleshooting

### Error: "love: command not found"
```bash
# Windows: Añade LÖVE a PATH
# Linux: 
sudo ln -s /usr/bin/love /usr/local/bin/love

# macOS: Debería estar en PATH automáticamente
```

### Error: "Cannot find sock.lua"
```bash
# Verifica que exists:
ls libs/sock/sock.lua
```

### Error: "Socket connection refused"
1. Verifica que servidor está corriendo (`Terminal 1`)
2. Verifica puerto 8888 está libre
3. Revisa logs del servidor

### Ventana negra sin actividad
- Servidor corriendo? (debería mostrar logs)
- Cliente corriendo? (debería mostrar logs)
- Revisa **console** (pueden haber errores silenciosos)

---

## Logs en Consola

El proyecto usa [common/utils/Logger.lua](../common/utils/Logger.lua).

Activa debug completo en [common/config/NetworkConfig.lua](../common/config/NetworkConfig.lua):

```lua
NetworkConfig.DEBUG_PACKETS = true   -- Log de paquetes
NetworkConfig.DEBUG_LATENCY = 50     -- Simular 50ms latencia
```

---

## Próximos Pasos

✅ **Completaste:** Configuración básica y primera ejecución

👉 **Lee ahora:** [01_ARCHITECTURE.md](01_ARCHITECTURE.md) (20 min)

👉 **Luego:** Modifica más valores y explora el código

---

## Cheat Sheet - Comandos Rápidos

```bash
# Terminal 1: Servidor
cd Jumble/server && love .

# Terminal 2: Cliente 1
cd Jumble/client && love .

# Terminal 3: Cliente 2
cd Jumble/client && love .

# Matar un proceso:
# Windows: Ctrl+C en el terminal
# macOS/Linux: Ctrl+C
```

---

**¡Listo! Ya tienes un videojuego multijugador funcionando. 🎮**
