-- chunkname: @script/lua/unit_extensions/interactable/interactable_lever_extension.lua

require("settings/lever_settings")

local LineObject = stingray.LineObject
local Color = stingray.Color
local Unit = stingray.Unit
local World = stingray.World
local Vector3 = stingray.Vector3
local Vector3Box = stingray.Vector3Box
local Quaternion = stingray.Quaternion
local QuaternionBox = stingray.QuaternionBox
local Matrix4x4 = stingray.Matrix4x4
local Matrix4x4Box = stingray.Matrix4x4Box
local Math = stingray.Math
local WwiseWorld = stingray.WwiseWorld

class("InteractableLeverExtension")

local DEBUG = false
local WAND_UNIT_GRIP_NODE = "j_weaponattach"
local LEVER_PIVOT_NODE = "ap"
local HANDLE_OFFSET = 0.25
local HANDLE_LENGTH = 0.5
local HANDLE_UI_OFFSET = 0.34
local HANDLE_UI_LENGTH = 0.27
local HANDLE_UI_RADIUS = 0.08

InteractableLeverExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._unit = unit
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._wwise_world = Wwise.wwise_world(self._world)
	self._interacting = false
	self._disable_at_end = Unit.get_data(unit, "lever_settings", "disable_at_end")
	self._pivot_node = Unit.node(unit, LEVER_PIVOT_NODE)
	self._lever_start_dir = Vector3Box(0, math.sqrt(1 - LeverSettings.max_lever_rotation * LeverSettings.max_lever_rotation), -LeverSettings.max_lever_rotation)
	self._lever_end_dir = Vector3Box(0, math.sqrt(1 - LeverSettings.max_lever_rotation * LeverSettings.max_lever_rotation), LeverSettings.max_lever_rotation)
	self._progress = 0
	self._progress_step = 0
	self._is_vibrating = false

	self:_set_state("idle")

	self._is_interactable = true

	self:_rotate(self._lever_start_dir:unbox())
end

InteractableLeverExtension._set_state = function (self, state)
	self._state = state
end

InteractableLeverExtension.flow_callback_reset = function (self)
	self:_set_state("resetting")
end

InteractableLeverExtension._update_vibration = function (self, dt)
	if self._wand_input and self._vibration_time then
		self._wand_input:trigger_feedback(self._vibration_strength)

		self._vibration_time = self._vibration_time - dt

		if self._vibration_time <= 0 then
			self._vibration_time = nil
		end
	end
end

InteractableLeverExtension.update = function (self, unit, dt, t)
	local state = self._state

	if state == "idle" then
		-- Nothing
	elseif state == "interacting" then
		self:_update_interacting(dt, t)
	elseif state == "activating" then
		self:_update_activating(dt, t)
	elseif state == "resetting" then
		self:_update_resetting(dt, t)
	elseif state == "disabled" then
		-- Nothing
	end

	self:_update_vibration(dt)

	if DEBUG then
		self:_debug_draw()
	end
end

InteractableLeverExtension._update_interacting = function (self, dt, t)
	local unit = self._unit
	local pivot_node = self._pivot_node
	local wand_input = self._wand_input
	local wand_pos = wand_input:wand_unit_position(WAND_UNIT_GRIP_NODE)
	local root_rot = Unit.world_rotation(unit, 1)
	local pivot_pos = Unit.world_position(unit, pivot_node)
	local tm = Matrix4x4.from_quaternion_position(root_rot, pivot_pos)
	local local_pos = Matrix4x4.transform(Matrix4x4.inverse(tm), wand_pos)
	local local_pos_flat = Vector3.multiply_elements(local_pos, Vector3(0, -1, -1))
	local local_dir = Vector3.normalize(local_pos_flat)

	self:_rotate(local_dir, false, true)

	if self._progress >= LeverSettings.min_activation_rotation then
		self:_set_state("activating")
	end
end

InteractableLeverExtension._update_activating = function (self, dt, t)
	local progress = self._progress
	local new_progress = progress + LeverSettings.activate_speed * dt
	local start_dir = self._lever_start_dir:unbox()
	local end_dir = self._lever_end_dir:unbox()
	local local_dir = Vector3.lerp(start_dir, end_dir, new_progress)

	self:_rotate(local_dir)

	if self._progress == 0 then
		self:_set_state("idle")
		Unit.flow_event(self._unit, "lever_was_reset")
	end
