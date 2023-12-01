-- chunkname: @script/lua/unit_extensions/staff_melee_extension.lua

require("settings/staff_settings")

local StaffMeleeSettings = StaffSettings.melee
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local World = stingray.World
local Actor = stingray.Actor
local Matrix4x4 = stingray.Matrix4x4
local Quaternion = stingray.Quaternion
local QuaternionBox = stingray.QuaternionBox
local Vector3Box = stingray.Vector3Box
local Math = stingray.Math
local LineObject = stingray.LineObject
local Color = stingray.Color
local Wwise = stingray.Wwise
local WwiseWorld = stingray.WwiseWorld
local DEBUG_HITS = false

class("StaffMeleeExtension")

StaffMeleeExtension.init = function (self, extension_init_context, unit)
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._wwise_world = Wwise.wwise_world(self._world)
	self._level = extension_init_context.level
	self._unit = unit
	self._tip_node = Unit.node(self._unit, "fx_03")
	self._network_mode = extension_init_context.network_mode

	local _, weapon_half_extents = Unit.box(self._unit)

	weapon_half_extents.z = weapon_half_extents.z / 4
	self.stored_half_extents = Vector3Box(weapon_half_extents)
	self.stored_position = Vector3Box()
	self.stored_rotation = QuaternionBox()
	self.last_position = Vector3Box()
	self.current_position = Vector3Box()
	self.hit_units = {}
	self.could_damage_last_update = false

	if DEBUG_HITS then
		self._drawer = DebugDrawer:new(World.create_line_object(self._world), true)
	end
end

StaffMeleeExtension.destroy = function (self)
	return
end

StaffMeleeExtension.update = function (self, unit, dt, t)
	if self._wand_input then
		self:_check_if_attacking(dt, t)

		if self._attacking then
			self:_update_attack(dt, t)
		end

		if DEBUG_HITS then
			self._drawer:update(self._world)
		end
	end
end

StaffMeleeExtension._check_if_attacking = function (self, dt, t)
	local last_position = self.last_position:unbox()
	local current_position = Unit.world_position(self._unit, self._tip_node)
	local distance = Vector3.length(last_position - current_position)
	local speed = distance / dt
	local attacking = self._attacking or false
	local enough_speed = speed > StaffMeleeSettings.attack_threshold_speed

	if not attacking and enough_speed then
		attacking = true

		self:_start_attack(dt, t)
	elseif attacking and not enough_speed then
		attacking = false
	end

	self.last_position:store(current_position)

	self._attacking = attacking
end

StaffMeleeExtension._start_attack = function (self, dt, t)
	self.action_time_started = t
	self.has_hit_environment = false
	self.has_hit_target = false
	self.target_breed_unit = nil
	self.number_of_hit_enemies = 0
	self.down_offset = 0
	self.auto_aim_reset = false

	local owner_unit = self.owner_unit

	self.attack_aborted = false

	table.clear(self.hit_units)

	local pos = Unit.world_position(self._unit, 1)
	local weapon_unit = self._unit
	local actual_position_initial = pos
	local position_initial = Vector3(actual_position_initial.x, actual_position_initial.y, actual_position_initial.z - self.down_offset)

	self.stored_position:store(position_initial)
	self.stored_rotation:store(Unit.world_rotation(weapon_unit, 1))

	self.could_damage_last_update = false

	if DEBUG_HITS then
		self._drawer:reset()
	end
end

local SWEEP_RESULTS = {}

StaffMeleeExtension._update_attack = function (self, dt, t)
	local do_damage = self._network_mode == nil or self._network_mode == "server"
	local current_time_in_action = t - self.action_time_started
	local unit = self._unit
	local physics_world = self._physics_world
	local max_dt = 0.011111111111111112
	local current_dt = 0
	local aborted = false
	local start_position = self.stored_position:unbox()
	local start_rotation = self.stored_rotation:unbox()
	local end_position = Unit.world_position(unit, 1)
	local end_rotation = Unit.world_rotation(unit, 1)
	local interpolate = true
	local i = 0

	if interpolate then
		while not aborted and not self.attack_aborted and current_dt < dt do
			i = i + 1

			local interpolated_dt = math.min(max_dt, dt - current_dt)

			current_dt = math.min(current_dt + max_dt, dt)

			local lerp_t = current_dt / dt
			local current_position = Vector3.lerp(start_position, end_position, lerp_t)
			local current_rotation = Quaternion.lerp(start_rotation, end_rotation, lerp_t)

			aborted = self:_do_overlap(interpolated_dt, t, do_damage, current_position, current_rotation)
		end
	else
		self:_do_overlap(dt, t, do_damage, end_position, end_rotation)
	end
end

