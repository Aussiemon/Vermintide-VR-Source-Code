-- chunkname: @script/lua/unit_extensions/handgun_extension.lua

require("settings/handgun_settings")

local HandgunSettings = HandgunSettings
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local World = stingray.World
local Actor = stingray.Actor
local Matrix4x4 = stingray.Matrix4x4
local Quaternion = stingray.Quaternion
local Vector3Box = stingray.Vector3Box
local Math = stingray.Math
local LineObject = stingray.LineObject
local Color = stingray.Color
local DEBUG_AIM = false

class("HandgunExtension")

HandgunExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._wwise_world = Wwise.wwise_world(self._world)
	self._level = extension_init_context.level
	self._unit = unit
	self._node = 1
	self._muzzle_node = Unit.node(unit, "fx_muzzle")
	self._wand_input = nil
	self._grip_anim = Unit.get_data(unit, "grip_info", "grip_anim") or "grip"
	self._network_mode = extension_init_context.network_mode
	self._current_vibration_time = 0
	self._trail_draw_time = nil
	self._handgun_trail = World.create_line_object(self._world)

	if DEBUG_AIM then
		self._line_object_aim = World.create_line_object(self._world)
	end

	self._fired_shots = 0
	self._magazine_size = HandgunSettings.magazine_size
	self._network_mode = extension_init_context.network_mode
	self._is_interactable = true

	local min, max = self:_get_world_extents()

	self._min_world_extent = Vector3Box(min)
	self._max_world_extent = Vector3Box(max)

	self:_add_impact_push_vector_field()
end

HandgunExtension.destroy = function (self)
	VectorField.remove(self._fire_push_vf_id)
end

HandgunExtension.update = function (self, unit, dt, t)
	self:_handle_input(dt, t)
	self:_update_trail(dt, t)
	self:_update_vibration(dt, t)
end

HandgunExtension._handle_input = function (self, dt, t)
	if self._triggered_force_push then
		self:_reset_force_push_vector_field()

		self._triggered_force_push = nil
	end

	local input = self._wand_input

	if input then
		if input:pressed("trigger") then
			self:_trigger_pressed(dt, t)
		end

		if input:pressed("grip") then
			self:_start_reload()
		end

		self:_update_reload(dt, t)
	end
end

HandgunExtension._spin_up = function (self)
	return
end

HandgunExtension._burst_fire = function (self)
	self._started_burst_fire = true
	self._burst_fire_timer = 0
end

HandgunExtension._update_burst_fire = function (self, dt, t)
	if self._started_burst_fire then
		self._burst_fire_timer = self._burst_fire_timer + dt

		if self._burst_fire_timer > HandgunSettings.time_between_burst_fire then
			self._burst_fire_timer = 0

			self:_trigger_pressed(dt, t)

			if not self:_can_fire() then
				self._started_burst_fire = nil
			end
		end
	end
end

HandgunExtension.fire = function (self, fire_pos, direction, look_target_pos, do_damage, peer_id)
	Unit.flow_event(self._unit, "flow_pressed")
	Unit.animation_event(self._unit, "shoot")

	if self:_remaining_ammo() == 1 then
		Unit.flow_event(self._unit, "last_shot_sound")
	end

	self._fired_shots = self._fired_shots + 1

	self:_trigger_vibration()

	local hits = PhysicsWorld.raycast(self._physics_world, fire_pos, direction, "all", "collision_filter", "filter_arrow")

	if DEBUG_AIM then
		LineObject.reset(self._line_object_aim)
		LineObject.add_line(self._line_object_aim, Color(255, 0, 0), fire_pos, fire_pos + direction * 50)
		LineObject.dispatch(self._world, self._line_object_aim)
	end

	local found_hit = false
	local num_hits = hits and #hits or 0

	num_hits = math.min(2, num_hits)

	for i = 1, num_hits do
		local hit = hits[i]

		if hit and not found_hit then
			local hit_pos = hit[1]
			local hit_distance = hit[2]
			local hit_normal = hit[3]
			local hit_actor = hit[4]
			local hit_unit = Actor.unit(hit_actor)
			local trigger_volume = Unit.get_data(hit_unit, "trigger_volume")

			if Unit.alive(hit_unit) and trigger_volume then
				Unit.set_flow_variable(hit_unit, "hit_actor", hit_actor)
				Unit.set_flow_variable(hit_unit, "hit_direction", direction)
				Unit.set_flow_variable(hit_unit, "hit_position", hit_pos)
				Unit.flow_event(hit_unit, "lua_simple_damage")
			elseif Unit.alive(hit_unit) then
				self:_start_trail(fire_pos, hit_pos, direction)

				if do_damage then
					local hit_unit_node_index = Actor.node(hit_actor)
					local has_health_extension = ScriptUnit.has_extension(hit_unit, "health_system")

					if has_health_extension then
						local health_extension = ScriptUnit.extension(hit_unit, "health_system")

						if health_extension:is_alive() then
							local params = {
								hit_direction = direction,
								hit_force = HandgunSettings.force,
								hit_node_index = hit_unit_node_index,
								peer_id = peer_id,
								force_dismember = HandgunSettings.always_dismember
							}

							health_extension:add_damage(HandgunSettings.damage, params)
						end
					end

					if ScriptUnit.has_extension(hit_unit, "ragdoll_system") then
						local ragdoll_extension = ScriptUnit.extension(hit_unit, "ragdoll_system")

						if ragdoll_extension.spawn_burst then
							ragdoll_extension:spawn_burst()
						end
					end
				end

				if Unit.alive(hit_unit) then
					local is_enemy = Unit.get_data(hit_unit, "breed")

					if not is_enemy then
						self:_hit_level_unit(hit_pos, direction, hit_normal, hit_unit)
					else
						self:_hit_enemy_unit(hit_pos, direction, hit_normal, hit_unit)
					end

					if self._network_mode ~= "client" then
						Unit.set_flow_variable(hit_unit, "hit_actor", hit_actor)
						Unit.set_flow_variable(hit_unit, "hit_direction", direction)
						Unit.set_flow_variable(hit_unit, "hit_position", hit_pos)
						Unit.flow_event(hit_unit, "lua_simple_damage")
					end
				end

				found_hit = true
			end
		end
	end

	self:_trigger_force_push(fire_pos)
