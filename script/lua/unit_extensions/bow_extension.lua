-- chunkname: @script/lua/unit_extensions/bow_extension.lua

require("script/lua/arrow_handler")
require("settings/bow_settings")

local BowSettings = BowSettings
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local World = stingray.World
local Actor = stingray.Actor
local Matrix4x4 = stingray.Matrix4x4
local Quaternion = stingray.Quaternion
local Vector3Box = stingray.Vector3Box
local Math = stingray.Math
local Wwise = stingray.Wwise
local WwiseWorld = stingray.WwiseWorld
local LineObject = stingray.LineObject
local Color = stingray.Color
local DEBUG = false
local HACKY_KEYBOARD_TEST = true

class("BowExtension")

BowExtension.init = function (self, extension_init_context, unit)
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._wwise_world = Wwise.wwise_world(self._world)
	self._level = extension_init_context.level
	self._unit = unit
	self._riser_wand_input = nil
	self._riser_node = 1
	self._string_wand_input = nil
	self._string_node = Unit.node(unit, "bow_string")
	self._aim_node = Unit.node(unit, "a_arrow_rest")
	self._bottom_node = Unit.node(unit, "bow_bottom_05")

	local new_scale = Vector3(unpack(BowSettings.base_scale))

	Unit.set_local_scale(unit, 1, new_scale)

	local r_pos = Unit.world_position(self._unit, self._riser_node)
	local s_pos = Unit.world_position(self._unit, self._string_node)

	self._base_dist = Vector3.length(r_pos - s_pos)
	self._draw_distance = 0
	self._last_draw_distance = 0
	self._line_object = World.create_line_object(self._world)
	self._network_mode = extension_init_context.network_mode

	local bow_vector_field_extension = ScriptUnit.extension(self._unit, "bow_vector_field_system")

	self._arrow_handler = ArrowHandler:new(self._world, bow_vector_field_extension, self._network_mode)
	self._string_base_pos = Vector3Box(Unit.local_position(self._unit, self._string_node))
	self._interactors = {}
	self._is_interactable = true
	self._arrow_timer = 0
	self._can_spawn_arrow = false
end

BowExtension.can_interact = function (self, wand_input)
	if not self._is_interactable then
		return false
	end

	if not self._interactors.riser then
		if wand_input:pressed("grip") or wand_input:pressed("trigger") or wand_input:pressed("touch_down") then
			local pos = Unit.world_position(self._unit, self._riser_node)

			if Vector3.length(wand_input:position() - pos) > BowSettings.bow_interaction_radius then
				return false
			end

			return true, "riser"
		end
	elseif not self._interactors.string then
		local pos = Unit.world_position(self._unit, self._string_node)
		local wand_hand = wand_input:wand_hand()
		local hand_position = wand_input:wand_unit_position("j_" .. wand_hand .. "handmiddle2")
		local close_enough = false

		if DEBUG then
			self._string_hand_position = hand_position
		end

		close_enough = Vector3.length(hand_position - pos) < BowSettings.string_grab_radius and self._arrow and true or false

		if self._arrow and self._arrow_outline_extension and close_enough then
			-- Nothing
		end

		if close_enough and wand_input:held("trigger") then
			return true, "string"
		end

		return false
	end
end

BowExtension.interaction_position = function (self)
	if not self._riser_wand_input then
		return Unit.world_position(self._unit, self._riser_node)
	elseif not self._string_wand_input then
		return Unit.world_position(self._unit, self._string_node)
	end
end

BowExtension._spawn_arrow_on_riser = function (self)
	self._arrow = World.spawn_unit(self._world, "units/weapons/player/wpn_we_bow_03_t1/proj_arrow")

	for ii = 1, Unit.num_actors(self._arrow) do
		local actor = Unit.actor(self._arrow, ii)

		if actor then
			Actor.set_scene_query_enabled(actor, false)
		end
	end

	local outline_system = Managers.state.extension:system("outline_system")

	self._arrow_outline_extension = outline_system:on_add_extension(self._world, self._arrow, "ArrowOutlineExtension")

	local other_wand_hand = "left"

	if self._riser_wand_input and self._riser_wand_input:wand_hand() == "left" then
		other_wand_hand = "right"
	end

	self._arrow_outline_extension.hand = other_wand_hand

	self:_update_arrow()
