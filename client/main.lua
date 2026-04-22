-- client/main.lua
-- Punto de entrada del cliente - Jumble
-- Modo single-player con física local y nivel 1 (plataformas + goal).
-- Es el scaffold base antes del mecánico co-op server-authoritative.

-- Permite `require("sock")`, `require("bitser")` sin prefijo libs.
package.path = package.path .. ";libs/?.lua;libs/?/?.lua"

local GameConfig = require("common.config.GameConfig")
local Logger     = require("common.utils.Logger")

-- Tuning local de controles. GameConfig.JUMP_FORCE=150000 es inusable
-- (salto de escape velocity); acá calibramos para un salto parabólico
-- de ~260px con GRAVITY=800: v = sqrt(2*g*h) ≈ 632.
local JUMP_IMPULSE_VELOCITY = 650
local GOAL_TOUCH_DISTANCE   = 45
local FAIL_COUNTDOWN        = 3.0  -- segundos que se muestra el overlay "FALLASTE" antes de reiniciar
local FALL_DEATH_Y          = GameConfig.WORLD_HEIGHT + 100 -- bajando de aquí = caída al vacío

GAME_STATE    = nil
physicsWorld  = nil

PLAYER_COLORS = {
    {1,   0.3, 0.3},  -- Rojo
    {0.3, 1,   0.3},  -- Verde
    {0.3, 0.3, 1  },  -- Azul
    {1,   1,   0.3},  -- Amarillo
    {1,   0.3, 1  },  -- Magenta
    {0.3, 1,   1  },  -- Cyan
    {1,   0.5, 0.3},  -- Naranja
    {0.5, 0.3, 1  },  -- Púrpura
}

----------------------------------------------------------------------
-- Niveles (data-driven, por ahora inline; se moverán a JSON/tablas
-- propias cuando entren más niveles).
----------------------------------------------------------------------

-- Convención: la primera plataforma de cada nivel es el SPAWN PLATFORM
-- (base ancha donde aparece el jugador). La última es la plataforma
-- del goal (también ancha, para que el landing sea claro). Los gaps
-- del medio son el desafío.
--
-- Todo lo que no sea plataforma = vacío. Caerse = fail.

local function createLevel1()
    return {
        name     = "Nivel 1 - Ascenso",
        spawn    = { x = 110, y = 790 },
        platforms = {
            { x = 20,   y = 820, w = 220, h = 20 },   -- SPAWN
            { x = 320,  y = 740, w = 140, h = 20 },
            { x = 540,  y = 650, w = 140, h = 20 },
            { x = 340,  y = 560, w = 140, h = 20 },
            { x = 600,  y = 470, w = 180, h = 20 },
            { x = 880,  y = 380, w = 180, h = 20 },
            { x = 1180, y = 280, w = 240, h = 20 },   -- GOAL platform
        },
        goal = { x = 1260, y = 220, w = 60, h = 60 },
    }
end

-- Nivel 2: plataformas más chicas, gaps más largos. Exige precisión
-- de salto y timing al girarse en el aire.
local function createLevel2()
    return {
        name     = "Nivel 2 - Precisión",
        spawn    = { x = 100, y = 790 },
        platforms = {
            { x = 20,   y = 820, w = 180, h = 20 },   -- SPAWN
            { x = 280,  y = 740, w = 90,  h = 20 },
            { x = 110,  y = 650, w = 90,  h = 20 },
            { x = 320,  y = 560, w = 90,  h = 20 },
            { x = 540,  y = 490, w = 100, h = 20 },
            { x = 770,  y = 420, w = 90,  h = 20 },
            { x = 980,  y = 360, w = 90,  h = 20 },
            { x = 1180, y = 290, w = 100, h = 20 },
            { x = 1370, y = 210, w = 200, h = 20 },   -- GOAL platform
        },
        goal = { x = 1450, y = 150, w = 60, h = 60 },
    }
end

local function allLevels()
    return { createLevel1(), createLevel2() }
end

----------------------------------------------------------------------
-- Lifecycle
----------------------------------------------------------------------

