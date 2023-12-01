-- chunkname: @script/lua/unit_extensions/staff_extension.lua

require("settings/staff_settings")
require("script/lua/arrow_handler")
require("script/lua/unit_extensions/staff_ragdoll_puller")

local StaffSettings = StaffSettings
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local VectorField = stingray.VectorField
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
local DEBUG_COLLISION = false
local DEBUG_PROJECTILE = false
local DEBUG_SKULL_DIRECTION = false
local NUM_CACHED_POSITIONS = 4
local CACHE_INTERVAL = 0.05
local OFFSET_HAND_ROT = {
	65,
	0,
	0
}
local NUM_TRACKED_POSITIONS = 4

class("StaffExtension")

StaffExtension.init = function (self, extension_init_context, unit)
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._wwise_world = Wwise.wwise_world(self._world)
	self._level = extension_init_context.level
	self._unit = unit
	self._staff_wand_input = nil
	self._staff_node = 1
	self._skull_node = Unit.has_node(self._unit, "Bone_03") and Unit.node(self._unit, "Bone_03") or Unit.node(self._unit, "fx_03")
	self._projectiles = {}
	self._current_staff_pos = Vector3Box(0, 0, 0)
	self._last_staff_pos = Vector3Box(0, 0, 0)
	self._explosion_impact_pos = Vector3Box(0, 0, 0)

	local min, max = self:_get_world_extents()

	self._min_world_extent = Vector3Box(min)
	self._max_world_extent = Vector3Box(max)

	self:_add_force_vortex_vector_field()
	self:_add_impact_push_vector_field()
	self:_add_off_hand_particle_pull_vector_field()
	self:_add_line_channel_vector_field()

	self._interactors = {}

	if DEBUG_COLLISION then
		self._line_object_collision = World.create_line_object(self._world)
	end

	if DEBUG_PROJECTILE then
		self._line_object_projectile = World.create_line_object(self._world)
	end

	if DEBUG_SKULL_DIRECTION then
		self._line_object_skull = World.create_line_object(self._world)
	end

	self._network_mode = extension_init_context.network_mode
	self._cached_hand_positions = {}
	self._cached_tracking_positions = {}

	for i = 1, NUM_CACHED_POSITIONS do
		self._cached_hand_positions[i] = Vector3Box(0, 0, 0)
		self._cached_tracking_positions[i] = Vector3Box(0, 0, 0)
	end

	self._hand_pos_counter = 1
	self._last_hand_pos_counter = 1
	self._last_hand_pos_index = 1
	self._current_hand_pos_index = 1
	self._overlap_callback = callback(self, "overlap_callback")
	self._callback_context = {
		has_gotten_callback = false,
		num_hits = 0,
		overlap_units = {}
	}
	self._is_interactable = true
	self._tracked_positions = {}
	self._charge_amount = 0
end

StaffExtension.destroy = function (self)
	VectorField.remove(self._charge_lift_vf_id)
	VectorField.remove(self._force_vortex_vf_id)
	VectorField.remove(self._impact_push_vf_id)
	VectorField.remove(self._line_channel_vf_id)

	local staff_vector_field_extension = ScriptUnit.extension(self._unit, "staff_vector_field_system")

	for index, projectile in pairs(self._projectiles) do
		staff_vector_field_extension:remove_projectile(projectile.cloth_vector_field_index)
		World.destroy_unit(self._world, projectile.unit)

		self._projectiles[index] = nil
	end
end

StaffExtension.update = function (self, unit, dt, t)
	self:_handle_input(dt, t)
	self:_update_projectiles(dt, t)
	self:_check_explosion_overlap()

	if self._collecting_charge then
		self:_collect_charge(dt, t)
		self:_update_projectile_position()
		self:_vibrate_charge_staff(dt, t)
		self:_vibrate_charge_off_hand(dt, t)
	end

	if self._releasing_charge then
		self:_update_release_charge(dt, t)
	end

	if self._should_vibrate_pickup_staff then
		self._should_vibrate_pickup_staff = self:_vibrate_pickup_staff(dt, t)
	end

	if self._should_vibrate_pickup_off_hand then
		self._should_vibrate_pickup_off_hand = self:_vibrate_pickup_off_hand(dt, t)
	end

	if self._staff_wand_input then
		local last_staff_pos = self._last_staff_pos:unbox()
		local current_staff_pos = Unit.world_position(self._unit, self._staff_node)
		local distance = Vector3.length(last_staff_pos - current_staff_pos)
		local speed = distance / dt
		local sound_param = math.min(speed / StaffSettings.max_sound_movement_speed * 100, 100)

		self._staff_source = WwiseWorld.make_auto_source(self._wwise_world, self._unit)

		WwiseWorld.set_source_parameter(self._wwise_world, self._staff_source, "fire_movement", sound_param)

		if self._staff_wand_input:held("trigger") then
			if not self._ragdoll_puller then
				self._ragdoll_puller = StaffRagdollPuller:new(self._world, self._unit, self._skull_node, self._staff_wand_unit, self._staff_attach_node, self._staff_node, self._min_world_extent, self._max_world_extent)
			end

			self._ragdoll_puller:update(dt, t)
		elseif self._ragdoll_puller then
			self._ragdoll_puller:destroy()

			self._ragdoll_puller = nil
		end

		self._last_staff_pos = Vector3Box(current_staff_pos)

		self:_update_off_hand_particle_pull()
	end

	if self._time_to_play_explosion_effect then
		self._time_to_play_explosion_effect = self._time_to_play_explosion_effect - dt

		if self._time_to_play_explosion_effect <= 0 then
			self:_reset_impact_vector_field_data()
			self:_apply_impact_vector_field(dt, t)

			self._time_to_play_explosion_effect = nil
		end
	end
end

