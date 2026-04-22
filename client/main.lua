-- client/main.lua
-- Punto de entrada del cliente - Jumble
-- Modo single-player con física local para testing

-- Permite `require("sock")`, `require("bitser")` sin prefijo libs.
-- Los patrones resuelven libs/<name>.lua y libs/<name>/<name>.lua.
package.path = package.path .. ";libs/?.lua;libs/?/?.lua"

local GameConfig = require("common.config.GameConfig")
local Logger = require("common.utils.Logger")

-- Estado global (inicializado en nil, configurado en love.load)
GAME_STATE = nil
physicsWorld = nil
groundBody = nil
groundShape = nil
groundFixture = nil

-- Colores de jugadores
PLAYER_COLORS = {
    {1, 0.3, 0.3},   -- Rojo
    {0.3, 1, 0.3},   -- Verde
    {0.3, 0.3, 1},   -- Azul
    {1, 1, 0.3},      -- Amarillo
    {1, 0.3, 1},      -- Magenta
    {0.3, 1, 1},     -- Cyan
    {1, 0.5, 0.3},    -- Naranja
    {0.5, 0.3, 1}     -- Púrpura
}

function love.load()
    Logger:info("JUMBLE", "Inicializando cliente...")
    
    -- Inicializar estado global
    GAME_STATE = {
        mode = "menu",
        menuSelection = 1,
        players = {},
        localPlayerId = 1,
        gameTime = 0
    }
    
    -- Inicializar mundos
    initPhysics()
    
    -- Inicializar input
    _G.inputManager = require("client.network.InputManager"):new()
    
    Logger:info("JUMBLE", "Cliente listo")
end

function initPhysics()
    -- Crear mundo de física
    _G.physicsWorld = love.physics.newWorld(0, GameConfig.GRAVITY, true)
    
    -- Suelo
    _G.groundBody = physicsWorld:newBody(0, GameConfig.WORLD_HEIGHT - 20)
    _G.groundShape = physicsWorld:newRectangleShape(0, 0, GameConfig.WORLD_WIDTH, 40)
    _G.groundFixture = physicsWorld:newFixture(groundBody, groundShape, 1)
    groundBody:setFixedRotation(true)
    
    -- Paretes
    local leftWall = physicsWorld:newBody(-20, GameConfig.WORLD_HEIGHT/2)
    local leftShape = physicsWorld:newRectangleShape(0, 0, 40, GameConfig.WORLD_HEIGHT)
    physicsWorld:newFixture(leftWall, leftShape, 1)
    
    local rightWall = physicsWorld:newBody(GameConfig.WORLD_WIDTH + 20, GameConfig.WORLD_HEIGHT/2)
    local rightShape = physicsWorld:newRectangleShape(0, 0, 40, GameConfig.WORLD_HEIGHT)
    physicsWorld:newFixture(rightWall, rightShape, 1)
    
    -- Inicializar jugadores locales
    initLocalPlayer()
end

function initLocalPlayer()
    -- Crear jugador local con física
    local player = {
        id = 1,
        name = "Jugador 1",
        x = GameConfig.WORLD_WIDTH / 2,
        y = GameConfig.WORLD_HEIGHT - 100,
        vx = 0,
        vy = 0,
        width = GameConfig.PLAYER_WIDTH,
        height = GameConfig.PLAYER_HEIGHT,
        isGrounded = false,
        color = PLAYER_COLORS[1],
        canJump = true,
        body = nil
    }
    
    -- Crear body de física para el jugador
    player.body = physicsWorld:newBody(player.x, player.y, "dynamic")
    player.shape = physicsWorld:newRectangleShape(0, 0, player.width, player.height)
    player.fixture = physicsWorld:newFixture(player.body, player.shape, 1)
    player.body:setFixedRotation(true)
    player.body:setLinearDamping(10)
    
    GAME_STATE.players[1] = player
    
    Logger:info("JUMBLE", "Jugador inicializado en (" .. player.x .. ", " .. player.y .. ")")
end

function love.update(dt)
    GAME_STATE.gameTime = GAME_STATE.gameTime + dt
    
    if GAME_STATE.mode == "menu" then
        return
    end
    
    if GAME_STATE.mode == "playing" then
        -- Actualizar input
        inputManager:update(dt)
        
        -- Actualizar física
        physicsWorld:update(dt)
        
        -- Actualizar jugadores
        updateLocalPlayer(dt)
    end