end

BowExtension.allowed_interact = function (self, interaction_type)
	return not self._interactors[interaction_type]
end

BowExtension.interaction_started = function (self, wand_input, wand_unit, attach_node, wand_hand, interaction_type, husk)
	if interaction_type == "riser" then
		local unit = self._unit

		Unit.set_data(unit, "linked", true)
		Unit.animation_event(wand_unit, "bow")

		if self._network_mode ~= "client" then
			local actor = Unit.actor(unit, 1)

			Actor.set_kinematic(actor, true)
		end

		World.unlink_unit(self._world, unit)
		World.link_unit(self._world, unit, self._riser_node, wand_unit, attach_node)

		local new_scale = Vector3(unpack(BowSettings.base_scale))

		Unit.set_local_scale(unit, 1, new_scale)

		local hand_rotation_offset = Quaternion.from_euler_angles_xyz(unpack(BowSettings.hand_rotation_offset))
		local base_rotation = Quaternion.multiply(Quaternion.from_euler_angles_xyz(unpack(BowSettings.grip_rotation_offset)), hand_rotation_offset)

		Unit.teleport_local_position(unit, self._riser_node, Vector3(unpack(BowSettings.grip_position_offset)))
		Unit.teleport_local_rotation(unit, self._riser_node, base_rotation)

		self._riser_wand_unit = wand_unit
		self._riser_attach_node = attach_node
		self._riser_wand_input = wand_input

		if self._riser_wand_input then
			self._riser_wand_input:set_additional_rotation_offset(hand_rotation_offset)
		end

		self:_reset_bow_rotation()
		self:set_is_gripped(true)

		self._interactors.riser = wand_unit

		Unit.flow_event(self._unit, "pickup_sound")
	elseif interaction_type == "string" then
		Unit.animation_event(wand_unit, "arrow")

		self._string_wand_input = wand_input
		self._string_attach_node = attach_node
		self._string_wand_unit = wand_unit

		if self._arrow and self._arrow_outline_extension then
			local outlined = self._arrow_outline_extension.outlined

			if outlined then
				self._arrow_outline_extension.enabled = false
			end
		end

		self._interactors.string = wand_unit

		local riser_pose = Unit.world_pose(self._unit, self._riser_node)
		local string_pose = Unit.world_pose(self._unit, self._string_node)

		self._riser_audio_source = WwiseWorld.make_auto_source(self._wwise_world, riser_pose)
		self._string_audio_source = WwiseWorld.make_auto_source(self._wwise_world, string_pose)

		WwiseWorld.trigger_event(self._wwise_world, "Play_bow_loop", self._riser_audio_source)
		WwiseWorld.trigger_event(self._wwise_world, "Play_bow_loop_string", self._string_audio_source)
		WwiseWorld.set_source_parameter(self._wwise_world, self._riser_audio_source, "tighten_bow", 0)
		WwiseWorld.set_source_parameter(self._wwise_world, self._string_audio_source, "tighten_string", 0)
	end
end

BowExtension.should_drop = function (self, wand_input)
	local riser_controller_index = self._riser_wand_input and self._riser_wand_input:controller_index() or -1
	local string_controller_index = self._string_wand_input and self._string_wand_input:controller_index() or -1

	if riser_controller_index == wand_input:controller_index() then
		local grip_pressed = wand_input:pressed("touch_down")

		return grip_pressed and not self._string_wand_input
	elseif string_controller_index == wand_input:controller_index() then
		local should_drop = wand_input:released("trigger")

		return should_drop
	end
end

BowExtension._reset_string_position = function (self)
	local var_index = Unit.animation_find_variable(self._unit, "drawn")

	Unit.animation_set_variable(self._unit, var_index, 0)

	if self._string_wand_unit then
		Unit.animation_event(self._string_wand_unit, "relax")
	end

	local position = self._string_base_pos:unbox()

	Unit.set_local_position(self._unit, self._string_node, position)
end

