-- chunkname: @script/lua/managers/game_mode/game_mode_manager.lua

class("GameModeManager")

local function debug_printf(...)
	if script_data.debug_scoring then
		printf(...)
	end
end

GameModeManager.init = function (self, world, level, level_name)
	self._world = world
	self._end_conditions_met = false
	self._start_conditions_met = false
	self._time_played = 0
	self._level = level
	self._level_name = level_name

	local level_settings = LevelSettings.levels[level_name]

	self._level_survival_time = tonumber(Game.startup_commands.survival_time) or level_settings.survival_time

	local network = Managers.lobby

	if network then
		self._network_mode = network.server and "server" or "client"

		if self._network_mode == "client" then
			Managers.state.network:register_rpc_callbacks(self, "rpc_server_end_conditions_met")
		end
	else
		self._network_mode = "local"
	end
end

GameModeManager.set_end_conditions_met = function (self, result)
	if self._network_mode == "client" then
		return
	end

	self:_set_end_conditions_met(result)
end

GameModeManager._set_end_conditions_met = function (self, result)
	self._end_conditions_met = true
	self._end_result = result

	if self._network_mode == "server" then
		local result_index = ScoreTypeLookup[result]

		Managers.state.network:send_rpc_clients("rpc_server_end_conditions_met", result_index)
		debug_printf("[server sent]: rpc_server_end_conditions_met %s", result)
	end

	if result == "victory" then
		Level.trigger_event(self._level, "game_mode_end_result_victory")
	elseif result == "defeat" then
		Level.trigger_event(self._level, "game_mode_end_result_defeat")
	else
		error("unknown end result", result)
	end

	local interactable_system = Managers.state.extension:system("interactable_system")

	interactable_system:disable_all_interactions()
end

GameModeManager.rpc_server_end_conditions_met = function (self, sender, result_index)
	local result = ScoreTypeLookup[result_index]

	self:_set_end_conditions_met(result)
	debug_printf("[client recieved]: rpc_server_end_conditions_met %s", result)
end

GameModeManager.end_conditions_met = function (self)
	return self._end_conditions_met, self._end_result
end

GameModeManager.set_start_conditions_met = function (self)
	self._start_conditions_met = true
end

GameModeManager.destroy = function (self)
	return
end

GameModeManager.update = function (self, dt, t)
	if self._network_mode == "client" then
		return
	end

	Profiler.start("GameModeManager")

	local start_conditions_met = self._start_conditions_met
	local end_conditions_met = self._end_conditions_met

	if start_conditions_met and not end_conditions_met then
		local time_played = self._time_played

		time_played = time_played + dt

		local survival_time = self._level_survival_time

		if survival_time and survival_time <= time_played then
			self:set_end_conditions_met("victory")
		end

		self._time_played = time_played
	end

	Profiler.stop("GameModeManager")
end
