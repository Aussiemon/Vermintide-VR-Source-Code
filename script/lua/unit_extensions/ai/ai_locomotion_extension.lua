﻿-- chunkname: @script/lua/unit_extensions/ai/ai_locomotion_extension.lua

require("script/lua/utils/mover_helper")

local Unit_local_position = Unit.local_position
local DEFAULT_ROTATION_SPEED = 10
local LOCOMOTION_GRAVITY = 20
local ALLOWED_MOVER_MOVE_DISTANCE = 0.5

class("AILocomotionExtension")

AILocomotionExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._system_data = extension_init_data.system_data
	self._unit = unit
	self._world = extension_init_context.world
	self._nav_world = extension_init_data.nav_world

	assert(self._nav_world)

	self._move_speed_var = Unit.animation_find_variable(unit, "move_speed")
	self._velocity = Vector3Box()
	self._update_function_name = "update_script_driven"
	self._debug_color_name = Colors.get_random_color()
	self._wanted_velocity = nil
	self._wanted_rotation = nil
	self._rotation_speed = DEFAULT_ROTATION_SPEED
	self._rotation_speed_modifier = 1
	self._infinite_rotation_speed = false
	self._affected_by_gravity = true
	self._constrained_by_mover = false
	self._constrained_by_players = false
	self._snap_to_navmesh = true
	self._animation_translation_scale = Vector3Box(Vector3(1, 1, 1))
	self._animation_rotation_scale = 1
	self._lerp_rotation = true
	self._is_falling = false
	self._check_falling = true
	self._gravity = LOCOMOTION_GRAVITY
	self.move_speed = 0
	self._system_data.all_update_units[self._unit] = self

	Unit.set_animation_merge_options(unit)

	self._last_fall_position = Vector3Box(10000, 10000, 10000)
	self._mover_state = MoverHelper.create_mover_state()

	local collision_actor_name = "c_mover_collision"
	local has_collision_actor = Unit.actor(unit, collision_actor_name)

	if has_collision_actor then
		self._collision_state = MoverHelper.create_collision_state(unit, collision_actor_name)
	end

	MoverHelper.set_active_mover(unit, self._mover_state, "mover")
	self:set_movement_type("snap_to_navmesh")

	if Managers.state.network then
		self.teleport_to = self.teleport_to_network
	else
		self.teleport_to = self.teleport_to_local
	end
end

AILocomotionExtension.destroy = function (self)
	local system_data = self._system_data
	local unit = self._unit

	system_data.destroy_units[unit] = self
end

AILocomotionExtension.ready = function (self, go_id, blackboard)
	return
end

AILocomotionExtension.hot_join_sync = function (self, sender)
	local unit = self._unit
	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
	local game_object_id = ai_base_extension.game_object_id

	if Unit.has_animation_state_machine(unit) then
		local breed = Unit.get_data(unit, "breed")

		RPC[breed.animation_sync_rpc](sender, game_object_id, Unit.animation_get_state(unit))
	else
		RPC.rpc_hot_join_nail_to_wall_fix(sender, game_object_id)
	end
end

AILocomotionExtension.set_mover_displacement = function (self, displacement, duration)
	if displacement then
		local mover = Unit.mover(self._unit)

		Mover.move(mover, displacement, 0.00390625)

		self._mover_displacement_duration = duration
		self._mover_displacement = Vector3Box(displacement)
		self._mover_displacement_t = duration
	else
		self._mover_displacement = Vector3Box(0, 0, 0)
		self._mover_displacement_duration = nil
		self._mover_displacement_t = nil
	end
end

AILocomotionExtension.teleport_to = function (self, position, rotation)
	assert(true, "function is redefined in init to either *_network or *_local")
end

AILocomotionExtension.teleport_to_network = function (self, position, rotation)
	local unit = self._unit
	local rotation = rotation or Unit.local_rotation(unit, 1)
	local in_session = Managers.state.network and Managers.state.network:state() == "in_session"

	if in_session then
		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
		local game_object_id = ai_base_extension.game_object_id

		Managers.state.network:send_rpc_clients("rpc_teleport_unit_to", game_object_id, position, rotation)

		local session = Managers.state.network:session()
		local has_teleported_value = GameSession.game_object_field(session, game_object_id, "has_teleported")
		local teleports_info = Network.type_info("teleports")

		has_teleported_value = has_teleported_value % teleports_info.max + 1

		GameSession.set_game_object_field(session, game_object_id, "has_teleported", has_teleported_value)
	end

	self:teleport_to_local(position, rotation)
end

AILocomotionExtension.teleport_to_local = function (self, position, rotation)
	local unit = self._unit

	Unit.set_local_position(unit, 1, position)

	if rotation then
		Unit.set_local_rotation(unit, 1, rotation)
	end
end

local ANIMATION_DRIVEN_SCRIPT_DRIVEN_ROTATION_FUNCTION_NAME = "update_animation_driven_movement_script_driven_rotation"
local ANIMATION_DRIVEN_FUNCTION_NAME = "update_animation_driven"
local SCRIPT_DRIVEN_FUNCTION_NAME = "update_script_driven"

