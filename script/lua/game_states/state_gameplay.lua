-- chunkname: @script/lua/game_states/state_gameplay.lua

require("foundation/script/util/script_world")
require("foundation/script/util/callback")
require("foundation/script/managers/event/event_manager")
require("script/lua/managers/extension/extension_manager")
require("script/lua/managers/spawn/spawn_manager")
require("script/lua/managers/score/score_manager")
require("script/lua/managers/game_mode/game_mode_manager")
require("script/lua/managers/hud/hud_manager")
require("script/lua/managers/debug/debug_manager")
require("script/lua/managers/extension/systems/ai/ai_system")
require("script/lua/managers/extension/systems/ai/ai_inventory_system")
require("script/lua/managers/extension/systems/ai/ai_slot_system")
require("script/lua/managers/extension/systems/ai/ai_navigation_system")
require("script/lua/managers/extension/systems/ai/nav_graph_system")
require("script/lua/managers/extension/systems/aggro_system")
require("script/lua/managers/extension/systems/spawner_system")
require("script/lua/managers/extension/systems/extension_system_base")
require("script/lua/managers/extension/systems/ragdoll_system")
require("script/lua/managers/extension/systems/interactable_system")
require("script/lua/managers/extension/systems/health_system")
require("script/lua/managers/extension/systems/locomotion/locomotion_system")
require("script/lua/managers/extension/systems/sound_environment_system")
require("script/lua/managers/extension/systems/wand_system")
require("script/lua/managers/extension/systems/head_system")
require("script/lua/managers/extension/systems/outlines/outline_system")
require("script/lua/unit_extensions/extension_particles")
require("script/lua/unit_extensions/staff_vector_field_extension")
require("script/lua/unit_extensions/bow_vector_field_extension")
require("script/lua/unit_extensions/staff_melee_extension")
require("script/lua/unit_extensions/health/health_extension")
require("script/lua/unit_extensions/health/door_health_extension")
require("script/lua/unit_extensions/wand/wand_extension")
require("script/lua/unit_extensions/wand/wand_husk_extension")
require("script/lua/unit_extensions/head/head_extension")
require("script/lua/unit_extensions/head/head_husk_extension")
require("script/lua/unit_extensions/pickup/weapon_rack_extension")
require("script/lua/unit_extensions/hit_reactions/player_hitreaction_extension")
require("script/lua/unit_extensions/hit_reactions/ai_hitreaction_extension")
require("script/lua/unit_extensions/parry_extension")
require("script/lua/unit_extensions/ai/ai_locomotion_extension")
require("script/lua/unit_extensions/ai/ai_husk_locomotion_extension")
require("script/lua/unit_extensions/ai/ai_navigation_extension")
require("script/lua/unit_extensions/ai/ai_base_extension")
require("script/lua/unit_extensions/ai/ai_husk_base_extension")
require("script/lua/unit_extensions/ai/ai_level_unit_base_extension")
require("script/lua/templates/animation_callback_templates")
require("script/lua/terror_event_mixer")
require("script/lua/utils/global_utils")
require("script/lua/steam_vr_manager")
require("script/lua/mock_vr_manager")
require("script/lua/vr_controller")
require("script/lua/vr_controller_mouse")
require("script/lua/tests/slow_wind")
require("settings/breeds")
require("script/lua/views/view_manager")

script_data.navigation_thread_disabled = true

class("StateGameplay")

local EXIT_DURATION = 3
local FADE_SPEED = math.max(1 / EXIT_DURATION, 2)