end

InteractableLeverExtension._update_resetting = function (self, dt, t)
	local progress = self._progress
	local new_progress = progress - LeverSettings.reset_speed * dt
	local start_dir = self._lever_start_dir:unbox()
	local end_dir = self._lever_end_dir:unbox()
	local local_dir = Vector3.lerp(start_dir, end_dir, new_progress)

	self:_rotate(local_dir)

	if self._progress == 0 then
		self:_set_state("idle")
		Unit.flow_event(self._unit, "lever_was_reset")
	end
end

InteractableLeverExtension._rotate = function (self, local_dir, use_steps, vibrate)
	local dot = Vector3.dot(local_dir, Vector3.up())
	local progress = (1 + dot / LeverSettings.max_lever_rotation) * 0.5

	if progress < 0 then
		local_dir = self._lever_start_dir:unbox()
		progress = 0
	elseif progress > 1 then
		local_dir = self._lever_end_dir:unbox()
		progress = 1
	end

	self._progress = progress

	local step

	if progress < 1 then
		step = math.ceil(progress * (LeverSettings.num_steps - 1))
	else
		step = LeverSettings.num_steps
	end

	if step ~= self._progress_step then
		if step == 0 then
			Unit.flow_event(self._unit, "lever_moved_to_start")
		elseif step == LeverSettings.num_steps then
			Unit.flow_event(self._unit, "lever_moved_to_end")

			if self._disable_at_end then
				self:_set_state("disabled")
			end

			if vibrate then
				self._vibration_time = LeverSettings.end_vibration_time
				self._vibration_strength = LeverSettings.end_vibration_strength
			end
		else
			Unit.flow_event(self._unit, "lever_moved_one_step")

			if vibrate then
				self._vibration_time = LeverSettings.step_vibration_time
				self._vibration_strength = LeverSettings.step_vibration_strength
			end
		end

		self._progress_step = step
	end

	local step_percentage = step / LeverSettings.num_steps

	if use_steps then
		local start_dir = self._lever_start_dir:unbox()
		local end_dir = self._lever_end_dir:unbox()

		local_dir = Vector3.lerp(start_dir, end_dir, step_percentage)
	end

	local rot = Quaternion.look(local_dir, Vector3.up())

	Unit.set_local_rotation(self._unit, self._pivot_node, rot)
end

InteractableLeverExtension._handle_center_world_position = function (self)
	local unit = self._unit
	local pivot_node = self._pivot_node
	local pivot_pos = Unit.world_position(unit, pivot_node)
	local lever_direction = self:_lever_world_direction()
	local center = pivot_pos + lever_direction * (HANDLE_OFFSET + HANDLE_LENGTH * 0.5)

	return center
end

InteractableLeverExtension._lever_world_direction = function (self)
	local unit = self._unit
	local pivot_node = self._pivot_node
	local pivot_rot = Unit.world_rotation(unit, pivot_node)
	local direction = -Quaternion.forward(pivot_rot)

	return direction
end

InteractableLeverExtension._is_point_inside_handle = function (self, point)
	local unit = self._unit
	local pivot_node = self._pivot_node
	local pivot_pose = Unit.world_pose(unit, pivot_node)
	local local_pos = Matrix4x4.transform(Matrix4x4.inverse(pivot_pose), point)

	if -local_pos[2] < HANDLE_OFFSET or -local_pos[2] > HANDLE_OFFSET + HANDLE_LENGTH then
		return false
	end

	local radius = self._interacting and LeverSettings.interacting_release_radius or LeverSettings.interaction_radius
	local local_pos_flat = Vector3(local_pos[1], 0, local_pos[3])
	local dist = Vector3.length(local_pos_flat)

	if radius < dist then
		return false
	end

	return true
end

