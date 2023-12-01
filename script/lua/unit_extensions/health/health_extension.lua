-- chunkname: @script/lua/unit_extensions/health/health_extension.lua

class("HealthExtension")

local DEBUG_DISMEMBER = false
local DISABLE_DISMEMBER = false

HealthExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._world = extension_init_context.world
	self._unit = unit
	self._level = extension_init_context.level
	self._health = extension_init_data.health or Unit.get_data(unit, "health")
	self._ragdoll_on_death = extension_init_data.ragdoll_on_death
	self._damage = 0
	self._breed_name = extension_init_data.breed_name
	self._network_mode = extension_init_context.network_mode
end

HealthExtension.destroy = function (self)
	return
end

HealthExtension.extensions_ready = function (self, world, unit)
	return
end

HealthExtension.update = function (self, unit, dt, t)
	if DEBUG_DISMEMBER and stingray.Keyboard.button(stingray.Keyboard.button_id("l")) == 1 then
		self:add_damage(1000, {
			hit_node_index = 1,
			score_disabled = true,
			force_dismember = true,
			hit_force = 1,
			hit_direction = Vector3(0, 0, 1)
		})
	end

	if self._is_pushed then
		local push_direction = self._push_direction:unbox()
		local push_strength = self._push_strength
		local push_node_index = self._push_node_index

		if self:_push(push_direction, push_strength, push_node_index) then
			local dismember_enabled = Managers.differentiation:dismember_enabled() or DEBUG_DISMEMBER

			if dismember_enabled and self._was_dismembered then
				self:dismember(push_node_index)

				self._was_dismembered = nil
			end

			self._is_pushed = nil
		end
	end
end

HealthExtension.is_alive = function (self)
	local remaining_health = self._health - self._damage
	local is_alive = remaining_health > 0

	return is_alive
end

HealthExtension.is_dead = function (self)
	return self._dead or not self:is_alive()
end

HealthExtension.add_damage = function (self, damage, params)
	local is_dead = self:is_dead()

	if is_dead then
		return
	end

	local unit = self._unit
	local hitreaction_extension = ScriptUnit.extension(unit, "hitreaction_system")

	if hitreaction_extension then
		hitreaction_extension:add_hitreaction(params)
	end

	self._damage = self._damage + damage

	if self._damage >= self._health then
		self:die(params)

		return
	end
end

HealthExtension.die = function (self, params)
	Managers.state.spawn:remove_num_spawned_breed_type(self._breed_name)

	local unit = self._unit
	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

	if ai_base_extension and not ai_base_extension.is_level_unit then
		local blackboard = ai_base_extension:blackboard()

		blackboard.is_dead = true
	end

	local score_enabled = not params.score_disabled
	local add_score = self._network_mode ~= "client" and score_enabled

	if add_score then
		local peer_id = params.peer_id
		local hit_node_index = params.hit_node_index
		local head_node = Unit.node(unit, "c_head")

		if hit_node_index == head_node then
			Managers.state.score:add_score("headshots", peer_id)
		end

		Managers.state.score:add_score("kills", peer_id)
	end

	if ScriptUnit.has_extension(unit, "ai_inventory_system") then
		local inventory_extension = ScriptUnit.extension(unit, "ai_inventory_system")

		inventory_extension:disable_inventory_scene_queries()
	end

	if not self._ragdoll_on_death then
		local breed_name = self._breed_name
		local breed = Breeds[breed_name]
		local death_animations = breed.death_animations

		if death_animations then
			local death_animation = death_animations[Math.random(#death_animations)]

			Unit.animation_event(unit, death_animation)
			self:_disable_collision()

			self._dead = true
		end

		return
	end

	local hit_node_index = params.hit_node_index

	if hit_node_index then
		local breed_name = self._breed_name
		local breed = Breeds[breed_name]

		params.was_dismembered = params.force_dismember or self:_get_was_dismembered(breed, hit_node_index)
	end

	if not Managers.lobby or Managers.lobby and Managers.lobby.server then
		self:ragdoll(params)
	end

	Unit.flow_event(unit, "die")
	self:_disable_collision()

	self._dead = true
end

HealthExtension.ragdoll = function (self, params)
	local unit = self._unit
	local push_direction = params.hit_direction
	local push_strength = params.hit_force
	local push_node_index = params.hit_node_index

	self._push_direction = Vector3Box(push_direction)
	self._push_strength = push_strength
	self._push_node_index = push_node_index

	Unit.animation_event(unit, "ragdoll")

	if self._network_mode ~= "client" then
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
				dismember = params.was_dismembered,
				position = Vector3(0, 0, 0),
				rotation = Quaternion.identity()
			}

			Managers.state.event:trigger("event_ragdoll_spawn", unit, data)
		end
	end

	self._is_pushed = true
	self._was_dismembered = params.was_dismembered
end

HealthExtension._push = function (self, push_strength, push_direction, push_node_index)
	local unit = self._unit
	local has_pushed = false
	local breed_name = self._breed_name
	local breed = Breeds[breed_name]
	local hit_zone = self:_get_hit_zone(breed, push_node_index)

	if not hit_zone then
		return false
	end

	local hit_zones = breed.hit_zones
	local hit_zone_data = hit_zones[hit_zone]
	local push_actors = hit_zone_data.push_actors

	for i, actor_name in ipairs(push_actors) do
		local actor = Unit.actor(unit, actor_name)

		if actor and not Actor.is_kinematic(actor) then
			Actor.wake_up(actor)

			local push = push_direction * push_strength

			Actor.add_impulse(actor, push)

			has_pushed = true
		end
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

HealthExtension.dismember = function (self, hit_node_index)
	local unit = self._unit
	local breed_name = self._breed_name
	local breed = Breeds[breed_name]

	if DEBUG_DISMEMBER then
		self:_dismember_hit_zone("head")
		self:_dismember_hit_zone("torso")
		self:_dismember_hit_zone("left_arm")
		self:_dismember_hit_zone("right_arm")
		self:_dismember_hit_zone("left_leg")
		self:_dismember_hit_zone("right_leg")
		self:_dismember_hit_zone("tail")
	else
		local hit_zone = self:_get_hit_zone(breed, hit_node_index)

		if hit_zone then
			self:_dismember_hit_zone(hit_zone)
		end
	end
end

HealthExtension._get_hit_zone = function (self, breed, hit_node_index)
	local unit = self._unit
	local hit_zones = breed.hit_zones

	for hit_zone_name, hit_zone_data in pairs(hit_zones) do
		local hit_zone_actors = hit_zone_data.actors

		for i, actor_name in ipairs(hit_zone_actors) do
			local actor_node_index = Unit.node(unit, actor_name)

			if actor_node_index == hit_node_index then
				return hit_zone_name
			end
		end
	end
end

HealthExtension._get_was_dismembered = function (self, breed, hit_node_index)
	local hit_zone = self:_get_hit_zone(breed, hit_node_index)

	if not hit_zone then
		return
	end

	local unit = self._unit
	local hit_zones = breed.hit_zones
	local hit_zone_data = hit_zones[hit_zone]
	local dismember_chance = hit_zone_data.dismember_chance or 0

	dismember_chance = DISABLE_DISMEMBER and 0 or dismember_chance

	if not dismember_chance then
		return false
	end

	local random_roll = Math.random()

	if dismember_chance < random_roll then
		return false
	end

	return true
end

HealthExtension._dismember_hit_zone = function (self, hit_zone)
	local unit = self._unit
	local dismember_flow_event = "dismember_" .. hit_zone

	Unit.flow_event(unit, dismember_flow_event)
end