StateGameplay.on_enter = function (self, params)
	self._params = params

	self:_setup_world()
	Managers.time:register_timer("game", "main")
	CLEAR_POSITION_LOOKUP()
	self:_spawn_level()
	self:_init_state_managers()

	local ADD_GAMEPLAY_EXTENSIONS = true

	self._vr_controller = Managers.vr:create_vr_controller(self._world, ADD_GAMEPLAY_EXTENSIONS)

	local views = {
		gameplay_view = "NewGameplayView",
		credits_view = "CreditsView",
		how_to_play_view = "HowToPlayView",
		result_view = "ResultView"
	}

	Managers.state.view = ViewManager:new(self._world, self._vr_controller, self, views)

	Level.trigger_level_loaded(self._level)
	TerrorEventMixer.reset()

	local outline_system = Managers.state.extension:system("outline_system")

	outline_system:set_vr_controller(self._vr_controller)
	Managers.state.event:register(self, "change_level", "event_change_level")
	Managers.state.event:register(self, "disconnect", "event_disconnect")
	Managers.state.event:register(self, "close_menu", "event_close_menu")
	Managers.state.event:register(self, "quit_game", "event_quit_game")
	Managers.state.event:register(self, "removed_member_from_lobby", "event_removed_member_from_lobby")

	self._wind = SlowWind:new(self._world, self._params.level_name)

	if Managers.lobby and self._level_name ~= "cart" and Managers.lobby.server then
		Managers.lobby:set_unjoinable(false)
	end

	self._rpc_notify_lobby_joined_received = {}

	Managers.transition:fade_out(3)
	Managers.unlock:check_dlcs()
end

StateGameplay._setup_world = function (self)
	self._world = GLOBAL_WORLD

	World.set_flow_callback_object(self._world, self)

	EffectHelper.world = self._world
	TerrorEventMixer.world = self._world
end

StateGameplay._spawn_level = function (self)
	local level_name = self._params.level_name

	self._level_name = level_name

	local level_resource = LevelSettings.levels[level_name].resource_name
	local object_sets, position, rotation, shading_callback, mood_setting

	printf("loading level [%s]", level_name)

	local level = ScriptWorld.load_level(self._world, level_resource, object_sets, position, rotation, shading_callback, mood_setting)

	self._level = level

	World.set_data(self._world, "current_level", self._level)
	Level.spawn_background(level)
end

StateGameplay._init_state_managers = function (self)
	local world = self._world

	if Managers.lobby then
		local nm = NetworkManager:new(true, world)

		Managers.state.network = nm

		if Managers.lobby.server then
			nm:register_rpc_callbacks(self, "rpc_notify_lobby_joined")
		else
			nm:register_rpc_callbacks(self, "rpc_load_level", "rpc_permission_to_enter_game")
		end
	end

	local level = self._level
	local level_name = self._level_name

	Managers.state.event = EventManager:new()
	Managers.state.spawn = SpawnManager:new(world, level, level_name)
	Managers.state.score = ScoreManager:new(world)
	Managers.state.game_mode = GameModeManager:new(world, level, level_name)
	Managers.state.debug = DebugManager:new(world, level)
	Managers.state.hud = HudManager:new(world, level)
	Managers.state.extension = ExtensionManager:new(world, level, level_name)

	self:_init_extension_systems()
	Managers.state.extension:add_and_register_units(world, Level.units(self._level))
end

