-- chunkname: @script/lua/unit_extensions/parry_extension.lua

class("ParryExtension")

local parry_settings = {
	left = {
		radius = 1,
		offset = Vector3Box(Vector3.right() + Vector3.forward() - Vector3.down())
	}
}
local DISABLE_PARRY = true

ParryExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._wwise_world = Wwise.wwise_world(self._world)
	self._level = extension_init_context.level
	self._unit = unit

	if script_data.debug_parry then
		self._line_object_parry = World.create_line_object(self._world)
	end

	self._top_parry_timer = 0
	self._left_parry_timer = 0
	self._right_parry_timer = 0
end

ParryExtension.destroy = function (self)
	return
end

ParryExtension.extensions_ready = function (self, world, unit)
	return
end

ParryExtension.update = function (self, unit, dt, t)
	if DISABLE_PARRY then
		return
	end

	if not self._wand_input then
		return
	end

	self:_update_parry(dt)
	self:_handle_input(dt, t)
	self:_update_vibration(dt, t)

	if not self._head_unit then
		local entities = Managers.state.extension:get_entities("HeadExtension")
		local num_entitites = table.size(entities)

		assert(num_entitites == 1, "only one HeadExtension should exist")

		local unit, extension = next(entities)

		self._head_unit = unit
		self._head_extension = extension
	end
end

ParryExtension._update_parry = function (self, dt)
	local head_unit = self._head_unit

	if not head_unit then
		return
	end

	local distance = 0.25
	local parry_time = 0.1
	local unit = self._unit
	local unit_position = Unit.world_position(unit, 1)
	local head_position = Unit.world_position(head_unit, 1)
	local head_rotation = Unit.world_rotation(head_unit, 1)
	local head_direction = Quaternion.forward(head_rotation)
	local head_forward = Vector3.normalize(Vector3.flat(head_direction))
	local left = -Quaternion.right(head_rotation) * 0.4 + Vector3.down()
	local left_parry_position = head_position + head_forward * 0.25 + left
	local left_distance = Vector3.distance(unit_position, left_parry_position)
	local left_parry_success = left_distance <= distance
	local right = Quaternion.right(head_rotation) * 0.4 + Vector3.down()
	local right_parry_position = head_position + head_forward * 0.25 + right
	local right_distance = Vector3.distance(unit_position, right_parry_position)
	local right_parry_success = right_distance <= distance
	local top = Vector3.down() * 0.4
	local top_parry_position = head_position + head_forward * 0.5 + top
	local top_distance = Vector3.distance(unit_position, top_parry_position)
	local top_parry_success = top_distance <= distance

	self._left_parry_timer = left_parry_success and self._left_parry_timer + dt or 0
	self._right_parry_timer = right_parry_success and self._right_parry_timer + dt or 0
	self._top_parry_timer = top_parry_success and self._top_parry_timer + dt or 0
	self._left_parry = parry_time <= self._left_parry_timer
	self._right_parry = parry_time <= self._right_parry_timer
	self._top_parry = parry_time <= self._top_parry_timer

	if script_data.debug_parry then
		local left_color = self._left_parry and Colors.get("green") or left_parry_success and Colors.get("medium_sea_green") or Colors.get("light_sea_green")
		local right_color = self._right_parry and Colors.get("green") or right_parry_success and Colors.get("medium_sea_green") or Colors.get("light_sea_green")
		local top_color = self._top_parry and Colors.get("green") or top_parry_success and Colors.get("medium_sea_green") or Colors.get("light_sea_green")

		LineObject.reset(self._line_object_parry)
		LineObject.add_sphere(self._line_object_parry, left_color, left_parry_position, distance)
		LineObject.add_sphere(self._line_object_parry, right_color, right_parry_position, distance)
		LineObject.add_sphere(self._line_object_parry, top_color, top_parry_position, distance)
		LineObject.add_line(self._line_object_parry, left_color, left_parry_position, left_parry_position + Vector3.up() * 0.5)
		LineObject.add_line(self._line_object_parry, right_color, right_parry_position, right_parry_position + Vector3.up() * 0.5)
		LineObject.add_line(self._line_object_parry, top_color, top_parry_position, top_parry_position - Quaternion.right(head_rotation) * 0.5)
		LineObject.dispatch(self._world, self._line_object_parry)
	end
end

ParryExtension._handle_input = function (self, dt, t)
	local input = self._wand_input
end

ParryExtension.is_parrying = function (self)
	if DISABLE_PARRY then
		return false
	end

	if not self._wand_input then
		return false
	end

	local is_parrying = self._left_parry or self._right_parry or self._top_parry

	return is_parrying
end

ParryExtension.interaction_started = function (self, wand_input, wand_unit, attach_node, wand_hand, interaction_type, husk, peer_id)
	self._wand_unit = wand_unit
	self._wand_input = wand_input
	self._wand_hand = wand_hand
end

ParryExtension.interaction_ended = function (self, wand_input, wand_unit)
	self._wand_unit = nil
	self._wand_input = nil
	self._wand_hand = nil
end

ParryExtension._trigger_vibration = function (self)
	self._is_vibrating = true
end

ParryExtension._stop_vibration = function (self)
	self._is_vibrating = false
end

ParryExtension._update_vibration = function (self, dt)
	if self._is_vibrating then
		local current_vibration_time = self._current_vibration_time

		if current_vibration_time < HandgunSettings.vibration_length then
			self:_vibrate()

			self._current_vibration_time = current_vibration_time + dt
		else
			self:_stop_vibration()

			self._current_vibration_time = 0
		end
	end
end

ParryExtension._vibrate = function (self)
	if not self._wand_input then
		return
	end

	local vibration_strength = HandgunSettings.base_vibration_strength

	self._wand_input:trigger_feedback(vibration_strength)
end

ParryExtension.set_is_gripped = function (self, gripped)
	self._gripped = gripped
end

ParryExtension.is_gripped = function (self)
	return self._gripped
end
