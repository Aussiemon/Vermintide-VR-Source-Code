-- chunkname: @script/lua/managers/extension/systems/health_system.lua

require("script/lua/unit_extensions/health/health_extension")
require("script/lua/unit_extensions/health/door_health_extension")
require("script/lua/unit_extensions/health/player_health_extension")
require("script/lua/unit_extensions/health/game_mode_object_health_extension")
class("HealthSystem", "ExtensionSystemBase")

HealthSystem.extension_list = {
	"HealthExtension",
	"DoorHealthExtension",
	"PlayerHealthExtension",
	"GameModeObjectHealthExtension"
}

HealthSystem.init = function (self, extension_system_creation_context, system_name, extension_list)
	HealthSystem.super.init(self, extension_system_creation_context, system_name, extension_list)

	local network = Managers.lobby

	if network then
		local is_server = network.server

		self._network_mode = is_server and "server" or "client"

		if is_server then
			-- Nothing
		else
			Managers.state.network:register_rpc_callbacks(self, "rpc_add_damage_level_unit", "rpc_add_damage_player", "rpc_set_damage_player")
		end
	else
		self._network_mode = "local"
	end

	self._extension_init_context.network_mode = self._network_mode
end

HealthSystem.rpc_add_damage_level_unit = function (self, sender, level_unit_id, damage)
	printf("received-> %s %d %d", "rpc_add_damage_level_unit", level_unit_id, damage)

	local unit = Level.unit_by_index(self._level, level_unit_id)
	local health_extension = ScriptUnit.extension(unit, "health_system")
	local params = {
		ai_attack = true
	}

	health_extension:add_damage(damage, params)
end

HealthSystem.rpc_add_damage_player = function (self, sender, game_object_id, damage, damage_type_id)
	printf("received-> %s %d %d", "rpc_add_damage_player", game_object_id, damage, damage_type_id)

	local entities = Managers.state.extension:get_entities("HeadExtension")

	for unit, head_extension in pairs(entities) do
		repeat
			local unit_game_object_id = head_extension.game_object_id

			if game_object_id ~= unit_game_object_id then
				break
			end

			local damage_type = DamageTypeLookup[damage_type_id]
			local health_extension = ScriptUnit.extension(unit, "health_system")
			local params = {
				ai_attack = true,
				damage_type = damage_type
			}

			health_extension:add_damage(damage, params)

			return
		until true
	end
end

HealthSystem.rpc_set_damage_player = function (self, sender, game_object_id, damage)
	printf("received-> %s %d %d", "rpc_set_damage_player", game_object_id, damage)

	local entities = Managers.state.extension:get_entities("HeadExtension")

	for unit, head_extension in pairs(entities) do
		repeat
			local unit_game_object_id = head_extension.game_object_id

			if game_object_id ~= unit_game_object_id then
				break
			end

			local health_extension = ScriptUnit.extension(unit, "health_system")

			health_extension:set_damage(damage)

			return
		until true
	end
end