end

HandgunExtension._trigger_pressed = function (self, dt, t)
	local can_fire = self:_can_fire()

	if can_fire then
		local position = Unit.world_position(self._unit, self._muzzle_node)
		local rotation = Unit.world_rotation(self._unit, self._node)
		local direction = Vector3.normalize(Quaternion.forward(rotation))
		local hmd_pose = Managers.vr:hmd_world_pose()
		local hmd_pos = Matrix4x4.translation(hmd_pose.head)
		local look_dir = Vector3.normalize(hmd_pose.forward)
		local hit, look_target_pos, _, _, _ = PhysicsWorld.raycast(self._physics_world, hmd_pos, look_dir, "closest", "collision_filter", "filter_arrow")

		if not hit then
			look_target_pos = hmd_pos + look_dir * 10
		end

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
	else
		Unit.flow_event(self._unit, "empty_chamber_sound")
		self:_start_reload()
	end

	return can_fire
end

HandgunExtension._remaining_ammo = function (self)
	return self._magazine_size - self._fired_shots
end

HandgunExtension._can_fire = function (self)
	local ammo_left = self:_remaining_ammo()

	return ammo_left > 0 and self._reload_time == nil
end

HandgunExtension._hit_level_unit = function (self, hit_position, hit_direction, hit_normal, hit_unit)
	local hit_effect = "bullet_impact"
	local world = self._world
	local wwise_world = self._wwise_world
	local hit_rotation = Quaternion.look(hit_direction)
	local is_husk = false

	EffectHelper.play_surface_material_effects(hit_effect, world, wwise_world, hit_unit, hit_position, hit_rotation, hit_normal, nil, is_husk)
end

HandgunExtension._hit_enemy_unit = function (self, hit_position, hit_direction, hit_normal, hit_unit)
	local hit_effect = "bullet_impact"
	local world = self._world
	local wwise_world = self._wwise_world
	local hit_rotation = Quaternion.look(hit_direction)
	local is_husk = false

	EffectHelper.play_skinned_surface_material_effects(hit_effect, world, wwise_world, hit_position, hit_rotation, hit_normal, is_husk, nil, nil, nil, nil)
end

HandgunExtension.can_interact = function (self, wand_input)
	if not self._is_interactable then
		return false
	end

	if not self._wand_input and (wand_input:pressed("grip") or wand_input:pressed("trigger", true) or wand_input:pressed("touch_down")) then
		local pos = Unit.world_position(self._unit, self._node)

		if Vector3.length(wand_input:position() - pos) > HandgunSettings.interaction_radius then
			return false
		end

		return true
	end
end

HandgunExtension.should_drop = function (self, wand_input)
	return wand_input:pressed("touch_down")
end

HandgunExtension.interaction_started = function (self, wand_input, wand_unit, attach_node, wand_hand)
	local unit = self._unit

	Unit.set_data(unit, "linked", true)
	Unit.animation_event(wand_unit, "pistol")

	if self._network_mode ~= "client" then
		local actor = Unit.actor(unit, 1)

		Actor.set_kinematic(actor, true)
	end

	World.unlink_unit(self._world, unit)
	World.link_unit(self._world, unit, self._node, wand_unit, attach_node)
	Unit.teleport_local_position(unit, self._node, Vector3(unpack(HandgunSettings.grip_position_offset)))
	Unit.teleport_local_rotation(unit, self._node, Quaternion.from_euler_angles_xyz(unpack(HandgunSettings.grip_rotation_offset)))

	self._wand_unit = wand_unit
	self._attach_node = attach_node
	self._wand_input = wand_input
	self._wand_hand = wand_hand

	self:set_is_gripped(true)
	Unit.flow_event(self._unit, "pickup_sound")
