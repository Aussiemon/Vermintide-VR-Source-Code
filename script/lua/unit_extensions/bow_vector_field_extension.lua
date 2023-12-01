-- chunkname: @script/lua/unit_extensions/bow_vector_field_extension.lua

require("settings/bow_settings")

local BowSettings = BowSettings
local VectorField = stingray.VectorField
local World = stingray.World
local PhysicsWorld = stingray.PhysicsWorld
local Unit = stingray.Unit
local Quaternion = stingray.Quaternion
local Vector3 = stingray.Vector3
local Vector3Box = stingray.Vector3Box
local Vector4 = stingray.Vector4

class("BowVectorFieldExtension")

BowVectorFieldExtension.init = function (self, extension_init_context, unit, extension_init_data)
	print("Init BowVectorFieldExtension")

	self._unit = unit
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._node = 1

	local min, max = self:_get_world_extents()

	self._min_world_extent = Vector3Box(min)
	self._max_world_extent = Vector3Box(max)
	self._was_active = false
	self._is_active = false
	self._arrows = {}

	self:_add_cloth_push_vector_field()
end

BowVectorFieldExtension._dynamic_parameters = function (self)
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

BowVectorFieldExtension._add_cloth_push_vector_field = function (self)
	self._cloth_push_vf = World.vector_field(self._world, "wind")

	local position, up, settings = self:_dynamic_parameters()
	local parameters = {
		center = Vector4(0, 0, 0, 0),
		up = Vector4(0, 0, 1, 0),
		speed = Vector4(1, 1, 1, 1),
		radius = Vector4(1, 1, 1, 1)
	}

	self._cloth_push_vf_id = VectorField.add(self._cloth_push_vf, "vector_fields/magic_pull_push", parameters, settings)
end

BowVectorFieldExtension.update = function (self, unit, dt, t)
	for _, arrow_pos in pairs(self._arrows) do
		local speed = BowSettings.arrow_push_cloth.speed
		local radius = BowSettings.arrow_push_cloth.radius
		local position, up, settings = self:_dynamic_parameters()
		local parameters = {
			center = Vector4(arrow_pos.x, arrow_pos.y, arrow_pos.z, 0),
			up = up,
			speed = Vector4(speed, speed, speed, speed),
			radius = Vector4(radius, radius, radius, radius)
		}

		VectorField.change(self._cloth_push_vf, self._cloth_push_vf_id, "vector_fields/magic_pull_push", parameters, settings)
	end
end

BowVectorFieldExtension.destroy = function (self)
	VectorField.remove(self._cloth_push_vf_id)
end

BowVectorFieldExtension.set_active = function (self, is_active)
	self._was_active = self._is_active
	self._is_active = is_active
end

BowVectorFieldExtension.add_arrow = function (self, position)
	self._arrow_counter = self._arrow_counter and self._arrow_counter + 1 or 1
	self._arrows[self._arrow_counter] = position

	return self._arrow_counter
end

BowVectorFieldExtension.remove_arrow = function (self, index)
	assert(self._arrows[index] and "tried to remove non-existing projectile")

	self._arrows[index] = nil

	if table.is_empty(self._arrows) then
		local position, up, settings = self:_dynamic_parameters()
		local parameters = {
			center = position,
			up = up,
			speed = Vector4(0, 0, 0, 0),
			radius = Vector4(1, 1, 1, 1)
		}

		VectorField.change(self._cloth_push_vf, self._cloth_push_vf_id, "vector_fields/magic_pull_push", parameters, settings)
	end
end

BowVectorFieldExtension.set_arrow_position = function (self, position, index)
	self._arrows[index] = position
end

BowVectorFieldExtension._get_world_extents = function (self)
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