StaffExtension._update_off_hand_particle_pull = function (self)
	local this_wand_hand = self._staff_wand_input:wand_hand()
	local other_wand_hand = "left"

	if this_wand_hand == "left" then
		other_wand_hand = "right"
	end

	local vr_controller = Managers.vr:get_vr_controller()
	local off_hand_wand = vr_controller:get_wand(other_wand_hand)
	local off_hand_wand_input = off_hand_wand:input()
	local off_hand_wand_pos = off_hand_wand_input:wand_unit_position("j_weaponattach")
	local skull_pos = Unit.world_position(self._unit, self._skull_node)
	local dir = off_hand_wand_pos - skull_pos
	local length = Vector3.length(dir)
	local strength = 100 * (1 - math.clamp((length - 0.3) / 0.2, 0, 1))
	local speed = -strength / 12
	local position, _, settings = self:_dynamic_parameters()
	local radius = 2
	local parameters = {
		center = off_hand_wand_pos,
		radius = Vector4(radius, radius, radius, radius),
		speed = Vector4(speed, speed, speed, speed)
	}

	VectorField.change(self._off_hand_pull_vf, self._off_hand_pull_vf_id, "vector_fields/magic_pull_push", parameters, settings)

	local normalized_dir = Vector3.normalize(dir)
	local parameters = {
		point1 = skull_pos,
		dir = normalized_dir,
		strength = Vector4(strength, strength, strength, strength)
	}
	local min_x = (skull_pos.x < off_hand_wand_pos.x and skull_pos.x or off_hand_wand_pos.x) - 0.3
	local max_x = (skull_pos.x > off_hand_wand_pos.x and skull_pos.x or off_hand_wand_pos.x) + 0.3
	local min_y = (skull_pos.y < off_hand_wand_pos.y and skull_pos.y or off_hand_wand_pos.y) - 0.3
	local max_y = (skull_pos.y > off_hand_wand_pos.y and skull_pos.y or off_hand_wand_pos.y) + 0.3
	local min_z = (skull_pos.z < off_hand_wand_pos.z and skull_pos.z or off_hand_wand_pos.z) - 0.3
	local max_z = (skull_pos.z > off_hand_wand_pos.z and skull_pos.z or off_hand_wand_pos.z) + 0.3

	settings.min = Vector3(min_x, min_y, min_z)
	settings.max = Vector3(max_x, max_y, max_z)

	VectorField.change(self._line_channel_vf, self._line_channel_vf_id, "vector_fields/towards_line", parameters, settings)
end

StaffExtension._reset_off_hand_particle_pull = function (self)
	local position, _, settings = self:_dynamic_parameters()
	local parameters = {
		center = position,
		radius = Vector4(1, 1, 1, 1),
		speed = Vector4(0, 0, 0, 0)
	}

	VectorField.change(self._off_hand_pull_vf, self._off_hand_pull_vf_id, "vector_fields/magic_pull_push", parameters, settings)
end

StaffExtension._handle_input = function (self, dt, t)
	if self._off_hand_wand_input then
		local tracking_space_pose = Managers.vr:tracking_space_pose()
		local tracking_space_pos = Matrix4x4.translation(tracking_space_pose)
		local hand_pos = Unit.world_position(self._off_hand_wand_unit, self._off_hand_attach_node)
		local cache_timer = self._cache_timer or 0

		cache_timer = cache_timer + dt

		if cache_timer >= CACHE_INTERVAL then
			self._last_hand_pos_index = self._current_hand_pos_index
			self._current_hand_pos_index = self._current_hand_pos_index + 1 <= NUM_CACHED_POSITIONS and self._current_hand_pos_index + 1 or 1

			self._cached_hand_positions[self._current_hand_pos_index]:store(hand_pos)
			self._cached_tracking_positions[self._current_hand_pos_index]:store(tracking_space_pos)

			cache_timer = 0
		end

		self._cache_timer = cache_timer
	end
end

StaffExtension._apply_force_vortex_vector_field = function (self, dt, t)
	PhysicsWorld.wake_actors(self._physics_world, "filter_staff_magic", self._min_world_extent:unbox(), self._max_world_extent:unbox())
	PhysicsWorld.apply_wind(self._physics_world, self._force_vortex_vf, "filter_staff_magic")
end

StaffExtension._apply_impact_vector_field = function (self, dt, t)
	PhysicsWorld.wake_actors(self._physics_world, "filter_staff_magic", self._min_world_extent:unbox(), self._max_world_extent:unbox())
	PhysicsWorld.apply_wind(self._physics_world, self._impact_push_vf, "filter_staff_magic")
end

StaffExtension._play_explosion_effect = function (self, position, projectile_unit)
	Unit.flow_event(projectile_unit, "lua_hit_target")
	self:_set_impact_vector_field_data(position)
	self:_apply_impact_vector_field()
	WwiseWorld.trigger_event(self._wwise_world, "Play_fireball_big_hit", position)

	self._time_to_play_explosion_effect = StaffSettings.impact_explosion.time_to_play
end

StaffExtension._set_impact_vector_field_data = function (self, position)
	local _, _, settings = self:_dynamic_parameters()
	local radius = StaffSettings.impact_explosion.max_radius
	local speed = StaffSettings.impact_explosion.max_force
	local parameters = {
		center = Vector4(position.x, position.y, position.z, 0),
		radius = Vector4(radius, radius, radius, radius),
		speed = Vector4(speed, speed, speed, speed)
	}

	VectorField.change(self._impact_push_vf, self._impact_push_vf_id, "vector_fields/magic_pull_push", parameters, settings)
end

StaffExtension._reset_impact_vector_field_data = function (self, position)
	local position, _, settings = self:_dynamic_parameters()
	local parameters = {
		center = position,
		radius = Vector4(1, 1, 1, 1),
		speed = Vector4(0, 0, 0, 0)
	}

	VectorField.change(self._impact_push_vf, self._impact_push_vf_id, "vector_fields/magic_pull_push", parameters, settings)
end

