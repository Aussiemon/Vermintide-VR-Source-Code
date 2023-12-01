-- chunkname: @script/lua/arrow_handler.lua

require("settings/bow_settings")
require("script/lua/helpers/effect_helper")

local BowSettings = BowSettings
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local World = stingray.World
local Actor = stingray.Actor
local Matrix4x4 = stingray.Matrix4x4
local Quaternion = stingray.Quaternion
local Vector3Box = stingray.Vector3Box
local Vector4 = stingray.Vector4
local PhysicsWorld = stingray.PhysicsWorld
local Wwise = stingray.Wwise
local WwiseWorld = stingray.WwiseWorld
local LineObject = stingray.LineObject
local Color = stingray.Color
local DEBUG = false
local DEBUG_HITS = false

class("ArrowHandler")

ArrowHandler.init = function (self, world, bow_vector_field_extension, network_mode)
	self._world = world
	self._physics_world = World.physics_world(world)
	self._wwise_world = Wwise.wwise_world(world)
	self._arrows = {}
	self._stuck_arrows = {}
	self._bow_vector_field_extension = bow_vector_field_extension
	self._line_object = World.create_line_object(self._world)

	if DEBUG_HITS then
		self._debug_hits = DebugDrawer:new(World.create_line_object(self._world), true)
	end

	self._network_mode = network_mode
end

ArrowHandler.fire_arrow = function (self, position, direction, look_target_pos, draw_length, do_damage, peer_id)
	local arrow = World.spawn_unit(self._world, "units/weapons/player/wpn_we_bow_03_t1/proj_arrow", position)
	local position = Unit.world_position(arrow, 1)
	local vector_field_index = self._bow_vector_field_extension:add_arrow(position)

	for ii = 1, Unit.num_actors(arrow) do
		local actor = Unit.actor(arrow, ii)

		if actor and Actor.is_dynamic(actor) then
			Actor.set_scene_query_enabled(actor, false)
		end
	end

	Unit.flow_event(arrow, "lua_trail")
	Unit.flow_event(arrow, "fire_sound")

	self._arrows[#self._arrows + 1] = {
		unit = arrow,
		velocity = Vector3Box(direction * BowSettings.arrow_speed * draw_length),
		look_target_pos = Vector3Box(look_target_pos),
		draw_length = draw_length,
		do_damage = do_damage,
		owner_peer_id = peer_id,
		vector_field_index = vector_field_index
	}
end

ArrowHandler._check_collision = function (self, pos, dir, length)
	local tip_pos = pos + BowSettings.max_draw_distance * dir
	local physics_world = self._physics_world
	local hit, pos, distance, normal, actor = PhysicsWorld.raycast(physics_world, tip_pos, dir, "closest", "collision_filter", "filter_arrow")

	if DEBUG then
		LineObject.add_line(self._line_object, Color(255, 255, 255), tip_pos, tip_pos + dir)
		LineObject.add_sphere(self._line_object, Color(255, 255, 255), tip_pos, 0.02)
		LineObject.add_sphere(self._line_object, Color(255, 200, 200), pos, 0.02)
	end

	if hit and distance < length then
		return pos, normal, actor
	end
end

ArrowHandler._hit = function (self, arrow, hit_pos, hit_normal, hit_actor, dir_n, do_damage, draw_length)
	if not hit_actor then
		return false
	end

	local hit_unit = Actor.unit(hit_actor)

	if not hit_unit then
		return false
	end

	local arrow_unit = arrow.unit
	local do_damage = arrow.do_damage
	local draw_length = arrow.draw_length
	local arrow_owner_peer_id = arrow.owner_peer_id
	local hit_unit_node_index = Actor.node(hit_actor)
	local final_pos = hit_pos - dir_n * BowSettings.max_draw_distance + dir_n * draw_length * 0.2 + dir_n * 0.05
	local has_health_extension = ScriptUnit.has_extension(hit_unit, "health_system")
	local target_exploding = Unit.get_data(hit_unit, "exploding")
	local trigger_volume = Unit.get_data(hit_unit, "trigger_volume")

	if has_health_extension and do_damage then
		local health_extension = ScriptUnit.extension(hit_unit, "health_system")
		local params = {
			hit_direction = dir_n,
			hit_force = BowSettings.force * draw_length,
			hit_node_index = hit_unit_node_index,
			peer_id = arrow_owner_peer_id,
			force_dismember = BowSettings.always_dismember
		}

		health_extension:add_damage(BowSettings.damage, params)
	end

	if ScriptUnit.has_extension(hit_unit, "ragdoll_system") then
		local ragdoll_extension = ScriptUnit.extension(hit_unit, "ragdoll_system")

		if ragdoll_extension.spawn_burst then
			ragdoll_extension:spawn_burst()
		end
	end

	if Unit.alive(hit_unit) and trigger_volume then
		Unit.set_flow_variable(hit_unit, "hit_actor", hit_actor)
		Unit.set_flow_variable(hit_unit, "hit_direction", dir_n)
		Unit.set_flow_variable(hit_unit, "hit_position", hit_pos)
		Unit.flow_event(hit_unit, "lua_simple_damage")
	elseif Unit.alive(hit_unit) then
		World.link_unit(self._world, arrow_unit, 1, hit_unit, hit_unit_node_index)

		local unit_transform = Matrix4x4.inverse(Unit.world_pose(hit_unit, hit_unit_node_index))
		local arrow_pos = Unit.world_position(arrow_unit, 1)
		local offset_pos = Matrix4x4.transform(unit_transform, final_pos)
		local unit_rot = Quaternion.inverse(Unit.world_rotation(hit_unit, hit_unit_node_index))
		local arrow_rot = Unit.world_rotation(arrow_unit, 1)
		local offset_rot = Quaternion.multiply(unit_rot, arrow_rot)

		Unit.teleport_local_position(arrow_unit, 1, offset_pos)
		Unit.teleport_local_rotation(arrow_unit, 1, offset_rot)

		local is_enemy = Unit.get_data(hit_unit, "breed")

		if not is_enemy then
			self:_hit_level_unit(hit_pos, dir_n, hit_normal, hit_unit)
		else
			self:_hit_enemy_unit(hit_pos, dir_n, hit_normal, hit_unit)
		end

		Unit.flow_event(arrow_unit, "lua_hit_target")

		for ii = 1, Unit.num_actors(arrow_unit) do
			local actor = Unit.actor(arrow_unit, ii)

			if actor then
				Actor.set_collision_enabled(actor, false)
			end
		end

		if self._network_mode ~= "client" then
			Unit.set_flow_variable(hit_unit, "hit_actor", hit_actor)
			Unit.set_flow_variable(hit_unit, "hit_direction", dir_n)
			Unit.set_flow_variable(hit_unit, "hit_position", hit_pos)
			Unit.flow_event(hit_unit, "lua_simple_damage")
		end
	end

	local stuck = Unit.alive(hit_unit) and not trigger_volume
	local arrow_alive = stuck or not stuck and not target_exploding

	return stuck, arrow_alive
