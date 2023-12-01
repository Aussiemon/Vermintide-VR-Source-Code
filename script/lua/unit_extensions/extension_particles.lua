-- chunkname: @script/lua/unit_extensions/extension_particles.lua

require("settings/staff_settings")

local StaffSettings = StaffSettings
local VectorField = stingray.VectorField
local World = stingray.World
local PhysicsWorld = stingray.PhysicsWorld
local Unit = stingray.Unit
local Quaternion = stingray.Quaternion
local Vector3 = stingray.Vector3
local Vector3Box = stingray.Vector3Box
local Vector4 = stingray.Vector4
local DEBUG = false

class("ExtensionParticles")

ExtensionParticles.init = function (self, extension_init_context, unit, extension_init_data)
	print("Init ExtensionParticles")

	self._unit = unit
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._node = Unit.has_node(self._unit, "Bone_03") and Unit.node(self._unit, "Bone_03") or Unit.node(self._unit, "fx_03")

	local min, max = self:_get_world_extents()

	self._min_world_extent = Vector3Box(min)
	self._max_world_extent = Vector3Box(max)

	self:_add_charge_channel_vector_field()
	self:_add_floating_particles_vector_field()
	self:_add_particle_pull_vector_field()
	self:_add_movement_drag_vector_field()

	self._last_position = Vector3Box(Unit.world_position(self._unit, self._node))
	self._charge_percentage = 0
	self._line_object = World.create_line_object(self._world)
end

ExtensionParticles._dynamic_parameters = function (self)
	local pos = Unit.world_position(self._unit, self._node)
	local rot = Unit.world_rotation(self._unit, self._node)
	local up = Quaternion.forward(rot)
	local min_pos = self._min_world_extent:unbox()
	local max_pos = self._max_world_extent:unbox()
	local duration = math.huge
	local settings = {
		min = min_pos,
		max = max_pos,
		duration = duration
	}

	return pos, up, settings
end

ExtensionParticles._add_charge_channel_vector_field = function (self)
	self._charge_channel_vf = World.vector_field(self._world, "magic")

	local position, up, settings = self:_dynamic_parameters()
	local parameters = {
		center = position,
		up = up,
		whirl_speed = Vector4(0.005, 0.005, 0.005, 0.005),
		pull_speed = Vector4(0.01, 0.01, 0.01, 0.01),
		radius = Vector4(1, 1, 1, 1)
	}

	self._charge_channel_vf_id = VectorField.add(self._charge_channel_vf, "vector_fields/staff_whirl", parameters, settings)
end

ExtensionParticles._add_floating_particles_vector_field = function (self)
	self._floating_particles_vf = World.vector_field(self._world, "magic_floating")

	local position, up, settings = self:_dynamic_parameters()
	local parameters = {
		center = position,
		up = Vector4(0, 0, 1, 0),
		whirl_speed = Vector4(5, 5, 5, 5),
		pull_speed = Vector4(0.05, 0.05, 0.05, 0.05),
		radius = Vector4(0.5, 0.5, 0.5, 0.5)
	}

	self._floating_particles_vf_id = VectorField.add(self._floating_particles_vf, "vector_fields/staff_whirl", parameters, settings)
end

ExtensionParticles._add_particle_pull_vector_field = function (self)
	self._particle_pull_vf = World.vector_field(self._world, "magic_floating_staff_pull")

	local position, up, settings = self:_dynamic_parameters()
	local parameters = {
		center = Vector4(0, 0, 0, 0),
		up = Vector4(0, 0, 1, 0),
		whirl_speed = Vector4(1, 1, 1, 1),
		pull_speed = Vector4(1, 1, 1, 1),
		radius = Vector4(1, 1, 1, 1)
	}

	self._particle_pull_vf_id = VectorField.add(self._particle_pull_vf, "vector_fields/magic_whirl", parameters, settings)
end

ExtensionParticles._add_movement_drag_vector_field = function (self)
	self._movement_drag_vf = World.vector_field(self._world, "magic_floating_staff_pull")

	local position, up, settings = self:_dynamic_parameters()
	local parameters = {
		center = Vector4(0, 0, 0, 0),
		up = Vector4(0, 0, 1, 0),
		force = Vector4(0, 0, 0, 0),
		direction = Vector4(0, 0, 0, 0)
	}

	self._movement_drag_vf_id = VectorField.add(self._movement_drag_vf, "vector_fields/magic_drag", parameters, settings)
end