StaffExtension._collect_charge = function (self, dt, t)
	if self._charge_amount < StaffSettings.charge_time then
		self._charge_amount = self._charge_amount + dt
	end

	self._charge_percentage = self._charge_amount / StaffSettings.charge_time

	if not Unit.alive(self._off_hand_wand_unit) then
		return
	end

	local hand_pos = Unit.world_position(self._off_hand_wand_unit, self._off_hand_attach_node)
	local particle_extension = ScriptUnit.extension(self._unit, "particle_system")

	particle_extension:set_charge_percentage(self._charge_percentage)
	particle_extension:set_hand_position(hand_pos)

	local staff_vector_field_extension = ScriptUnit.extension(self._unit, "staff_vector_field_system")

	staff_vector_field_extension:set_charge_percentage(self._charge_percentage)
	staff_vector_field_extension:set_hand_position(hand_pos)

	if self._projectile then
		local min_scale = StaffSettings.projectile_scale_min
		local max_scale = StaffSettings.projectile_scale_max
		local lerp_scale = math.lerp(min_scale, max_scale, self._charge_percentage)
		local new_scale = Vector3(1, 1, 1) * lerp_scale

		Unit.set_local_scale(self._projectile, 1, new_scale)

		local sound_param = self._charge_percentage * 100

		self._off_hand_source = WwiseWorld.make_auto_source(self._wwise_world, self._projectile)

		WwiseWorld.set_source_parameter(self._wwise_world, self._off_hand_source, "fire_size", sound_param)

		if self._charge_amount > StaffSettings.fire_skull_sound_time and not self._played_skull_spawn_sound then
			self._played_skull_spawn_sound = true

			WwiseWorld.trigger_event(self._wwise_world, "Play_weapon_stuff_fire_skull_spawn", self._off_hand_source)
		end
	end
end

StaffExtension._get_adjusted_throw_direction = function (self, original_direction)
	local hmd_pose = Managers.vr:hmd_world_pose()
	local hmd_pos = Matrix4x4.translation(hmd_pose.head)
	local look_dir = Vector3.normalize(hmd_pose.forward)
	local _, look_target_pos, _, _, _ = PhysicsWorld.raycast(self._physics_world, hmd_pos, look_dir, 100, "closest", "collision_filter", "filter_arrow")
	local dot = Vector3.dot(original_direction, look_dir)
	local angle = math.radians_to_degrees(math.acos(dot))
	local percentage = 1 - angle / StaffSettings.hmd_forward_influence.half_angle
	local adjusted_throw_dir = Vector3.lerp(original_direction, look_dir, StaffSettings.hmd_forward_influence.look * percentage)

	adjusted_throw_dir = Vector3.normalize(adjusted_throw_dir)
	look_target_pos = look_target_pos or hmd_pos + look_dir * 25

	return adjusted_throw_dir, look_target_pos
end

StaffExtension._get_delayed_throw_length = function (self)
	local current_hand_pos = self._tracked_positions[NUM_TRACKED_POSITIONS]
	local oldest_hand_pos = self._tracked_positions[1]
	local hand_vector = current_hand_pos - oldest_hand_pos
	local tracking_vector = current_tracking_pos - oldest_tracking_pos
	local throw_length = Vector3.length(hand_vector - tracking_vector)

	return throw_length / 0.011111111111111112
end

StaffExtension._get_throw_length = function (self)
	local current_hand_pos = self._cached_hand_positions[self._current_hand_pos_index]:unbox()
	local current_tracking_pos = self._cached_tracking_positions[self._current_hand_pos_index]:unbox()
	local oldest_hand_pos_index = self._current_hand_pos_index + 1 <= NUM_CACHED_POSITIONS and self._current_hand_pos_index + 1 or 1
	local oldest_hand_pos = self._cached_hand_positions[oldest_hand_pos_index]:unbox()
	local oldest_tracking_pos = self._cached_tracking_positions[oldest_hand_pos_index]:unbox()
	local hand_vector = current_hand_pos - oldest_hand_pos
	local tracking_vector = current_tracking_pos - oldest_tracking_pos
	local throw_length = Vector3.length(hand_vector - tracking_vector)

	return throw_length / 0.011111111111111112
end

StaffExtension._get_delayed_throw_direction = function (self)
	local current_hand_pos = self._tracked_positions[NUM_TRACKED_POSITIONS]
	local oldest_hand_pos = self._tracked_positions[1]
	local hand_vector = current_hand_pos - oldest_hand_pos
	local tracking_vector = current_tracking_pos - oldest_tracking_pos
	local throw_dir = Vector3.normalize(hand_vector - tracking_vector)
	local adjusted_throw_dir, look_target_pos = self:_get_adjusted_throw_direction(throw_dir)

	return adjusted_throw_dir, look_target_pos
end

StaffExtension._get_throw_direction = function (self)
	local current_hand_pos = self._cached_hand_positions[self._current_hand_pos_index]:unbox()
	local current_tracking_pos = self._cached_tracking_positions[self._current_hand_pos_index]:unbox()
	local oldest_hand_pos_index = self._current_hand_pos_index + 1 <= NUM_CACHED_POSITIONS and self._current_hand_pos_index + 1 or 1
	local oldest_hand_pos = self._cached_hand_positions[oldest_hand_pos_index]:unbox()
	local oldest_tracking_pos = self._cached_tracking_positions[oldest_hand_pos_index]:unbox()
	local hand_vector = current_hand_pos - oldest_hand_pos
	local tracking_vector = current_tracking_pos - oldest_tracking_pos
	local throw_dir = Vector3.normalize(hand_vector - tracking_vector)
	local adjusted_throw_dir, look_target_pos = self:_get_adjusted_throw_direction(throw_dir)

	return adjusted_throw_dir, look_target_pos
end

StaffExtension.delayed_release_charge = function (self)
	table.clear(self._tracked_positions)

	self._current_tracked_index = 1
	self._releasing_charge = true
end

StaffExtension._update_release_charge = function (self, dt, t)
	local this_wand_hand = self._staff_wand_input:wand_hand()
	local other_wand_hand = "left"

	if this_wand_hand == "left" then
		other_wand_hand = "right"
	end

	local vr_controller = Managers.vr:get_vr_controller()
	local off_hand_wand = vr_controller:get_wand(other_wand_hand)
	local off_hand_wand_input = off_hand_wand:input()
	local off_hand_wand_pos = off_hand_wand_input:wand_unit_position("j_weaponattach")

	self._tracked_positions[self._current_tracked_index] = off_hand_wand_pos
	self._current_tracked_index = self._current_tracked_index + 1

	if self._current_tracked_index > NUM_TRACKED_POSITIONS then
		self:_release_charge()

		self._releasing_charge = nil
	end
end

