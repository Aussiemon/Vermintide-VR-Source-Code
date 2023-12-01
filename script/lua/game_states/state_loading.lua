-- chunkname: @script/lua/game_states/state_loading.lua

require("script/lua/managers/network/network_manager")
require("settings/level_settings")
require("script/lua/flow_callbacks")
require("script/lua/views/how_to_play_view")
class("StateLoading")

local function verify_print(statement, message, ...)
	if not statement then
		message = "[StateLoading] " .. message

		Application.error(string.format(message, ...))
	end
end

local PACKAGES_TO_LOAD = {
	"resource_packages/gameplay"
}

StateLoading.on_enter = function (self, params)
	Network.log(Network.MESSAGES)

	self._params = params
	self._world = GLOBAL_WORLD
	self._wwise_world = Wwise.wwise_world(self._world)

	verify_print(params.next_state, "No state specified - defaulting to StateGameplay")
	self:_init_state_managers()
	self:_setup_input()

	self._disable_how_to_play = params.disable_how_to_play

	self:_load_packages()

	if not params.skip_loading_level then
		self._level = params.level or self:_spawn_level()

		Managers.transition:fade_out(1)

		local views = {
			how_to_play_view = "HowToPlayView"
		}

		Managers.state.view = ViewManager:new(self._world, self._vr_controller, self, views)
	end

	if params.leave_lobby and Managers.lobby then
		Managers.lobby:reset()
	end

	if params.exit_to_menu then
		self:_unload_level_package()
	else
		local join_ip, join_any = params.join_ip, params.join_any
		local join_by_steam_invite = params.join_by_steam_invite
		local join_by_lobby_data = params.join_by_lobby_data
		local joining = join_ip or join_any
		local level_name = params.level_name or params.leave_lobby and "inn" or not joining and LevelSettings.default_level
		local old_level_name = params.old_level_name

		if level_name then
			self:_load_level(level_name, old_level_name)
		end

		if Managers.lobby then
			self:_init_network(join_ip, join_any, params.join_by_lobby_data, params.join_by_steam_invite, params.permission_to_enter_game)
		end
	end
end

StateLoading._setup_input = function (self)
	self._vr_controller = Managers.vr:create_vr_controller(self._world)
end

StateLoading._init_state_managers = function (self)
	Managers.state.extension = ExtensionManager:new(self._world)

	self:_init_extension_systems()
end

