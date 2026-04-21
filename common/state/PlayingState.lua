-- common/state/PlayingState.lua
-- Estado de juego en progreso con lógica completa

local PlayingState = {}
PlayingState.__index = PlayingState

local Logger = require("common.utils.Logger")
local GameConfig = require("common.config.GameConfig")
local LevelConfig = require("common.config.LevelConfig")
local Player = require("common.entities.Player")

function PlayingState:new()
    local self = setmetatable({}, PlayingState)
    self.gameTime = 0
    self.client = nil
    self.inputManager = nil
    self.renderer = nil
    self.physicsWorld = nil
    self.paused = false
    
    -- Jugador local
    self.localPlayer = nil
    self.localPlayerId = 1
    self.players = {}
    
    -- Plataformas (mundo)
    self.platforms = {}
    
    -- Coyote time para jump mejorado
    self.coyoteCounter = 0
    self.coyoteTime = 0.1  -- 6 frames @ 60fps
    
    -- Input buffering
    self.jumpBuffer = false
    self.jumpBufferTime = 0.05  -- 3 frames
    
    -- Sistema de niveles
    self.levelManager = nil
    self.currentLevel = nil
    self.levelCompletionTime = nil
    self.levelTimeRemaining = 0
    self.showLevelInfo = true
    
    return self
end

function PlayingState:enter()
    Logger:info("PLAYING", "Entrando al estado de juego")
    
    -- Obtener referencias
    self.client = _G.client
    self.inputManager = _G.inputManager
    self.renderer = _G.renderer
    self.physicsWorld = _G.physicsWorld
    self.levelManager = _G.levelManager
    
    if not self.client or not self.client:isConnected() then
        Logger:warn("PLAYING", "Cliente no conectado, volviendo a menu")
        return "menu"
    end
    
    if not self.physicsWorld then
        Logger:error("PLAYING", "Physics world no inicializado")
        return "menu"
    end
    
    -- Obtener nivel actual si levelManager existe
    if self.levelManager then
        self.currentLevel = self.levelManager:getCurrentLevel()
        if self.currentLevel then
            Logger:info("PLAYING", "Nivel cargado: " .. self.currentLevel.name)
        end
    end
    
    -- Crear jugador local
    self:initializeLocalPlayer()
    
    -- Crear plataformas (desde nivel o por defecto)
    self:createPlatforms()
    
    self.gameTime = 0
    self.paused = false
    self.showLevelInfo = true
    
    Logger:info("PLAYING", "✓ Juego iniciado")
end

function PlayingState:initializeLocalPlayer()
    -- Obtener posición de spawn del nivel o usar por defecto
    local spawnX, spawnY = GameConfig.WORLD_WIDTH / 2, GameConfig.WORLD_HEIGHT - 100
    
    if self.currentLevel then
        spawnX, spawnY = self.currentLevel:getSpawnPoint()
    end
    
    -- Crear jugador con física
    self.localPlayer = Player:new(self.localPlayerId, "Jugador 1", spawnX, spawnY)
    
    -- Crear body Box2D
    self.localPlayer.body = self.physicsWorld:newBody(
        self.localPlayer.position.x,
        self.localPlayer.position.y,
        "dynamic"
    )
    
    -- Shape rectangular
    self.localPlayer.shape = self.physicsWorld:newRectangleShape(
        0, 0, 
        self.localPlayer.width, 
        self.localPlayer.height
    )
    
    self.localPlayer.fixture = self.physicsWorld:newFixture(
        self.localPlayer.body, 
        self.localPlayer.shape, 
        1
    )
    
    -- Propiedades
    self.localPlayer.body:setFixedRotation(true)
    self.localPlayer.body:setLinearDamping(5)
    
    -- Color específico
    self.localPlayer.color = {0.2, 1, 0.2}  -- Verde
    
    -- Agregar al renderer
    if self.renderer then
        self.renderer:addPlayer(self.localPlayerId, self.localPlayer)
    end
    
    self.players[self.localPlayerId] = self.localPlayer
    
    Logger:debug("PLAYING", "Jugador local creado en (" .. 
                self.localPlayer.position.x .. ", " .. self.localPlayer.position.y .. ")")
end

