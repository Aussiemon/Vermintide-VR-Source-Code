-- chunkname: @script/lua/managers/extension/systems/aggro_system.lua

require("script/lua/unit_extensions/aggro_extension")
class("AggroSystem", "ExtensionSystemBase")

AggroSystem.extension_list = {
	"AggroExtension"
}

AggroSystem.init = function (self, extension_system_creation_context, system_name, extension_list)
	AggroSystem.super.init(self, extension_system_creation_context, system_name, extension_list)

	self.aggroable_units = {}
end

AggroSystem.on_add_extension = function (self, world, unit, extension_name, extension_init_data)
	self.aggroable_units[unit] = true

	local is_level_unit = true

	if is_level_unit then
		POSITION_LOOKUP[unit] = Unit.world_position(unit, 1)
	end

	return AggroSystem.super.on_add_extension(self, world, unit, extension_name, extension_init_data)
end

AggroSystem.on_remove_extension = function (self, unit, extension_name)
	REMOVE_AGGRO_UNITS(unit)
	AggroSystem.super.on_remove_extension(self, unit, extension_name)

	self.aggroable_units[unit] = nil
end

AggroSystem.destroy = function (self)
	AggroSystem.super.destroy(self)

	self.aggroable_units = nil
end
