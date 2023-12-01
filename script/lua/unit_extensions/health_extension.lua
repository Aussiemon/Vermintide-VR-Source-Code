-- chunkname: @script/lua/unit_extensions/health_extension.lua

class("HealthExtension")

HealthExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._world = extension_init_context.world
	self._unit = unit
	self._level = extension_init_context.level
	self._health = extension_init_data.health or Unit.get_data(unit, "health")
	self._ragdoll_on_death = extension_init_data.ragdoll_on_death
	self._damage = 0
	self._breed_name = extension_init_data.breed_name
end

HealthExtension.destroy = function (self)
	return
end

HealthExtension.extensions_ready = function (self, world, unit)
	return
end

HealthExtension.update = function (self, unit, dt, t)
	if self._is_pushed then
		local push_direction = self._push_direction:unbox()
		local push_strength = self._push_strength
		local push_node_index = self._push_node_index
	end
end

HealthExtension.is_alive = function (self)
	local remaining_health = self._health - self._damage
	local is_alive = remaining_health > 0

	return is_alive
end

HealthExtension.is_dead = function (self)
	return not self:is_alive()
end

HealthExtension.add_damage = function (self, damage, hit_direction, hit_force, hit_node_index)
	local is_dead = self:is_dead()

	if is_dead then
		return
	end

	self._damage = self._damage + damage

	if self._damage >= self._health then
		self:die(hit_direction, hit_force, hit_node_index)
	end
end

HealthExtension.die = function (self, hit_direction, hit_force, hit_node_index)
	Managers.state.spawn:remove_num_spawned_breed_type(self._breed_name)

	if not self._ragdoll_on_death then
		return
	end

	local unit = self._unit

	if ScriptUnit.has_extension(unit, "ai_system") then
		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
		local blackboard = ai_base_extension:blackboard()

		blackboard.is_dead = true
	end

	if ScriptUnit.has_extension(unit, "ai_inventory_system") then
		local inventory_extension = ScriptUnit.extension(unit, "ai_inventory_system")

		inventory_extension:disable_inventory_scene_queries()
	end

	if not Managers.lobby or Managers.lobby and Managers.lobby.server then
		self:ragdoll(hit_direction, hit_force, hit_node_index)
	end

	Unit.flow_event(unit, "die")
	self:_disable_collision()
end

HealthExtension.ragdoll = function (self, push_direction, push_strength, push_node_index)
	local unit = self._unit

	self._push_direction = Vector3Box(push_direction or Vector3(0, 0, 0))
	self._push_strength = push_strength
	self._push_node_index = push_node_index

	Unit.animation_event(unit, "ragdoll")

	if not Managers.lobby or Managers.lobby and Managers.lobby.server then
		local ai_extension = ScriptUnit.extension(unit, "ai_system")

		if ai_extension then
			local ai_id = ai_extension.game_object_id
			local data = {
				level_unit_id = 1,
				push_seed = 0,
				from_ai = true,
				push_strength = push_strength,
				push_direction = push_direction,
				push_node_index = push_node_index,
				ai_id = ai_id,
				position = Vector3(0, 0, 0),
				rotation = Quaternion.identity()
			}

			Managers.state.event:trigger("event_ragdoll_spawn", unit, data)
		end
	end

	self._is_pushed = true
end

HealthExtension._push = function (self, push_strength, push_direction, push_node_index)
	local unit = self._unit
	local has_pushed = false
	local actor = Unit.actor(unit, push_node_index)

	if actor and not Actor.is_kinematic(actor) then
		Actor.wake_up(actor)

		local push = push_direction * push_strength

		Actor.add_impulse(actor, push)

		has_pushed = true
	end

	return has_pushed
end

HealthExtension._disable_collision = function (self)
	local unit = self._unit
	local num_actors = Unit.num_actors(self._unit)

	for i = 1, num_actors do
		local actor = Unit.actor(unit, i)

		if actor then
			Actor.set_collision_enabled(actor, false)
		end
	end
end