function PlayingState:createPlatforms()
    self.platforms = {}
    
    -- Cargar plataformas del nivel
    if self.currentLevel then
        for _, platform in ipairs(self.currentLevel:getPlatforms()) do
            self:addPlatform({
                x = platform.x,
                y = platform.y,
                w = platform.width,
                h = platform.height
            })
        end
    else
        -- Plataformas por defecto si no hay nivel
        local p1 = {x = 100, y = GameConfig.WORLD_HEIGHT - 50, w = 400, h = 30}
        self:addPlatform(p1)
        
        local p2 = {x = 550, y = GameConfig.WORLD_HEIGHT - 150, w = 150, h = 30}
        self:addPlatform(p2)
        
        local p3 = {x = 850, y = GameConfig.WORLD_HEIGHT - 250, w = 150, h = 30}
        self:addPlatform(p3)
        
        local p4 = {x = 1200, y = GameConfig.WORLD_HEIGHT - 350, w = 200, h = 30}
        self:addPlatform(p4)
        
        local ground = {x = 0, y = GameConfig.WORLD_HEIGHT - 20, w = GameConfig.WORLD_WIDTH, h = 20}
        self:addPlatform(ground)
    end
    
    -- Pasar plataformas al renderer
    if self.renderer then
        self.renderer:addPlatforms(self.platforms)
    end
    
    Logger:debug("PLAYING", "✓ Creadas " .. #self.platforms .. " plataformas")
end

function PlayingState:addPlatform(platformDef)
    local body = self.physicsWorld:newBody(
        platformDef.x + platformDef.w / 2,
        platformDef.y + platformDef.h / 2,
        "static"
    )
    
    local shape = self.physicsWorld:newRectangleShape(0, 0, platformDef.w, platformDef.h)
    self.physicsWorld:newFixture(body, shape, 1)
    
    table.insert(self.platforms, {
        body = body,
        x = platformDef.x,
        y = platformDef.y,
        w = platformDef.w,
        h = platformDef.h,
        color = {0.6, 0.4, 0.2}
    })
end

function PlayingState:update(dt)
    self.gameTime = self.gameTime + dt
    
    -- Actualizar tiempo de nivel
    if self.levelManager and self.currentLevel then
        self.levelTimeRemaining = self.currentLevel.time_limit - self.levelManager:getElapsedTime()
        
        -- Verificar si completó el nivel
        if not self.levelCompletionTime and self.levelManager:checkLevelCompletion(self.localPlayer) then
            self.levelCompletionTime = self.levelManager:getPlayerCompletionTime(self.localPlayerId)
            Logger:info("LEVEL", "¡Nivel completado en " .. self.levelCompletionTime .. " segundos!")
            self.paused = true
        end
        
        -- Verificar si se agotó el tiempo
        if self.levelTimeRemaining <= 0 then
            Logger:info("LEVEL", "¡Se agotó el tiempo!")
            self:resetLevel()
        end
    end
    
    if not self.paused then
        -- Procesar input local
        if self.inputManager then
            self.inputManager:update(dt)
            local input = self.inputManager:getInput()
            
            if self.localPlayer and self.localPlayer.body then
                -- Movimiento horizontal
                if input.x ~= 0 then
                    self.localPlayer.body:setLinearVelocity(input.x * GameConfig.PLAYER_SPEED, 
                                                           self.localPlayer.body:getLinearVelocity())
                else
                    -- Friction cuando no se presiona tecla
                    local vx, vy = self.localPlayer.body:getLinearVelocity()
                    self.localPlayer.body:setLinearVelocity(vx * 0.9, vy)
                end
                
                -- Salto con coyote time
                if self.inputManager.inputState.jump then
                    if self:canJump() then
                        self.localPlayer.body:applyLinearImpulse(0, -GameConfig.JUMP_FORCE)
                        self.coyoteCounter = 0
                    end
                end
            end
        end
        
        -- Actualizar posición desde physics
        if self.localPlayer and self.localPlayer.body then
            local px, py = self.localPlayer.body:getPosition()
            self.localPlayer.position.x = px
            self.localPlayer.position.y = py
        end
        
        -- Detectar si está en el suelo
        self:updateGroundedState()
        
        -- Actualizar renderer
        if self.renderer then
            self.renderer:update(dt)
        end
        
        -- Procesar red
        if self.client then
            self.client:update(dt)
        end
        
        -- Validar posición (fuera del mapa = reset)
        if self.localPlayer and self.localPlayer.position.y > GameConfig.WORLD_HEIGHT + 100 then
            Logger:info("PLAYING", "Jugador cayó, reaparición")
            self.localPlayer.body:setPosition(GameConfig.WORLD_WIDTH / 2, 100)
            self.localPlayer.body:setLinearVelocity(0, 0)
        end
    end
end

function PlayingState:canJump()
    return self.localPlayer.isGrounded or self.coyoteCounter < self.coyoteTime
end

function PlayingState:updateGroundedState()
    if not self.localPlayer or not self.localPlayer.body then return end
    
    self.localPlayer.isGrounded = false
    
    -- Raycast hacia abajo desde los pies del jugador
    local px, py = self.localPlayer.body:getPosition()
    local rayX = px
    local rayY = py + self.localPlayer.height / 2 + 2
    
    local hit = self.physicsWorld:rayCast(rayX, rayY - 5, rayX, rayY + 2, function(fixture, x, y, xn, yn, fraction)
        if fixture:getBody() ~= self.localPlayer.body then
            self.localPlayer.isGrounded = true
            self.coyoteCounter = 0
            return 0
        end
        return 1
    end)
    
    -- Actualizar coyote counter
    if not self.localPlayer.isGrounded then
        self.coyoteCounter = self.coyoteCounter + (1/60)  -- Asumir 60fps
    end
end

function PlayingState:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Fondo
    love.graphics.setColor(0.3, 0.4, 0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Renderizar desde renderer
    if self.renderer then
        self.renderer:draw()
    else
        -- Fallback
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("Esperando renderer...", 0, h/2, w, "center")
    end
    
    -- HUD - Información del nivel
    if self.currentLevel then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Nivel " .. self.currentLevel.id .. ": " .. self.currentLevel.name, 10, 10, w - 20, "left")
        
        -- Mostrar tiempo restante
        local timeColor = {0.2, 1, 0.2}
        if self.levelTimeRemaining < 30 then
            timeColor = {1, 0.2, 0.2}
        end
        love.graphics.setColor(timeColor[1], timeColor[2], timeColor[3])
        love.graphics.printf("Tiempo: " .. math.ceil(self.levelTimeRemaining) .. "s", 10, 35, w - 20, "left")
        
        -- Meta
        local goalX, goalY = self.currentLevel:getGoalPoint()
        love.graphics.setColor(1, 1, 0.2, 0.6)
        love.graphics.circle("fill", goalX, goalY, 32)
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("line", goalX, goalY, 32)
    end
    
    -- Pause overlay
    if self.paused then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, w, h)
        
        if self.levelCompletionTime then
            love.graphics.setColor(0.2, 1, 0.2)
            love.graphics.printf("¡NIVEL COMPLETADO!", 0, h/2 - 60, w, "center")
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("Tiempo: " .. self.levelCompletionTime .. "s", 0, h/2 - 20, w, "center")
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("PAUSADO", 0, h/2 - 20, w, "center")
        end
        
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("P para reanudar | ESC para menú", 0, h/2 + 20, w, "center")
    end
end

function PlayingState:handleInput(key, scancode, isrepeat)
    if key == "escape" then
        Logger:info("PLAYING", "Retornando al menú")
        return "menu"
    elseif key == "p" then
        self.paused = not self.paused
        Logger:info("PLAYING", self.paused and "PAUSADO" or "REANUDADO")
    elseif key == "r" and self.paused and self.levelCompletionTime then
        -- R para reintentar nivel después de completarlo
        Logger:info("PLAYING", "Reiniciando nivel")
        return "playing"
    elseif key == "n" and self.paused and self.levelCompletionTime then
        -- N para siguiente nivel
        if self.levelManager then
            if self.levelManager:loadNextLevel() then
                Logger:info("PLAYING", "Cargando siguiente nivel")
                return "playing"
            else
                Logger:info("PLAYING", "¡Todos los niveles completados!")
                return "menu"
            end
        end
    end
end

function PlayingState:resetLevel()
    -- Reiniciar el nivel
    if self.localPlayer then
        if self.currentLevel then
            local spawnX, spawnY = self.currentLevel:getSpawnPoint()
            self.localPlayer.body:setPosition(spawnX, spawnY)
        else
            self.localPlayer.body:setPosition(GameConfig.WORLD_WIDTH / 2, 100)
        end
        self.localPlayer.body:setLinearVelocity(0, 0)
    end
    
    self.levelCompletionTime = nil
    self.paused = false
    Logger:info("PLAYING", "Nivel reiniciado")
end

function PlayingState:exit()
    Logger:info("PLAYING", "Saliendo del estado de juego")
end

return PlayingState
