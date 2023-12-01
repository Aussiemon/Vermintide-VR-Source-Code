-- chunkname: @script/lua/managers/extension/extension_manager.lua

require("script/lua/managers/extension/extension_system_bag")
require("foundation/script/util/script_unit")

local function readonlytable(table)
	return setmetatable({}, {
		__metatable = false,
		__index = table,
		__newindex = function (table, key, value)
			error("Coder trying to modify ExtensionManager's read-only empty table. Don't do it!")
		end
	})
end

local EMPTY_TABLE = readonlytable({})
local EXTENSIONS_WHITELIST = {
	AggroExtension = true,
	EnemyOutlineExtension = true,
	HealthExtension = true,
	AIAggroableSlotExtension = true,
	StaffOutlineExtension = true,
	AIEnemySlotExtension = true,
	HeadHuskExtension = true,
	AIHuskBaseExtension = true,
	InteractableLeverExtension = true,
	PlayerHealthExtension = true,
	AIInventoryExtension = true,
	HeadExtension = true,
	WandHuskExtension = true,
	AILevelUnitBaseExtension = true,
	WandExtension = true,
	RagdollShooterExtension = true,
	LeverOutlineExtension = true,
	StaffExtension = true,
	AIPlayerSlotExtension = true,
	AIHuskLocomotionExtension = true,
	StaffVectorFieldExtension = true,
	BowOutlineExtension = true,
	GameModeObjectHealthExtension = true,
	AIHitReactionExtension = true,
	BowExtension = true,
	InteractableExtension = true,
	AISpawnerExtension = true,
	ExtensionGenericWeapon = true,
	RapierExtension = true,
	WeaponRackExtension = true,
	AIBaseExtension = true,
	HandgunExtension = true,
	DoorHealthExtension = true,
	ArrowOutlineExtension = true,
	HandgunOutlineExtension = true,
	AILocomotionExtension = true,
	ParryExtension = true,
	ExtensionParticles = true,
	AINavigationExtension = true,
	RapierOutlineExtension = true,
	StaffMeleeExtension = true,
	InteractableOutlineExtension = true,
	PlayerHitReactionExtension = true,
	BowVectorFieldExtension = true
}

class("ExtensionManager")

ExtensionManager.init = function (self, world, level, level_name)
	self.temp_table = {}
	self._units = {}
	self._unit_extensions_list = {}
	self._extensions = {}
	self._systems = {}
	self._extension_to_system_map = {}
	self._system_to_extension_per_unit_type_map = {}
	self._world = world
	self._level = level
	self._level_name = level_name
	self._extension_system_bag = ExtensionSystemBag:new()
	self._extension_init_context = {
		world = world,
		level = level,
		level_name = level_name
	}
end

ExtensionManager._extension_extractor_function = function (self, unit, unit_template_name)
	local extensions = ScriptUnit.extension_definitions(unit)
	local num_extensions = #extensions

	return extensions, num_extensions
end

ExtensionManager.system = function (self, system_name)
	return self._systems[system_name]
end

ExtensionManager.system_by_extension = function (self, extension_name)
	local system_name = self._extension_to_system_map[extension_name]

	return system_name and self._systems[system_name]
end

ExtensionManager.get_entities = function (self, extension_name)
	return self._extensions[extension_name] or EMPTY_TABLE
end

ExtensionManager.destroy = function (self)
	self._extension_system_bag:destroy()
end

ExtensionManager.extract_extensions = function (self, unit, unit_template_name)
	local extensions_list, num_extensions = self:_extension_extractor_function(unit, unit_template_name)

	for i = num_extensions, 1, -1 do
		local extension = extensions_list[i]

		if not EXTENSIONS_WHITELIST[extension] then
			extensions_list[i] = nil
			num_extensions = num_extensions - 1
		end
	end

	return extensions_list, num_extensions
end

