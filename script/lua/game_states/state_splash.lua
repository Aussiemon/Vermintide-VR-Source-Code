-- chunkname: @script/lua/game_states/state_splash.lua

require("settings/game_settings_development")
require("script/lua/views/splash_view")
require("script/lua/mock_vr_manager")
require("script/lua/steam_vr_manager")
require("gui/atlas_settings/splash_atlas")
class("StateSplash")

local PACKAGES_TO_LOAD = {
	"resource_packages/game_scripts"
}

StateSplash.on_enter = function (self, params)
	self._world = GLOBAL_WORLD
	self._wwise_world = Wwise.wwise_world(self._world)
	self._params = params

	self:_load_packages()
	Managers.transition:force_fade_in()
end

StateSplash._spawn_level = function (self)
	local level = ScriptWorld.load_level(self._world, "levels/loading/loading")

	self._level = level

	Level.spawn_background(level)
	Level.trigger_level_loaded(level)
end

StateSplash.cb_fade_in_done = function (self)
	self._fade_in_done = true
end

StateSplash._setup_splash_view = function (self)
	self._splash_view = SplashView:new()
end

StateSplash._load_packages = function (self)
	local package_manager = Managers.package

	for _, package_name in pairs(PACKAGES_TO_LOAD) do
		if not package_manager:has_loaded(package_name) then
			package_manager:load(package_name, "StateSplash", nil, true)
		end
	end
end

StateSplash._packages_loaded = function (self)
	if self._packages_are_loaded then
		return true
	end

	local package_manager = Managers.package

	for _, package_name in pairs(PACKAGES_TO_LOAD) do
		if not package_manager:has_loaded(package_name) then
			return
		end
	end

	self:_init_managers()
	self:_require_scripts()
	self:_spawn_level()

	self._packages_are_loaded = true

	self:_setup_splash_view()
	print("### Packages loaded")

	return true
end

StateSplash._require_scripts = function (self)
	require("settings/level_settings")
	require("settings/breeds")
	require("script/lua/game_states/state_loading")
	require("script/lua/game_states/state_title_screen")
	require("script/lua/game_states/state_end_of_level")
	require("foundation/script/util/script_world")
	require("script/lua/game_states/state_gameplay")
	require("script/lua/game_states/state_quit")
end

StateSplash._init_managers = function (self)
	require("foundation/script/managers/lobby/lobby_manager_lan")
	require("foundation/script/managers/lobby/lobby_manager_steam")
	require("script/lua/managers/differentiation/differentiation_manager")
	require("script/lua/managers/sizzle_reel/sizzle_reel_manager")

	Managers.differentiation = DifferentiationManager:new()

	if Game.startup_commands.standalone then
		Managers.sizzle_reel = SizzleReelManager:new()
	end

	if Game.startup_commands.network == "steam" then
		local params = {
			project_hash = "VRmintide",
			revision_check = true
		}

		Managers.lobby = LobbyManagerSteam:new(params)
	elseif Game.startup_commands.network == "lan" then
		local params = {
			project_hash = "VRmintide",
			revision_check = true,
			port = 4711
		}

		Managers.lobby = LobbyManagerLan:new(params)
	end
end

StateSplash.update = function (self, dt, t)
	if self._splash_view then
		self._splash_view:update(dt, t)
	end

	self:_update_listener(dt, t)

	return self:_try_next_state()
end

StateSplash._update_listener = function (self, dt, t)
	local hmd_pose = Managers.vr:hmd_world_pose()
	local head_pose = hmd_pose.head

	WwiseWorld.set_listener(self._wwise_world, Wwise.LISTENER_0, head_pose)
end

StateSplash._try_next_state = function (self)
	if self:_packages_loaded() and self._splash_view:is_done() then
		local startup_commands = Game.startup_commands
		local params = {
			skip_fade = true,
			skip_start = true,
			level = self._level,
			join_any = startup_commands.join_any
		}

		return StateTitleScreen, params
	end
end

StateSplash.on_exit = function (self, params)
	Managers.state:destroy()
	self._splash_view:destroy()

	self._splash_view = nil
end
