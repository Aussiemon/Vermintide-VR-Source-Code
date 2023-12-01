-- chunkname: @script/lua/unit_extensions/pickup/weapon_rack_extension.lua

require("settings/weapon_rack_settings")

local DEBUG_WEAPON_SPAWNING = false
local RESPAWN_TIME = 3
local RESPAWN_UNITS = false

class("WeaponRackExtension")

WeaponRackExtension.init = function (self, extension_init_context, unit, extension_init_data)
	local world = extension_init_context.world
	local input = extension_init_data.input
	local settings = extension_init_data.settings

	self._unit = unit
	self._world = world
	self._spawned_units = {}
	self._network_mode = extension_init_context.network_mode
	self._suffix = Unit.get_data(unit, "suffix")
	self._debug = DebugDrawer:new(World.create_line_object(self._world), true)

	self:_spawn_weapons()
end

WeaponRackExtension._spawn_weapons = function (self)
	local weapon_rack_settings = Unit.get_data(self._unit, "weapon_rack_settings")
	local weapon_settings = WeaponRackSettings[weapon_rack_settings]

	for name, weapon in pairs(weapon_settings) do
		local unit_name = weapon.unit_name
		local node_name = weapon.node_name
		local position_offset = Vector3(unpack(weapon.position_offset))
		local rotation_offset = Quaternion.from_euler_angles_xyz(unpack(weapon.rotation_offset))
		local node = Unit.node(self._unit, node_name)
		local unit = World.spawn_unit(self._world, unit_name)
		local weapon_specific_settings = weapon.settings

		if weapon_specific_settings.uses_vectorfield_suffix then
			Unit.set_data(unit, "suffix", self._suffix)
			Unit.set_flow_variable(unit, "particle_suffix", self._suffix)
			Unit.flow_event(unit, "lua_start_particles")
		end

		local scale = weapon_specific_settings and weapon_specific_settings.base_scale and weapon_specific_settings.base_scale or {
			1,
			1,
			1
		}

		if self._network_mode ~= "client" then
			World.unlink_unit(self._world, unit)
			World.link_unit(self._world, unit, self._unit, node)
			World.update_unit(self._world, unit)
		end

		if scale then
			local new_scale = Vector3(unpack(scale))

			Unit.set_local_scale(unit, 1, new_scale)
		end

		Unit.set_local_rotation(unit, 1, rotation_offset)
		Unit.set_local_position(unit, 1, position_offset)
		World.update_unit(self._world, unit)

		local stored_weapon_settings = {
			unit_name = unit_name,
			node_name = node_name,
			scale = scale,
			position_offset = Vector3Box(position_offset),
			rotation_offset = QuaternionBox(rotation_offset)
		}

		printf("*** Added [ %s to %s at position %s with scale %f, %f, %f ] ***", stored_weapon_settings.unit_name, stored_weapon_settings.node_name, tostring(Unit.world_position(unit, 1)), unpack(scale))
		Managers.state.extension:register_unit(self._world, unit)

		self._spawned_units[#self._spawned_units + 1] = {
			weapon_settings = stored_weapon_settings,
			unit = unit,
			interactable_ext = ScriptUnit.extension(unit, "interactable_system")
		}

		Unit.set_data(unit, "in_rack", true)
	end
end

WeaponRackExtension._respawn_weapon = function (self, weapon_settings)
	local unit_name = weapon_settings.unit_name
	local unit = World.spawn_unit(self._world, unit_name)
	local node = Unit.node(self._unit, weapon_settings.node_name)
	local scale = weapon_settings.scale

	if self._network_mode ~= "client" then
		World.unlink_unit(self._world, unit)
		World.link_unit(self._world, unit, self._unit, node)
		World.update_unit(self._world, unit)
	end

	if scale then
		local new_scale = Vector3(unpack(scale))

		Unit.set_local_scale(unit, 1, new_scale)
	end

	Unit.set_local_rotation(unit, 1, weapon_settings.rotation_offset:unbox())
	Unit.set_local_position(unit, 1, weapon_settings.position_offset:unbox())
	World.update_unit(self._world, unit)
	Managers.state.extension:add_unit_extensions(self._world, unit)

	return {
		weapon_settings = weapon_settings,
		unit = unit,
		interactable_ext = ScriptUnit.extension(unit, "interactable_system")
	}
end

local UNITS_TO_REMOVE = {}
local UNITS_TO_RESPAWN = {}

WeaponRackExtension.update = function (self, unit, dt, t)
	if DEBUG_WEAPON_SPAWNING then
		self._debug:reset()

		for _, unit_data in pairs(self._spawned_units) do
			local unit = unit_data.unit

			self._debug:sphere(Unit.world_position(unit, 1), 1, Color(255, 0, 0))
		end

		self._debug:update(self._world)
	end

	if self._network_mode == "client" then
		return
	end

	for idx, unit_data in pairs(self._spawned_units) do
		if unit_data.interactable_ext:is_gripped() then
			unit_data.gripped_time = t + WeaponRackConfig.respawn_time
		elseif unit_data.gripped_time and t > unit_data.gripped_time then
			UNITS_TO_REMOVE[#UNITS_TO_REMOVE + 1] = idx
		end
	end

	local respawn_units = WeaponRackConfig.respawn_units

	for i = #UNITS_TO_REMOVE, 1, -1 do
		local idx = UNITS_TO_REMOVE[i]
		local unit_data = self._spawned_units[idx]

		if respawn_units then
			Managers.state.extension:unregister_unit(unit_data.unit)
			table.remove(self._spawned_units, idx)
			World.destroy_unit(self._world, unit_data.unit)

			UNITS_TO_RESPAWN[#UNITS_TO_RESPAWN + 1] = self:_respawn_weapon(unit_data.weapon_settings)
		else
			local weapon_settings = unit_data.weapon_settings
			local unit = unit_data.unit
			local node = Unit.node(self._unit, weapon_settings.node_name)
			local scale = weapon_settings.scale

			World.unlink_unit(self._world, unit)
			World.link_unit(self._world, unit, self._unit, node)
			World.update_unit(self._world, unit)

			if scale then
				local new_scale = Vector3(unpack(scale))

				Unit.set_local_scale(unit, 1, new_scale)
			end

			Unit.set_local_rotation(unit, 1, weapon_settings.rotation_offset:unbox())
			Unit.set_local_position(unit, 1, weapon_settings.position_offset:unbox())
			World.update_unit(self._world, unit)
			printf("*** Teleported [ %s to %s at position %s with scale %f, %f, %f ] ***", weapon_settings.unit_name, weapon_settings.node_name, tostring(Unit.world_position(unit, 1)), unpack(scale))

			local actor = Unit.actor(unit, 1)

			Actor.set_kinematic(actor, true)

			unit_data.gripped_time = nil
		end
	end

	if respawn_units then
		for i = 1, #UNITS_TO_RESPAWN do
			self._spawned_units[#self._spawned_units + 1] = UNITS_TO_RESPAWN[i]
		end
	end

	table.clear(UNITS_TO_REMOVE)
	table.clear(UNITS_TO_RESPAWN)
end

WeaponRackExtension.destroy = function (self)
	return
end