InteractableLeverExtension._debug_draw = function (self)
	local world = self._world
	local unit = self._unit
	local line_object = self._line_object or World.create_line_object(world)

	self._line_object = line_object

	LineObject.reset(line_object)

	local pivot_node = self._pivot_node
	local pivot_pos = Unit.world_position(unit, pivot_node)
	local pivot_rot = Unit.world_rotation(unit, pivot_node)

	LineObject.add_line(line_object, Color(255, 0, 0), pivot_pos, pivot_pos + Quaternion.right(pivot_rot))
	LineObject.add_line(line_object, Color(0, 255, 0), pivot_pos, pivot_pos + Quaternion.forward(pivot_rot))
	LineObject.add_line(line_object, Color(0, 0, 255), pivot_pos, pivot_pos + Quaternion.up(pivot_rot))

	if self._interacting then
		LineObject.add_sphere(line_object, Color(255, 255, 0), self._wand_input:wand_unit_position(WAND_UNIT_GRIP_NODE), 0.02)
	end

	local handle_center = self:_handle_center_world_position()
	local interaction_radius = self:interaction_radius()

	if not self._interacting then
		LineObject.add_sphere(line_object, Color(50, 255, 255, 255), handle_center, interaction_radius)
	end

	local num_segments = 10
	local segment_dist = HANDLE_LENGTH / num_segments
	local lever_dir = self:_lever_world_direction()
	local handle_base = handle_center - lever_dir * (HANDLE_LENGTH / 2)

	for i = 0, num_segments - 1 do
		if not self._interacting then
			LineObject.add_circle(line_object, Color(255, 255, 255), handle_base + lever_dir * i * segment_dist, LeverSettings.interaction_radius, lever_dir)
		elseif self._interacting then
			LineObject.add_circle(line_object, Color(0, 255, 0), handle_base + lever_dir * i * segment_dist, LeverSettings.interacting_release_radius, lever_dir)
		end
	end

	LineObject.dispatch(world, line_object)
end

InteractableLeverExtension.destroy = function (self)
	self._unit = nil
	self._world = nil

	if self._line_object then
		LineObject.reset(self._line_object)
		LineObject.dispatch(self._world, self._line_object)
		World.destroy_line_object(self._world, self._line_object)

		self._line_object = nil
	end
end

InteractableLeverExtension.interaction_position = function (self)
	return self:_handle_center_world_position()
end

InteractableLeverExtension.interaction_radius = function (self)
	return LeverSettings.interaction_radius
end

InteractableLeverExtension.can_interact = function (self, wand_input)
	if self._state ~= "idle" then
		return false
	end

	if wand_input:pressed("grip") or wand_input:pressed("trigger") or wand_input:pressed("touch_down") then
		local pos = wand_input:wand_unit_position(WAND_UNIT_GRIP_NODE)
		local inside_handle = self:_is_point_inside_handle(pos)

		if not inside_handle then
			return false
		end

		return true
	end
end

InteractableLeverExtension.should_drop = function (self, wand_input)
	if self._state ~= "interacting" then
		return true
	end

	local pos = wand_input:wand_unit_position(WAND_UNIT_GRIP_NODE)
	local inside_handle = self:_is_point_inside_handle(pos)

	if not inside_handle then
		return true
	end

	if wand_input:released("trigger") or wand_input:released("grip") or wand_input:pressed("touch_down") then
		return true
	end

	return false
end

InteractableLeverExtension.interaction_started = function (self, wand_input, wand_unit, wand_node, wand_hand)
	self:_set_state("interacting")

	self._wand_input = wand_input
	self._wand_unit = wand_unit

	Unit.set_unit_visibility(self._wand_unit, false)
	self:set_is_gripped(true)
end

InteractableLeverExtension.interaction_ended = function (self, wand_input, wand_unit)
	if self._state == "interacting" then
		self:_set_state("idle")
	end

	self._wand_input = nil
	self._wand_unit = nil

	Unit.set_unit_visibility(wand_unit, true)
	self:set_is_gripped(false)
end

InteractableLeverExtension.is_gripped = function (self)
	return self._gripped
end

InteractableLeverExtension.set_interactable = function (self, is_interactable)
	self._is_interactable = is_interactable
end

InteractableLeverExtension.set_is_gripped = function (self, gripped)
	self._gripped = gripped
end
