-- chunkname: @script/lua/views/view_manager.lua

require("script/lua/views/new_gameplay_view")
require("script/lua/views/result_view")
require("script/lua/views/result_view_demo")
require("script/lua/views/hud_view")
require("script/lua/views/title_view")
require("script/lua/views/input_ip_view")
require("script/lua/views/credits_view")
class("ViewManager")

ViewManager.init = function (self, world, input, parent, views)
	self._world = world
	self._input = input
	self._parent = parent
	self._views = {}

	for view, class_name in pairs(views) do
		local klass = rawget(_G, class_name)

		self._views[view] = klass:new(world, input, parent)
	end

	self._current_view_stack = {}

	self:_create_laser()

	self._hud_view = HUDView:new(self._world, self._input, self._parent)
end

ViewManager.view_enabled = function (self)
	return #self._current_view_stack > 0
end

ViewManager._create_laser = function (self)
	self._laser_unit = World.spawn_unit(self._world, "content/models/vr/laser")

	Unit.set_unit_visibility(self._laser_unit, false)
end

ViewManager._update_laser = function (self, dt, t)
	local right_wand_unit = self._input:get_wand("right"):wand_unit()
	local base_pose = Unit.world_pose(right_wand_unit, Unit.node(right_wand_unit, "j_pointer"))
	local laser_pose = base_pose

	Matrix4x4.set_scale(laser_pose, Vector3(0.03, 1000, 0.03))
	Unit.set_local_pose(self._laser_unit, 1, laser_pose)
	World.update_unit(self._world, self._laser_unit)
end

ViewManager.enable_view = function (self, view_name, enable, ...)
	fassert(self._views[view_name], "[ViewManager] There is currently no view called %s", view_name)

	if enable then
		if table.find(self._current_view_stack, view_name) then
			print(string.format("[ViewManager] %s is already enabled", view_name))
		else
			self._views[view_name]:enable(true, ...)

			self._current_view_stack[#self._current_view_stack + 1] = view_name
		end
	else
		local index = table.find(self._current_view_stack, view_name)

		if index then
			self._views[view_name]:enable(false, ...)
			table.remove(self._current_view_stack, index)
		else
			print(string.format("[ViewManager] Tried to disable %s which wasn't enabled", view_name))
		end
	end
end

ViewManager.disable_all_views = function (self, ...)
	for _, view_name in pairs(self._current_view_stack) do
		self._views[view_name]:enable(false, ...)
	end

	self._disabled = true
end

ViewManager.update = function (self, dt, t)
	local view_name = self._current_view_stack[#self._current_view_stack]

	if view_name and not Managers.popup:has_popup() then
		self._views[view_name]:update(dt, t)
		self:_update_hud_units(true, dt, t)
		self:_update_laser(dt, t)
	elseif Managers.popup:has_popup() then
		self:_update_laser(dt, t)
		self:_update_hud_units(true, dt, t)
	else
		self:_update_hud_units(false, dt, t)
		self:_update_input(dt, t)
	end
end

ViewManager._update_hud_units = function (self, enabled, dt, t)
	if enabled then
		if not self._hud_units_enabled then
			Unit.set_unit_visibility(self._laser_unit, true)
			self._input:get_wand("right"):enable_generic_wand(true)
			self._hud_view:enable(true)
		end
	elseif self._hud_units_enabled then
		Unit.set_unit_visibility(self._laser_unit, false)
		self._input:get_wand("right"):enable_generic_wand(false)
		self._hud_view:enable(false)
	end

	self._hud_units_enabled = enabled

	if self._hud_units_enabled then
		self._hud_view:update(dt, t)
	end

	self:_update_laser()
end

ViewManager._update_laser = function (self)
	local right_wand_unit = self._input:get_wand("right"):wand_unit()
	local base_pose = Unit.world_pose(right_wand_unit, Unit.node(right_wand_unit, "j_pointer"))
	local laser_pose = base_pose

	Matrix4x4.set_scale(laser_pose, Vector3(0.03, 1000, 0.03))
	Unit.set_local_pose(self._laser_unit, 1, laser_pose)
	World.update_unit(self._world, self._laser_unit)
end

ViewManager._update_input = function (self, dt, t)
	if not self._disabled and not Managers.popup:has_popup() and self._input:get("pressed", "menu", "any") and self._views.gameplay_view then
		Managers.state.view:enable_view("gameplay_view", true)
	end
end

ViewManager.view = function (self, view_name)
	fassert(self._views[view_name], "[ViewManager] There is no view called %s in ViewManager", view_name)

	return self._views[view_name]
end

ViewManager.destroy = function (self)
	for _, view in pairs(self._views) do
		view:destroy()
	end
end