StaffMeleeExtension._is_within_damage_window = function (self, current_time_in_action)
	local damage_window_start = 0.15
	local damage_window_end = 0.3
	local total_time = 1.5

	if not damage_window_start and not damage_window_end then
		return false
	end

	damage_window_end = damage_window_end or total_time or math.huge

	local after_start = damage_window_start < current_time_in_action
	local before_end = current_time_in_action < damage_window_end

	return after_start and before_end
end

StaffMeleeExtension._calculate_attack_direction = function (self, weapon_rotation)
	local attack_direction = "up"
	local quaternion_axis = attack_direction
	local attack_direction = Quaternion[quaternion_axis](weapon_rotation)

	return attack_direction
end

StaffMeleeExtension._do_overlap = function (self, dt, t, do_damage, current_position, current_rotation)
	local current_time_in_action = t - self.action_time_started
	local current_rot_up = Quaternion.up(current_rotation)

	if self.attack_aborted then
		return
	end

	if not do_damage and not self.could_damage_last_update then
		local actual_last_position_current = current_position
		local last_position_current = Vector3(actual_last_position_current.x, actual_last_position_current.y, actual_last_position_current.z - self.down_offset)

		self.stored_position:store(last_position_current)
		self.stored_rotation:store(current_rotation)

		return
	end

	local final_frame = not do_damage and self.could_damage_last_update

	self.could_damage_last_update = do_damage

	local position_previous = self.stored_position:unbox()
	local rotation_previous = self.stored_rotation:unbox()
	local weapon_up_dir_previous = Quaternion.up(rotation_previous)
	local actual_position_current = current_position
	local position_current = Vector3(actual_position_current.x, actual_position_current.y, actual_position_current.z - self.down_offset)
	local rotation_current = current_rotation

	self.stored_position:store(position_current)
	self.stored_rotation:store(rotation_current)

	local weapon_half_extents = self.stored_half_extents:unbox()
	local weapon_half_length = weapon_half_extents.z
	local range_mod = 1
	local width_mod = 1

	weapon_half_length = weapon_half_length * range_mod
	weapon_half_extents.x = weapon_half_extents.x * width_mod

	if DEBUG_HITS then
		self._drawer:capsule(position_previous, position_previous + weapon_up_dir_previous * (weapon_half_length * 2), 0.02)
		self._drawer:capsule(position_current, position_current + current_rot_up * (weapon_half_length * 2), 0.01, Color(0, 0, 255))
		self._drawer:sphere(Unit.world_position(self._unit, self._tip_node), 0.025, Color(255, 0, 0))
	end

	local weapon_rot = current_rotation
	local middle_rot = Quaternion.lerp(rotation_previous, weapon_rot, 0.5)
	local position_start = position_previous + weapon_up_dir_previous * weapon_half_length
	local position_end = position_previous + current_rot_up * weapon_half_length * 2 - Quaternion.up(rotation_previous) * weapon_half_length
	local max_num_hits = 5
	local attack_direction = self:_calculate_attack_direction(weapon_rot)
	local weapon_cross_section = Vector3(weapon_half_extents.x, weapon_half_extents.y, 0.0001)
	local collision_filter = "filter_melee"
	local physics_world = self._physics_world
	local sweep_results1 = PhysicsWorld.linear_obb_sweep(physics_world, position_previous, position_previous + weapon_up_dir_previous * weapon_half_length * 2, weapon_cross_section, rotation_previous, max_num_hits, "collision_filter", collision_filter, "report_initial_overlap")
	local sweep_results2 = PhysicsWorld.linear_obb_sweep(physics_world, position_start, position_end, weapon_half_extents, rotation_previous, max_num_hits, "collision_filter", collision_filter, "report_initial_overlap")
	local sweep_results3 = PhysicsWorld.linear_obb_sweep(physics_world, position_previous + current_rot_up * weapon_half_length, position_current + current_rot_up * weapon_half_length, weapon_half_extents, rotation_current, max_num_hits, "collision_filter", collision_filter, "report_initial_overlap")
	local num_results1 = 0
	local num_results2 = 0
	local num_results3 = 0

	if sweep_results1 then
		num_results1 = #sweep_results1

		for i = 1, num_results1 do
			SWEEP_RESULTS[i] = sweep_results1[i]
		end
	end

	if sweep_results2 then
		for i = 1, #sweep_results2 do
			local info = sweep_results2[i]
			local this_actor = info.actor
			local found

			for j = 1, num_results1 do
				if SWEEP_RESULTS[j].actor == this_actor then
					found = true
				end
			end

			if not found then
				num_results2 = num_results2 + 1
				SWEEP_RESULTS[num_results1 + num_results2] = info
			end
		end
	end

	if sweep_results3 then
		for i = 1, #sweep_results3 do
			local info = sweep_results3[i]
			local this_actor = info.actor
			local found

			for j = 1, num_results1 + num_results2 do
				if SWEEP_RESULTS[j].actor == this_actor then
					found = true
				end
			end

			if not found then
				num_results3 = num_results3 + 1
				SWEEP_RESULTS[num_results1 + num_results2 + num_results3] = info
			end
		end
	end

	for i = num_results1 + num_results2 + num_results3 + 1, #SWEEP_RESULTS do
		SWEEP_RESULTS[i] = nil
	end

	if #SWEEP_RESULTS > 0 then
		self:_vibrate()
	end

	local hit_units = self.hit_units
	local environment_unit_hit = false
	local max_targets = 5

	for i = 1, num_results1 + num_results2 + num_results3 do
		repeat
			local result = SWEEP_RESULTS[i]
			local hit_actor = result.actor
			local hit_position = result.position
			local hit_normal = result.normal
			local hit_distance = result.distance
			local hit_unit = Actor.unit(hit_actor)
			local hit_armor = false

			if hit_unit and Unit.alive(hit_unit) and Vector3.is_valid(hit_position) then
				local hit_unit_node_index = Actor.node(hit_actor)
				local breed = Unit.get_data(hit_unit, "breed")

				if hit_units[hit_unit] == nil and breed then
					local has_health_extension = ScriptUnit.has_extension(hit_unit, "health_system")

					if has_health_extension then
						local health_extension = ScriptUnit.extension(hit_unit, "health_system")

						if do_damage and health_extension:is_alive() and max_targets > self.number_of_hit_enemies then
							print(self._network_mode)

							local peer_id = self._network_mode == "server" and Network.peer_id() or nil
							local params = {
								hit_direction = -hit_normal,
								hit_force = StaffMeleeSettings.force,
								hit_node_index = hit_unit_node_index,
								peer_id = peer_id
							}

							health_extension:add_damage(StaffMeleeSettings.damage, params)

							self.number_of_hit_enemies = self.number_of_hit_enemies + 1
							hit_armor = breed.armor_category == 2
						else
							break
						end
					end

					hit_units[hit_unit] = true

					self:_hit_enemy_unit(hit_position, -hit_normal, hit_normal, hit_unit)
				end
			elseif hit_units[hit_unit] == nil then
				environment_unit_hit = i
			end

			if environment_unit_hit and not self.has_hit_environment and num_results1 + num_results2 > 0 then
				local result = SWEEP_RESULTS[environment_unit_hit]
				local hit_actor = result.actor
				local hit_position = result.position
				local hit_normal = result.normal
				local hit_distance = result.distance

				self.has_hit_environment = true

				self:_hit_level_unit(hit_position, -hit_normal, hit_normal, hit_unit)

				if self._network_mode ~= "client" then
					Unit.set_flow_variable(hit_unit, "hit_actor", hit_actor)
					Unit.set_flow_variable(hit_unit, "hit_direction", -hit_normal)
					Unit.set_flow_variable(hit_unit, "hit_position", hit_position)
					Unit.flow_event(hit_unit, "lua_simple_damage")
				end
			end
		until true
	end

	if DEBUG_HITS then
		local pose = Matrix4x4.from_quaternion_position(rotation_previous, position_start)

		self._drawer:box_sweep(pose, weapon_half_extents, position_end - position_start, Color(0, 255, 0), Color(0, 100, 0))
		self._drawer:sphere(position_start, 0.05)
		self._drawer:sphere(position_end, 0.05, Color(255, 0, 255))
		self._drawer:vector(position_start, position_end - position_start)

		local pose = Matrix4x4.from_quaternion_position(rotation_current, position_previous + Quaternion.up(rotation_current) * weapon_half_length)

		self._drawer:box_sweep(pose, weapon_half_extents, position_current - position_previous)
	end
