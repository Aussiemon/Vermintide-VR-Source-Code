-- chunkname: @script/lua/unit_extensions/wand/wand_extension.lua

require("script/lua/laser")
require("script/lua/tests/rag_doll_controller")
require("script/lua/tests/spawn_controller")
class("WandExtension")

local DEBUG = false

WandExtension.init = function (self, extension_init_context, unit, extension_init_data)
	local world = extension_init_context.world

	self._unit = unit
	self._world = world
	self._physics_world = World.physics_world(world)
	self._wwise_world = Wwise.wwise_world(world)

	local input = extension_init_data.input
	local settings = extension_init_data.settings

	self._wand_input = input

	local wand_hand = settings.hand

	self._wand_hand = wand_hand
	self._picked_actor_string = "picked_actor" .. wand_hand
	self._grip_node = "j_" .. wand_hand .. "handmiddle1"
	self._ctrl_offset = Vector3Box(Vector3(0, 0.045, -0.015))

	self:_setup_unit(unit, settings)

	self._spawn_controller = SpawnController:new(world, input, "system", unit)
	self._last_grip_state = "nothing"
	self._line_object = World.create_line_object(world)
	self._closest_overlap_unit = nil
	self._closest_overlap_distance = math.huge

	local radius = 0.1

	self._collision_overlap_radius = radius

	self._collision_overlap_callback = function (actors)
		local wand_pos = self:_grip_position()
		local closest_dist = math.huge

		for _, actor in pairs(actors) do
			local unit = Actor.unit(actor)

			if unit then
				if ScriptUnit.has_extension(unit, "interactable_system") then
					Unit.set_data(unit, self._picked_actor_string, actor)

					local dist = Vector3.distance(wand_pos, Actor.center_of_mass(actor))

					if dist < closest_dist then
						self._closest_overlap_unit = unit
						closest_dist = dist
					end
				else
					printf("Warning! wand overlap hit %q but it does not have \"InteractableExtension\" in script data.", Unit.debug_name(unit))
				end
			end
		end

		if self._closest_overlap_unit then
			self._closest_overlap_distance = math.max(closest_dist, radius)
		end
	end

	self._laser = Laser:new(world, input, "touch_up", unit)
end

WandExtension._setup_unit = function (self, unit, wand_settings)
	local wand_unit_name = wand_settings.unit_name
	local wand_pos_offset = wand_settings.pos_offset
	local wand_rot_offset = wand_settings.rot_offset
	local pos_offset = Vector3(wand_pos_offset[1], wand_pos_offset[2], wand_pos_offset[3])

	self._wand_pos_offset = Vector3Box(pos_offset)

	local rot_offset = Quaternion.from_euler_angles_xyz(wand_rot_offset[1], wand_rot_offset[2], wand_rot_offset[3])

	self._wand_rot_offset = QuaternionBox(rot_offset)

	local base_pose = self._wand_input:pose()
	local wand_pose = self:_calculate_wand_pose(base_pose, rot_offset, pos_offset)

	Unit.set_local_pose(unit, 1, wand_pose)

	self._attach_node = Unit.node(unit, "j_weaponattach")

	self._wand_input:set_wand_unit(unit)
end

WandExtension.update = function (self, unit, dt, t)
	self:_update_wand_position()
	self:_update_grip()
	self._laser:update(dt)

	if script_data.debug_spawning and self._spawn_controller then
		self._spawn_controller:update(dt, t)
	end

	if DEBUG then
		LineObject.reset(self._line_object)

		local pos = self._wand_input:position()

		LineObject.add_sphere(self._line_object, Color(255, 255, 0), pos, 0.03)
		LineObject.dispatch(self._world, self._line_object)
	end
end

WandExtension._calculate_wand_pose = function (self, base_pose, rotation_offset, position_offset)
	local rotation = Quaternion.multiply(Matrix4x4.rotation(base_pose), rotation_offset)
	local additional_rotation_offset = self._wand_input:get_additional_rotation_offset()

	if additional_rotation_offset then
		rotation = Quaternion.multiply(rotation, additional_rotation_offset)
	end

	local wand_pose = Matrix4x4.from_quaternion_position(rotation, Matrix4x4.transform(base_pose, position_offset))

	return wand_pose
end

WandExtension._update_wand_position = function (self)
	local base_pose = self._wand_input:pose()
	local wand_pose = self:_calculate_wand_pose(base_pose, self._wand_rot_offset:unbox(), self._wand_pos_offset:unbox())

	self:_update_game_object(wand_pose)
	Unit.set_local_pose(self._unit, 1, wand_pose)
end