function love.load()
    Logger:info("JUMBLE", "Inicializando cliente...")

    GAME_STATE = {
        -- Modos: "menu", "playing", "failed", "all_done"
        -- (más adelante: "lobby", "completed" como transiciones explícitas)
        mode                 = "menu",
        menuSelection        = 1,
        players              = {},
        localPlayerId        = 1,
        gameTime             = 0,

        -- Progresión. GAME_STATE.currentLevel es la referencia activa;
        -- los bodies de sus platforms viven dentro suyo (en platformBodies).
        levels               = allLevels(),
        currentLevelIndex    = 1,
        currentLevel         = nil, -- se setea más abajo

        -- Estado del nivel actual
        levelCompleted       = false,
        levelCompletedTimer  = 0,

        -- Shared-fate: si algún jugador cae, todo el equipo reinicia.
        -- En single-player esto es just-in-time; cuando tengamos network,
        -- el server emitirá un evento "fail" y todos los clientes
        -- entrarán acá simultáneamente.
        failTimer            = 0,
        failReason           = nil,
        attempts             = 0,  -- acumulativo por sesión (todos los niveles)
    }
    GAME_STATE.currentLevel = GAME_STATE.levels[GAME_STATE.currentLevelIndex]

    initPhysics()
    loadLevel(GAME_STATE.currentLevel)

    _G.inputManager = require("client.network.InputManager"):new()
    _G.client       = require("client.network.Client"):new()

    Logger:info("JUMBLE", "Cliente listo")
end

function initPhysics()
    _G.physicsWorld = love.physics.newWorld(0, GameConfig.GRAVITY, true)

    -- No hay suelo full-width. Cada nivel define su propio spawn platform
    -- como primera entrada en `platforms`. Todo lo que no es plataforma = vacío.
    -- Solo quedan las paredes, que centran el cuadro de juego y evitan que
    -- el player escape lateralmente (termina cayendo igual por las esquinas).
    --
    -- Body en (x=pos, y=WORLD_HEIGHT/2) con shape centrado: physics y visual
    -- coinciden (cubren el ancho completo en Y, solapados con el borde de
    -- ventana). Antes el suelo tenía un bug — body en X=0 con shape ancho
    -- 1600 centrado dejaba el shape cubriendo X=-800..800 mientras el draw
    -- lo pintaba en X=0..1600. De ahí el "piso fantasma" desde X=800.
    local leftWall = love.physics.newBody(physicsWorld, -20, GameConfig.WORLD_HEIGHT/2)
    love.physics.newFixture(leftWall,
        love.physics.newRectangleShape(0, 0, 40, GameConfig.WORLD_HEIGHT), 1)

    local rightWall = love.physics.newBody(physicsWorld, GameConfig.WORLD_WIDTH + 20, GameConfig.WORLD_HEIGHT/2)
    love.physics.newFixture(rightWall,
        love.physics.newRectangleShape(0, 0, 40, GameConfig.WORLD_HEIGHT), 1)
end

function loadLevel(levelData)
    -- Plataformas estáticas. Guarda refs a los bodies para poder destruirlos
    -- en reloadCurrentLevel().
    levelData.platformBodies = {}
    for _, p in ipairs(levelData.platforms) do
        local body = love.physics.newBody(physicsWorld, p.x + p.w/2, p.y + p.h/2, "static")
        love.physics.newFixture(body, love.physics.newRectangleShape(0, 0, p.w, p.h), 1)
        table.insert(levelData.platformBodies, body)
    end

    spawnLocalPlayer(levelData.spawn.x, levelData.spawn.y)

    Logger:info("JUMBLE", "Cargado: " .. levelData.name)
end

