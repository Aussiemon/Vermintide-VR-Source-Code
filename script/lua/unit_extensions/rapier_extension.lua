-- chunkname: @script/lua/unit_extensions/rapier_extension.lua

require("settings/rapier_settings")

local RapierSettings = RapierSettings
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
local DEBUG_HITBOX = false
local DEBUG_HITS = false

class("RapierExtension")

RapierExtension.init = function (self, extension_init_context, unit)
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._wwise_world = Wwise.wwise_world(self._world)
	self._level = extension_init_context.level
	self._unit = unit
	self._node = 1
	self._tip_node = Unit.node(self._unit, "a_tip")
	self._wand_input = nil
	self._grip_anim = Unit.get_data(unit, "grip_info", "grip_anim") or "grip"
	self._current_vibration_time = 0
	self._network_mode = extension_init_context.network_mode
	self._is_interactable = true

	local _, weapon_half_extents = Unit.box(self._unit)

	self.stored_half_extents = Vector3Box(weapon_half_extents)
	self.stored_position = Vector3Box()
	self.stored_rotation = QuaternionBox()
	self.last_position = Vector3Box()
	self.current_position = Vector3Box()
	self.hit_units = {}
	self.could_damage_last_update = false

	if DEBUG_HITBOX or DEBUG_HITS then
		self._drawer = DebugDrawer:new(World.create_line_object(self._world), true)
	end
end

RapierExtension.destroy = function (self)
	return
end

RapierExtension.update = function (self, unit, dt, t)
	if self._wand_input then
		self:_check_if_attacking(dt, t)

		if self._attacking then
			self:_update_attack(dt, t)
		end

		if DEBUG_HITBOX or DEBUG_HITS then
			self._drawer:update(self._world)
		end

		if self._effect_cooldown then
			self._effect_cooldown = self._effect_cooldown - dt

			if self._effect_cooldown <= 0 then
				self._effect_cooldown = nil
			end
		end
	end
end

RapierExtension._check_if_attacking = function (self, dt, t)
	local last_position = self.last_position:unbox()
	local current_position = Unit.world_position(self._unit, self._tip_node)
	local distance = Vector3.length(last_position - current_position)

	self._move_speed = distance / dt

	local attacking = self._attacking or false
	local enough_speed = self._move_speed > RapierSettings.attack_threshold_speed

	if not attacking and enough_speed then
		attacking = true

		self:_start_attack(dt, t)
	elseif attacking and not enough_speed then
		attacking = false
	end

	local sound_param = math.min(self._move_speed / RapierSettings.max_attack_speed * 100, 100)

	WwiseWorld.set_source_parameter(self._wwise_world, self._audio_source, "swing_speed", sound_param)
	self.last_position:store(current_position)

	self._attacking = attacking
end

RapierExtension._start_attack = function (self, dt, t)
	self.action_time_started = t
	self.has_hit_target = false
	self.number_of_hit_enemies = 0

	table.clear(self.hit_units)
	self.stored_position:store(Unit.world_position(self._unit, 1))
	self.stored_rotation:store(Unit.world_rotation(self._unit, 1))

	if stingray.Keyboard.button(stingray.Keyboard.button_id("r")) == 1 then
		self._drawer:reset()
	end
end

local SWEEP_RESULTS = {}

RapierExtension._update_attack = function (self, dt, t)
	local do_damage = self._network_mode == nil or self._network_mode == "server"
	local unit = self._unit
	local physics_world = self._physics_world
	local position = Unit.world_position(unit, 1)
	local rotation = Unit.world_rotation(unit, 1)

	self:_do_overlap(dt, t, do_damage, position, rotation)
end

