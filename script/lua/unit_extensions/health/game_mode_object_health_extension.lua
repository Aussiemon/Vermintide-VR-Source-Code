-- chunkname: @script/lua/unit_extensions/health/game_mode_object_health_extension.lua

require("script/lua/unit_extensions/health/health_extension")
require("settings/explosive_barrel_settings")

local ExplosiveBarrelSettings = ExplosiveBarrelSettings

class("GameModeObjectHealthExtension", "HealthExtension")

GameModeObjectHealthExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._world = extension_init_context.world
	self._unit = unit
	self._level = extension_init_context.level
	self._health = Unit.get_data(unit, "health")
	self._damage = 0
	self._level_unit_index = Level.unit_index(self._level, self._unit)
	self._network_mode = extension_init_context.network_mode
	self._player_target = Unit.get_data(unit, "player_target")
	self._exploding = Unit.get_data(unit, "exploding")

	if Managers.state.network then
		self.add_damage = self.add_damage_network
	else
		self.add_damage = self.add_damage_local
	end
end

GameModeObjectHealthExtension.destroy = function (self)
	return
end

GameModeObjectHealthExtension.extensions_ready = function (self, world, unit)
	return
end

GameModeObjectHealthExtension.update = function (self, unit, dt, t)
	return
end

GameModeObjectHealthExtension.is_alive = function (self)
	return HealthExtension.is_alive(self)
end

GameModeObjectHealthExtension.is_dead = function (self)
	return HealthExtension.is_dead(self)
end

GameModeObjectHealthExtension.add_damage = function (self)
	error("function is redefined in init() to either *_network or *_local")
end

GameModeObjectHealthExtension.add_damage_local = function (self, damage, params)
	local ai_attack = params.ai_attack or self._player_target

	if not ai_attack then
		return
	end

	HealthExtension.add_damage(self, damage, params)
end

GameModeObjectHealthExtension.add_damage_network = function (self, damage, params)
	local ai_attack = params.ai_attack or self._player_target

	if not ai_attack then
		return
	end

	self:add_damage_local(damage, params)

	local network_mode = self._network_mode

	if network_mode == "server" then
		local level_unit_id = self._level_unit_index

		Managers.state.network:send_rpc_clients("rpc_add_damage_level_unit", level_unit_id, damage)
		printf("sending-> %s %d %d", "rpc_add_damage_level_unit", level_unit_id, damage)
	end
end

GameModeObjectHealthExtension.die = function (self, params)
	local unit = self._unit

	if self._exploding then
		self:_explode(params)
	end

	Unit.flow_event(unit, "lua_destroyed")
end

GameModeObjectHealthExtension._explode = function (self, params)
	local position = Unit.local_position(self._unit, 1)
	local position_box = Vector3Box(position)
	local radius = 3
	local world = self._world
	local physics_world = World.physics_world(world)
	local hit_units = {}

	local function overlap_callback(actors)
		local position = position_box:unbox()

		for _, actor in pairs(actors) do
			local hit_unit = Actor.unit(actor)

			if hit_unit and not hit_units[hit_unit] then
				hit_units[hit_unit] = true

				local damage = ExplosiveBarrelSettings.damage
				local force = ExplosiveBarrelSettings.force
				local peer_id = params.peer_id
				local hit_node_index = Actor.node(actor)
				local hit_pos = Actor.position(actor)
				local dir = hit_pos - position
				local dir_n = Vector3.normalize(dir)
				local distance = Vector3.length(dir)
				local hit_force = force / math.sqrt(distance)
				local has_health_extension = ScriptUnit.has_extension(hit_unit, "health_system")

				if has_health_extension then
					if self._network_mode ~= "client" then
						local health_extension = ScriptUnit.extension(hit_unit, "health_system")
						local damage_parameters = {
							hit_direction = dir_n,
							hit_force = hit_force,
							hit_node_index = hit_node_index,
							peer_id = peer_id,
							force_dismember = ExplosiveBarrelSettings.always_dismember
						}

						health_extension:add_damage(damage, damage_parameters)
					end
				elseif Actor.is_dynamic(actor) and not Actor.is_kinematic(actor) then
					Actor.wake_up(actor)

					local push = dir * hit_force

					Actor.add_impulse(actor, push)
					Unit.flow_event(hit_unit, "lua_simple_damage")
				end
			end
		end
	end

	PhysicsWorld.overlap(physics_world, overlap_callback, "shape", "sphere", "position", position, "size", radius, "collision_filter", "filter_explosion")
end