AILocomotionExtension.set_animation_driven = function (self, is_animation_driven, is_affected_by_gravity, script_driven_rotation)
	is_affected_by_gravity = is_affected_by_gravity or false

	local unit = self._unit
	local old_func_name = self._update_function_name
	local was_affected_by_gravity = self._affected_by_gravity
	local was_animation_driven = old_func_name == ANIMATION_DRIVEN_FUNCTION_NAME
	local was_animation_driven_script_rot = old_func_name == ANIMATION_DRIVEN_SCRIPT_DRIVEN_ROTATION_FUNCTION_NAME
	local was_script_driven = old_func_name == SCRIPT_DRIVEN_FUNCTION_NAME

	self:set_affected_by_gravity(is_affected_by_gravity)

	local network_manager = Managers.state.network
	local in_session = network_manager and network_manager:state() == "in_session"
	local changed = false
	local system_data = self._system_data

	if is_animation_driven and script_driven_rotation and not was_animation_driven_script_rot then
		self._update_function_name = ANIMATION_DRIVEN_SCRIPT_DRIVEN_ROTATION_FUNCTION_NAME
		system_data.animation_update_units[unit] = nil
		system_data.animation_and_script_update_units[unit] = self

		if in_session then
			local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
			local game_object_id = ai_base_extension.game_object_id
			local position = Unit.local_position(unit, 1)
			local rotation = Unit.local_rotation(unit, 1)

			Managers.state.network:send_rpc_clients("rpc_set_animation_driven_script_movement", game_object_id, position, rotation, is_affected_by_gravity)
		end

		changed = true
	elseif is_animation_driven and not script_driven_rotation and not was_animation_driven then
		self._update_function_name = ANIMATION_DRIVEN_FUNCTION_NAME
		system_data.animation_update_units[unit] = self
		system_data.animation_and_script_update_units[unit] = nil

		if in_session then
			local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
			local game_object_id = ai_base_extension.game_object_id
			local position = Unit.local_position(unit, 1)
			local rotation = Unit.local_rotation(unit, 1)

			Managers.state.network:send_rpc_clients("rpc_set_animation_driven", game_object_id, position, rotation, is_affected_by_gravity)
		end

		changed = true
	elseif not is_animation_driven and not was_script_driven then
		self._update_function_name = SCRIPT_DRIVEN_FUNCTION_NAME
		system_data.animation_update_units[unit] = nil
		system_data.animation_and_script_update_units[unit] = nil

		if in_session then
			local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
			local game_object_id = ai_base_extension.game_object_id

			Managers.state.network:send_rpc_clients("rpc_set_script_driven", game_object_id, is_affected_by_gravity)
		end

		changed = true
	end

	if in_session and not changed and was_affected_by_gravity ~= is_affected_by_gravity then
		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
		local game_object_id = ai_base_extension.game_object_id

		Managers.state.network:send_rpc_clients("rpc_set_affected_by_gravity", game_object_id, is_affected_by_gravity)
	end
end

AILocomotionExtension.set_animation_translation_scale = function (self, animation_translation_scale)
	self._animation_translation_scale:store(animation_translation_scale)
end

AILocomotionExtension.set_animation_rotation_scale = function (self, animation_rotation_scale)
	self._animation_rotation_scale = animation_rotation_scale
end

AILocomotionExtension.set_wanted_velocity_flat = function (self, wanted_velocity)
	wanted_velocity.z = self._velocity.z
	self._wanted_velocity = wanted_velocity
end

AILocomotionExtension.set_wanted_velocity = function (self, wanted_velocity)
	self._wanted_velocity = wanted_velocity

	self._velocity:store(wanted_velocity)
end

AILocomotionExtension.set_wanted_rotation = function (self, rotation)
	self._wanted_rotation = rotation
end

AILocomotionExtension.use_lerp_rotation = function (self, active)
	self._lerp_rotation = active
end

AILocomotionExtension.set_rotation_speed = function (self, rotation_speed)
	if rotation_speed == nil then
		self._rotation_speed = DEFAULT_ROTATION_SPEED
	else
		self._rotation_speed = rotation_speed
	end
end

AILocomotionExtension.set_rotation_speed_modifier = function (self, rotation_speed_modifier, rotation_speed_modifier_lerp_time, start_time)
	self._system_data.rotation_speed_modifier_update_units[self._unit] = self
	self._rotation_speed_modifier = rotation_speed_modifier
	self._rotation_speed_modifier_lerp_start_value = rotation_speed_modifier
	self._rotation_speed_modifier_lerp_start_time = start_time
	self._rotation_speed_modifier_lerp_end_time = start_time + rotation_speed_modifier_lerp_time
end

AILocomotionExtension.set_affected_by_gravity = function (self, affected_by_gravity)
	self._affected_by_gravity = affected_by_gravity

	if affected_by_gravity and self._system_data.snap_to_navmesh_update_units[self._unit] == nil then
		self._system_data.affected_by_gravity_update_units[self._unit] = self
	elseif not affected_by_gravity then
		self._system_data.affected_by_gravity_update_units[self._unit] = nil
	end