RapierExtension._do_overlap = function (self, dt, t, do_damage, current_position, current_rotation)
	local position_previous = self.stored_position:unbox()
	local rotation_previous = self.stored_rotation:unbox()
	local position_current = current_position
	local rotation_current = current_rotation

	self.stored_position:store(position_current)
	self.stored_rotation:store(rotation_current)

	local current_rot_up = Quaternion.up(current_rotation)
	local previous_rot_up = Quaternion.up(rotation_previous)
	local weapon_half_extents = self.stored_half_extents:unbox()
	local weapon_half_length = weapon_half_extents.z
	local range_mod = 0.9
	local width_mod = 1

	weapon_half_length = weapon_half_length * range_mod
	weapon_half_extents.x = weapon_half_extents.x * width_mod

	local position_start = position_previous + previous_rot_up * weapon_half_length
	local position_end = current_position + current_rot_up * weapon_half_length * 2 - previous_rot_up * weapon_half_length
	local max_num_hits = 5

	if DEBUG_HITBOX then
		self._drawer:capsule(position_previous, position_previous + previous_rot_up * (weapon_half_length * 2), 0.02, Color(255, 0, 0))
		self._drawer:capsule(position_current, position_current + current_rot_up * (weapon_half_length * 2), 0.01, Color(0, 255, 0))
		self._drawer:sphere(position_previous, 0.015, Color(255, 0, 255))
		self._drawer:sphere(position_current, 0.025, Color(255, 255, 255))
	end

	local weapon_cross_section = Vector3(weapon_half_extents.x, weapon_half_extents.y, 0.0001)
	local collision_filter = "filter_melee"
	local physics_world = self._physics_world
	local sweep_results = PhysicsWorld.linear_obb_sweep(physics_world, position_start, position_end, weapon_cross_section, rotation_previous, max_num_hits, "collision_filter", collision_filter, "report_initial_overlap")
	local num_results = sweep_results and #sweep_results or 0

	if num_results > 0 then
		self:_vibrate()

		if DEBUG_HITS then
			print("-------------")
			print(num_results)
		end
	end

	local hit_units = self.hit_units

	for i = 1, num_results do
		repeat
			local result = sweep_results[i]
			local hit_actor = result.actor
			local hit_position = result.position
			local hit_normal = result.normal
			local hit_distance = result.distance

			if hit_distance <= 0 then
				break
			end

			local hit_unit = Actor.unit(hit_actor)

			if DEBUG_HITS then
				self._drawer:sphere(hit_position, 0.025, Color(255, 0, 0))
				print(hit_unit)
				table.dump(result, nil, 2)
			end

			if hit_unit and Unit.alive(hit_unit) and Vector3.is_valid(hit_position) then
				local hit_unit_node_index = Actor.node(hit_actor)
				local breed = Unit.get_data(hit_unit, "breed")

				if hit_units[hit_unit] == nil then
					if breed then
						do
							local has_health_extension = ScriptUnit.has_extension(hit_unit, "health_system")

							if has_health_extension then
								local health_extension = ScriptUnit.extension(hit_unit, "health_system")

								if do_damage and health_extension:is_alive() and max_num_hits > self.number_of_hit_enemies then
									local peer_id = self._network_mode == "server" and Network.peer_id() or nil
									local params = {
										hit_direction = -hit_normal,
										hit_force = RapierSettings.force,
										hit_node_index = hit_unit_node_index,
										peer_id = peer_id,
										force_dismember = RapierSettings.always_dismember
									}

									health_extension:add_damage(RapierSettings.damage, params)

									self.number_of_hit_enemies = self.number_of_hit_enemies + 1
								else
									break
								end

								hit_units[hit_unit] = true

								self:_hit_enemy_unit(hit_position, -hit_normal, hit_normal, hit_unit)
							end
						end

						break
					end

					if hit_units[hit_unit] == nil then
						hit_units[hit_unit] = true

						if not self._effect_cooldown then
							self:_hit_level_unit(hit_position, -hit_normal, hit_normal, hit_unit)

							self._effect_cooldown = RapierSettings.effect_cooldown
						end

						if self._network_mode ~= "client" then
							Unit.set_flow_variable(hit_unit, "hit_actor", hit_actor)
							Unit.set_flow_variable(hit_unit, "hit_direction", -hit_normal)
							Unit.set_flow_variable(hit_unit, "hit_position", hit_position)
							Unit.flow_event(hit_unit, "lua_simple_damage")
						end
					end
				end
			end
		until true
	end
end

RapierExtension._hit_level_unit = function (self, hit_position, hit_direction, hit_normal, hit_unit)
	local hit_effect = "melee_hit_slashing"
	local world = self._world
	local wwise_world = self._wwise_world
	local hit_rotation = Quaternion.look(hit_direction)
	local is_husk = false

	EffectHelper.play_surface_material_effects(hit_effect, world, wwise_world, hit_unit, hit_position, hit_rotation, hit_normal, nil, is_husk)
end