function spawnLocalPlayer(x, y)
    local player = {
        id         = 1,
        name       = "P1",
        x          = x,
        y          = y,
        vx         = 0,
        vy         = 0,
        width      = GameConfig.PLAYER_WIDTH,
        height     = GameConfig.PLAYER_HEIGHT,
        isGrounded = false,
        color      = PLAYER_COLORS[1],
    }

    player.body    = love.physics.newBody(physicsWorld, x, y, "dynamic")
    player.shape   = love.physics.newRectangleShape(0, 0, player.width, player.height)
    player.fixture = love.physics.newFixture(player.body, player.shape, 1)
    player.body:setFixedRotation(true)
    -- Sin damping: la velocidad horizontal la seteamos directo cada frame.

    GAME_STATE.players[1] = player
    Logger:info("JUMBLE", string.format("Spawn en (%d, %d)", x, y))
end

function reloadCurrentLevel()
    -- Tear-down de bodies del nivel actual.
    local level = GAME_STATE.currentLevel
    if level.platformBodies then
        for _, body in ipairs(level.platformBodies) do
            if not body:isDestroyed() then body:destroy() end
        end
    end

    local player = GAME_STATE.players[1]
    if player and player.body and not player.body:isDestroyed() then
        player.body:destroy()
    end

    GAME_STATE.players             = {}
    GAME_STATE.levelCompleted      = false
    GAME_STATE.levelCompletedTimer = 0
    GAME_STATE.failTimer           = 0
    GAME_STATE.failReason          = nil

    loadLevel(level)
end

-- Avanza al siguiente nivel de GAME_STATE.levels, o marca "all_done"
-- si ya se jugó el último. También es la entrada a la progression en
-- el modo network: cuando el server broadcastea "level_completed" con
-- el siguiente índice, esto lo carga.
function advanceToNextLevel()
    GAME_STATE.currentLevelIndex = GAME_STATE.currentLevelIndex + 1

    if GAME_STATE.currentLevelIndex > #GAME_STATE.levels then
        GAME_STATE.mode = "all_done"
        Logger:info("JUMBLE", "¡Todos los niveles completados en " ..
                              GAME_STATE.attempts .. " intentos!")
        return
    end

    GAME_STATE.currentLevel = GAME_STATE.levels[GAME_STATE.currentLevelIndex]
    reloadCurrentLevel()
    GAME_STATE.mode = "playing"
end

-- Resetea la progresión al primer nivel y el contador de intentos.
-- Punto único para volver a "nueva partida" desde any estado post-juego.
function resetProgression()
    GAME_STATE.currentLevelIndex  = 1
    GAME_STATE.currentLevel       = GAME_STATE.levels[1]
    GAME_STATE.attempts           = 0
    reloadCurrentLevel()
end

-- Shared-fate: dispara el overlay de fallo y arranca el countdown para
-- reiniciar el nivel. En single-player lo llamamos nosotros mismos
-- (cuando el player cae). Cuando haya network, el server emitirá un
-- evento "fail" y el callback lo invocará con la misma firma.
function triggerFail(reason)
    if GAME_STATE.mode == "failed" or GAME_STATE.levelCompleted then return end

    GAME_STATE.mode       = "failed"
    GAME_STATE.failTimer  = 0
    GAME_STATE.failReason = reason or "Un jugador cayó"
    GAME_STATE.attempts   = GAME_STATE.attempts + 1

    Logger:warn("JUMBLE", "¡Fallaste! Motivo: " .. GAME_STATE.failReason ..
                          " (intento #" .. GAME_STATE.attempts .. ")")
end

----------------------------------------------------------------------
-- Update
----------------------------------------------------------------------

function love.update(dt)
    GAME_STATE.gameTime = GAME_STATE.gameTime + dt

    -- Procesar eventos enet (incluso durante el menú, así el handshake
    -- con el server arranca apenas abre la ventana).
    client:update(dt)

    if GAME_STATE.mode == "failed" then
        -- Countdown para reiniciar. Physics sigue corriendo para que el
        -- player "muerto" no se quede congelado en el aire si estaba
        -- cayendo (feel más natural que freeze puro).
        physicsWorld:update(dt)
        GAME_STATE.failTimer = GAME_STATE.failTimer + dt
        if GAME_STATE.failTimer >= FAIL_COUNTDOWN then
            reloadCurrentLevel()
            GAME_STATE.mode = "playing"
        end
        return
    end

    if GAME_STATE.mode ~= "playing" then return end

    inputManager:update(dt)
    physicsWorld:update(dt)
    updateLocalPlayer(dt)

    if GAME_STATE.levelCompleted then
        GAME_STATE.levelCompletedTimer = GAME_STATE.levelCompletedTimer + dt
    end
