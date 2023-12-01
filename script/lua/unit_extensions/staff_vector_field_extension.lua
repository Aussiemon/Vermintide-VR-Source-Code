-- chunkname: @script/lua/unit_extensions/staff_vector_field_extension.lua

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

class("StaffVectorFieldExtension")

StaffVectorFieldExtension.init = function (self, extension_init_context, unit, extension_init_data)
	print("Init StaffVectorFieldExtension")

	self._unit = unit
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._node = Unit.has_node(self._unit, "Bone_03") and Unit.node(self._unit, "Bone_03") or Unit.node(self._unit, "fx_03")

	local min, max = self:_get_world_extents()

	self._min_world_extent = Vector3Box(min)
	self._max_world_extent = Vector3Box(max)
	self._projectiles = {}
	self._projectile_multiplier = {}
	self._settings = {
		min = self._min_world_extent:unbox(),
		max = self._max_world_extent:unbox(),
		duration = math.huge
	}
	self._projectile_push_vf = World.vector_field(self._world, "wind")
	self._projectile_counter = 0

	self:_add_charge_vortex_vector_field()

	if DEBUG then
		self._line_object = World.create_line_object(self._world)
	end
end

StaffVectorFieldExtension._dynamic_parameters = function (self)
	local pos = Unit.world_position(self._unit, self._node)
	local rot = Unit.world_rotation(self._unit, self._node)
	local up = Quaternion.forward(rot)
	local min_pos = self._min_world_extent:unbox()
	local max_pos = self._max_world_extent:unbox()

	self._settings.min = self._min_world_extent:unbox()
	self._settings.max = self._max_world_extent:unbox()

	return pos, up, self._settings
end

StaffVectorFieldExtension._add_charge_vortex_vector_field = function (self)
	self._charge_vortex_vf = World.vector_field(self._world, "wind")

	local position, up, settings = self:_dynamic_parameters()
	local parameters = {
		center = Vector4(0, 0, 0, 0),
		up = Vector4(0, 0, 1, 0),
		whirl_speed = Vector4(1, 1, 1, 1),
		pull_speed = Vector4(1, 1, 1, 1),
		radius = Vector4(1, 1, 1, 1)
	}

	self._charge_vortex_vf_id = VectorField.add(self._charge_vortex_vf, "vector_fields/magic_whirl", parameters, settings)
end

StaffVectorFieldExtension.update = function (self, unit, dt, t)
	if self._collecting_charge and self._charge_percentage > 0 and self._hand_position then
		local position, up, settings = self:_dynamic_parameters()
		local modifier = math.max(0.8, math.abs(math.sin(t)))
		local cloth_settings = StaffSettings.charge_pull_cloth
		local whirl_speed = cloth_settings.max_charge_whirl_speed * self._charge_percentage * modifier
		local pull_speed = cloth_settings.max_charge_pull_speed * self._charge_percentage * modifier
		local radius = cloth_settings.max_charge_radius * self._charge_percentage
		local parameters = {
			center = self._hand_position:unbox(),
			up = up,
			whirl_speed = Vector4(whirl_speed, whirl_speed, whirl_speed, whirl_speed),
			pull_speed = Vector4(pull_speed, pull_speed, pull_speed, pull_speed),
			radius = Vector4(radius, radius, radius, radius)
		}

		VectorField.change(self._charge_vortex_vf, self._charge_vortex_vf_id, "vector_fields/magic_whirl", parameters, settings)
	else
		local position, up, settings = self:_dynamic_parameters()
		local parameters = {
			center = position,
			up = up,
			whirl_speed = Vector4(0, 0, 0, 0),
			pull_speed = Vector4(0, 0, 0, 0),
			radius = Vector4(1, 1, 1, 1)
		}

		VectorField.change(self._charge_vortex_vf, self._charge_vortex_vf_id, "vector_fields/magic_whirl", parameters, settings)
	end

	for _, projectile in pairs(self._projectiles) do
		local projectile_pos = projectile.position
		local speed_multiplier = projectile.speed_multiplier
		local vortex_settings = StaffSettings.projectile_push_cloth
		local pull_speed = vortex_settings.push_speed * speed_multiplier
		local radius = vortex_settings.radius

		if DEBUG then
			LineObject.add_sphere(self._line_object, Color(255, 0, 255), projectile_pos, 0.02)
		end

		local position, up, settings = self:_dynamic_parameters()
		local parameters = {
			center = Vector4(projectile_pos.x, projectile_pos.y, projectile_pos.z, 0),
			speed = Vector4(pull_speed, pull_speed, pull_speed, pull_speed),
			radius = Vector4(radius, radius, radius, radius)
		}
		local id = projectile.vector_field_id

		if id then
			VectorField.change(self._projectile_push_vf, id, "vector_fields/magic_pull_push", parameters, settings)
		end
	end

	if DEBUG then
		LineObject.dispatch(self._world, self._line_object)
	end
end

StaffVectorFieldExtension.set_charge_percentage = function (self, percentage)
	self._charge_percentage = percentage
end

StaffVectorFieldExtension.set_collecting = function (self, value)
	self._collecting_charge = value
end

StaffVectorFieldExtension.set_hand_position = function (self, position)
	if position and self._hand_position then
		self._hand_position:store(position)
	elseif position and not self._hand_position then
		self._hand_position = Vector3Box(position)
	else
		self._hand_position = nil
	end
end

StaffVectorFieldExtension.add_projectile = function (self, position, speed_multiplier)
	if DEBUG then
		LineObject.reset(self._line_object)
	end

	local _, __, settings = self:_dynamic_parameters()
	local vortex_settings = StaffSettings.projectile_push_cloth
	local pull_speed = vortex_settings.push_speed * speed_multiplier
	local radius = vortex_settings.radius
	local parameters = {
		center = position,
		speed = Vector4(pull_speed, pull_speed, pull_speed, pull_speed),
		radius = Vector4(radius, radius, radius, radius)
	}
	local vector_field_id = VectorField.add(self._projectile_push_vf, "vector_fields/magic_pull_push", parameters, settings)

	self._projectile_counter = self._projectile_counter + 1
	self._projectiles[self._projectile_counter] = {
		position = position,
		speed_multiplier = speed_multiplier,
		vector_field_id = vector_field_id
	}

	return self._projectile_counter
end

StaffVectorFieldExtension.remove_projectile = function (self, index)
	local projectile = self._projectiles[index]

	assert(projectile, "tried to remove non-existing projectile")

	if projectile.vector_field_id then
		VectorField.remove(self._projectile_push_vf, projectile.vector_field_id)
	end

	self._projectiles[index] = nil
end

StaffVectorFieldExtension.set_projectile_position = function (self, position, index)
	self._projectiles[index].position = position
end

StaffVectorFieldExtension.destroy = function (self)
	VectorField.remove(self._charge_vortex_vf, self._charge_vortex_vf_id)

	for index, _ in pairs(self._projectiles) do
		self:remove_projectile(index)
	end
end

StaffVectorFieldExtension._get_world_extents = function (self)
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
