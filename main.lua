-- main.lua
-- Jumble - Juego de plataformas (FIXED)
-- Arquitectura: Single-threaded game loop con Box2D para física determinista

-- ============================================================================
-- CONFIGURACIÓN GLOBAL
-- ============================================================================

local CONFIG = {
    WINDOW_WIDTH = 800,
    WINDOW_HEIGHT = 600,
    GRAVITY = 980,
    PLAYER_SIZE = 32,
    PLAYER_SPEED = 300,
    PLAYER_JUMP_POWER = 500,
    GROUND_THRESHOLD = 5  -- píxeles para detectar ground
}

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================

function love.load()
    print("[JUMBLE] Inicializando...")
    
    -- Estado del juego
    gameState = {
        mode = "menu",  -- menu, playing, completed
        currentLevel = 1,
        debugMode = false
    }
    
    -- Física - Sistema Box2D determinista
    world = createPhysicsWorld()
    
    -- Jugador - Entity con componentes
    player = createPlayer()
    
    -- Niveles
    levels = {
        createLevel1(),
        createLevel2()
    }
    
    -- Nivel actual
    currentLevelData = levels[1]
    loadLevel(currentLevelData)
    
    print("[JUMBLE] ✓ Listo")
end

function createPhysicsWorld()
    local w = love.physics.newWorld(0, CONFIG.GRAVITY, true)
    w:setSleepingAllowed(false)  -- Física más consistente
    return w
end

function createPlayer()
    return {
        x = 50,
        y = 0,  -- Se calculará basado en el nivel
        vx = 0,
        vy = 0,
        width = 32,
        height = 32,
        isGrounded = false,
        canJump = true,
        body = nil,
        fixture = nil,
        color = {0.2, 1, 0.2}
    }
end

-- ============================================================================
-- NIVELES
-- ============================================================================

function createLevel1()
    return {
        name = "Nivel 1",
        playerSpawn = {x = 50, y = 500},
        platforms = {
            {x = 30, y = 530, w = 150, h = 30, color = {0.8, 0.4, 0.2}},      -- Inicio
            {x = 220, y = 480, w = 120, h = 30, color = {0.8, 0.4, 0.2}},     -- Plat 2
            {x = 370, y = 430, w = 120, h = 30, color = {0.8, 0.4, 0.2}},     -- Plat 3
            {x = 520, y = 380, w = 120, h = 30, color = {0.8, 0.4, 0.2}},     -- Plat 4
            {x = 650, y = 320, w = 150, h = 30, color = {0.8, 0.4, 0.2}}      -- Final
        },
        goal = {x = 720, y = 280, w = 60, h = 60}
    }
end

function createLevel2()
    return {
        name = "Nivel 2: Desafío",
        playerSpawn = {x = 50, y = 500},
        platforms = {
            {x = 30, y = 550, w = 100, h = 30, color = {0.8, 0.4, 0.2}},
            {x = 160, y = 500, w = 100, h = 30, color = {0.8, 0.4, 0.2}},
            {x = 290, y = 420, w = 100, h = 30, color = {0.8, 0.4, 0.2}},
            {x = 420, y = 480, w = 100, h = 30, color = {0.8, 0.4, 0.2}},
            {x = 550, y = 380, w = 100, h = 30, color = {0.8, 0.4, 0.2}},
            {x = 680, y = 300, w = 120, h = 30, color = {0.8, 0.4, 0.2}}
        },
        goal = {x = 740, y = 260, w = 60, h = 60}
    }
end

function loadLevel(levelData)
    print(string.format("[JUMBLE] Cargando: %s", levelData.name))
    
    -- Destruir mundo anterior
    if world then
        world:destroy()
    end
    world = createPhysicsWorld()
    
    -- Reset player
    player.x = levelData.playerSpawn.x
    player.y = levelData.playerSpawn.y
    player.isGrounded = false
    player.canJump = false
    
    -- Crear body del jugador
    player.body = love.physics.newBody(world, player.x + player.width/2, player.y + player.height/2, "dynamic")
    local playerShape = love.physics.newRectangleShape(0, 0, player.width, player.height)
    player.fixture = love.physics.newFixture(player.body, playerShape, 1)
    player.fixture:setRestitution(0)
    player.body:setFixedRotation(true)
    player.body:setLinearDamping(0)
    
    -- Crear plataformas
    levelData.platformBodies = {}
    for i, platform in ipairs(levelData.platforms) do
        local body = love.physics.newBody(world, platform.x + platform.w/2, platform.y + platform.h/2, "static")
        local shape = love.physics.newRectangleShape(0, 0, platform.w, platform.h)
        love.physics.newFixture(body, shape, 1)
        table.insert(levelData.platformBodies, body)
    end
    
    currentLevelData = levelData
    gameState.goalCollected = false
end

-- ============================================================================
-- UPDATE (Lógica de juego)
-- ============================================================================

function love.update(dt)
    -- Limitar deltatime para estabilidad
    dt = math.min(dt, 1/30)
    
    if gameState.mode == "playing" then
        updatePlayer(dt)
        world:update(dt)
        checkCollisions()
        checkGoal()
    end
end