end

StaffMeleeExtension._hit_level_unit = function (self, hit_position, hit_direction, hit_normal, hit_unit)
	local hit_effect = "melee_hit_staff"
	local world = self._world
	local wwise_world = self._wwise_world
	local hit_rotation = Quaternion.look(hit_direction)
	local is_husk = false

	EffectHelper.play_surface_material_effects(hit_effect, world, wwise_world, hit_unit, hit_position, hit_rotation, hit_normal, nil, is_husk)
end

StaffMeleeExtension._hit_enemy_unit = function (self, hit_position, hit_direction, hit_normal, hit_unit)
	local hit_effect = "melee_hit_staff"
	local world = self._world
	local wwise_world = self._wwise_world
	local hit_rotation = Quaternion.look(hit_direction)
	local is_husk = false

	EffectHelper.play_skinned_surface_material_effects(hit_effect, world, wwise_world, hit_position, hit_rotation, hit_normal, is_husk, nil, nil, nil, nil)
end

StaffMeleeExtension.set_wand_input = function (self, wand_input)
	self._wand_input = wand_input
end

StaffMeleeExtension._vibrate = function (self)
	local base_strength = StaffMeleeSettings.hit_vibration_strength
	local move_speed = self._move_speed or 0
	local final_strength = base_strength * move_speed

	self._wand_input:trigger_feedback(final_strength)
end