StaffExtension._release_charge = function (self)
	if self._charge_amount <= 0 then
		return
	end

	local particle_extension = ScriptUnit.extension(self._unit, "particle_system")

	particle_extension:set_charge_percentage(0)
	particle_extension:set_hand_position(nil)
	particle_extension:set_collecting(false)

	local staff_vector_field_extension = ScriptUnit.extension(self._unit, "staff_vector_field_system")

	staff_vector_field_extension:set_charge_percentage(0)
	staff_vector_field_extension:set_hand_position(nil)
	staff_vector_field_extension:set_collecting(false)
	WwiseWorld.trigger_event(self._wwise_world, "Stop_combat_weapon_staff_hold_fire_ball", self._fireball_audio_source)

	self._fireball_audio_source = nil

	local throw_length = self:_get_throw_length()
	local throw_ok = throw_length > StaffSettings.min_throw_length
	local charge_ok = self._charge_amount > StaffSettings.min_charge_time

	if self._staff_wand_input and self._off_hand_wand_input then
		if throw_ok and charge_ok then
			local position = self._off_hand_wand_input:wand_unit_position()
			local direction, look_target_pos = self:_get_throw_direction()

			if self._network_mode == "server" then
				self:fire(position, direction, look_target_pos, true, Network.peer_id())

				local unit_index = Unit.get_data(self._unit, "unit_index")

				Managers.state.network:send_rpc_clients("rpc_client_fire", unit_index, position, direction, look_target_pos)
			elseif self._network_mode == "client" then
				local unit_index = Unit.get_data(self._unit, "unit_index")

				Managers.state.network:send_rpc_session_host("rpc_server_request_fire", unit_index, position, direction, look_target_pos)
			else
				self:fire(position, direction, look_target_pos, true)
			end
		elseif self._network_mode == "server" then
			self:cancel_fire()

			local unit_index = Unit.get_data(self._unit, "unit_index")

			Managers.state.network:send_rpc_clients("rpc_client_cancel_fire", unit_index)
		elseif self._network_mode == "client" then
			local unit_index = Unit.get_data(self._unit, "unit_index")

			Managers.state.network:send_rpc_session_host("rpc_server_cancel_fire", unit_index)
		else
			self:cancel_fire()
		end
	end

	Unit.animation_event(self._off_hand_wand_unit, "relax")
end

StaffExtension._spawn_projectile = function (self)
	self._projectile = World.spawn_unit(self._world, "units/weapons/player/wpn_screaming_skull/wpn_screaming_skull")

	Unit.flow_event(self._projectile, "lua_projectile_init")

	self._fireball_audio_source = WwiseWorld.make_auto_source(self._wwise_world, self._projectile)

	WwiseWorld.trigger_event(self._wwise_world, "Play_combat_weapon_staff_hold_fire_ball", self._fireball_audio_source)
	self:_update_projectile_position()
end

StaffExtension._update_projectile_position = function (self)
	if self._projectile then
		local hmd_pose = Managers.vr:hmd_world_pose()
		local hmd_pos = Matrix4x4.translation(hmd_pose.head)
		local hand_pos = Unit.world_position(self._off_hand_wand_unit, self._off_hand_attach_node)
		local look_dir = Vector3.normalize(hmd_pos - hand_pos)
		local look = Quaternion.look(look_dir, Vector3.up())

		if DEBUG_SKULL_DIRECTION then
			LineObject.reset(self._line_object_skull)
			LineObject.add_line(self._line_object_skull, Color(255, 255, 255), hand_pos - look_dir, hand_pos + look_dir)
			LineObject.dispatch(self._world, self._line_object_skull)
			LineObject.reset(self._line_object_skull)
		end

		Unit.set_local_position(self._projectile, 1, hand_pos)
		Unit.set_local_rotation(self._projectile, 1, look)
	end
end

StaffExtension.cancel_fire = function (self)
	Unit.flow_event(self._projectile, "cancel_throw")
	Unit.flow_event(self._projectile, "lua_remove")

	self._projectile = nil
	self._charge_amount = 0
	self._charge_pull_position = nil
end

local MAX_FIREBALLS = 3

StaffExtension.fire = function (self, source_pos, dir_normalized, look_target_pos, do_damage, peer_id)
	local look = Quaternion.look(dir_normalized, Vector3.up())

	Unit.set_local_rotation(self._projectile, 1, look)

	local projectile = self._projectile

	self._projectile = nil

	for ii = 1, Unit.num_actors(projectile) do
		local actor = Unit.actor(projectile, ii)

		if actor and Actor.is_dynamic(actor) then
			Actor.set_scene_query_enabled(actor, false)
			Actor.set_collision_enabled(actor, false)
			Actor.set_gravity_enabled(actor, false)
		end
	end

	Unit.flow_event(projectile, "lua_trail")

	local staff_vector_field_extension = ScriptUnit.extension(self._unit, "staff_vector_field_system")
	local charge_percentage = self._charge_percentage
	local min_speed = StaffSettings.projectile_speed_min
	local max_speed = StaffSettings.projectile_speed_max
	local lerp_speed = math.lerp(max_speed, min_speed, charge_percentage)
	local force_multiplier = math.map_range(lerp_speed, min_speed, max_speed, 1, 2)
	local index = staff_vector_field_extension:add_projectile(source_pos, force_multiplier)
	local min_impact_radius = StaffSettings.impact_damage_radius_min
	local max_impact_radius = StaffSettings.impact_damage_radius_max
	local lerp_impact_radius = math.lerp(min_impact_radius, max_impact_radius, charge_percentage)
	local min_flight_radius = StaffSettings.flight_damage_radius_min
	local max_flight_radius = StaffSettings.flight_damage_radius_max
	local lerp_flight_radius = math.lerp(min_flight_radius, max_flight_radius, charge_percentage)
	local min_gravity = StaffSettings.gravity_min
	local max_gravity = StaffSettings.gravity_max
	local lerp_gravity = math.lerp(max_gravity, min_gravity, charge_percentage)
	local min_spiral_speed = StaffSettings.min_spiral_speed
	local max_spiral_speed = StaffSettings.max_spiral_speed
	local lerp_spiral = math.lerp(max_spiral_speed, min_spiral_speed, charge_percentage)
	local particle_spacing = 5

	self._projectiles[#self._projectiles + 1] = {
		flight_time = 0,
		flight_distance = 0,
		unit = projectile,
		velocity = Vector3Box(dir_normalized * lerp_speed),
		position = Vector3Box(Unit.world_position(projectile, 1)),
		speed = lerp_speed,
		impact_damage_radius = lerp_impact_radius,
		flight_damage_radius = lerp_flight_radius,
		gravity = lerp_gravity,
		spiral_speed = lerp_spiral,
		look_target_pos = Vector3Box(look_target_pos),
		do_damage = do_damage,
		cloth_vector_field_index = index,
		damaged_units = {},
		next_particles = particle_spacing,
		particle_spacing = particle_spacing
	}

	WwiseWorld.trigger_event(self._wwise_world, "Play_combat_weapon_staff_fire_fireball_small", source_pos)

	self._charge_amount = 0
	self._charge_pull_position = nil

	if table.size(self._projectiles) > MAX_FIREBALLS then
		local oldest
		local oldest_time = -math.huge

		for index, projectile in pairs(self._projectiles) do
			if oldest_time < projectile.flight_time then
				oldest_time = projectile.flight_time
				oldest = index
			end
		end

		if oldest then
			local staff_vector_field_extension = ScriptUnit.extension(self._unit, "staff_vector_field_system")
			local projectile = self._projectiles[oldest]

			staff_vector_field_extension:remove_projectile(projectile.cloth_vector_field_index)
			World.destroy_unit(self._world, projectile.unit)

			self._projectiles[oldest] = nil

			print("destroying", table.size(self._projectiles) + 1)
		end
	end
