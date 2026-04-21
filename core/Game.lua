-- core/Game.lua
-- Facade de los submódulos de core. Pura referencia: requerirlo NO
-- instala handlers globales `love.*`. Los entry points (client/main.lua,
-- server/main.lua, main.lua) siguen siendo los dueños de sus callbacks.
--
-- Histórico: esta versión usada a instalar love.load/update/draw/quit/run
-- como side-effect del require. Eso sombreaba los callbacks declarados en
-- los entry points y volvía el módulo un footgun. Ver issue #7.

local Game = {}

Game.config    = require("core.conf")
Game.callbacks = require("core.callbacks")
Game.input     = require("core.input")
Game.graphics  = require("core.graphics")
Game.audio     = require("core.audio")
Game.physics   = require("core.physics")
Game.window    = require("core.window")

Game.state  = "menu"
Game.paused = false

return Game
