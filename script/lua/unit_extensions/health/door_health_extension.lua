-- chunkname: @script/lua/unit_extensions/health/door_health_extension.lua

require("script/lua/unit_extensions/health/health_extension")
class("DoorHealthExtension", "HealthExtension")

DoorHealthExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._world = extension_init_context.world
	self._unit = unit
	self._level = extension_init_context.level
	self._health = Unit.get_data(unit, "health")
	self._damage = 0
	self._level_unit_index = Level.unit_index(self._level, self._unit)
	self._network_mode = extension_init_context.network_mode

	if Managers.state.network then
		self.add_damage = self.add_damage_network
	else
		self.add_damage = self.add_damage_local
	end
end

DoorHealthExtension.destroy = function (self)
	return
end

DoorHealthExtension.extensions_ready = function (self, world, unit)
	return
end

DoorHealthExtension.update = function (self, unit, dt, t)
	return
end

DoorHealthExtension.is_alive = function (self)
	return HealthExtension.is_alive(self)
end

DoorHealthExtension.is_dead = function (self)
	return HealthExtension.is_dead(self)
end

DoorHealthExtension.add_damage = function (self)
	error("function is redefined in init() to either *_network or *_local")
end

DoorHealthExtension.add_damage_local = function (self, damage, params)
	local ai_attack = params.ai_attack

	if not ai_attack then
		return
	end

	HealthExtension.add_damage(self, damage)

	local damage = self._damage
	local health = self._health
	local health_percent = 1 - damage / health
	local unit = self._unit

	if health_percent < 1 then
		Unit.flow_event(unit, "lua_door_broken_state_1")
	end

	if health_percent < 0.85 then
		Unit.flow_event(unit, "lua_door_broken_state_2")
	end

	if health_percent < 0.6 then
		Unit.flow_event(unit, "lua_door_broken_state_3")
	end

	if health_percent < 0.45 then
		Unit.flow_event(unit, "lua_door_broken_state_4")
	end

	if health_percent < 0.3 then
		Unit.flow_event(unit, "lua_door_broken_state_5")
	end

	if health_percent < 0.15 then
		Unit.flow_event(unit, "lua_door_broken_state_6")
	end

	if health_percent <= 0 then
		Unit.flow_event(unit, "lua_door_destroyed")
	end

	Unit.flow_event(unit, "lua_door_hit")
end

DoorHealthExtension.add_damage_network = function (self, damage, params)
	local ai_attack = params.ai_attack

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

DoorHealthExtension.die = function (self, hit_direction, hit_force, hit_node_index)
	return
end