BowExtension._reset_bow_rotation = function (self)
	local riser_unit = self._unit
	local riser_node = self._riser_node
	local hand_offset = Quaternion.from_euler_angles_xyz(unpack(BowSettings.hand_rotation_offset))
	local base_rotation = Quaternion.multiply(Quaternion.from_euler_angles_xyz(unpack(BowSettings.grip_rotation_offset)), hand_offset)

	Unit.teleport_local_rotation(riser_unit, riser_node, base_rotation)
end

BowExtension._rotate_back_riser = function (self, dt, t)
	local riser_unit = self._unit
	local riser_node = self._riser_node
	local rotation_speed = BowSettings.rotation_speed
	local hand_offset = Quaternion.from_euler_angles_xyz(unpack(BowSettings.hand_rotation_offset))
	local wanted_rotation = Quaternion.multiply(Quaternion.from_euler_angles_xyz(unpack(BowSettings.grip_rotation_offset)), hand_offset)
	local current_rotation = Unit.local_rotation(riser_unit, riser_node)
	local new_rotation = Quaternion.lerp(current_rotation, wanted_rotation, rotation_speed * dt)

	Unit.teleport_local_rotation(riser_unit, riser_node, new_rotation)
end

BowExtension._release_string = function (self)
	if not self._arrow then
		return
	end

	self:_reset_string_position()

	if self._riser_audio_source and self._string_audio_source then
		local sound_param = math.min(self._draw_distance / BowSettings.max_draw_distance * 100, 100)

		WwiseWorld.set_source_parameter(self._wwise_world, self._riser_audio_source, "bow_fire_release", sound_param)
		WwiseWorld.set_source_parameter(self._wwise_world, self._string_audio_source, "string_fire_release", sound_param)
		WwiseWorld.trigger_event(self._wwise_world, "Play_bow_arrow_shoot", self._riser_audio_source)
		WwiseWorld.trigger_event(self._wwise_world, "Play_bow_light_fire", self._string_audio_source)
		WwiseWorld.set_source_parameter(self._wwise_world, self._riser_audio_source, "tighten_bow", 0)
		WwiseWorld.set_source_parameter(self._wwise_world, self._string_audio_source, "tighten_string", 0)
		WwiseWorld.trigger_event(self._wwise_world, "Stop_bow_loop", self._riser_audio_source)
		WwiseWorld.trigger_event(self._wwise_world, "Stop_bow_loop_string", self._string_audio_source)

		self._riser_audio_source = nil
		self._string_audio_source = nil
	end

	if self._draw_distance < BowSettings.min_draw_distance then
		return
	end

	Unit.animation_event(self._unit, "release")

	local position = Unit.world_position(self._arrow, 1)
	local aim_dir, look_target_pos = self:_get_arrow_direction()

	if self._network_mode == "server" then
		self:fire(position, aim_dir, look_target_pos, true, Network.peer_id())

		local unit_index = Unit.get_data(self._unit, "unit_index")

		Managers.state.network:send_rpc_clients("rpc_client_fire", unit_index, position, aim_dir, look_target_pos)
	elseif self._network_mode == "client" then
		local unit_index = Unit.get_data(self._unit, "unit_index")

		Managers.state.network:send_rpc_session_host("rpc_server_request_fire", unit_index, position, aim_dir, look_target_pos)
	else
		self:fire(position, aim_dir, look_target_pos, true)
	end

	self:_destroy_arrow()

	self._arrow_timer = 0
end

BowExtension._get_adjusted_arrow_direction = function (self, original_direction)
	local hmd_pose = Managers.vr:hmd_world_pose()
	local hmd_pos = Matrix4x4.translation(hmd_pose.head)
	local look_dir = Vector3.normalize(hmd_pose.forward)
	local _, look_target_pos, _, _, _ = PhysicsWorld.raycast(self._physics_world, hmd_pos, look_dir, "closest", "collision_filter", "filter_arrow")
	local dot = Vector3.dot(original_direction, look_dir)
	local angle = math.radians_to_degrees(math.acos(dot))
	local percentage = 1 - angle / BowSettings.hmd_forward_influence.half_angle
	local adjusted_arrow_dir = Vector3.lerp(original_direction, look_dir, BowSettings.hmd_forward_influence.look * percentage)

	adjusted_arrow_dir = Vector3.normalize(adjusted_arrow_dir)
	look_target_pos = look_target_pos or hmd_pos + look_dir * 25

	return adjusted_arrow_dir, look_target_pos