end

function updateLocalPlayer(dt)
    local player = GAME_STATE.players[1]
    if not player then return end
    
    -- Obtener input
    local input = inputManager:getInput()
    
    -- Aplicar movimiento horizontal
    local moveForce = GameConfig.PLAYER_SPEED * 50 -- Force para Box2D
    player.body:applyForceToCenter(input.x * moveForce, 0, true)
    
    -- Saltar
    if inputManager.inputState.jump and player.isGrounded then
        player.body:applyLinearImpulse(0, -GameConfig.JUMP_FORCE * player.body:getMass())
        player.isGrounded = false
    end
    
    -- Verificar si está en el suelo
    checkGrounded(player)
    
    -- Sincronizar posición del body a la entidad
    player.x = player.body:getX()
    player.y = player.body:getY()
    local vx, vy = player.body:getLinearVelocity()
    player.vx = vx
    player.vy = vy
end

function checkGrounded(player)
    -- Verificar colisión simple con el suelo
    player.isGrounded = false
    
    local y = player.body:getY()
    local groundY = GameConfig.WORLD_HEIGHT - 20 - 20 -- ground position - half height
    
    if y >= groundY - 5 then
        player.isGrounded = true
        player.body:setY(groundY)
        player.body:setLinearVelocity(0, 0)
    end
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    
    if GAME_STATE.mode == "menu" then
        drawMenu()
    elseif GAME_STATE.mode == "playing" then
        drawGame()
    end
end

function drawMenu()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(48)
    love.graphics.printf("JUMBLE", 0, h * 0.25, w, "center")
    
    love.graphics.setNewFont(16)
    love.graphics.printf("Un juego cooperativo para 2-32 jugadores", 0, h * 0.32, w, "center")
    
    local options = {"JUGAR", "Salir"}
    local startY = h * 0.45
    
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
    love.graphics.printf("WASD/Flechas para navegar | ESPACIO para seleccionar", 0, h * 0.7, w, "center")
end

function drawGame()
    local w, h = love.graphics.getWidth()
    local worldH = GameConfig.WORLD_HEIGHT
    
    -- Dibujar suelo
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 0, worldH - 20, GameConfig.WORLD_WIDTH, 40)
    
    -- Dibujar paredes
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("fill", 0, 0, 20, worldH)
    love.graphics.rectangle("fill", GameConfig.WORLD_WIDTH - 20, 0, 20, worldH)
    
    -- Dibujar jugadores
    for id, player in pairs(GAME_STATE.players) do
        local color = player.color or PLAYER_COLORS[id]
        love.graphics.setColor(color[1], color[2], color[3])
        
        local x = player.x or GameConfig.WORLD_WIDTH/2
        local y = player.y or worldH - 100
        local size = player.width or GameConfig.PLAYER_WIDTH
        
        love.graphics.rectangle("fill", x - size/2, y - size/2, size, size)
        
        -- Borde según si está en suelo
        if player.isGrounded then
            love.graphics.setColor(0.3, 1, 0.3)
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x - size/2, y - size/2, size, size)
        
        -- Nombre
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(12)
        love.graphics.printf(player.name or "P" .. id, x - size/2, y - size/2 - 18, size, "center")
    end
    
    -- Info
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.setNewFont(14)
    love.graphics.print("JUMBLE - Modo Prueba", 10, 10)
    love.graphics.print("Jugadores: " .. #GAME_STATE.players, 10, 30)
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("WASD - Mover | ESPACIO - Saltar | ESC - Menú", 10, worldH - 30)
end

function love.keypressed(key)
    if GAME_STATE.mode == "menu" then
        if key == "up" or key == "w" or key == "left" then
            GAME_STATE.menuSelection = 1
        elseif key == "down" or key == "s" or key == "right" then
            GAME_STATE.menuSelection = 2
        elseif key == "return" or key == "space" or key == "down" or key == "s" then
            if GAME_STATE.menuSelection == 1 then
                GAME_STATE.mode = "playing"
            else
                love.event.quit()
            end
        end
    elseif GAME_STATE.mode == "playing" then
        if key == "escape" then
            GAME_STATE.mode = "menu"
        end
    end
end