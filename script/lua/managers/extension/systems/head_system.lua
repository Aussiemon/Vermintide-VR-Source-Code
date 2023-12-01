-- chunkname: @script/lua/managers/extension/systems/head_system.lua

class("HeadSystem", "ExtensionSystemBase")

HeadSystem.init = function (self, ...)
	HeadSystem.super.init(self, ...)

	local network_manager = Managers.state.network

	if network_manager then
		self._network_mode = Managers.lobby.server and "server" or "client"

		network_manager:register_game_object_callback(self, "head", "head_game_object_created", "head_game_object_destroyed")
	else
		self._network_mode = "local"
	end

	self._extension_init_context.network_mode = self._network_mode
	self._remote_units = {}
	self._extensions_list = {}
end

HeadSystem.on_add_extension = function (self, world, unit, extension_name, extension_init_data)
	local extension = HeadSystem.super.on_add_extension(self, world, unit, extension_name, extension_init_data)

	self._extensions_list[unit] = extension

	return extension
end

HeadSystem.head_game_object_created = function (self, object_type, session, object_id, owner)
	local head_settings = HeadSettings
	local unit_name = head_settings.unit_name
	local position = GameSession.game_object_field(session, object_id, "position")
	local rotation = GameSession.game_object_field(session, object_id, "rotation")
	local unit = World.spawn_unit(self._world, unit_name, position, rotation)

	Unit.set_data(unit, "extensions", 0, "HeadHuskExtension")

	if self._network_mode == "server" then
		Unit.set_data(unit, "extensions", 1, "AggroExtension")
		Unit.set_data(unit, "extensions", 2, "PlayerHealthExtension")
		Unit.set_data(unit, "extensions", 3, "AIPlayerSlotExtension")
		Unit.set_data(unit, "aggro_modifier_passive", 10)
		Unit.set_data(unit, "aggro_modifier_active", 20)
	end

	Managers.state.extension:register_unit(self._world, unit, {
		head_system = {
			game_object_id = object_id,
			settings = head_settings
		},
		health_system = {
			is_husk = true
		}
	})

	self._remote_units[object_id] = unit
end

HeadSystem.head_game_object_destroyed = function (self, object_type, session, object_id, owner)
	local unit = self._remote_units[object_id]

	Managers.state.extension:unregister_unit(unit)
	World.destroy_unit(self._world, unit)

	self._remote_units[object_id] = nil
end

HeadSystem.remote_unit = function (self, game_object_id)
	local unit = self._remote_units[game_object_id]

	fassert(unit, "HeadSystem:remote_unit no unit matching game_object_id:%d", game_object_id)

	return unit
end

HeadSystem.game_object_id = function (self, unit)
	local extension = self._extensions_list[unit]
	local game_object_id = extension.game_object_id

	return game_object_id
end