end

BowExtension._get_arrow_direction = function (self)
	local arrow = self._arrow
	local base_rot = Quaternion.from_euler_angles_xyz(unpack(BowSettings.arrow_base_rotation))
	local rot = Unit.world_rotation(arrow, 1)
	local actual_rot = Quaternion.multiply(rot, base_rot)
	local dir = Quaternion.forward(actual_rot)
	local dir_n = Vector3.normalize(dir)
	local adjusted_arrow_dir, look_target_pos = self:_get_adjusted_arrow_direction(dir_n)

	return adjusted_arrow_dir, look_target_pos
end

BowExtension.fire = function (self, fire_pos, direction, look_target_pos, do_damage, peer_id)
	Unit.animation_event(self._unit, "release")
	self._arrow_handler:fire_arrow(fire_pos, direction, look_target_pos, self._draw_distance, do_damage, peer_id)

	if self._arrow_outline_extension then
		self._arrow_outline_extension.enabled = false
	end

	self._draw_distance = 0
end

BowExtension._drop = function (self)
	local unit = self._unit

	World.unlink_unit(self._world, unit)

	local new_scale = Vector3(unpack(BowSettings.base_scale))

	Unit.set_local_scale(unit, 1, new_scale)

	if self._network_mode ~= "client" then
		for ii = 1, Unit.num_actors(unit) do
			local actor = Unit.actor(unit, ii)

			if actor and Actor.is_dynamic(actor) then
				Actor.set_scene_query_enabled(actor, true)
				Actor.set_kinematic(actor, false)
				Actor.wake_up(actor)
			end
		end
	end

	Unit.set_data(unit, "linked", false)
	Unit.animation_event(self._riser_wand_unit, "relax")
end

BowExtension.interaction_ended = function (self, wand_input, wand_unit, force_drop)
	if self._interactors.riser == wand_unit or force_drop then
		if self._string_wand_unit then
			self:_release_string()
		end

		if self._riser_wand_input then
			self._riser_wand_input:set_additional_rotation_offset(nil)
		end

		self:_drop(wand_unit)

		self._riser_wand_input = nil
		self._string_wand_input = nil
		self._riser_wand_unit = nil
		self._string_wand_unit = nil

		if self._arrow then
			self:_destroy_arrow()
		end

		self:set_is_gripped(false)

		self._interactors.riser = nil

		Unit.flow_event(self._unit, "drop_sound")
	end

	if self._interactors.string == wand_unit or force_drop then
		self:_release_string()

		self._string_wand_input = nil
		self._string_wand_unit = nil
		self._interactors.string = nil
	end

	return not self._interactors.riser and not self._interactors.string
end

BowExtension._update_arrow = function (self)
	local riser_unit = self._unit
	local bottom_node = self._bottom_node
	local string_unit = self._unit
	local string_node = self._string_node
	local aim_node = self._aim_node
	local string_pos = Unit.world_position(string_unit, string_node)
	local bottom_pos = Unit.world_position(riser_unit, bottom_node)
	local nook_offset_dir = Vector3.normalize(bottom_pos - string_pos)
	local nook_pos = string_pos + nook_offset_dir * 0.03
	local riser_pos = Unit.world_position(riser_unit, aim_node)
	local pose = Matrix4x4.from_translation(nook_pos)
	local base_rot = Quaternion.from_euler_angles_xyz(-90, 0, 90)
	local look_dir = Vector3.normalize(nook_pos - riser_pos)
	local arrow_pos = nook_pos
	local look = Quaternion.look(look_dir)
	local look = Quaternion.multiply(look, base_rot)

	Matrix4x4.set_rotation(pose, look)
	Matrix4x4.set_translation(pose, arrow_pos)
	Unit.set_local_pose(self._arrow, 1, pose)
end

BowExtension._draw_length = function (self, riser_pos, string_pos)
	local distance = Vector3.length(riser_pos - string_pos) - self._base_dist

	return math.max(0, distance)
end