end

AILocomotionExtension.set_gravity = function (self, gravity)
	self._gravity = gravity or LOCOMOTION_GRAVITY
end

AILocomotionExtension.set_mover_disable_reason = function (self, reason, state)
	MoverHelper.set_disable_reason(self._unit, self._mover_state, reason, state)
end

AILocomotionExtension.set_check_falling = function (self, state)
	self._check_falling = state
end

AILocomotionExtension.set_collision_disabled = function (self, reason, state)
	if self._collision_state then
		MoverHelper.set_collision_disable_reason(self._unit, self._collision_state, reason, state)
	end
end

AILocomotionExtension.set_movement_type = function (self, movement_type, override_mover_move_distance)
	if movement_type == self.movement_type then
		return
	end

	self.movement_type = movement_type

	local unit = self._unit

	Profiler.start(movement_type)

	if movement_type == "script_driven" then
		self._snap_to_navmesh = false
		self._constrained_by_mover = false
		self._system_data.script_driven_update_units[unit] = self
		self._system_data.snap_to_navmesh_update_units[unit] = nil
		self._system_data.get_to_navmesh_update_units[unit] = nil
		self._system_data.mover_constrained_update_units[unit] = nil
		self._system_data.affected_by_gravity_update_units[unit] = self._affected_by_gravity and self or nil

		MoverHelper.set_disable_reason(unit, self._mover_state, "constrained_by_mover", true)
	elseif movement_type == "snap_to_navmesh" then
		local pos = Unit_local_position(unit, 1)
		local is_position_on_navmesh, altitude = GwNavQueries.triangle_from_position(self._nav_world, pos, 0.5, 0.5)

		if is_position_on_navmesh then
			self._system_data.snap_to_navmesh_update_units[unit] = self
			self._system_data.get_to_navmesh_update_units[unit] = nil
		else
			self._system_data.get_to_navmesh_update_units[unit] = self
			self._system_data.snap_to_navmesh_update_units[unit] = nil
		end

		self._snap_to_navmesh = true
		self._constrained_by_mover = false
		self._system_data.script_driven_update_units[unit] = nil
		self._system_data.mover_constrained_update_units[unit] = nil
		self._system_data.affected_by_gravity_update_units[unit] = nil

		MoverHelper.set_disable_reason(unit, self._mover_state, "constrained_by_mover", true)
	elseif movement_type == "constrained_by_mover" then
		self._snap_to_navmesh = false
		self._constrained_by_mover = true
		self._system_data.script_driven_update_units[unit] = nil
		self._system_data.snap_to_navmesh_update_units[unit] = nil
		self._system_data.get_to_navmesh_update_units[unit] = nil
		self._system_data.mover_constrained_update_units[unit] = self
		self._system_data.affected_by_gravity_update_units[unit] = self._affected_by_gravity and self or nil

		MoverHelper.set_disable_reason(unit, self._mover_state, "constrained_by_mover", false)

		local mover = Unit.mover(unit)
		local allowed_mover_move_distance = override_mover_move_distance or ALLOWED_MOVER_MOVE_DISTANCE
		local is_colliding, colliding_actor, move_vector, new_position = Mover.separate(mover, allowed_mover_move_distance)

		if is_colliding then
			if new_position then
				Mover.set_position(mover, new_position)
			else
				local damage_type = "forced"
				local damage_direction = Vector3(0, 0, -1)

				AiUtils.kill_unit(unit, nil, nil, damage_type, damage_direction)
				Profiler.stop()

				return
			end
		end

		local mover_position = Mover.position(mover)

		Unit.set_local_position(unit, 1, mover_position)

		local physics_world = World.get_data(self._world, "physics_world")
		local size = Vector3(0.5, 1.5, 0.5)
		local rotation = Quaternion.look(Vector3(0, 0, 1))
		local hit_actors, num_hit_actors = PhysicsWorld.immediate_overlap(physics_world, "shape", "capsule", "position", mover_position, "rotation", rotation, "size", size, "collision_filter", "filter_environment_overlap", "use_global_table")

		self._is_falling = num_hit_actors == 0
	end

	Profiler.stop()
end

AILocomotionExtension.set_disabled = function (self)
	assert(not self._disabled, "ai_locomotion_extension disabled extension several times.")

	self._system_data.destroy_units[unit] = self

	MoverHelper.set_disable_reason(unit, self._mover_state, "constrained_by_mover", true)

	self._disabled = true
end

AILocomotionExtension.get_velocity = function (self)
	return self._velocity:unbox()
end

AILocomotionExtension.current_velocity = function (self)
	return self._velocity:unbox()
end

AILocomotionExtension.is_falling = function (self)
	return self._is_falling
end

AILocomotionExtension.get_rotation_speed = function (self)
	return self._rotation_speed
end

AILocomotionExtension.get_rotation_speed_modifier = function (self)
	return self._rotation_speed_modifier
end