end

StaffExtension.overlap_callback = function (self, actors)
	local callback_context = self._callback_context

	callback_context.has_gotten_callback = true

	local overlap_units = callback_context.overlap_units

	for k, actor in pairs(actors) do
		callback_context.num_hits = callback_context.num_hits + 1

		if overlap_units[callback_context.num_hits] == nil then
			overlap_units[callback_context.num_hits] = ActorBox()
		end

		overlap_units[callback_context.num_hits]:store(actor)
	end
end

StaffExtension._check_explosion_overlap = function (self)
	local callback_context = self._callback_context

	if callback_context.has_gotten_callback then
		local num_actors = callback_context.num_hits
		local actors = callback_context.overlap_units
		local impact_pos

		impact_pos = self._explosion_impact_pos:unbox()

		for i = 1, num_actors do
			repeat
				local hit_actor = actors[i]:unbox()
				local hit_unit = Actor.unit(hit_actor)

				if hit_unit then
					local actor_pos = Actor.position(hit_actor)
					local hit_unit_node_index = Actor.node(hit_actor)
					local dir = Vector3.normalize(actor_pos - impact_pos)
					local has_health_extension = ScriptUnit.has_extension(hit_unit, "health_system")
					local do_damage = self._network_mode == "server" or self._network_mode == nil

					if has_health_extension and do_damage then
						local health_extension = ScriptUnit.extension(hit_unit, "health_system")

						if health_extension:is_alive() then
							local peer_id = self._owner_peer_id
							local params = {
								hit_direction = dir,
								hit_force = StaffSettings.impact_force,
								hit_node_index = hit_unit_node_index,
								peer_id = peer_id,
								force_dismember = StaffSettings.always_dismember_impact
							}

							health_extension:add_damage(StaffSettings.impact_damage, params)
						end

						do break end
						break
					end
				end
			until true
		end

		callback_context.has_gotten_callback = false
		callback_context.num_hits = 0
		callback_context.overlap_units = {}
	end
end