BowExtension.update_bow_draw = function (self, riser_pos, string_pos, draw_length)
	self:_animate_draw(riser_pos, string_pos)
	self:_rotate_bow(riser_pos, string_pos)

	local var_index = Unit.animation_find_variable(self._unit, "drawn")

	Unit.animation_set_variable(self._unit, var_index, draw_length)

	self._draw_distance = draw_length
end

BowExtension._animate_draw = function (self, riser_wand_position, string_wand_position)
	local unit = self._unit
	local string_pos = string_wand_position
	local length = Vector3.length(riser_wand_position - string_wand_position)

	if length > BowSettings.max_draw_distance then
		local dir = Vector3.normalize(riser_wand_position - string_wand_position)

		string_pos = riser_wand_position - dir * BowSettings.max_draw_distance
	end

	local pose = Matrix4x4.from_translation(string_pos)
	local parent = Unit.scene_graph_parent(unit, self._string_node)
	local world_pose = Unit.world_pose(unit, parent)
	local inverse = Matrix4x4.inverse(world_pose)

	pose = Matrix4x4.multiply(pose, inverse)

	Matrix4x4.set_rotation(pose, Quaternion.from_euler_angles_xyz(0, 0, 180))
	Unit.set_local_pose(unit, self._string_node, pose)
end

BowExtension._rotate_bow = function (self, riser_wand_position, string_wand_position)
	local base_rot = Quaternion(Vector3.up(), math.pi)
	local look_dir = Vector3.normalize(riser_wand_position - string_wand_position)
	local riser_wand_rotation = Unit.world_rotation(self._riser_wand_unit, self._riser_attach_node)
	local hand_offset = Quaternion.from_euler_angles_xyz(unpack(BowSettings.hand_rotation_offset))
	local offset_rot = Quaternion.multiply(Quaternion.from_euler_angles_xyz(unpack(BowSettings.grip_rotation_offset)), hand_offset)
	local offset_wand_rot = Quaternion.multiply(riser_wand_rotation, offset_rot)
	local x = Vector3.dot(look_dir, Quaternion.right(offset_wand_rot))
	local y = Vector3.dot(look_dir, Quaternion.forward(offset_wand_rot))
	local yaw = (math.pi - math.atan2(x, y)) % (2 * math.pi)
	local final_rot = Quaternion.multiply(offset_rot, Quaternion(Vector3.up(), yaw))

	Unit.set_local_rotation(self._unit, self._riser_node, final_rot)
end