ExtensionParticles.update = function (self, unit, dt, t)
	if DEBUG then
		LineObject.reset(self._line_object)
	end

	if not self._collecting_charge or not (self._charge_percentage > 0) then
		local position, up, settings = self:_dynamic_parameters()
		local parameters = {
			center = position,
			up = up,
			whirl_speed = Vector4(0, 0, 0, 0),
			pull_speed = Vector4(0, 0, 0, 0),
			radius = Vector4(1, 1, 1, 1)
		}

		VectorField.change(self._charge_channel_vf, self._charge_channel_vf_id, "vector_fields/staff_whirl", parameters, settings)

		parameters = {
			center = position,
			up = up,
			whirl_speed = Vector4(0, 0, 0, 0),
			pull_speed = Vector4(0, 0, 0, 0),
			radius = Vector4(1, 1, 1, 1)
		}

		VectorField.change(self._particle_pull_vf, self._particle_pull_vf_id, "vector_fields/magic_whirl", parameters, settings)

		return
	end

	if self._hand_position then
		local position, up, settings = self:_dynamic_parameters()
		local hand_position = self._hand_position:unbox()
		local last_hand_position = self._last_position:unbox()
		local parameters = {
			center = hand_position,
			up = up,
			whirl_speed = Vector4(1, 1, 1, 1),
			pull_speed = Vector4(10, 10, 10, 10),
			radius = Vector4(5, 5, 5, 5)
		}

		VectorField.change(self._charge_channel_vf, self._charge_channel_vf_id, "vector_fields/staff_whirl", parameters, settings)

		if DEBUG and hand_position then
			LineObject.add_sphere(self._line_object, Color(255, 255, 255), hand_position, 0.01)
			LineObject.add_sphere(self._line_object, Color(255, 255, 255), hand_position, 0.05)
			LineObject.add_sphere(self._line_object, Color(255, 255, 255), hand_position, 0.1)
			LineObject.add_sphere(self._line_object, Color(255, 255, 255), hand_position, 0.15)
			LineObject.add_sphere(self._line_object, Color(255, 255, 255), hand_position, 0.2)
		end

		local particle_settings = StaffSettings.charge_pull_particles
		local whirl_speed = particle_settings.max_charge_whirl_speed * self._charge_percentage
		local pull_speed = particle_settings.max_charge_pull_speed * self._charge_percentage
		local radius = particle_settings.max_charge_radius * self._charge_percentage

		parameters = {
			center = hand_position,
			up = up,
			whirl_speed = Vector4(whirl_speed, whirl_speed, whirl_speed, whirl_speed),
			pull_speed = Vector4(pull_speed, pull_speed, pull_speed, pull_speed),
			radius = Vector4(radius, radius, radius, radius)
		}

		VectorField.change(self._particle_pull_vf, self._particle_pull_vf_id, "vector_fields/magic_whirl", parameters, settings)

		local dir = Vector3.normalize(hand_position - last_hand_position)

		dir = self._is_collecting_charge and dir or dir * 0.5

		local force_x = self._is_collecting_charge and Math.random(1, 3) or Math.random(1, 2)
		local force_y = self._is_collecting_charge and Math.random(1, 3) or Math.random(1, 2)
		local force_z = self._is_collecting_charge and Math.random(0, 2) or Math.random(0, 1)

		parameters = {
			center = hand_position,
			up = up,
			force = Vector4(force_x, force_y, force_z, 0),
			direction = dir,
			radius = Vector4(7, 7, 7, 7)
		}

		VectorField.change(self._movement_drag_vf, self._movement_drag_vf_id, "vector_fields/magic_drag", parameters, settings)
		self._last_position:store(position)

		if DEBUG then
			LineObject.dispatch(self._world, self._line_object)
		end
	end
end

ExtensionParticles.set_charge_percentage = function (self, percentage)
	self._charge_percentage = percentage
end

ExtensionParticles.set_collecting = function (self, value)
	self._collecting_charge = value
end

ExtensionParticles.set_hand_position = function (self, position)
	if position and self._hand_position then
		self._hand_position:store(position)
	elseif position and not self._hand_position then
		self._hand_position = Vector3Box(position)
	else
		self._hand_position = nil
	end
end

ExtensionParticles.destroy = function (self)
	print("Destroying Vector Field for staff particles")
	VectorField.remove(self._charge_channel_vf_id)
	VectorField.remove(self._floating_particles_vf_id)
	VectorField.remove(self._particle_pull_vf_id)
end

ExtensionParticles._get_world_extents = function (self)
	local min_pos = Vector3(math.huge, math.huge, math.huge)
	local max_pos = Vector3(-math.huge, -math.huge, -math.huge)
	local units = World.units(self._world)

	for _, unit in pairs(units) do
		repeat
			if Unit.is_a(unit, "prototype") then
				break
			end

			local pos = Unit.world_position(unit, 1)

			if min_pos.x > pos.x then
				min_pos.x = pos.x
			end

			if min_pos.y > pos.y then
				min_pos.y = pos.y
			end

			if min_pos.z > pos.z then
				min_pos.z = pos.z
			end

			if max_pos.x < pos.x then
				max_pos.x = pos.x
			end

			if max_pos.y < pos.y then
				max_pos.y = pos.y
			end

			if max_pos.z < pos.z then
				max_pos.z = pos.z
			end
		until true
	end

	return min_pos, max_pos
end