StateGameplay._init_extension_systems = function (self)
	local NO_PRE_UPDATE, NO_POST_UPDATE, HAS_PRE_UPDATE, HAS_POST_UPDATE, EXTENSIONS_DEFINED_BY_SYSTEM = false, false, true, true
	local ext_manager = Managers.state.extension

	ext_manager:add_system("ai_system", AISystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("nav_graph_system", NavGraphSystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("ai_inventory_system", AIInventorySystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("ai_slot_system", AISlotSystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("aggro_system", AggroSystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("ai_navigation_system", AINavigationSystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, HAS_POST_UPDATE)
	ext_manager:add_system("health_system", HealthSystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("hitreaction_system", ExtensionSystemBase, {
		"PlayerHitReactionExtension",
		"AIHitReactionExtension"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("locomotion_system", LocomotionSystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("wand_system", WandSystem, {
		"WandExtension",
		"WandHuskExtension"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("head_system", HeadSystem, {
		"HeadExtension",
		"HeadHuskExtension"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("interactable_system", InteractableSystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, HAS_POST_UPDATE)
	ext_manager:add_system("sound_environment_system", SoundEnvironmentSystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("spawner_system", SpawnerSystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("particle_system", ExtensionSystemBase, {
		"ExtensionParticles"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("staff_vector_field_system", ExtensionSystemBase, {
		"StaffVectorFieldExtension"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("bow_vector_field_system", ExtensionSystemBase, {
		"BowVectorFieldExtension"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("staff_melee_system", ExtensionSystemBase, {
		"StaffMeleeExtension"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("ragdoll_system", RagdollSystem, {
		"RagdollShooterExtension"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("outline_system", OutlineSystem, EXTENSIONS_DEFINED_BY_SYSTEM, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("pickup_system", ExtensionSystemBase, {
		"WeaponRackExtension"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
	ext_manager:add_system("parry_system", ExtensionSystemBase, {
		"ParryExtension"
	}, NO_PRE_UPDATE, NO_POST_UPDATE)
end

StateGameplay.spawn_unit = function (self, unit)
	print("Unit name:", Unit.debug_name(unit))
	print("Unit alive on spawn:", Unit.alive(unit))
end

StateGameplay.unspawn_unit = function (self, unit)
	print("unspawn unit", unit)
	print("Unit alive on unspawn:", Unit.alive(unit))

	local ext_manager = Managers.state.extension

	if ext_manager then
		ext_manager:unregister_unit(unit)
	end
end

StateGameplay._spawn_player = function (self)
	local unit = World.spawn_unit(self._world, "units/character/character", Vector3.zero(), Quaternion.identity())

	self._player_unit = unit

	Managers.state.extension:register_unit(self._world, unit)
end

StateGameplay.event_close_menu = function (self)
	Managers.state.view:enable_view("gameplay_view", false)
end

StateGameplay.event_disconnect = function (self)
	self._disconnect = true
end

StateGameplay.event_quit_game = function (self)
	self._quit_game = true
end

StateGameplay.event_change_level = function (self, level_name, skip_loading_level)
	if Managers.lobby and not Managers.lobby.server then
		return
	end

	local new_level

	if level_name and LevelSettings.levels[level_name] then
		new_level = level_name
	else
		local sequence = LevelSettings.level_sequence
		local current_index = table.find(sequence, self._level_name)
		local next_index = (current_index or 0) % #sequence + 1

		new_level = sequence[next_index]
	end

	self._skip_loading_level = skip_loading_level

	if self._end_conditions_met then
		printf("[StateGameplay] Ignore change level to %q - End conditins already met -> %q.", new_level, self._end_conditions_met)
	elseif self._change_level then
		printf("[StateGameplay] ignore change level to %q, already changing level to %q", new_level, self._change_level)
	else
		printf("[StateGameplay] changing level to %q.", new_level)

		self._change_level = new_level
	end
end

StateGameplay.set_end_conditions_met = function (self, result)
	local sequence = LevelSettings.level_sequence
	local current_index = table.find(sequence, self._level_name)
	local next_index = (current_index or 0) % #sequence + 1
	local new_level = sequence[next_index]

	if self._change_level then
		printf("[StateGameplay] ignore END CONDITIONS MET -> %q, already changing level to %q", new_level, self._change_level)
	elseif self._end_conditions_met then
		printf("[StateGameplay] Ignore END CONDITIONS MET -> %q, End conditions already met -> %q.", new_level, self._end_conditions_met)
	else
		printf("[StateGameplay] END CONDITIONS MET - changing level to %q.", new_level)

		self._end_conditions_met_show_scoreboard = true

		Managers.state.view:enable_view("result_view", true, result == "victory")
		Managers.state.view:enable_view("gameplay_view", false, true)
		self:_register_score_to_leaderboard()
	end

	if result == "victory" then
		local new_unlock = populate_save_add_unlock(SaveDataUnlocks, self._level_name)

		local function save_callback(info)
			if info.error then
				print("Failed saving")
			else
				print("Success saving")
			end
		end

		Managers.save:auto_save(SaveFileNameUnlocks, SaveDataUnlocks, save_callback)

		if new_unlock then
			Managers.popup:queue_popup("Congratulations", "Your have unlocked items for:\nWarhammer: End Times - Vermintide\nStart the game to receive your rewards.")
		end
	end
end

StateGameplay._register_score_to_leaderboard = function (self)
	if not Managers.lobby or not Managers.lobby:using_steam() or not Managers.leaderboards:enabled() then
		return
	end

	local score_table = Managers.state.score:scores()
	local peer_id = Network.peer_id()
	local my_score = score_table[peer_id]

	if my_score then
		local score_data = {
			score = my_score.kills + my_score.headshots,
			kills = my_score.kills,
			headshots = my_score.headshots,
			time_in_seconds = my_score.minutes_played
		}

		Managers.leaderboards:register_score(self._level_name, score_data)
	end
end

StateGameplay.pre_update = function (self, dt)
	UPDATE_PLAYER_LISTS()
	UPDATE_POSITION_LOOKUP()

	local t = Managers.time:time("game")

	Managers.state.view:update(dt, t)
end

StateGameplay._update_matchmaking = function (self, dt)
	if not Managers.lobby then
		return
	end

	if Managers.lobby.server and #Managers.lobby:lobby_members() > 1 then
		Managers.lobby:enable_matchmaking(false)

		return
	end

	if not Managers.popup:has_popup() and Managers.lobby and Managers.lobby:is_matchmaking() and not self._join_lobby_data then
		local lobby_manager = Managers.lobby
		local lobbies = lobby_manager:lobby_browser_content({
			"matchmaking",
			"private",
			"unjoinable"
		}) or {}

		for _, data in ipairs(lobbies) do
			repeat
				if data.valid and data.matchmaking ~= "true" and data.private == "false" and data.unjoinable == "false" then
					local join_lobby_data = Managers.lobby:get_lobby_info(data.lobby_num)

					if join_lobby_data then
						if Managers.lobby:using_steam() then
							local lobby_id = join_lobby_data.id
							local lobby_is_blacklisted = Managers.lobby:is_lobby_blacklisted(lobby_id)

							if lobby_is_blacklisted then
								break
							end

							self._join_lobby_data = join_lobby_data

							Managers.popup:queue_popup("Game Found", self._join_lobby_data.name)
						else
							self._join_by_ip = join_lobby_data.address

							Managers.popup:queue_popup("Game Found", join_lobby_data.server_name)
						end

						Managers.lobby:enable_matchmaking(false)

						return
					end
				end
			until true
		end
	end
end

StateGameplay.update = function (self, dt)
	local main_t = Managers.time:time("main")

	Managers.popup:update(dt, main_t, self._vr_controller)

	local t = Managers.time:time("game")

	if self._level_name == "inn" and not self._menu_activated then
		Managers.state.view:enable_view("gameplay_view", true)

		self._menu_activated = true
	end

	self:_update_matchmaking(dt)
	Profiler.start("TerrorEventMixer")

	local ai_system = Managers.state.extension:system("ai_system")

	TerrorEventMixer.update(t, dt, ai_system.ai_debugger and ai_system.ai_debugger.screen_gui)
	Profiler.stop("TerrorEventMixer")

	local disconnect_popup_id = self._disconnect_popup_id

	if disconnect_popup_id and Managers.popup:query_popup_done(disconnect_popup_id) then
		Managers.transition:fade_in(FADE_SPEED)

		self._exit_data.time = t + EXIT_DURATION
		self._disconnect_popup_id = nil
	end

	self._wind:update()

	local network_manager = Managers.state.network

	if network_manager then
		network_manager:update_receive(dt, t)
	end

	self._vr_controller:update(dt, t)
	Managers.state.extension:update(dt, t)
	Managers.state.spawn:update(dt, t)
	Managers.state.score:update(dt, t)
	Managers.state.game_mode:update(dt, t)
	Managers.state.hud:update(dt, t)
	Managers.state.debug:update(dt, t)
	Managers.state.extension:post_update(dt, t)

	if network_manager then
		network_manager:update_transmit(dt, t)
	end

	Managers.differentiation:update(dt, t)
	VALIDATE_POSITION_LOOKUP()
	Profiler.start("StateGameplay end of update")

	if not self._end_conditions_met_show_scoreboard and not self._end_conditions_met then
		local end_conditions_met, result = Managers.state.game_mode:end_conditions_met()

		if end_conditions_met then
			self:set_end_conditions_met(result)
		end
	end

	local new_state, params = self:_update_exit(dt, t)

	Profiler.stop("StateGameplay end of update")

	return new_state, params
end

StateGameplay._update_exit = function (self, dt, t)
	if Managers.popup:has_popup() then
		return
	end

	local input_exit = Keyboard.pressed(Keyboard.button_index("esc")) or self._exit_to_main_menu
	local exit_data = self._exit_data
	local network_manager = Managers.state.network
	local steam_invite_join = Managers.invite:poll_invite()

	if not exit_data then
		if input_exit then
			local network_ready = not network_manager
			local exit_time = t + EXIT_DURATION

			self._exit_data = {
				reason = "quit_to_menu",
				time = exit_time,
				network_ready = network_ready
			}

			if not network_ready then
				if Managers.lobby.server then
					network_manager:shutdown_session(EXIT_DURATION)
				else
					network_manager:leave_session(EXIT_DURATION)
				end
			end

			Managers.transition:fade_in(FADE_SPEED)
			Managers.state.view:disable_all_views()

			if Managers.lobby and Managers.lobby.server then
				Managers.lobby:set_unjoinable(true)
			end
		elseif self._change_level then
			local exit_time = t + EXIT_DURATION
			local network_ready = not network_manager

			self._exit_data = {
				reason = "load_level",
				time = exit_time,
				network_ready = network_ready
			}

			if not network_ready then
				if Managers.lobby.server then
					for _, member in ipairs(Managers.lobby:lobby_members()) do
						if member ~= Network.peer_id() then
							RPC.rpc_load_level(member, NetworkLookup.levels[self._change_level], false)
						end
					end

					network_manager:shutdown_session(EXIT_DURATION)
				else
					network_manager:leave_session(EXIT_DURATION)
				end
			end

			Managers.transition:fade_in(FADE_SPEED)
			Managers.state.view:disable_all_views(true)

			if Managers.lobby and Managers.lobby.server then
				Managers.lobby:set_unjoinable(true)
			end
		elseif self._end_conditions_met then
			local exit_time = t + EXIT_DURATION
			local network_ready = not network_manager

			self._exit_data = {
				reason = "end_conditions_met",
				time = exit_time,
				network_ready = network_ready
			}

			if not network_ready then
				if Managers.lobby.server then
					for _, member in ipairs(Managers.lobby:lobby_members()) do
						if member ~= Network.peer_id() then
							RPC.rpc_load_level(member, NetworkLookup.levels[self._end_conditions_met], true)
						end
					end

					network_manager:shutdown_session(EXIT_DURATION)
				else
					network_manager:leave_session(EXIT_DURATION)
				end
			end

			Managers.transition:fade_in(FADE_SPEED)
			Managers.state.view:disable_all_views(true)

			if Managers.lobby then
				Managers.lobby:set_unjoinable(true)
			end
		elseif network_manager and (network_manager:state() == "leaving" or network_manager:state() == "left") then
			self._exit_data = {
				network_ready = false,
				reason = "disconnect",
				time = math.huge
			}

			Managers.state.view:disable_all_views(true)

			if Managers.lobby and Managers.lobby.server then
				Managers.lobby:set_unjoinable(true)
			end

			if Game.startup_commands.standalone then
				self._disconnect_popup_id = Managers.popup:queue_popup("Disconnected", "Disconnected from host, the game will end")
			else
				self._disconnect_popup_id = Managers.popup:queue_popup("Disconnected", "Disconnected from host, returning to Inn")
			end
		elseif steam_invite_join then
			local exit_time = t + EXIT_DURATION
			local network_ready = not network_manager

			self._exit_data = {
				reason = "join_by_steam_invite",
				time = exit_time,
				network_ready = network_ready
			}

			if not network_ready then
				if Managers.lobby.server then
					network_manager:shutdown_session(EXIT_DURATION)
				else
					network_manager:leave_session(EXIT_DURATION)
				end
			end

			Managers.transition:fade_in(FADE_SPEED)
			Managers.state.view:disable_all_views(true)

			if Managers.lobby and Managers.lobby.server then
				Managers.lobby:set_unjoinable(true)
			end
		elseif self._join_lobby_data then
			local exit_time = t + EXIT_DURATION
			local network_ready = not network_manager

			self._exit_data = {
				reason = "join_by_id",
				time = exit_time,
				network_ready = network_ready
			}

			if not network_ready then
				if Managers.lobby.server then
					network_manager:shutdown_session(EXIT_DURATION)
				else
					network_manager:leave_session(EXIT_DURATION)
				end
			end

			Managers.transition:fade_in(FADE_SPEED)
			Managers.state.view:disable_all_views(true)

			if Managers.lobby and Managers.lobby.server then
				Managers.lobby:set_unjoinable(true)
			end
		elseif self._join_by_ip then
			local exit_time = t + EXIT_DURATION
			local network_ready = not network_manager

			self._exit_data = {
				reason = "join_by_ip",
				time = exit_time,
				network_ready = network_ready
			}

			if not network_ready then
				if Managers.lobby.server then
					network_manager:shutdown_session(EXIT_DURATION)
				else
					network_manager:leave_session(EXIT_DURATION)
				end
			end

			Managers.transition:fade_in(FADE_SPEED)
			Managers.state.view:disable_all_views(true)

			if Managers.lobby then
				Managers.lobby:set_unjoinable(true)
			end
		elseif self._disconnect then
			local exit_time = t + EXIT_DURATION
			local network_ready = not network_manager

			self._exit_data = {
				reason = "disconnect",
				time = exit_time,
				network_ready = network_ready
			}

			if not network_ready then
				if Managers.lobby.server then
					network_manager:shutdown_session(EXIT_DURATION)
				else
					network_manager:leave_session(EXIT_DURATION)
				end
			end

			Managers.transition:fade_in(FADE_SPEED)
			Managers.state.view:disable_all_views(true)

			if Managers.lobby and Managers.lobby.server then
				Managers.lobby:set_unjoinable(true)
			end

			Managers.lobby:refresh_lobby_browser()
		elseif self._quit_game then
			local exit_time = t + EXIT_DURATION
			local network_ready = not network_manager

			self._exit_data = {
				reason = "quit",
				time = exit_time,
				network_ready = network_ready
			}

			if not network_ready then
				if Managers.lobby.server then
					network_manager:shutdown_session(EXIT_DURATION)
				else
					network_manager:leave_session(EXIT_DURATION)
				end
			end

			Managers.transition:fade_in(FADE_SPEED)
			Managers.state.view:disable_all_views(true)

			if Managers.lobby and Managers.lobby.server then
				Managers.lobby:set_unjoinable(true)
			end
		end
	end

	if exit_data and exit_data.reason == "quit" then
		TerrorEventMixer.reset()

		local network_ready = exit_data.network_ready or not network_manager:in_session()

		exit_data.network_ready = network_ready

		if network_ready and t > exit_data.time then
			local params = {
				leave_lobby = true,
				old_level_name = self._level_name
			}

			return StateQuit, params
		end
	elseif exit_data and exit_data.reason == "quit_to_menu" then
		TerrorEventMixer.reset()

		local network_ready = exit_data.network_ready or not network_manager:in_session()

		exit_data.network_ready = network_ready

		if network_ready and t > exit_data.time then
			local params = {
				exit_to_menu = true,
				leave_lobby = true,
				permission_to_enter_game = true,
				old_level_name = self._level_name,
				next_state = StateTitleScreen
			}

			return StateLoading, params
		end
	elseif exit_data and exit_data.reason == "load_level" then
		TerrorEventMixer.reset()

		local network_ready = exit_data.network_ready or not network_manager:in_session()

		exit_data.network_ready = network_ready

		if network_ready and t > exit_data.time then
			print("network ready")

			return StateLoading, {
				level_name = self._change_level,
				old_level_name = self._level_name,
				next_state = StateGameplay,
				permission_to_enter_game = self._permission_to_enter_next_game
			}
		elseif t > exit_data.time + 5 then
			print("network unready, timeout")

			return StateLoading, {
				leave_lobby = true,
				next_state = StateGameplay,
				old_level_name = self._level_name
			}
		end
	elseif exit_data and exit_data.reason == "end_conditions_met" then
		TerrorEventMixer.reset()

		local network_ready = exit_data.network_ready or not network_manager:in_session()

		exit_data.network_ready = network_ready

		if network_ready and t > exit_data.time then
			print("network ready")

			local params = {
				level_name = self._end_conditions_met,
				old_level_name = self._level_name,
				permission_to_enter_game = self._permission_to_enter_next_game,
				skip_loading_level = self._skip_loading_level
			}

			return StateLoading, params
		elseif t > exit_data.time + 5 then
			print("network unready, timeout")

			return StateLoading, {
				leave_lobby = true,
				next_state = StateGameplay,
				old_level_name = self._level_name
			}
		end
	elseif exit_data and exit_data.reason == "disconnect" then
		TerrorEventMixer.reset()

		local network_ready = exit_data.network_ready or not network_manager:in_session()

		exit_data.network_ready = network_ready

		if network_ready and t > exit_data.time then
			if Game.startup_commands.standalone then
				local params = {
					leave_lobby = true,
					old_level_name = self._level_name
				}

				return StateQuit, params
			else
				return StateLoading, {
					leave_lobby = true,
					next_state = StateGameplay,
					old_level_name = self._level_name
				}
			end
		end
	elseif exit_data and exit_data.reason == "join_by_steam_invite" then
		local network_ready = exit_data.network_ready or not network_manager:in_session()

		exit_data.network_ready = network_ready

		if network_ready and t > exit_data.time then
			local parameters = {
				leave_lobby = true,
				join_by_steam_invite = true
			}

			return StateLoading, parameters
		end
	elseif exit_data and exit_data.reason == "join_by_id" then
		local network_ready = exit_data.network_ready or not network_manager:in_session()

		exit_data.network_ready = network_ready

		if network_ready and t > exit_data.time then
			local parameters = {
				leave_lobby = true,
				join_by_lobby_data = self._join_lobby_data
			}

			return StateLoading, parameters
		end
	elseif exit_data and exit_data.reason == "join_by_ip" then
		local network_ready = exit_data.network_ready or not network_manager:in_session()

		exit_data.network_ready = network_ready

		if network_ready and t > exit_data.time then
			local parameters = {
				leave_lobby = true,
				join_ip = self._join_by_ip
			}

			return StateLoading, parameters
		end
	end
end

StateGameplay.on_exit = function (self, params)
	self._wind:destroy()
	Managers.state:destroy()
	RESET_WORLD()
	Managers.vr:reinitialize()
	Managers.transition:reinitialize()
	Managers.differentiation:reinitialize()
	Managers.popup:reinitialize()
	Managers.time:unregister_timer("game")

	if params and params.leave_lobby and Managers.lobby then
		Managers.lobby:reset()
	end
end

StateGameplay.event_removed_member_from_lobby = function (self, member)
	self._rpc_notify_lobby_joined_received[member] = nil
end

StateGameplay.rpc_notify_lobby_joined = function (self, sender)
	if not self._rpc_notify_lobby_joined_received[sender] then
		RPC.rpc_load_level(sender, NetworkLookup.levels[self._level_name], false)
		RPC.rpc_permission_to_enter_game(sender)

		self._rpc_notify_lobby_joined_received[sender] = true
	end
end

StateGameplay.rpc_load_level = function (self, sender, level_id, end_conditions_met)
	local level_name = NetworkLookup.levels[level_id]

	if end_conditions_met then
		print("END CONDITIONS MET -> NEXT LEVEL", level_name)

		self._end_conditions_met = level_name
	else
		print("CHANGE LEVEL", level_name)

		self._change_level = level_name
	end
end

StateGameplay.rpc_permission_to_enter_game = function (self, sender)
	fassert(self._change_level, "Got permission to enter game before loading next level")

	self._permission_to_enter_next_game = true
end