function updatePlayer(dt)
    local vx, vy = player.body:getLinearVelocity()
    
    -- Input horizontal
    local targetVx = 0
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        targetVx = -CONFIG.PLAYER_SPEED
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        targetVx = CONFIG.PLAYER_SPEED
    end
    
    -- Aplicar velocidad X directamente (más responsivo)
    player.body:setLinearVelocity(targetVx, vy)
    
    -- Saltar
    if (love.keyboard.isDown("space") or love.keyboard.isDown("w") or love.keyboard.isDown("up")) and player.isGrounded then
        player.body:applyLinearImpulse(0, -CONFIG.PLAYER_JUMP_POWER, player.body:getWorldCenter())
        player.isGrounded = false
        player.canJump = false
    end
    
    -- Sincronizar posición visual
    player.x = player.body:getX() - player.width/2
    player.y = player.body:getY() - player.height/2
    
    -- Caer fuera del mapa = reset
    if player.y > 700 then
        loadLevel(currentLevelData)
    end
end

function checkCollisions()
    -- Detectar si está en el suelo usando raycasts
    player.isGrounded = false
    
    -- Punto de raycast: pie del jugador
    local rayX = player.body:getX()
    local rayY = player.body:getY() + player.height/2 + CONFIG.GROUND_THRESHOLD
    
    -- Raycast hacia abajo
    local hit = world:rayCast(rayX, rayY - 5, rayX, rayY + 2, function(fixture, x, y, xn, yn, fraction)
        if fixture:getBody() ~= player.body then
            player.isGrounded = true
            return 0
        end
        return 1
    end)
end

function checkGoal()
    if gameState.goalCollected then return end
    
    local goal = currentLevelData.goal
    local goalCenterX = goal.x + goal.w/2
    local goalCenterY = goal.y + goal.h/2
    
    local dx = player.body:getX() - goalCenterX
    local dy = player.body:getY() - goalCenterY
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist < 40 then
        gameState.goalCollected = true
        print("[JUMBLE] ¡Nivel completado!")
    end
end

-- ============================================================================
-- DRAW (Renderizado)
-- ============================================================================

function love.draw()
    love.graphics.clear(0.08, 0.08, 0.1)
    
    if gameState.mode == "menu" then
        drawMenu()
    elseif gameState.mode == "playing" then
        drawGame()
    end
end

function drawMenu()
    local w, h = CONFIG.WINDOW_WIDTH, CONFIG.WINDOW_HEIGHT
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("JUMBLE", w/2 - 50, h/4 - 20)
    
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Juego de Plataformas", w/2 - 80, h/4 + 30)
    
    love.graphics.setColor(0.3, 1, 0.3)
    love.graphics.print("> JUGAR <", w/2 - 50, h/2)
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Presiona ESPACIO", w/2 - 70, h * 0.7)
end

function drawGame()
    -- Plataformas
    for _, platform in ipairs(currentLevelData.platforms) do
        love.graphics.setColor(platform.color[1], platform.color[2], platform.color[3])
        love.graphics.rectangle("fill", platform.x, platform.y, platform.w, platform.h)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", platform.x, platform.y, platform.w, platform.h)
    end
    
    -- Meta (Goal)
    local goal = currentLevelData.goal
    if gameState.goalCollected then
        love.graphics.setColor(0.3, 1, 0.3)
    else
        love.graphics.setColor(1, 1, 0)
    end
    love.graphics.rectangle("fill", goal.x, goal.y, goal.w, goal.h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", goal.x, goal.y, goal.w, goal.h)
    
    -- Jugador
    love.graphics.setColor(player.color[1], player.color[2], player.color[3])
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", player.x, player.y, player.width, player.height)
    
    -- HUD
    love.graphics.setColor(0.3, 1, 0.3)
    love.graphics.print(currentLevelData.name, 10, 10)
    love.graphics.print("WASD/Flechas - Mover  |  ESPACIO - Saltar  |  ESC - Menu", 10, 30)
    
    if player.isGrounded then
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.print("En el suelo", 10, 50)
    else
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.print("En el aire", 10, 50)
    end
    
    -- Objetivo completado
    if gameState.goalCollected then
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("¡COMPLETADO! Presiona ENTER para siguiente nivel", 150, 300)
    end
end

-- ============================================================================
-- INPUT
-- ============================================================================

function love.keypressed(key)
    if gameState.mode == "menu" then
        if key == "space" or key == "return" then
            gameState.mode = "playing"
        end
    elseif gameState.mode == "playing" then
        if key == "escape" then
            gameState.mode = "menu"
        end
        
        if key == "return" and gameState.goalCollected then
            if gameState.currentLevel < #levels then
                gameState.currentLevel = gameState.currentLevel + 1
                loadLevel(levels[gameState.currentLevel])
                gameState.mode = "playing"
            else
                gameState.mode = "menu"
                gameState.currentLevel = 1
            end
        end
        
        -- Debug
        if key == "f1" then
            gameState.debugMode = not gameState.debugMode
        end
    end
end

-- ============================================================================
-- CONF (Configuración de LÖVE)
-- ============================================================================

function love.conf(t)
    t.version = "11.5"
    t.window.width = CONFIG.WINDOW_WIDTH
    t.window.height = CONFIG.WINDOW_HEIGHT
    t.window.title = "JUMBLE"
    t.modules.font = true
    t.modules.physics = true
end