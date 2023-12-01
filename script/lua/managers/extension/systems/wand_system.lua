-- chunkname: @script/lua/managers/extension/systems/wand_system.lua

class("WandSystem", "ExtensionSystemBase")

WandSystem.init = function (self, ...)
	WandSystem.super.init(self, ...)

	local network_manager = Managers.state.network

	if network_manager then
		network_manager:register_game_object_callback(self, "wand", "wand_game_object_created", "wand_game_object_destroyed")
	end

	self._remote_units = {}
end

WandSystem.wand_game_object_created = function (self, object_type, session, object_id, owner)
	local wand_id = GameSession.game_object_field(session, object_id, "type_index")
	local wand_type = WandUnitLookup[wand_id]
	local wand_settings = WandSettings[wand_type]
	local unit_name = wand_settings.unit_name
	local position = GameSession.game_object_field(session, object_id, "position")
	local rotation = GameSession.game_object_field(session, object_id, "rotation")
	local unit = World.spawn_unit(self._world, unit_name, position, rotation)

	Unit.set_data(unit, "extensions", 0, "WandHuskExtension")
	Managers.state.extension:register_unit(self._world, unit, {
		wand_system = {
			game_object_id = object_id,
			settings = wand_settings
		}
	})

	self._remote_units[object_id] = unit
end

WandSystem.wand_game_object_destroyed = function (self, object_type, session, object_id, owner)
	local unit = self._remote_units[object_id]

	Managers.state.extension:unregister_unit(unit)

	self._remote_units[unit] = nil

	World.destroy_unit(self._world, unit)
end