StaffExtension._update_projectiles = function (self, dt, t)
	if DEBUG_PROJECTILE then
		LineObject.reset(self._line_object_projectile)
	end

	local staff_vector_field_extension = ScriptUnit.extension(self._unit, "staff_vector_field_system")

	for index, projectile in pairs(self._projectiles) do
		local flight_time = projectile.flight_time
		local projectile_unit = projectile.unit
		local do_damage = projectile.do_damage
		local old_pos = projectile.position:unbox()
		local speed = projectile.speed
		local spiral_speed = projectile.spiral_speed
		local impact_damage_radius = projectile.impact_damage_radius
		local flight_damage_radius = projectile.flight_damage_radius
		local gravity = projectile.gravity
		local velocity = projectile.velocity:unbox()
		local dir_n = velocity / speed
		local target_pos = projectile.look_target_pos:unbox()
		local target_velocity = target_pos - old_pos
		local wanted_dir = Vector3.normalize(target_velocity)
		local current_rot = Quaternion.look(dir_n)
		local wanted_rot = Quaternion.look(wanted_dir)
		local new_rot = Quaternion.lerp(current_rot, wanted_rot, StaffSettings.hmd_forward_influence.seek * StaffSettings.hmd_forward_influence.seek_modifier * dt)
		local new_dir = Quaternion.forward(new_rot)
		local spiral_percentage = math.min(flight_time / StaffSettings.spiral_expansion_time, 1)
		local spiral_radius = flight_damage_radius * spiral_percentage * 0.5
		local v1 = Vector3.normalize(Vector3.cross(new_dir, Vector3(1, 0, 0)))
		local v2 = Vector3.normalize(Vector3.cross(new_dir, v1))
		local x = spiral_radius * math.cos(math.pi * flight_time * spiral_speed)
		local y = spiral_radius * math.sin(math.pi * flight_time * spiral_speed)
		local z = flight_time * new_dir
		local new_velocity = new_dir * speed

		new_velocity.z = new_velocity.z - gravity * dt

		local new_pos = old_pos + new_velocity * dt

		projectile.velocity:store(new_velocity)
		projectile.position:store(new_pos)

		local visual_pos = new_pos + v1 * x + v2 * y

		if DEBUG_PROJECTILE then
			LineObject.add_line(self._line_object_projectile, Color(255, 255, 255), old_pos, old_pos + new_dir)
			LineObject.add_line(self._line_object_projectile, Color(255, 0, 0), old_pos, old_pos + v1)
			LineObject.add_line(self._line_object_projectile, Color(0, 255, 0), old_pos, old_pos + v2)
		end

		local hits = self:_check_collision(old_pos, new_pos, flight_damage_radius)
		local hit_something = false

		if hits and #hits > 0 then
			local new_hits = {}

			for _, hit in ipairs(hits) do
				local actor = hit.actor
				local unit = Actor.unit(actor)

				if not new_hits[unit] then
					new_hits[unit] = hit
				end
			end

			for _, hit in pairs(new_hits) do
				repeat
					local hit_actor = hit.actor
					local hit_distance = hit.distance
					local hit_normal = hit.normal
					local hit_pos = hit.position
					local hit_unit = Actor.unit(hit_actor)

					if hit_unit then
						local hit_unit_node_index = Actor.node(hit_actor)
						local has_health_extension = ScriptUnit.has_extension(hit_unit, "health_system")

						if has_health_extension then
							local health_extension = ScriptUnit.extension(hit_unit, "health_system")

							if health_extension:is_alive() and not projectile.damaged_units[hit_unit] and do_damage then
								local peer_id = self._owner_peer_id
								local params = {
									hit_direction = new_dir,
									hit_force = StaffSettings.flight_force,
									hit_node_index = hit_unit_node_index,
									peer_id = peer_id,
									force_dismember = StaffSettings.always_dismember_flight
								}

								health_extension:add_damage(StaffSettings.flight_damage, params)

								projectile.damaged_units[hit_unit] = true
							else
								break
							end
						end

						if ScriptUnit.has_extension(hit_unit, "ragdoll_system") then
							local ragdoll_extension = ScriptUnit.extension(hit_unit, "ragdoll_system")

							if ragdoll_extension.spawn_burst then
								ragdoll_extension:spawn_burst()
							end
						end

						if Unit.alive(hit_unit) then
							local is_enemy = Unit.get_data(hit_unit, "breed")

							if not is_enemy then
								self:_hit_level_unit(hit_pos, new_dir, hit_normal, hit_unit)

								for ii = 1, Unit.num_actors(projectile_unit) do
									local actor = Unit.actor(projectile_unit, ii)

									if actor then
										Actor.set_collision_enabled(actor, false)
									end
								end

								hit_something = true
							else
								self:_hit_enemy_unit(hit_pos, new_dir, hit_normal, hit_unit)
							end

							if self._network_mode ~= "client" then
								Unit.set_flow_variable(hit_unit, "hit_actor", hit_actor)
								Unit.set_flow_variable(hit_unit, "hit_direction", new_dir)
								Unit.set_flow_variable(hit_unit, "hit_position", hit_pos)
								Unit.flow_event(hit_unit, "lua_simple_damage")
							end

							Unit.flow_event(hit_unit, "burn")
						end
					end
				until true
			end
		end

		if old_pos.x > 1200 or old_pos.x < -1200 or old_pos.y > 1200 or old_pos.y < -1200 or old_pos.z > 1200 or old_pos.z < -1200 then
			hit_something = true
		end

		if projectile.flight_distance > 100 then
			hit_something = true
		end

		if hit_something then
			self:_play_explosion_effect(new_pos, projectile_unit)
			self:_create_explosion(new_pos, impact_damage_radius)
			staff_vector_field_extension:remove_projectile(projectile.cloth_vector_field_index)
			World.destroy_unit(self._world, projectile_unit)

			self._projectiles[index] = nil
		else
			projectile.flight_time = projectile.flight_time + dt

			Unit.set_local_position(projectile_unit, 1, visual_pos)

			if Managers.differentiation:extra_particle_trail() then
				local distance = Vector3.length(old_pos - new_pos)

				projectile.flight_distance = projectile.flight_distance + distance

				if projectile.next_particles < projectile.flight_distance then
					local particle_id = World.create_particles(self._world, "fx/wpnfx_fireball_projectile", new_pos)

					World.link_particles(self._world, particle_id, projectile_unit, 1, Matrix4x4.identity(), "destroy")

					projectile.next_particles = projectile.flight_distance + projectile.particle_spacing
				end
			end

			local vortex_settings = StaffSettings.projectile_vortex_ragdolls
			local whirl_speed = vortex_settings.whirl_speed
			local pull_speed = vortex_settings.pull_speed
			local radius = vortex_settings.radius
			local position, up, settings = self:_dynamic_parameters()
			local parameters = {
				center = Vector4(new_pos.x, new_pos.y, new_pos.z, 0),
				up = up,
				speed = Vector4(pull_speed, pull_speed, pull_speed, pull_speed),
				radius = Vector4(radius, radius, radius, radius)
			}

			VectorField.change(self._force_vortex_vf, self._force_vortex_vf_id, "vector_fields/magic_pull_push", parameters, settings)
			self:_apply_force_vortex_vector_field(dt, t)
			staff_vector_field_extension:set_projectile_position(new_pos, projectile.cloth_vector_field_index)
		end
	end

	if DEBUG_PROJECTILE then
		LineObject.dispatch(self._world, self._line_object_projectile)
	end
end

