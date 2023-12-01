-- chunkname: @script/lua/managers/spawn/spawn_manager.lua

require("settings/conflict_settings")
require("script/lua/managers/extension/systems/horde_spawner")
class("SpawnManager")

SpawnManager.init = function (self, world, level, level_name)
	self._world = world
	self._unit_unique_id = 0
	self._horde_spawner = HordeSpawner:new(self._world)
	self._deletion_queue = {}
	self._num_spawned_by_breed = {}
	self._level = level
	self._level_name = level_name

	for name, breed in pairs(Breeds) do
		self._num_spawned_by_breed[name] = 0
	end
end

SpawnManager.breed_max_health = function (self, breed_name)
	local breed = Breeds[breed_name]
	local max_health_table = breed.max_health
	local level_name = self._level_name
	local max_health = max_health_table[level_name] or max_health_table.default

	return max_health
end

SpawnManager.count_units_by_breed = function (self, breed_name)
	return self._num_spawned_by_breed[breed_name]
end

SpawnManager.remove_num_spawned_breed_type = function (self, breed_name)
	if breed_name then
		self._num_spawned_by_breed[breed_name] = self._num_spawned_by_breed[breed_name] - 1
	end
end

local dialogue_system_init_data = {
	faction = "enemy"
}

SpawnManager.spawn_enemy = function (self, breed, position, rotation, category, spawn_animation, spawn_type, inventory_template, group_data, target)
	Profiler.start("SpawnManager:spawn_enemy")

	local breed_unit_field = breed.base_unit
	local base_unit_name = type(breed_unit_field) == "string" and breed_unit_field or breed_unit_field[math.random(#breed_unit_field)]
	local unit_template = breed.unit_template
	local extension_manager = Managers.state.extension
	local ai_system = extension_manager:system("ai_system")
	local nav_world = ai_system:nav_world()
	local inventory_init_data

	if breed.has_inventory then
		inventory_init_data = {
			inventory_template = inventory_template or breed.default_inventory_template
		}
	end

	local breed_name = breed.name
	local max_health = self:breed_max_health(breed_name)
	local extension_data = {
		AIBaseExtension = {
			breed = breed,
			nav_world = nav_world,
			spawn_type = spawn_type,
			spawn_category = category,
			target = target
		},
		AINavigationExtension = {
			nav_world = nav_world
		},
		AILocomotionExtension = {
			nav_world = nav_world
		},
		AIEnemySlotExtension = {},
		AIInventoryExtension = inventory_init_data,
		HealthExtension = {
			health = max_health,
			ragdoll_on_death = breed.ragdoll_on_death,
			breed_name = breed.name
		},
		AIHitReactionExtension = {
			breed_name = breed_name
		}
	}
	local ai_unit = self:spawn_unit(base_unit_name, extension_data, position, rotation)

	self._num_spawned_by_breed[breed.name] = self._num_spawned_by_breed[breed.name] + 1

	local ai_base_extension = ScriptUnit.extension(ai_unit, "ai_system")
	local blackboard = ai_base_extension:blackboard()

	blackboard.spawn_animation = spawn_animation
	blackboard.spawn = true

	local locomotion_extension = ScriptUnit.extension(ai_unit, "locomotion_system")

	locomotion_extension:set_affected_by_gravity(true)
	locomotion_extension:set_movement_type("script_driven")
	Profiler.stop()

	return ai_unit
end

SpawnManager.spawn_unit = function (self, unit_name, extension_data, position, rotation, material)
	Profiler.start("spawn_unit")

	position = position or Vector3.zero()
	rotation = rotation or Quaternion.identity()
	extension_data = extension_data or {}

	local world = self._world
	local unit = World.spawn_unit(world, unit_name, position, rotation, material)

	self:_add_unit_extensions(world, unit, extension_data)
	self:_set_unique_id(unit)

	POSITION_LOOKUP[unit] = Unit.world_position(unit, 1)

	Profiler.stop("spawn_unit")

	return unit
end

SpawnManager._add_unit_extensions = function (self, world, unit, extension_data)
	local index = 0
	local extension_init_data = {}

	for extension_name, init_data in pairs(extension_data) do
		Unit.set_data(unit, "extensions", index, extension_name)

		index = index + 1

		local system = Managers.state.extension:system_by_extension(extension_name)
		local system_name = system.name

		extension_init_data[system_name] = init_data
	end

	Managers.state.extension:register_unit(world, unit, extension_init_data)
end

SpawnManager._set_unique_id = function (self, unit)
	local unit_unique_id = self._unit_unique_id

	self._unit_unique_id = unit_unique_id + 1

	Unit.set_data(unit, "unique_id", unit_unique_id)
end

SpawnManager.destroy = function (self)
	return
end

SpawnManager.mark_for_deletion = function (self, unit)
	if not Unit.alive(unit) then
		Application.error(string.format("Tried to destroy a unit (%s) that was already destroyed.", tostring(unit)))

		return
	end

	self._deletion_queue[#self._deletion_queue + 1] = unit
end

SpawnManager._delete_unit = function (self, unit)
	if not Unit.alive(unit) then
		return
	end

	local world = self._world
	local extension_manager = Managers.state.extension

	Profiler.start("Delete units")
	extension_manager:unregister_unit(unit)

	POSITION_LOOKUP[unit] = nil

	Profiler.start("destroy unit")
	World.destroy_unit(world, unit)
	Profiler.stop("destroy unit")
	Profiler.stop("Delete units")
end

SpawnManager.remove_units_marked_for_deletion = function (self)
	Profiler.start("Delete units")

	if #self._deletion_queue >= 1 then
		local unit = table.remove(self._deletion_queue, 1)

		self:_delete_unit(unit)
	end

	Profiler.stop("Delete units")
end

SpawnManager.update = function (self, dt, t)
	Profiler.start("SpawnManager")
	self._horde_spawner:update(t, dt)
	self:remove_units_marked_for_deletion()
	Profiler.stop("SpawnManager")
end

SpawnManager.event_horde = function (self, t, terror_event_id, composition_type, limit_spawners, silent, group_template, target)
	local horde = self._horde_spawner:execute_event_horde(t, terror_event_id, composition_type, limit_spawners, silent, group_template, target)

	return horde
end