StateLoading._init_extension_systems = function (self)
	local NO_PRE_UPDATE, NO_POST_UPDATE = false, false
	local ext_manager = Managers.state.extension

	ext_manager:add_system("wand_system", WandSystem, {
		"WandExtension",
		"WandHuskExtension"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("head_system", HeadSystem, {
		"HeadExtension",
		"HeadHuskExtension"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
end

StateLoading._spawn_level = function (self)
	self._loading_level_name = "levels/loading/loading"

	local level = ScriptWorld.load_level(self._world, self._loading_level_name)

	Level.spawn_background(level)
	Level.trigger_level_loaded(level)

	return level
end

StateLoading._unload_level_package = function (self)
	local package_manager = Managers.package
	local level_to_unload = self._params.old_level_name

	verify_print(level_to_unload, "No level to unload specified")

	local old_level_settings = LevelSettings.levels[level_to_unload]
	local package_to_unload = old_level_settings.package_name

	if package_manager:has_loaded(package_to_unload, "Level") then
		package_manager:unload(package_to_unload, "Level")
	end
end

StateLoading._load_packages = function (self)
	local package_manager = Managers.package

	for _, package_name in pairs(PACKAGES_TO_LOAD) do
		if not package_manager:has_loaded(package_name, "Gameplay") then
			package_manager:load(package_name, "Gameplay", nil, true)
		end
	end
end

StateLoading._packages_loaded = function (self)
	local package_manager = Managers.package

	for _, package_name in pairs(PACKAGES_TO_LOAD) do
		if not package_manager:has_loaded(package_name, "Gameplay") then
			return false
		end
	end

	if not self._level_package_name or not package_manager:has_loaded(self._level_package_name, "Level") then
		return false
	end

	return true
end

StateLoading._load_level = function (self, level_name, old_level_name)
	local level_settings = LevelSettings.levels[level_name]

	self._level_name = level_name

	local package_name = level_settings.package_name
	local level_name = level_settings.level_name

	self._level_package_name = package_name

	local package_to_unload

	if old_level_name then
		local old_level_settings = LevelSettings.levels[old_level_name]

		package_to_unload = old_level_settings.package_name
	end

	local package_manager = Managers.package

	if not package_to_unload then
		package_manager:load(package_name, "Level", nil, true)
	elseif package_to_unload ~= package_name then
		package_manager:unload(package_to_unload, "Level")
		package_manager:load(package_name, "Level", nil, true)
	end
end

StateLoading._init_network = function (self, join_ip, join_any, join_lobby_by_data, join_by_steam_invite, already_got_permission_to_enter_game)
	print("StateLoading:_init_network", join_ip, join_any, join_by_steam_invite, already_got_permission_to_enter_game)

	local lobby_manager = Managers.lobby

	self._searching_for_lobby = false

	if Managers.lobby.lobby then
		print("Managers.lobby.lobby", Managers.lobby.server, already_got_permission_to_enter_game)

		self._permission_to_enter_game = Managers.lobby.server or already_got_permission_to_enter_game or false
	elseif join_ip then
		lobby_manager:join_lobby_by_ip(join_ip)

		self._permission_to_enter_game = false
		self._joining = true
	elseif join_any then
		self._searching_for_lobby = true

		lobby_manager:refresh_lobby_browser()

		self._timeout = Managers.time:time("main") + 5
		self._permission_to_enter_game = false
		self._joining = true
	elseif join_by_steam_invite then
		Managers.invite:poll_invite()
		Managers.invite:join_last_invite()

		self._permission_to_enter_game = false
		self._join_game_timer = 0
		self._joining = true
	elseif join_lobby_by_data then
		Managers.lobby:join_lobby_by_lobby_id(join_lobby_by_data.id)

		self._permission_to_enter_game = false
		self._join_game_timer = 0
		self._join_lobby_id = join_lobby_by_data.id
		self._joining = true
	else
		local NO_CHAT = true

		lobby_manager:create_lobby(nil, 2, NO_CHAT)
		lobby_manager:set_server(true)

		self._permission_to_enter_game = true
		self._joining = false
	end

	local network_manager = NetworkManager:new()

	if Managers.lobby.server then
		network_manager:register_rpc_callbacks(self, "rpc_notify_lobby_joined")
	else
		network_manager:register_rpc_callbacks(self, "rpc_permission_to_enter_game", "rpc_load_level")
	end

	Managers.state.network = network_manager
end

StateLoading._update_network = function (self, dt, t)
	local lobby_manager = Managers.lobby

	if not lobby_manager then
		return true
	end

	local network_manager = Managers.state.network

	network_manager:update_receive(dt, t)
	network_manager:update_transmit(dt, t)

	local join_game_timer = self._join_game_timer

	if join_game_timer then
		local join_game_timer = join_game_timer + dt
		local join_game_timeout = GameSettingsDevelopment.join_game_timeout
		local timed_out = join_game_timeout < join_game_timer

		if timed_out then
			if not self._join_game_timeout_popup_id then
				self._join_game_timeout_popup_id = Managers.popup:queue_popup("Join Game Timed Out", "Could not join host, returning to Inn")

				local lobby_id = self._join_lobby_id

				if lobby_id then
					Managers.lobby:blacklist_lobby(lobby_id)
				end
			end

			return false
		end

		self._join_game_timer = join_game_timer
	end

	local state = lobby_manager.state

	if state == LobbyState.JOINED then
		return self._permission_to_enter_game
	elseif self._joining and state == LobbyState.FAILED then
		self._join_failed_popup_id = Managers.popup:queue_popup("Join Failed", "Could not join host, returning to Inn")

		local lobby_id = self._join_lobby_id

		if lobby_id then
			Managers.lobby:blacklist_lobby(lobby_id)
		end

		return false
	elseif state == LobbyState.FAILED then
		self._create_lobby_failed_id = Managers.popup:queue_popup("Failed creating Lobby", "Lobby couldn't be created. There might be a problem with your network or Steam might be down. Quitting game...")

		return false
	elseif Network.fatal_error() then
		self._network_error_popup_id = Managers.popup:queue_popup("Network Error", "Network Fatal Error when joining, returning to Inn")

		local lobby_id = self._join_lobby_id

		if lobby_id then
			Managers.lobby:blacklist_lobby(lobby_id)
		end

		return false
	end

	return false
end

StateLoading._update_lobby_search = function (self, dt, t)
	local lobby_manager = Managers.lobby
	local lobbies = lobby_manager:lobby_browser_content()

	for _, data in ipairs(lobbies) do
		if data.valid then
			self._searching_for_lobby = false

			lobby_manager:join_lobby(data.lobby_num)

			return
		end
	end

	if not lobby_manager:is_refreshing_lobby_browser() or t > self._timeout then
		self._timeout = Managers.time:time("main") + 5

		lobby_manager:refresh_lobby_browser()
		print("lobby browser refresh")
	end
end

StateLoading._update_state_managers = function (self, dt, t)
	Managers.state.extension:update(dt, t)
end

StateLoading.update = function (self, dt)
	local pose = Managers.vr:hmd_world_pose().head
	local position = Matrix4x4.translation(pose)

	WwiseWorld.set_listener(self._wwise_world, Wwise.LISTENER_0, pose)

	local t = Managers.time:time("main")

	self._vr_controller:update(dt, t)
	self:_update_state_managers(dt, t)

	if Managers.state.view then
		Managers.state.view:update(dt, t)
	end

	local active_popup, next_state, params = self:update_popups(dt, t)

	if next_state then
		return next_state, params
	elseif active_popup then
		return
	end

	if not self._disable_how_to_play and not self._enabled_how_to_play then
		local leaving_lobby = self._params.leave_lobby

		if not leaving_lobby and Managers.lobby and #Managers.lobby:lobby_members() > 1 then
			Managers.state.view:enable_view("how_to_play_view", false)
		else
			Managers.state.view:enable_view("how_to_play_view", true, nil, self._level_name)
		end

		self._enabled_how_to_play = true
	end

	if self._params.exit_to_menu then
		return self._next_state, {
			level = self._level
		}
	else
		Managers.token:update(dt, t)

		if self._searching_for_lobby then
			self:_update_lobby_search(dt, t)
		end

		local network_done, error = self:_update_network(dt, t)

		if self:_packages_loaded() and network_done then
			if Managers.lobby and Managers.lobby.server and not Managers.state.view:view_enabled() and not self._permission_sent then
				for _, member in ipairs(Managers.lobby:lobby_members()) do
					if member ~= Network.peer_id() then
						RPC.rpc_permission_to_enter_game(member)
					end
				end

				self._permission_sent = true
			end

			if not self._fading and not Managers.state.view:view_enabled() then
				Managers.transition:fade_in(1, callback(self, "cb_fade_in_done"))

				self._fading = true
			end

			return self:_try_next_state()
		end
	end
end

StateLoading.update_popups = function (self, dt, t)
	Managers.popup:update(dt, t, self._vr_controller)

	local active_popup = true
	local network_error_popup_id = self._network_error_popup_id

	if network_error_popup_id then
		if Managers.popup:query_popup_done(network_error_popup_id) then
			self._network_error_popup_id = nil

			return active_popup, StateLoading, {
				leave_lobby = true,
				disable_how_to_play = true,
				next_state = StateGameplay,
				level_name = LevelSettings.default_level
			}
		else
			return active_popup
		end
	end

	local join_failed_popup_id = self._join_failed_popup_id

	if join_failed_popup_id then
		if Managers.popup:query_popup_done(join_failed_popup_id) then
			self._join_failed_popup_id = nil

			return active_popup, StateLoading, {
				leave_lobby = true,
				disable_how_to_play = true,
				next_state = StateGameplay,
				level_name = LevelSettings.default_level
			}
		else
			return active_popup
		end
	end

	local join_game_timeout_popup_id = self._join_game_timeout_popup_id

	if join_game_timeout_popup_id then
		if Managers.popup:query_popup_done(join_game_timeout_popup_id) then
			self._join_game_timeout_popup_id = nil

			return active_popup, StateLoading, {
				leave_lobby = true,
				disable_how_to_play = true,
				next_state = StateGameplay,
				level_name = LevelSettings.default_level
			}
		else
			return active_popup
		end
	end

	local unjoinable_level_joined_id = self._unjoinable_level_joined_id

	if unjoinable_level_joined_id then
		if Managers.popup:query_popup_done(unjoinable_level_joined_id) then
			self._unjoinable_level_joined_id = nil

			return active_popup, StateLoading, {
				leave_lobby = true,
				disable_how_to_play = true,
				next_state = StateGameplay,
				level_name = LevelSettings.default_level
			}
		else
			return active_popup
		end
	end

	local create_lobby_failed_id = self._create_lobby_failed_id

	if create_lobby_failed_id then
		if Managers.popup:query_popup_done(create_lobby_failed_id) then
			self._create_lobby_failed_id = nil

			return active_popup, StateQuit, {
				leave_lobby = true
			}
		else
			return active_popup
		end
	end

	return false
end

StateLoading.cb_fade_in_done = function (self)
	self._next_state = self._params.next_state or StateGameplay
end

StateLoading._try_next_state = function (self)
	if self._next_state then
		local params = {
			level_name = self._level_name
		}

		return self._next_state, params
	end
end

StateLoading.rpc_notify_lobby_joined = function (self, sender)
	RPC.rpc_load_level(sender, NetworkLookup.levels[self._level_name], false)
end

StateLoading.rpc_permission_to_enter_game = function (self, sender)
	print("got rpc permission_to_enter_game")

	self._permission_to_enter_game = true
end

StateLoading.rpc_load_level = function (self, sender, level_key, end_conditions_met)
	local old_level_name = self._params.old_level_name
	local level_name = NetworkLookup.levels[level_key]

	if level_name == "cart" then
		self._unjoinable_level_joined_id = Managers.popup:queue_popup("Join Failed", "The Level you're trying to join doesn't support multiplayer. Returning to Inn...")
	else
		self:_load_level(level_name, old_level_name)
	end

	self._permission_to_enter_game = false
end

StateLoading.on_exit = function (self, exit_params)
	Network.log(Network.SILENT)
	self._vr_controller:destroy()
	Managers.state:destroy()

	if self._level or self._loading_level_name then
		ScriptWorld.destroy_level(self._world, "levels/loading/loading")
		Managers.vr:set_tracking_space_unit(nil)
	end
end