WandExtension._update_game_object = function (self, wand_pose)
	local network_manager = Managers.state.network
	local in_session = network_manager and network_manager:state() == "in_session"

	if in_session and self._game_object_id then
		local session = network_manager:session()
		local position = Matrix4x4.translation(wand_pose)
		local rotation = Matrix4x4.rotation(wand_pose)
		local object_id = self._game_object_id

		GameSession.set_game_object_field(session, object_id, "position", position)
		GameSession.set_game_object_field(session, object_id, "rotation", rotation)
	elseif in_session then
		local session = network_manager:session()
		local position = Matrix4x4.translation(wand_pose)
		local rotation = Matrix4x4.rotation(wand_pose)
		local wand_index = WandUnitLookup[self._wand_hand]
		local id = network_manager:create_game_object("wand", {
			position = position,
			rotation = rotation,
			type_index = wand_index
		}, self._unit)

		network_manager:set_game_object_unit(self._unit, id)

		self._game_object_id = id
	end
end

WandExtension._grip_position = function (self)
	return self._wand_input:wand_unit_position(self._grip_node)
end

WandExtension._update_grip = function (self)
	local interactable_system = Managers.state.extension:system("interactable_system")

	if not interactable_system then
		return
	end

	if not self._held_item then
		if self._last_grip_state == "nothing" then
			local closest_item, _ = self:_find_closest_unit(interactable_system, self._wand_input, self._wand_hand)

			if closest_item then
				local can_interact, interaction_type = interactable_system:can_interact(closest_item, self._wand_input)

				if can_interact then
					self:_grab_item(closest_item, interaction_type)
				end
			end
		end
	elseif self._last_grip_state == "gripping" then
		local held_item = self._held_item

		if held_item then
			local should_drop = interactable_system:should_drop(held_item, self._wand_input)

			if should_drop then
				self:_drop_item()
			end
		end
	end

	self._closest_overlap_unit = nil
	self._closest_overlap_distance = math.huge
end

WandExtension._interaction_position = function (self, extension, unit)
	if extension.interaction_position then
		return extension:interaction_position()
	else
		return Unit.world_position(unit, 1)
	end
end

WandExtension._interaction_radius = function (self, extension, unit)
	if extension.interaction_radius then
		return extension:interaction_radius()
	else
		return 0.1
	end
end

WandExtension._find_closest_unit = function (self, interactable_system)
	if DEBUG then
		LineObject.reset(self._line_object)
	end

	local world = self._world
	local wand_pos = self:_grip_position()

	PhysicsWorld.overlap(self._physics_world, self._collision_overlap_callback, "shape", "sphere", "position", wand_pos, "size", self._collision_overlap_radius, "collision_filter", "filter_minor_check")

	if DEBUG then
		LineObject.add_sphere(self._line_object, Color(255, 128, 128), wand_pos, 0.1)
	end

	local closest_unit = self._closest_overlap_unit
	local closest_distance = self._closest_overlap_distance or math.huge

	for unit, extension in pairs(interactable_system:unit_extension_data()) do
		if not extension.FIND_WITH_OVERLAP then
			local pos = self:_interaction_position(extension, unit)

			if DEBUG then
				LineObject.add_sphere(self._line_object, Color(255, 255, 255), pos, 0.05)
			end

			local distance = Vector3.distance(wand_pos, pos)
			local max_distance = self:_interaction_radius(extension, unit)

			if distance <= max_distance and distance < closest_distance then
				closest_distance = distance
				closest_unit = unit
			end
		end
	end

	if DEBUG then
		LineObject.dispatch(self._world, self._line_object)
	end

	return closest_unit, closest_distance
end

WandExtension.cb_interaction_request_result = function (self, confirmed)
	if confirmed then
		self._last_grip_state = "gripping"
	else
		self._last_grip_state = "nothing"

		local item = self._held_item

		self._held_item = nil
	end
end

WandExtension._grab_item = function (self, item, interaction_type)
	self._held_item = item
	self._last_grip_state = "requesting"

	local interactable_system = Managers.state.extension:system("interactable_system")

	interactable_system:interaction_started(item, self._wand_input, self._unit, self._wand_hand, self._attach_node, interaction_type, callback(self, "cb_interaction_request_result"))

	local outline_system = Managers.state.extension:system("outline_system")

	if outline_system then
		outline_system:disable_highlight(item)
	end

	Unit.flow_event(self._unit, "close_hand_sound")
end

WandExtension.destroy = function (self)
	if self._last_grip_state == "gripping" then
		self:_drop_item()
	end
end

WandExtension._drop_item = function (self)
	self._last_grip_state = "nothing"

	local item = self._held_item

	self._held_item = nil

	local interactable_system = Managers.state.extension:system("interactable_system")
	local enable_highlight = interactable_system:interaction_ended(item, self._wand_input, self._unit, self._wand_hand)
	local outline_system = Managers.state.extension:system("outline_system")

	if outline_system and enable_highlight then
		outline_system:enable_highlight(item)
	end

	Unit.flow_event(self._unit, "open_hand_sound")
end

WandExtension.trigger_feedback = function (self, duration)
	self._wand_input:trigger_feedback(duration)
end
