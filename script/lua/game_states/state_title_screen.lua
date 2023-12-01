-- chunkname: @script/lua/game_states/state_title_screen.lua

require("script/lua/views/view_manager")
require("script/lua/managers/invite/invite_manager")
require("script/lua/managers/save/save_manager")
class("StateTitleScreen")

StateTitleScreen.on_enter = function (self, params)
	self._params = params
	self._world = GLOBAL_WORLD

	self:_init_state_managers()
	self:_setup_input()

	self._level = params.level or self:_spawn_level()
	self._current_view = "TitleView"

	if not self._params.skip_fade then
		Managers.transition:fade_out(1)
	end

	if self._params.skip_start or GameSettingsDevelopment.skip_start_menu then
		self._skip_start_menu = true
		self._input_blocked = true
		self._new_state = StateLoading
	else
		self._view = rawget(_G, self._current_view):new(self._world, self._vr_controller, self)
	end

	Managers.token = TokenManager:new()
	Managers.invite = InviteManager:new()

	local DISABLE_CLOUD_SAVE = true

	Managers.save = SaveManager:new(DISABLE_CLOUD_SAVE)

	local function load_callback(info)
		if info.error then
			print("failed loading save due to", info.error)
		else
			print("succeded loading save")

			SaveDataUnlocks = info.data
		end
	end

	Managers.save:auto_load(SaveFileNameUnlocks, load_callback)
end

StateTitleScreen._spawn_level = function (self)
	local level = ScriptWorld.load_level(self._world, "levels/loading/loading")

	Level.spawn_background(level)
	Level.trigger_level_loaded(level)

	return level
end

StateTitleScreen._init_state_managers = function (self)
	Managers.state.extension = ExtensionManager:new(self._world)
	Managers.state.debug = DebugManager:new(self._world)

	self:_init_extension_systems()
end

StateTitleScreen._init_extension_systems = function (self)
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

StateTitleScreen._setup_input = function (self)
	local NO_GAMEPLAY_EXTENSIONS = false

	self._vr_controller = Managers.vr:create_vr_controller(self._world, NO_GAMEPLAY_EXTENSIONS)
	self._input_blocked = false
end

StateTitleScreen.pre_update = function (self, dt, t)
	local t = Managers.time:time("main")

	if self._view then
		self._view:update(dt, t)
	end
end

StateTitleScreen.update = function (self, dt, t)
	self:_update_state_managers(dt, t)
	self._vr_controller:update(dt, t)
	Managers.token:update(dt, t)

	return self:_try_new_state()
end

StateTitleScreen.join_by_ip = function (self, ip_address)
	self._params.join_ip = ip_address .. ":4711"
	self._new_state = StateLoading
end

StateTitleScreen.switch_view = function (self, view_class_name)
	local klass = rawget(_G, view_class_name)

	fassert(klass, "[StateTitleScreen] No such class: %s", view_class_name)
	self._view:destroy()

	self._view = klass:new(self._world, self._vr_controller, self)
end

StateTitleScreen._update_state_managers = function (self, dt, t)
	Managers.state.extension:update(dt, t)
	Managers.state.debug:update(dt, t)
end

StateTitleScreen._try_new_state = function (self)
	if not self._new_state then
		return
	end

	local params = {
		level_name = Game.startup_commands.level,
		next_state = StateGameplay,
		join_ip = Game.startup_commands["join-ip"] or self._params.join_ip,
		join_any = Game.startup_commands["join-any"] or self._params.join_any,
		level = self._level,
		join_by_steam_invite = Managers.invite:poll_boot_invite()
	}

	return self._new_state, params
end

StateTitleScreen.on_exit = function (self, params)
	if self._view then
		self._view:destroy()
	end

	Managers.state:destroy()
	self._vr_controller:destroy()

	if Game.quit then
		World.destroy_level(self._world, self._level)
		Managers.vr:set_tracking_space_unit(nil)
	end
end