BowExtension.update = function (self, unit, dt, t)
	if DEBUG then
		LineObject.reset(self._line_object)

		local r_pos = Unit.world_position(self._unit, self._riser_node)

		LineObject.add_sphere(self._line_object, Color(255, 0, 255), r_pos, BowSettings.bow_interaction_radius)

		local s_pos = Unit.world_position(self._unit, self._string_node)

		LineObject.add_sphere(self._line_object, Color(0, 255, 255), s_pos, BowSettings.string_grab_radius)

		local sh_pos = self._string_hand_position

		if sh_pos then
			LineObject.add_sphere(self._line_object, Color(255, 255, 0), sh_pos, 0.05)

			self._string_hand_position = nil
		end
	end

	if self._gripped and self:_can_arrow_spawn(dt) then
		self:_spawn_arrow_on_riser()
	end

	local riser_input = self._riser_wand_input
	local string_input = self._string_wand_input

	if riser_input and string_input and self._arrow then
		local string_pos = string_input:wand_unit_position("j_weaponattach")
		local riser_pos = riser_input:wand_unit_position("j_weaponattach")
		local draw_length = self:_draw_length(riser_pos, string_pos)

		self:update_bow_draw(riser_pos, string_pos, draw_length)

		if self._network_mode == "server" then
			local unit_index = Unit.get_data(self._unit, "unit_index")

			Managers.state.network:send_rpc_clients("rpc_update_bow_draw", unit_index, riser_pos, string_pos, draw_length)
		elseif self._network_mode == "client" then
			local unit_index = Unit.get_data(self._unit, "unit_index")

			Managers.state.network:send_rpc_session_host("rpc_update_bow_draw", unit_index, riser_pos, string_pos, draw_length)
		end

		if DEBUG then
			LineObject.add_sphere(self._line_object, Color(255, 255, 255), string_pos, 0.03)
		end

		self:_vibrate(riser_input, string_input, draw_length)

		local sound_param = math.min(draw_length / BowSettings.max_draw_distance * 100, 100)

		WwiseWorld.set_source_parameter(self._wwise_world, self._riser_audio_source, "tighten_bow", sound_param)
		WwiseWorld.set_source_parameter(self._wwise_world, self._string_audio_source, "tighten_string", sound_param)

		local riser_world_pos = Unit.world_position(self._unit, self._riser_node)
		local string_world_pos = Unit.world_position(self._unit, self._string_node)

		WwiseWorld.set_source_position(self._wwise_world, self._riser_audio_source, riser_world_pos)
		WwiseWorld.set_source_position(self._wwise_world, self._string_audio_source, string_world_pos)
	end

	if riser_input and self._arrow then
		self:_update_arrow()
	end

	if riser_input and not string_input then
		self:_rotate_back_riser(dt, t)
	end

	if HACKY_KEYBOARD_TEST and riser_input then
		local was_pressed = self._keyboard_draw_key_was_pressed
		local is_pressed = stingray.Keyboard.button(stingray.Keyboard.button_id("f")) == 1

		if is_pressed and was_pressed then
			local unit_pose = Unit.world_pose(self._unit, self._riser_node)
			local unit_rot = Matrix4x4.rotation(unit_pose)
			local unit_forward = Quaternion.rotate(unit_rot, Vector3.forward())
			local riser_pos = riser_input:wand_unit_position("j_weaponattach")
			local draw_speed = 0.5
			local string_pos = riser_pos + unit_forward * BowSettings.max_draw_distance

			self:_animate_draw(riser_pos, string_pos)

			self._draw_distance = BowSettings.max_draw_distance
		elseif not is_pressed and was_pressed then
			self:_release_string()
		end

		self._keyboard_draw_key_was_pressed = is_pressed
	end

	self._arrow_handler:update(dt)

	if DEBUG then
		LineObject.dispatch(self._world, self._line_object)
	end
end

BowExtension._vibrate = function (self, riser_input, string_input, draw_distance)
	local sound_param = 0
	local unit = self._unit

	WwiseWorld.set_source_parameter(self._wwise_world, self._riser_audio_source, "bow_vibration", sound_param)
	WwiseWorld.set_source_parameter(self._wwise_world, self._string_audio_source, "bow_vibration_string", sound_param)

	if math.abs(self._last_draw_distance - draw_distance) > BowSettings.draw_deadzone then
		sound_param = 1

		WwiseWorld.set_source_parameter(self._wwise_world, self._riser_audio_source, "bow_vibration", sound_param)
		WwiseWorld.set_source_parameter(self._wwise_world, self._string_audio_source, "bow_vibration_string", sound_param)

		local vibration_strength = BowSettings.base_vibration_strength

		riser_input:trigger_feedback(vibration_strength * draw_distance * 0.8)
		string_input:trigger_feedback(vibration_strength * draw_distance^2)
	end

	self._last_draw_distance = draw_distance
end

BowExtension._destroy_arrow = function (self)
	if self._arrow then
		local outline_system = Managers.state.extension:system("outline_system")

		outline_system:on_remove_extension(self._arrow, "ArrowOutlineExtension")
		World.destroy_unit(self._world, self._arrow)

		self._arrow_outline_extension = nil
		self._arrow = nil
	end
end

BowExtension.destroy = function (self)
	self:_destroy_arrow()
	self._arrow_handler:destroy()
end

BowExtension.set_is_gripped = function (self, gripped)
	self._gripped = gripped
end

BowExtension.is_gripped = function (self)
	return self._gripped
end

BowExtension.interaction_radius = function (self)
	return BowSettings.bow_interaction_radius
end

BowExtension.set_interactable = function (self, is_interactable)
	self._is_interactable = is_interactable
end

BowExtension.is_interactable = function (self)
	return self._is_interactable
end

BowExtension._can_arrow_spawn = function (self, dt)
	self._arrow_timer = self._arrow_timer + dt
	self._can_spawn_arrow = self._arrow_timer > BowSettings.time_until_arrow_respawns_after_shot and not self._arrow

	if self._can_spawn_arrow then
		return true or false
	end
end
