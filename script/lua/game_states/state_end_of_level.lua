-- chunkname: @script/lua/game_states/state_end_of_level.lua

require("script/lua/views/end_of_level_view")
class("StateEndOfLevel")

StateEndOfLevel.on_enter = function (self, params)
	self._world = GLOBAL_WORLD
	self._in_params = params

	self:_init_state_managers()
	self:_setup_input()
	Managers.transition:force_fade_in()
	Managers.transition:fade_out(1)

	self._end_of_level_view = EndOfLevelView:new(self._world, self._vr_controller, self)
end

StateEndOfLevel._init_state_managers = function (self)
	Managers.state.extension = ExtensionManager:new(self._world)

	self:_init_extension_systems()
end

StateEndOfLevel._init_extension_systems = function (self)
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

StateEndOfLevel._setup_input = function (self)
	local NO_GAMEPLAY_EXTENSIONS = false

	self._vr_controller = Managers.vr:create_vr_controller(self._world, NO_GAMEPLAY_EXTENSIONS)
	self._input_blocked = false
end

StateEndOfLevel.pre_update = function (self, dt)
	local t = Managers.time:time("main")

	self._end_of_level_view:update(dt, t)
end

StateEndOfLevel.update = function (self, dt, t)
	self._vr_controller:update(dt, t)
	Managers.state.extension:update(dt, t)

	return self:_try_next_state()
end

StateEndOfLevel.cb_fade_in_done = function (self, index)
	self._fade_done = true
end

StateEndOfLevel._update_input = function (self, dt, t)
	if Keyboard.pressed(Keyboard.button_index("enter")) then
		self._exit_state = "continue"
	elseif Keyboard.pressed(Keyboard.button_index("esc")) then
		self._exit_state = "exit_to_menu"
	end
end

StateEndOfLevel._try_next_state = function (self)
	if not self._new_state or not self._fade_done then
		return
	end

	return self._new_state, self._params
end

StateEndOfLevel.on_exit = function (self, params)
	self._end_of_level_view:destroy()
	self._vr_controller:destroy()
	Managers.state:destroy()
end