end

HandgunExtension.interaction_ended = function (self, wand_input, wand_unit)
	self:_drop()

	self._wand_unit = nil
	self._attach_node = nil
	self._wand_input = nil
	self._wand_hand = nil

	Unit.flow_event(self._unit, "drop_sound")

	return not self._wand_input
end

HandgunExtension._drop = function (self)
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

HandgunExtension._trigger_vibration = function (self)
	self._is_vibrating = true
end

HandgunExtension._stop_vibration = function (self)
	self._is_vibrating = false
end

HandgunExtension._update_vibration = function (self, dt)
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

HandgunExtension._vibrate = function (self)
	if not self._wand_input then
		return
	end

	local vibration_strength = HandgunSettings.base_vibration_strength

	self._wand_input:trigger_feedback(vibration_strength)
end

HandgunExtension.set_is_gripped = function (self, gripped)
	self._gripped = gripped
end

HandgunExtension.is_gripped = function (self)
	return self._gripped
end

HandgunExtension._start_reload = function (self)
	if not self._reload_time then
		Unit.flow_event(self._unit, "reload_sound")
		Unit.animation_event(self._unit, "spin")

		self._reload_time = 0
	end
end

HandgunExtension._update_reload = function (self, dt, t)
	if self._reload_time then
		if self._reload_time < HandgunSettings.reload_time then
			self._reload_time = self._reload_time + dt
		elseif self._reload_time > HandgunSettings.reload_time then
			self._reload_time = nil
			self._fired_shots = 0
		end
	end
end

HandgunExtension.interaction_radius = function (self)
	return HandgunSettings.interaction_radius
end

HandgunExtension.set_interactable = function (self, is_interactable)
	self._is_interactable = is_interactable
end

HandgunExtension.is_interactable = function (self)
	return self._is_interactable
end

HandgunExtension._start_trail = function (self, from, to, dir)
	local t = Managers.time:time("game")

	self._trail_draw_time = t + HandgunSettings.trail_draw_time

	local color = Color(unpack(HandgunSettings.trail_color))

	if to then
		LineObject.add_line(self._handgun_trail, color, from, to)
	else
		LineObject.add_line(self._handgun_trail, color, from, from + dir * 50)
	end

	LineObject.dispatch(self._world, self._handgun_trail)
end

HandgunExtension._update_trail = function (self, dt, t)
	local trail_time = self._trail_draw_time

	if trail_time and trail_time < t then
		LineObject.reset(self._handgun_trail)
		LineObject.dispatch(self._world, self._handgun_trail)

		trail_time = nil
	end
end

HandgunExtension._get_world_extents = function (self)
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

HandgunExtension._add_impact_push_vector_field = function (self)
	self._fire_push_vf = World.vector_field(self._world, "wind")

	local position, up, settings = self:_dynamic_parameters()
	local parameters = {
		center = position,
		up = up,
		speed = Vector4(1, 1, 1, 1),
		radius = Vector4(1, 1, 1, 1)
	}

	self._fire_push_vf_id = VectorField.add(self._fire_push_vf, "vector_fields/magic_pull_push", parameters, settings)
end

HandgunExtension._trigger_force_push = function (self, position)
	local _, up, settings = self:_dynamic_parameters()
	local radius = HandgunSettings.fire_push_cloth.radius
	local speed = HandgunSettings.fire_push_cloth.speed
	local parameters = {
		center = Vector4(position.x, position.y, position.z, 0),
		up = up,
		radius = Vector4(radius, radius, radius, radius),
		speed = Vector4(speed, speed, speed, speed)
	}

	VectorField.change(self._fire_push_vf, self._fire_push_vf_id, "vector_fields/magic_pull_push", parameters, settings)

	self._triggered_force_push = true
end

HandgunExtension._reset_force_push_vector_field = function (self)
	local position, up, settings = self:_dynamic_parameters()
	local radius = HandgunSettings.fire_push_cloth.radius
	local speed = HandgunSettings.fire_push_cloth.speed
	local parameters = {
		center = position,
		up = up,
		radius = Vector4(1, 1, 1, 1),
		speed = Vector4(0, 0, 0, 0)
	}

	VectorField.change(self._fire_push_vf, self._fire_push_vf_id, "vector_fields/magic_pull_push", parameters, settings)

	self._triggered_force_push = true
end

HandgunExtension._dynamic_parameters = function (self)
	local pos = Unit.world_position(self._unit, self._node)
	local rot = Unit.world_rotation(self._unit, self._node)
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