ExtensionManager.add_unit_extensions = function (self, world, unit, unit_template_name, all_extension_init_data)
	all_extension_init_data = all_extension_init_data or EMPTY_TABLE

	local extension_to_system_map = self._extension_to_system_map
	local self_units, self_extensions, self_systems = self._units, self._extensions, self._systems
	local extensions_list, num_extensions = self:extract_extensions(unit, unit_template_name)

	if unit_template_name and self._system_to_extension_per_unit_type_map[extensions_list] == nil then
		local reverse_lookup = {}

		for i = 1, num_extensions do
			local extension_name = extensions_list[i]
			local system_name = self._extension_to_system_map[extension_name]

			reverse_lookup[system_name] = extension_name
		end

		self._system_to_extension_per_unit_type_map[extensions_list] = reverse_lookup
	end

	local unit_extensions_list = self._unit_extensions_list

	assert(not unit_extensions_list[unit], "Adding extensions to a unit that already has extensions added!")

	unit_extensions_list[unit] = extensions_list

	if num_extensions == 0 then
		if unit_template_name ~= nil then
			Unit.flow_event(unit, "unit_registered")
		end

		return false
	end

	for index, extension_name in pairs(extensions_list) do
		local extension_system_name = extension_to_system_map[extension_name]

		fassert(extension_system_name, "No such registered extension %q", extension_name)

		local extension_init_data = all_extension_init_data[extension_system_name] or EMPTY_TABLE

		assert(extension_to_system_map[extension_name])

		local system = self_systems[extension_system_name]

		assert(system ~= nil, "Adding extension %q with no system is registered.", extension_name)

		local extension = system:on_add_extension(world, unit, extension_name, extension_init_data)

		assert(extension, "System (%s) must return the created extension (%s)", extension_system_name, extension_name)

		self_extensions[extension_name] = self_extensions[extension_name] or {}
		self_units[unit] = self_units[unit] or {}
		self_units[unit][extension_name] = extension

		assert(extension ~= EMPTY_TABLE)
	end

	local extensions = self_units[unit]

	for index, extension_name in pairs(extensions_list) do
		local extension = extensions[extension_name]

		if extension.extensions_ready ~= nil then
			extension:extensions_ready(world, unit)
		end

		local extension_system_name = extension_to_system_map[extension_name]
		local system = self_systems[extension_system_name]

		if system.extensions_ready ~= nil then
			system:extensions_ready(world, unit, extension_name)
		end
	end

	Unit.flow_event(unit, "unit_registered")

	return true
end

local TEMP_TABLE = {}

ExtensionManager.register_unit = function (self, world, unit, maybe_init_data, ...)
	local extension_init_data

	if type(maybe_init_data) == "table" then
		extension_init_data = maybe_init_data
	else
		extension_init_data = {
			maybe_init_data,
			...
		}
	end

	if self:add_unit_extensions(world, unit, nil, extension_init_data) then
		TEMP_TABLE[1] = unit

		self:register_units_extensions(TEMP_TABLE, 1)
	end
end

ExtensionManager.add_and_register_units = function (self, world, unit_list, num_units)
	num_units = num_units or #unit_list

	local added_list = self.temp_table
	local num_added = 0

	for i = 1, num_units do
		local unit = unit_list[i]
		local unit_template = Unit.get_data(unit, "unit_template")

		if self:add_unit_extensions(world, unit, unit_template) then
			num_added = num_added + 1
			added_list[num_added] = unit
		end
	end

	if num_added > 0 then
		self:register_units_extensions(added_list, num_added)
	end
end

ExtensionManager.register_units_extensions = function (self, unit_list, num_units)
	local self_units = self._units
	local self_extensions = self._extensions

	for i = 1, num_units do
		repeat
			local unit = unit_list[i]
			local unit_extensions = self_units[unit]

			if not unit_extensions then
				break
			end

			for extension_name, extension in pairs(unit_extensions) do
				assert(not self_extensions[extension_name][unit], "Unit %q already has extension %s registered.", unit, extension_name)

				self_extensions[extension_name][unit] = extension
			end
		until true
	end
end

ExtensionManager.remove_extensions_from_unit = function (self, unit, extensions_to_remove)
	local unit_extensions_list = self._unit_extensions_list
	local self_extensions = self._extensions
	local ScriptUnit_destroy_extension = ScriptUnit.destroy_extension
	local unit_extensions = ScriptUnit.extensions(unit)
	local extensions_list = unit_extensions_list[unit]

	if not extensions_list then
		return
	end

	local num_ext = #extensions_list

	for _, extension_name in ipairs(extensions_to_remove) do
		local system = self:system_by_extension(extension_name)
		local system_name = system.NAME

		ScriptUnit_destroy_extension(unit, system_name)
	end

	for _, extension_name in ipairs(extensions_to_remove) do
		local system = self:system_by_extension(extension_name)

		system:on_remove_extension(unit, extension_name)
		assert(not ScriptUnit.has_extension(unit, system.NAME), "Extension was not properly destroyed for extension %s", extension_name)

		self_extensions[extension_name][unit] = nil
	end

	unit_extensions_list[unit] = nil
end

