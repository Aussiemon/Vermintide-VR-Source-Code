-- chunkname: @script/lua/game_states/state_quit.lua

class("StateQuit")

StateQuit.on_enter = function (self, params)
	self._params = params
	Game.quit = true
end

StateQuit.update = function (self, dt, t)
	return
end

StateQuit.on_exit = function (self)
	return
end

StateQuit.destroy = function (self)
	return
end
