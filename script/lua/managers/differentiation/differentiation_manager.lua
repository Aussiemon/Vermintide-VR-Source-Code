-- chunkname: @script/lua/managers/differentiation/differentiation_manager.lua

require("settings/ragdoll_settings")
class("DifferentiationManager")

DifferentiationManager.init = function (self)
	local mode_settings = stingray.Application.user_setting("differentiation")

	self._modes = {}
	self._ui_modes = {}

	for key, value in pairs(mode_settings) do
		self._modes[value.index] = value
		self._ui_modes[value.index] = value.title
	end

	self:set_world(GLOBAL_WORLD)
	self:_set_cpu_mode()
end

DifferentiationManager.mode_name_list = function (self)
	return self._ui_modes
end

DifferentiationManager.modes = function (self)
	return self._modes
end

DifferentiationManager.current_mode = function (self)
	return self._mode
end

DifferentiationManager.next_mode = function (self)
	local mode = self._mode
	local current_index = table.find(self._modes, mode)
	local new_index = current_index + 1

	if not self._modes[new_index] then
		new_index = 1
	end

	self:_set_mode(new_index)
end

DifferentiationManager.dismember_enabled = function (self)
	return self._mode.dismember_enabled
end

DifferentiationManager.max_levitating_ragdolls = function (self)
	return self._mode.max_levitating_ragdolls
end

DifferentiationManager.extra_particle_trail = function (self)
	return self._mode.extra_particle_trail
end

DifferentiationManager.reinitialize = function (self)
	self._gui = nil

	self:set_world(GLOBAL_WORLD)

	local current_index = table.find(self._modes, self._mode)

	self:_set_mode(current_index)
end

DifferentiationManager._set_cpu_mode = function (self, value)
	local mode = Application.is_high_level_cpu() and 1 or 0

	self:_set_mode(1 + mode)
end

DifferentiationManager._set_mode = function (self, index)
	fassert(self._modes[index], "Index out of range %q", tostring(index))

	local mode = self._modes[index]

	self._mode = mode

	self:_show_mode()

	if self._world then
		local apex_enabled = self._mode.apex_enabled

		Apex.set_enabled(self._world, apex_enabled)

		local async_update = self._mode.particle_async_update
		local vector_fields = self._mode.particle_vector_fields
		local collisions = self._mode.particle_collisions

		World.set_particles_settings(self._world, async_update, vector_fields, collisions)
		printf("World.set_particles_settings async_update:%s vector_fields:%s, collisions:%s", async_update == true and "true" or "false", vector_fields == true and "true" or "false", collisions == true and "true" or "false")
	end
end

DifferentiationManager._show_mode = function (self)
	local world = self._world

	if world then
		if self._gui then
			print("DifferentiationManager:_show_mode -> World.destroy_gui")
			World.destroy_gui(world, self._gui)

			self._gui = nil
			self._gui_timeout = nil
		end

		local hmd_pose = Managers.vr:hmd_world_pose()
		local pose = hmd_pose.head

		Matrix4x4.set_translation(pose, Matrix4x4.translation(pose) + hmd_pose.forward * 3)

		local gui = World.create_world_gui(world, pose, 1000, 1000)

		print("DifferentiationManager:_show_mode -> World.create_world_gui")

		if self._mode then
			local text = self._mode.title
			local text_pos = Vector3(100, 100, 0)
		end

		self._gui = gui
		self._gui_timeout = Managers.time:time("main") + 5
	end
end

DifferentiationManager.update = function (self, dt)
	Profiler.start("DifferentiationManager:update()")

	local t = Managers.time:time("main")

	if self._gui_timeout and t > self._gui_timeout then
		print("DifferentiationManager:update -> World.destroy_gui")
		World.destroy_gui(self._world, self._gui)

		self._gui = nil
		self._gui_timeout = nil
	end

	Profiler.stop("DifferentiationManager:update()")
end

DifferentiationManager.set_world = function (self, world)
	if not world then
		if self._gui and self._world then
			print("DifferentiationManager:set_world -> World.destroy_gui")
			World.destroy_gui(self._world, self._gui)

			self._gui = nil
			self._gui_timeout = nil
		end

		self._world = world
	else
		self._world = world

		self:_show_mode()
	end

	self._world = world
end