end

function updateLocalPlayer(dt)
    local player = GAME_STATE.players[1]
    if not player then return end

    checkGrounded(player)

    -- Movimiento horizontal: velocidad directa preserva vy para la física
    -- vertical (gravedad, salto, caída). Feel estilo platformer clásico.
    local input = inputManager:getInput()
    local _, vy = player.body:getLinearVelocity()
    player.body:setLinearVelocity(input.x * GameConfig.PLAYER_SPEED, vy)

    -- Salto: impulso = masa * deltaV (Box2D). Usamos la constante local
    -- en vez de GameConfig.JUMP_FORCE (que era 150000, ~200x demasiado).
    if inputManager.inputState.jump and player.isGrounded then
        player.body:applyLinearImpulse(0, -JUMP_IMPULSE_VELOCITY * player.body:getMass())
        player.isGrounded = false
    end

    -- Caída al vacío: dispara shared-fate (el equipo entero reinicia).
    -- En single-player el "equipo" es este único player, pero el pattern
    -- ya deja la puerta abierta para la versión network.
    if player.body:getY() > FALL_DEATH_Y then
        triggerFail("Un jugador cayó al vacío")
        return
    end

    checkGoal(player)

    -- Sync visual.
    player.x = player.body:getX()
    player.y = player.body:getY()
    player.vx, player.vy = player.body:getLinearVelocity()
end

function checkGrounded(player)
    -- Raycast vertical desde los pies del player. Más preciso que comparar
    -- contra la Y del suelo base — funciona también sobre plataformas.
    player.isGrounded = false
    local rayX   = player.body:getX()
    local feetY  = player.body:getY() + player.height/2
    local probeY = feetY + 4

    physicsWorld:rayCast(rayX, feetY, rayX, probeY,
        function(fixture, x, y, xn, yn, fraction)
            if fixture:getBody() ~= player.body then
                player.isGrounded = true
                return 0
            end
            return 1
        end)
end

function checkGoal(player)
    if GAME_STATE.levelCompleted then return end

    local goal = GAME_STATE.currentLevel.goal
    local gx = goal.x + goal.w/2
    local gy = goal.y + goal.h/2
    local dx = player.body:getX() - gx
    local dy = player.body:getY() - gy

    if (dx*dx + dy*dy) < (GOAL_TOUCH_DISTANCE * GOAL_TOUCH_DISTANCE) then
        GAME_STATE.levelCompleted      = true
        GAME_STATE.levelCompletedTimer = 0
        Logger:info("JUMBLE", "¡" .. GAME_STATE.currentLevel.name .. " completado!")
    end
end

----------------------------------------------------------------------
-- Draw
----------------------------------------------------------------------

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.12)

    if GAME_STATE.mode == "menu" then
        drawMenu()
    elseif GAME_STATE.mode == "playing" or GAME_STATE.mode == "failed" then
        drawGame()
        if GAME_STATE.mode == "failed" then
            drawFailOverlay()
        end
    elseif GAME_STATE.mode == "all_done" then
        drawAllDoneOverlay()
    end
end