end

ArrowHandler.update = function (self, dt)
	if DEBUG then
		LineObject.reset(self._line_object)
	end

	if DEBUG_HITS then
		self._debug_hits:update(self._world)
	end

	for index, arrow in pairs(self._arrows) do
		local arrow_unit = arrow.unit
		local draw_length = arrow.draw_length
		local velocity = arrow.velocity:unbox()
		local target_pos = arrow.look_target_pos:unbox()
		local old_pos = Unit.world_position(arrow_unit, 1)
		local dir_n = velocity / BowSettings.arrow_speed / draw_length
		local target_velocity = target_pos - old_pos
		local wanted_dir = Vector3.normalize(target_velocity)
		local current_rot = Quaternion.look(dir_n)
		local wanted_rot = Quaternion.look(wanted_dir)
		local new_rot = Quaternion.lerp(current_rot, wanted_rot, BowSettings.hmd_forward_influence.seek * BowSettings.hmd_forward_influence.seek_modifier * dt)
		local new_dir = Quaternion.forward(new_rot)
		local velocity = new_dir * BowSettings.arrow_speed * draw_length

		velocity.z = velocity.z - BowSettings.gravity * dt

		arrow.velocity:store(velocity)

		local new_pos = old_pos + velocity * dt
		local distance = Vector3.length(new_pos - old_pos)
		local hit_pos, hit_normal, hit_actor = self:_check_collision(old_pos, dir_n, distance)
		local stuck, alive = false, true

		if hit_pos then
			stuck, alive = self:_hit(arrow, hit_pos, hit_normal, hit_actor, dir_n, draw_length)
		end

		if old_pos.x > 1200 or old_pos.x < -1200 or old_pos.y > 1200 or old_pos.y < -1200 or old_pos.z > 1200 or old_pos.z < -1200 then
			alive = false
		end

		if stuck then
			self._bow_vector_field_extension:remove_arrow(arrow.vector_field_index)

			self._arrows[index] = nil
			self._stuck_arrows[#self._stuck_arrows + 1] = arrow_unit

			if DEBUG_HITS then
				self._debug_hits:line(new_pos - dir_n, new_pos + dir_n)
				self._debug_hits:sphere(new_pos + dir_n, 0.2)
				self._debug_hits:sphere(new_pos, 0.1, Color(255, 0, 0))
			end
		elseif alive then
			self._bow_vector_field_extension:set_arrow_position(new_pos, arrow.vector_field_index)

			local pose = Matrix4x4.from_translation(new_pos)
			local base_rot = Quaternion.from_euler_angles_xyz(90, 0, 0)
			local look = Quaternion.look(dir_n)
			local look = Quaternion.multiply(look, base_rot)

			Matrix4x4.set_rotation(pose, look)
			Unit.set_local_pose(arrow_unit, 1, pose)
		else
			self._bow_vector_field_extension:remove_arrow(arrow.vector_field_index)

			self._arrows[index] = nil

			World.destroy_unit(self._world, arrow_unit)
		end
	end

	if DEBUG then
		LineObject.dispatch(self._world, self._line_object)
	end

	if DEBUG_HITS then
		-- Nothing
	end
end

ArrowHandler._hit_level_unit = function (self, hit_position, hit_direction, hit_normal, hit_unit)
	local hit_effect = "arrow_impact"
	local world = self._world
	local wwise_world = self._wwise_world
	local hit_rotation = Quaternion.look(hit_direction)
	local is_husk = false

	EffectHelper.play_surface_material_effects(hit_effect, world, wwise_world, hit_unit, hit_position, hit_rotation, hit_normal, nil, is_husk)
end

ArrowHandler._hit_enemy_unit = function (self, hit_position, hit_direction, hit_normal, hit_unit)
	local hit_effect = "arrow_impact"
	local world = self._world
	local wwise_world = self._wwise_world
	local hit_rotation = Quaternion.look(hit_direction)
	local is_husk = false

	EffectHelper.play_skinned_surface_material_effects(hit_effect, world, wwise_world, hit_position, hit_rotation, hit_normal, is_husk, nil, nil, nil, nil)
end

ArrowHandler.destroy = function (self)
	for i = 1, #self._stuck_arrows do
		World.destroy_unit(self._world, self._stuck_arrows[i])
	end

	for _, arrow in pairs(self._arrows) do
		World.destroy_unit(self._world, arrow.unit)
	end
end