ExtensionManager.unregister_all_units = function (self)
	local all_units = {}

	for unit, _ in pairs(self._unit_extensions_list) do
		all_units[#all_units + 1] = unit
	end

	self:unregister_units(all_units, #all_units)
	assert(not next(self._unit_extensions_list), "Failed removing all units from extension system")
end

ExtensionManager.unregister_units = function (self, units, num_units)
	local self_units, self_extensions = self._units, self._extensions
	local unit_extensions_list = self._unit_extensions_list
	local ScriptUnit_destroy_extension = ScriptUnit.destroy_extension
	local remove_from_position_lookup = REMOVE_FROM_POSITION_LOOKUP

	for i = 1, num_units do
		repeat
			local unit = units[i]

			remove_from_position_lookup[unit] = true

			local unit_extensions = ScriptUnit.extensions(unit)

			if not unit_extensions then
				ScriptUnit.remove_unit(unit)

				self_units[unit] = nil
				unit_extensions_list[unit] = nil

				break
			end

			local extensions_list = unit_extensions_list[unit]

			if not extensions_list then
				ScriptUnit.remove_unit(unit)

				self_units[unit] = nil
				unit_extensions_list[unit] = nil

				break
			end

			for system_name, _ in pairs(unit_extensions) do
				local system = self._systems[system_name]

				ScriptUnit_destroy_extension(unit, system_name)
			end

			local system_to_extension_map = self._system_to_extension_per_unit_type_map[extensions_list]

			if system_to_extension_map then
				for system_name, _ in pairs(unit_extensions) do
					local extension_name = system_to_extension_map[system_name]
					local system = self._systems[system_name]

					system:on_remove_extension(unit, extension_name)
					assert(not ScriptUnit.has_extension(unit, system.NAME), "Extension was not properly destroyed for extension %s", extension_name)

					self_extensions[extension_name][unit] = nil
				end
			else
				for i = #extensions_list, 1, -1 do
					local extension_name = extensions_list[i]
					local system = self:system_by_extension(extension_name)

					system:on_remove_extension(unit, extension_name)
					assert(not ScriptUnit.has_extension(unit, system.NAME), "Extension was not properly destroyed for extension %s", extension_name)

					self_extensions[extension_name][unit] = nil
				end
			end

			ScriptUnit.remove_unit(unit)

			self_units[unit] = nil
			unit_extensions_list[unit] = nil
		until true
	end
end

ExtensionManager.game_object_unit_destroyed = function (self, unit)
	local unit_extensions_list = self._unit_extensions_list
	local extensions_list = unit_extensions_list[unit]
	local unit_extensions = ScriptUnit.extensions(unit)

	if not unit_extensions then
		return
	end

	for system_name, _ in pairs(unit_extensions) do
		local system = self._systems[system_name]
		local extension = ScriptUnit.extension(unit, system_name)

		if extension.game_object_unit_destroyed then
			extension:game_object_unit_destroyed()
		end
	end
end

local TEMP_UNIT_TABLE = {}

ExtensionManager.unregister_unit = function (self, unit)
	if unit and Unit.alive(unit) then
		TEMP_UNIT_TABLE[1] = unit

		self:unregister_units(TEMP_UNIT_TABLE, 1)
	end
end

ExtensionManager.add_system = function (self, name, class, extension_list, has_pre_update, has_post_update)
	assert(self._systems[name] == nil, "Tried to register system whose name '%s' was already registered.", name)

	local extension_list = extension_list or class.extension_list
	local context = self._extension_init_context
	local system = class:new(context, name, extension_list)
	local block_pre_update = not has_pre_update
	local block_post_update = not has_post_update

	self._extension_system_bag:add_system(system, block_pre_update, block_post_update)

	self._systems[name] = system
	system.NAME = name

	for i, extension in ipairs(extension_list) do
		self._extension_to_system_map[extension] = name
	end
end

ExtensionManager.pre_update = function (self, dt, dt)
	self:_system_update("pre_update", dt, t)
end

ExtensionManager.update = function (self, dt, t)
	self:_system_update("update", dt, t)
end

ExtensionManager.post_update = function (self, dt, t)
	self:_system_update("post_update", dt, t)
end

ExtensionManager.physics_async_update = function (self, dt, t)
	self:_system_update("physics_async_update", dt, t)
end

ExtensionManager.hot_join_sync = function (self, peer_id)
	for name, system in pairs(self._systems) do
		system:hot_join_sync(peer_id)
	end
end

ExtensionManager._system_update = function (self, update_func, dt, t)
	self._extension_system_bag:update(dt, t, self._world, update_func)
end