StaffExtension._check_collision = function (self, from_pos, to_pos, radius)
	local hits = PhysicsWorld.linear_sphere_sweep(self._physics_world, from_pos, to_pos, radius, 100, "types", "both", "collision_filter", "filter_fireball_no_level")
	local raycast_vector = to_pos - from_pos
	local dir = Vector3.normalize(raycast_vector)
	local length = Vector3.length(raycast_vector)
	local level_hit, level_hit_pos, level_hit_distance, level_hit_normal, level_hit_actor = PhysicsWorld.raycast(self._physics_world, from_pos, dir, length, "closest", "collision_filter", "filter_fireball_no_enemy")
	local level_hit_data = {
		actor = level_hit_actor,
		distance = level_hit_distance,
		normal = level_hit_normal,
		position = level_hit_pos
	}

	if level_hit then
		hits = hits or {}
		hits[#hits + 1] = level_hit_data
	end

	if DEBUG_COLLISION then
		if not self._line_object_collision then
			self._line_object_collision = World.create_line_object(self._world)
		end

		LineObject.reset(self._line_object_collision)
		LineObject.add_sphere(self._line_object_collision, Color(255, 0, 0), from_pos, radius)
		LineObject.add_sphere(self._line_object_collision, Color(255, 0, 0), to_pos, radius)

		if level_hit then
			LineObject.add_line(self._line_object_collision, Color(0, 255, 0), from_pos, to_pos)
			LineObject.add_sphere(self._line_object_collision, Color(0, 255, 0), level_hit_pos, 0.1)
		end

		LineObject.dispatch(self._world, self._line_object_collision)
	end

	return hits
end

StaffExtension._create_explosion = function (self, source_pos, radius)
	self._explosion_impact_pos = Vector3Box(source_pos)

	PhysicsWorld.overlap(self._physics_world, self._overlap_callback, "shape", "sphere", "position", source_pos, "size", radius, "types", "both", "collision_filter", "filter_arrow")
end

StaffExtension._hit_level_unit = function (self, hit_position, hit_direction, hit_normal, hit_unit)
	local hit_effect = "fireball_impact"
	local world = self._world
	local wwise_world = self._wwise_world
	local hit_rotation = Quaternion.look(hit_direction)
	local is_husk = false

	EffectHelper.play_surface_material_effects(hit_effect, world, wwise_world, hit_unit, hit_position, hit_rotation, hit_normal, nil, is_husk)
end

StaffExtension._hit_enemy_unit = function (self, hit_position, hit_direction, hit_normal, hit_unit)
	local hit_effect = "fireball_impact"
	local world = self._world
	local wwise_world = self._wwise_world
	local hit_rotation = Quaternion.look(hit_direction)
	local is_husk = false

	EffectHelper.play_skinned_surface_material_effects(hit_effect, world, wwise_world, hit_position, hit_rotation, hit_normal, is_husk, nil, nil, nil, nil)
end

StaffExtension.allowed_interact = function (self, interaction_type)
	return not self._interactors[interaction_type]
end

StaffExtension.interaction_started = function (self, wand_input, wand_unit, attach_node, wand_hand, interaction_type, husk, peer_id)
	if interaction_type == "staff" then
		self._owner_peer_id = peer_id

		local unit = self._unit

		Unit.set_data(unit, "linked", true)
		Unit.animation_event(wand_unit, "staff")

		if self._network_mode ~= "client" then
			local actor = Unit.actor(unit, 1)

			Actor.set_kinematic(actor, true)
		end

		World.unlink_unit(self._world, unit)
		World.link_unit(self._world, unit, self._staff_node, wand_unit, attach_node)

		self._staff_wand_unit = wand_unit
		self._staff_attach_node = attach_node
		self._staff_wand_input = wand_input

		Unit.teleport_local_position(unit, self._staff_node, Vector3(unpack(StaffSettings.grip_position_offset)))
		Unit.teleport_local_rotation(unit, self._staff_node, Quaternion.from_euler_angles_xyz(unpack(StaffSettings.grip_rotation_offset)))

		self._interactors.staff = wand_unit

		Unit.flow_event(self._unit, "pickup_sound")
		self:set_is_gripped(true)

		local melee_extension = ScriptUnit.extension(self._unit, "staff_melee_system")

		melee_extension:set_wand_input(self._staff_wand_input)

		self._should_vibrate_pickup_staff = true
	elseif interaction_type == "off_hand" then
		Unit.animation_event(wand_unit, "fireball")

		self._off_hand_wand_unit = wand_unit
		self._off_hand_attach_node = attach_node
		self._off_hand_wand_input = wand_input
		self._interactors.off_hand = wand_unit
		self._collecting_charge = true

		local particle_extension = ScriptUnit.extension(self._unit, "particle_system")

		particle_extension:set_collecting(true)

		local staff_vector_field_extension = ScriptUnit.extension(self._unit, "staff_vector_field_system")

		staff_vector_field_extension:set_collecting(true)
		self:_spawn_projectile()

		local pos = Unit.world_position(wand_unit, attach_node)

		for i = 1, NUM_CACHED_POSITIONS do
			self._cached_hand_positions[i]:store(pos)
		end

		self._should_vibrate_pickup_off_hand = true
		self._played_skull_spawn_sound = nil
	end
end

StaffExtension.interaction_ended = function (self, wand_input, wand_unit, force_drop)
	if self._interactors.staff == wand_unit or force_drop then
		self._owner_peer_id = nil

		self:_drop()

		self._staff_wand_input = nil
		self._staff_wand_unit = nil
		self._interactors.staff = nil

		Unit.flow_event(self._unit, "drop_sound")

		local melee_extension = ScriptUnit.extension(self._unit, "staff_melee_system")

		melee_extension:set_wand_input(nil)
	end

	if self._interactors.off_hand == wand_unit or force_drop then
		self:_release_charge()

		self._should_vibrate_throw = true
		self._interactors.off_hand = nil
		self._off_hand_wand_input = nil
		self._off_hand_wand_unit = nil
		self._hand_pos_counter = 1
		self._collecting_charge = nil
	end

	return not self._interactors.staff and not self._interactors.off_hand
end

StaffExtension.can_interact = function (self, wand_input)
	if not self._is_interactable then
		return false
	end

	if not self._interactors.staff then
		if wand_input:pressed("grip") or wand_input:pressed("trigger") or wand_input:pressed("touch_down") then
			local pos = Unit.world_position(self._unit, self._staff_node)

			if Vector3.length(wand_input:position() - pos) > StaffSettings.pickup_interaction_radius then
				return false
			end

			return true, "staff"
		end
	elseif not self._interactors.off_hand and wand_input:pressed("trigger") then
		local skull_pos = Unit.world_position(self._unit, self._skull_node)
		local wand_pos = wand_input:position()

		if Vector3.length(wand_pos - skull_pos) > StaffSettings.draw_interaction_radius then
			return false
		end

		return true, "off_hand"
	end

	return false
end

StaffExtension.interaction_position = function (self)
	if self._interactors.staff then
		return Unit.world_position(self._unit, self._skull_node)
	else
		return Unit.world_position(self._unit, self._staff_node)
	end
end

StaffExtension.should_drop = function (self, wand_input)
	local staff_controller_index = self._staff_wand_input and self._staff_wand_input:controller_index() or -1
	local off_hand_controller_index = self._off_hand_wand_input and self._off_hand_wand_input:controller_index() or -1

	if staff_controller_index == wand_input:controller_index() then
		local grip_pressed = wand_input:pressed("touch_down")

		return grip_pressed and not self._off_hand_wand_input
	elseif off_hand_controller_index == wand_input:controller_index() then
		local should_drop = wand_input:released("trigger")

		return should_drop
	end
end

StaffExtension._drop = function (self)
	local unit = self._unit

	World.unlink_unit(self._world, unit)

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
	Unit.animation_event(self._staff_wand_unit, "relax")
	self:set_is_gripped(false)
end

StaffExtension._dynamic_parameters = function (self)
	local pos = Unit.world_position(self._unit, self._staff_node)
	local rot = Unit.world_rotation(self._unit, self._staff_node)
	local up = Quaternion.up(rot)
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

StaffExtension._add_force_vortex_vector_field = function (self)
	self._force_vortex_vf = World.vector_field(self._world, "magic_whirl")

	local position, up, settings = self:_dynamic_parameters()
	local parameters = {
		center = position,
		up = Vector4(0, 0, 1, 0),
		whirl_speed = Vector4(0, 0, 0, 0),
		pull_speed = Vector4(0, 0, 0, 0),
		radius = Vector4(1, 1, 1, 1)
	}

	self._force_vortex_vf_id = VectorField.add(self._force_vortex_vf, "vector_fields/magic_whirl", parameters, settings)
end

StaffExtension._add_off_hand_particle_pull_vector_field = function (self)
	local suffix = Unit.get_data(self._unit, "suffix")

	self._off_hand_pull_vf = World.vector_field(self._world, "magic_off_hand_pull_" .. tostring(suffix))

	local position, up, settings = self:_dynamic_parameters()
	local parameters = {
		center = position,
		radius = Vector4(1, 1, 1, 1),
		speed = Vector4(0, 0, 0, 0)
	}

	self._off_hand_pull_vf_id = VectorField.add(self._off_hand_pull_vf, "vector_fields/magic_pull_push", parameters, settings)
end

StaffExtension._add_impact_push_vector_field = function (self)
	self._impact_push_vf = World.vector_field(self._world, "magic_pull_push")

	local position, up, settings = self:_dynamic_parameters()
	local parameters = {
		center = position,
		radius = Vector4(1, 1, 1, 1),
		speed = Vector4(0, 0, 0, 0)
	}

	self._impact_push_vf_id = VectorField.add(self._impact_push_vf, "vector_fields/magic_pull_push", parameters, settings)
end

StaffExtension._add_line_channel_vector_field = function (self)
	local suffix = Unit.get_data(self._unit, "suffix")

	self._line_channel_vf = World.vector_field(self._world, "magic_off_hand_pull_" .. tostring(suffix))

	local position, up, settings = self:_dynamic_parameters()
	local dir = Vector3(0, 0, 0) - position
	local normalized_dir = Vector3.normalize(dir)
	local strength = 0.1
	local parameters = {
		point1 = position,
		dir = normalized_dir,
		strength = Vector4(strength, strength, strength, strength)
	}

	self._line_channel_vf_id = VectorField.add(self._line_channel_vf, "vector_fields/towards_line", parameters, settings)
end

StaffExtension._get_world_extents = function (self)
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

StaffExtension.interaction_radius = function (self)
	return StaffSettings.pickup_interaction_radius
end

StaffExtension._vibrate = function (self, input, vibration_strength)
	input:trigger_feedback(vibration_strength)
end

StaffExtension._vibrate_pickup_staff = function (self, dt, t)
	if not self._staff_wand_input then
		return false
	end

	self._pickup_staff_vibration_time = (self._pickup_staff_vibration_time or 0) + dt

	local vibration_strength, done = StaffSettings.vibration_functions.pickup_staff(dt, self._pickup_staff_vibration_time)

	if not done then
		self:_vibrate(self._staff_wand_input, vibration_strength)
	end

	return not done
end

StaffExtension._vibrate_pickup_off_hand = function (self, dt, t)
	if not self._off_hand_wand_input then
		return false
	end

	self._pickup_off_hand_vibration_time = (self._pickup_off_hand_vibration_time or 0) + dt

	local vibration_strength, done = StaffSettings.vibration_functions.pickup_off_hand(dt, self._pickup_off_hand_vibration_time)

	if not done then
		self:_vibrate(self._off_hand_wand_input, vibration_strength)
	end

	return not done
end

StaffExtension._vibrate_throw_staff = function (self, dt, t)
	if not self._staff_wand_input then
		return false
	end

	self._throw_staff_vibration_time = (self._throw_staff_vibration_time or 0) + dt

	local vibration_strength, done = StaffSettings.vibration_functions.throw_staff(dt, self._throw_staff_vibration_time)

	if not done then
		self:_vibrate(self._staff_wand_input, vibration_strength)
	end
end

StaffExtension._vibrate_throw_off_hand = function (self, dt, t)
	if not self._off_hand_wand_input then
		return false
	end

	self._throw_off_hand_vibration_time = (self._throw_off_hand_vibration_time or 0) + dt

	local vibration_strength, done = StaffSettings.vibration_functions.throw_off_hand(dt, self._throw_off_hand_vibration_time)

	if not done then
		self:_vibrate(self._off_hand_wand_input, vibration_strength)
	end
end

StaffExtension._vibrate_charge_staff = function (self, dt, t)
	if not self._staff_wand_input then
		return false
	end

	self._charge_staff_vibration_time = (self._charge_staff_vibration_time or 0) + dt

	local vibration_strength, done = StaffSettings.vibration_functions.charge_staff(dt, self._charge_staff_vibration_time)

	if not done then
		self:_vibrate(self._staff_wand_input, vibration_strength)
	end
end

StaffExtension._vibrate_charge_off_hand = function (self, dt, t)
	if not self._off_hand_wand_input then
		return false
	end

	self._charge_off_hand_vibration_time = (self._charge_off_hand_vibration_time or 0) + dt

	local vibration_strength, done = StaffSettings.vibration_functions.charge_off_hand(dt, self._charge_off_hand_vibration_time)

	if not done then
		self:_vibrate(self._off_hand_wand_input, vibration_strength)
	end
end

StaffExtension.set_is_gripped = function (self, gripped)
	self._gripped = gripped
end

StaffExtension.is_gripped = function (self)
	return self._gripped
end

StaffExtension.set_interactable = function (self, is_interactable)
	self._is_interactable = is_interactable
end

StaffExtension.is_interactable = function (self)
	return self._is_interactable
end