RapierExtension._hit_enemy_unit = function (self, hit_position, hit_direction, hit_normal, hit_unit)
	local hit_effect = "melee_hit_slashing"
	local world = self._world
	local wwise_world = self._wwise_world
	local hit_rotation = Quaternion.look(hit_direction)
	local is_husk = false

	EffectHelper.play_skinned_surface_material_effects(hit_effect, world, wwise_world, hit_position, hit_rotation, hit_normal, is_husk, nil, nil, nil, nil)
end

RapierExtension.can_interact = function (self, wand_input)
	if not self._is_interactable then
		return false
	end

	if not self._wand_input and (wand_input:pressed("grip") or wand_input:pressed("trigger") or wand_input:pressed("touch_down")) then
		local pos = Unit.world_position(self._unit, self._node)

		if Vector3.length(wand_input:position() - pos) > RapierSettings.interaction_radius then
			return false
		end

		return true
	end
end

RapierExtension.should_drop = function (self, wand_input)
	return wand_input:pressed("touch_down")
end

RapierExtension.interaction_started = function (self, wand_input, wand_unit, attach_node, wand_hand)
	local unit = self._unit

	Unit.flow_event(unit, "disable_collision_sound")
	Unit.set_data(unit, "linked", true)
	Unit.animation_event(wand_unit, "bow")

	if self._network_mode ~= "client" then
		local actor = Unit.actor(unit, 1)

		Actor.set_kinematic(actor, true)
	end

	World.unlink_unit(self._world, unit)
	World.link_unit(self._world, unit, self._node, wand_unit, attach_node)

	local hand_rotation_offset = Quaternion.from_euler_angles_xyz(unpack(RapierSettings.hand_rotation_offset))
	local base_rotation = Quaternion.multiply(Quaternion.from_euler_angles_xyz(unpack(RapierSettings.grip_rotation_offset)), hand_rotation_offset)

	Unit.teleport_local_position(unit, self._node, Vector3(unpack(RapierSettings.grip_position_offset)))
	Unit.teleport_local_rotation(unit, self._node, base_rotation)

	self._wand_unit = wand_unit
	self._attach_node = attach_node
	self._wand_input = wand_input
	self._wand_hand = wand_hand

	if self._wand_input then
		self._wand_input:set_additional_rotation_offset(hand_rotation_offset)
	end

	self:set_is_gripped(true)
	Unit.flow_event(self._unit, "pickup_sound")

	local pos = Unit.world_position(unit, 1)

	self.last_position:store(pos)
	self.current_position:store(pos)

	self._audio_source = WwiseWorld.make_auto_source(self._wwise_world, self._unit, self._tip_node)

	WwiseWorld.trigger_event(self._wwise_world, "Play_fencing_sword_swing_loop", self._audio_source)
	WwiseWorld.set_source_parameter(self._wwise_world, self._audio_source, "swing_speed", 0)
end

RapierExtension.interaction_ended = function (self, wand_input, wand_unit)
	Unit.flow_event(self._unit, "enable_collision_sound")

	if self._wand_input then
		self._wand_input:set_additional_rotation_offset(nil)
	end

	self:_drop()

	self._wand_unit = nil
	self._attach_node = nil
	self._wand_input = nil
	self._wand_hand = nil

	Unit.flow_event(self._unit, "drop_sound")
	WwiseWorld.set_source_parameter(self._wwise_world, self._audio_source, "swing_speed", 0)
	WwiseWorld.trigger_event(self._wwise_world, "Stop_fencing_sword_swing_loop", self._audio_source)

	self._audio_source = nil

	return not self._wand_input
end

RapierExtension._drop = function (self)
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
	Unit.animation_event(self._wand_unit, "relax")
	self:set_is_gripped(false)
end

RapierExtension.set_is_gripped = function (self, gripped)
	self._gripped = gripped
end

RapierExtension.is_gripped = function (self)
	return self._gripped
end

RapierExtension.interaction_radius = function (self)
	return RapierSettings.interaction_radius
end

RapierExtension.set_interactable = function (self, is_interactable)
	self._is_interactable = is_interactable
end

RapierExtension.is_interactable = function (self)
	return self._is_interactable
end

RapierExtension._vibrate = function (self)
	local base_strength = RapierSettings.hit_vibration_strength
	local move_speed = self._move_speed or 0
	local final_strength = base_strength * move_speed

	self._wand_input:trigger_feedback(final_strength)
end
