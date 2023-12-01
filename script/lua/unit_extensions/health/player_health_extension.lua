-- chunkname: @script/lua/unit_extensions/health/player_health_extension.lua

require("script/lua/unit_extensions/health/health_extension")
require("settings/player_health_settings")
class("PlayerHealthExtension", "HealthExtension")

local function debug_printf(...)
	if script_data.debug_health then
		printf(...)
	end
end

PlayerHealthExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._world = extension_init_context.world
	self._unit = unit
	self._level = extension_init_context.level
	self._level_name = extension_init_context.level_name
	self._health = PlayerHealthSettings.max_health[self._level_name] or PlayerHealthSettings.max_health.default
	self._damage = 0
	self._network_mode = extension_init_context.network_mode
	self._is_husk = extension_init_data.is_husk

	if Managers.state.network then
		self.add_damage = self.add_damage_network
	else
		self.add_damage = self.add_damage_local
	end

	local initial_injury_level = self:_injury_level()

	Managers.state.hud:set_injury_level(initial_injury_level)
end

PlayerHealthExtension.destroy = function (self)
	return
end

PlayerHealthExtension.extensions_ready = function (self, world, unit)
	return
end

PlayerHealthExtension.update = function (self, unit, dt, t)
	if self._vibrate_controllers_duration then
		self:_update_vibrate_controllers(dt)
	end

	local network_mode = self._network_mode

	if network_mode == "server" or network_mode == "local" then
		self:_update_regeneration(t, dt)
	end
end

PlayerHealthExtension.is_alive = function (self)
	return HealthExtension.is_alive(self)
end

PlayerHealthExtension.is_dead = function (self)
	return HealthExtension.is_dead(self)
end

PlayerHealthExtension.add_damage = function (self)
	error("function is redefined in init() to either *_network or *_local")
end

PlayerHealthExtension.add_damage_local = function (self, damage, params)
	local ai_attack = params.ai_attack

	if not ai_attack then
		return
	end

	HealthExtension.add_damage(self, damage, params)

	self._last_damage_at = Managers.time:time("game")

	local is_local_player = not self._is_husk

	if is_local_player then
		self:_vibrate_controllers()

		local injury_level = self:_injury_level()

		Managers.state.hud:set_injury_level(injury_level)
		Managers.state.hud:add_damage_indicator(damage, params)
	end
end

PlayerHealthExtension.add_damage_network = function (self, damage, params)
	local ai_attack = params and params.ai_attack

	if not ai_attack then
		return
	end

	self:add_damage_local(damage, params)

	local network_mode = self._network_mode

	if network_mode == "server" and self._is_husk then
		local unit = self._unit
		local head_system = Managers.state.extension:system("head_system")
		local game_object_id = head_system:game_object_id(unit)
		local damage_type = params.damage_type
		local damage_type_id = DamageTypeLookup[damage_type]

		Managers.state.network:send_rpc_clients("rpc_add_damage_player", game_object_id, damage, damage_type_id)
		printf("sending-> %s %d %d", "rpc_add_damage_player", game_object_id, damage, damage_type_id)
	end
end

PlayerHealthExtension.die = function (self, hit_direction, hit_force, hit_node_index)
	if self._network_mode == "client" then
		return
	end

	Managers.state.game_mode:set_end_conditions_met("defeat")
end

PlayerHealthExtension._injury_level = function (self)
	local health = self._health
	local damage = self._damage
	local health_percent = math.clamp(math.round_with_precision(1 - damage / health, 2), 0, 1)
	local injury_levels = PlayerHealthSettings.injury_levels

	for injury_level, data in pairs(injury_levels) do
		local health_data = data.health
		local min_health = health_data.min
		local max_health = health_data.max

		if min_health <= health_percent and health_percent <= max_health then
			return injury_level
		end
	end
end

PlayerHealthExtension._vibrate_controllers = function (self)
	self._vibrate_controllers_duration = PlayerHealthSettings.haptic_feedback_duration
end

PlayerHealthExtension._update_vibrate_controllers = function (self, dt)
	local vibrate_controllers_duration = self._vibrate_controllers_duration
	local controllers = Managers.state.extension:get_entities("WandExtension")

	for unit, wand_extension in pairs(controllers) do
		wand_extension:trigger_feedback(1)
		debug_printf("VIBRATING")
	end

	vibrate_controllers_duration = vibrate_controllers_duration - dt
	self._vibrate_controllers_duration = vibrate_controllers_duration > 0 and vibrate_controllers_duration or nil
end

PlayerHealthExtension._update_regeneration = function (self, t, dt)
	if self._damage == 0 then
		return
	end

	if self:is_dead() then
		return
	end

	local last_damage_at = self._last_damage_at
	local regeneration_delay = PlayerHealthSettings.regeneration_delay
	local regeneration_start = last_damage_at + regeneration_delay

	if regeneration_start < t then
		local regeneration = PlayerHealthSettings.regeneration_speed * dt
		local previous_damage = math.round(self._damage)
		local damage = self._damage - regeneration

		self:set_damage(damage)

		local network_mode = self._network_mode

		if network_mode == "server" and self._is_husk then
			local current_damage = math.round(self._damage)

			if previous_damage ~= current_damage then
				local unit = self._unit
				local head_system = Managers.state.extension:system("head_system")
				local game_object_id = head_system:game_object_id(unit)

				Managers.state.network:send_rpc_clients("rpc_set_damage_player", game_object_id, current_damage)
				printf("sending-> %s %d %d", "rpc_set_damage_player", game_object_id, current_damage)
			end
		end
	end
end

PlayerHealthExtension.set_damage = function (self, damage)
	self._damage = math.max(damage, 0)

	local is_local_player = not self._is_husk

	if is_local_player then
		local injury_level = self:_injury_level()

		Managers.state.hud:set_injury_level(injury_level)
		debug_printf("REGENERATING damage is now %f", self._damage)
	end
end