function drawAllDoneOverlay()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    love.graphics.setColor(0.1, 0.2, 0.1)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(0.3, 1, 0.3)
    love.graphics.setNewFont(64)
    love.graphics.printf("¡JUEGO COMPLETADO!", 0, h * 0.28, w, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(24)
    love.graphics.printf(
        string.format("Terminaste los %d niveles", #GAME_STATE.levels),
        0, h * 0.44, w, "center"
    )
    love.graphics.printf(
        string.format("Intentos totales: %d", GAME_STATE.attempts),
        0, h * 0.50, w, "center"
    )

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setNewFont(18)
    love.graphics.printf("SPACE / ENTER / ESC para volver al menú",
        0, h * 0.68, w, "center")
end

function drawFailOverlay()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    -- Tint rojizo para marcar la urgencia
    love.graphics.setColor(0.25, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.setColor(1, 0.35, 0.35)
    love.graphics.setNewFont(72)
    love.graphics.printf("¡FALLASTE!", 0, h * 0.28, w, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(22)
    love.graphics.printf(GAME_STATE.failReason or "", 0, h * 0.42, w, "center")

    local remaining = math.max(0, FAIL_COUNTDOWN - GAME_STATE.failTimer)
    love.graphics.setColor(1, 0.9, 0.3)
    love.graphics.setNewFont(40)
    love.graphics.printf(
        string.format("Reiniciando en %.1f", remaining),
        0, h * 0.52, w, "center"
    )

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setNewFont(16)
    love.graphics.printf("ESC para volver al menú",
        0, h * 0.65, w, "center")
end

function drawMenu()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(48)
    love.graphics.printf("JUMBLE", 0, h * 0.22, w, "center")

    love.graphics.setNewFont(16)
    love.graphics.printf("Cooperative puzzle platformer", 0, h * 0.30, w, "center")

    local options = { "JUGAR", "Salir" }
    local startY  = h * 0.45
    for i, option in ipairs(options) do
        if i == GAME_STATE.menuSelection then
            love.graphics.setColor(0.3, 0.9, 0.3)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
        end
        love.graphics.setNewFont(24)
        love.graphics.printf("> " .. option .. " <", 0, startY + i * 50, w, "center")
    end

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setNewFont(12)
    love.graphics.printf("W/S para navegar | ESPACIO para seleccionar",
        0, h * 0.72, w, "center")
end

function drawGame()
    local level  = GAME_STATE.currentLevel
    local worldW = GameConfig.WORLD_WIDTH
    local worldH = GameConfig.WORLD_HEIGHT

    -- Fondo con hazard zone: gradiente de arriba (azul oscuro, zona "aire
    -- neutra") a abajo (rojo oscuro, zona "caer aquí = fail"). Es puramente
    -- visual — la detección real es por Y del player. Pero le da al jugador
    -- un indicador constante de dónde está el peligro.
    local gradientSteps = 8
    for i = 0, gradientSteps - 1 do
        local t = i / (gradientSteps - 1)  -- 0 arriba, 1 abajo
        -- Interpolamos de (0.10, 0.11, 0.16) a (0.35, 0.08, 0.10)
        local r = 0.10 + (0.35 - 0.10) * t
        local g = 0.11 + (0.08 - 0.11) * t
        local b = 0.16 + (0.10 - 0.16) * t
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill",
            0, i * worldH / gradientSteps,
            worldW, worldH / gradientSteps + 1)
    end

    -- Paredes (físicas también, para que el player no escape)
    love.graphics.setColor(0.45, 0.45, 0.5)
    love.graphics.rectangle("fill", 0, 0, 20, worldH)
    love.graphics.rectangle("fill", worldW - 20, 0, 20, worldH)

    -- Plataformas: fill + borde claro. El borde marca visualmente "este es
    -- el borde sólido — más allá es vacío". Responde al pedido de distinguir
    -- claramente superficie segura de caída.
    for i, p in ipairs(level.platforms) do
        -- Fill (tono ligeramente más claro en la spawn y la goal platform
        -- para que se reconozcan a simple vista)
        local isSpawn = (i == 1)
        local isGoal  = (i == #level.platforms)
        if isSpawn then
            love.graphics.setColor(0.35, 0.75, 0.35)   -- Verde: segura, spawn
        elseif isGoal then
            love.graphics.setColor(0.85, 0.55, 0.25)   -- Naranja más saturado: meta
        else
            love.graphics.setColor(0.70, 0.42, 0.20)   -- Naranja base
        end
        love.graphics.rectangle("fill", p.x, p.y, p.w, p.h)

        -- Borde
        love.graphics.setColor(1, 0.85, 0.6)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", p.x + 0.5, p.y + 0.5, p.w - 1, p.h - 1)
    end

    -- Goal (pulsante)
    local goal = level.goal
    local pulse = 0.6 + 0.4 * math.sin(GAME_STATE.gameTime * 3)
    love.graphics.setColor(1, 0.85 * pulse, 0.15)
    love.graphics.rectangle("fill", goal.x, goal.y, goal.w, goal.h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", goal.x + 0.5, goal.y + 0.5, goal.w - 1, goal.h - 1)
    love.graphics.setNewFont(14)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.printf("GOAL", goal.x, goal.y + goal.h/2 - 8, goal.w, "center")

    -- Players — render en píxel entero para que no oscile por el settle
    -- de Box2D (antes el cuadro podía verse 1px arriba o abajo por la
    -- tolerancia de penetración).
    for id, player in pairs(GAME_STATE.players) do
        local color = player.color or PLAYER_COLORS[id] or PLAYER_COLORS[1]
        local size  = player.width or GameConfig.PLAYER_WIDTH
        local drawX = math.floor(player.x - size/2)
        local drawY = math.floor(player.y - size/2)

        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill", drawX, drawY, size, size)

        love.graphics.setColor(player.isGrounded and 0.3 or 1,
                               player.isGrounded and 1   or 1,
                               player.isGrounded and 0.3 or 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", drawX + 0.5, drawY + 0.5, size - 1, size - 1)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(12)
        love.graphics.printf(player.name or ("P" .. id),
            drawX, drawY - 18, size, "center")
    end

    -- HUD
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.setNewFont(14)
    love.graphics.print(string.format("JUMBLE - %s  [%d/%d]",
        level.name, GAME_STATE.currentLevelIndex, #GAME_STATE.levels), 10, 10)
    love.graphics.print("Jugadores: " .. #GAME_STATE.players, 10, 30)
    love.graphics.setColor(0.9, 0.8, 0.3)
    love.graphics.print("Intentos: " .. GAME_STATE.attempts, 10, 50)

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("A/D - Mover | SPACE - Saltar | R - Reintentar | ESC - Menú",
        10, worldH - 30)

    -- Overlay de nivel completado
    if GAME_STATE.levelCompleted then
        local w = love.graphics.getWidth()
        local h = love.graphics.getHeight()
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", 0, 0, w, h)

        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.setNewFont(64)
        love.graphics.printf("¡NIVEL COMPLETADO!", 0, h * 0.33, w, "center")

        local isLast = GAME_STATE.currentLevelIndex >= #GAME_STATE.levels
        local nextHint = isLast
            and "SPACE para ver resultados finales"
            or  "SPACE para el siguiente nivel"

        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(20)
        love.graphics.printf(nextHint .. "  |  R para repetir  |  ESC al menú",
            0, h * 0.55, w, "center")
    end
end

----------------------------------------------------------------------
-- Input global
----------------------------------------------------------------------

function love.keypressed(key)
    if GAME_STATE.mode == "menu" then
        if key == "up" or key == "w" then
            GAME_STATE.menuSelection = math.max(1, GAME_STATE.menuSelection - 1)
        elseif key == "down" or key == "s" then
            GAME_STATE.menuSelection = math.min(2, GAME_STATE.menuSelection + 1)
        elseif key == "return" or key == "space" then
            if GAME_STATE.menuSelection == 1 then
                GAME_STATE.mode = "playing"
            else
                love.event.quit()
            end
        end
    elseif GAME_STATE.mode == "playing" then
        if key == "escape" then
            GAME_STATE.mode = "menu"
        elseif key == "space" and GAME_STATE.levelCompleted then
            advanceToNextLevel()
        elseif key == "r" then
            -- Reintentar el nivel actual (sin avanzar). Útil si querés
            -- practicar un nivel específico.
            reloadCurrentLevel()
        end
    elseif GAME_STATE.mode == "failed" then
        if key == "escape" then
            -- Abortar el countdown y volver al menú.
            GAME_STATE.mode = "menu"
        end
    elseif GAME_STATE.mode == "all_done" then
        if key == "escape" or key == "return" or key == "space" then
            resetProgression()
            GAME_STATE.mode = "menu"
        end
    end
end
