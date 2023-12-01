-- chunkname: @script/lua/tests/spawn_controller.lua

require("script/lua/terror_event_mixer")
class("SpawnController")

local World = stingray.World
local PhysicsWorld = stingray.PhysicsWorld
local Matrix4x4 = stingray.Matrix4x4
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local Quaternion = stingray.Quaternion
local Actor = stingray.Actor
local Mesh = stingray.Mesh

SpawnController.init = function (self, world, wand_input, button, wand_unit)
	self._world = world
	self._wand_input = wand_input
	self._spawn_button = button
	self._wand_unit = wand_unit
	self._spawned_units = {}
end

SpawnController.set_wand_unit = function (self, wand_unit)
	self._wand_unit = wand_unit
end

SpawnController.update = function (self, dt, t)
	if not t then
		return
	end

	if self._last_spawn_at and t < self._last_spawn_at + 1 then
		return
	end

	if stingray.Keyboard.button(stingray.Keyboard.button_id("o")) == 1 then
		self:_spawn_rat_ogre()

		self._last_spawn_at = t
	end

	if stingray.Keyboard.button(stingray.Keyboard.button_id("p")) == 1 then
		self:_spawn_storm_vermin()

		self._last_spawn_at = t
	end

	if stingray.Keyboard.button(stingray.Keyboard.button_id("i")) == 1 then
		self:_spawn_clan_rat()

		self._last_spawn_at = t
	end
end

SpawnController._aim_position = function (self)
	local pose = Unit.world_pose(self._wand_unit, Unit.node(self._wand_unit, "j_pointer"))
	local forward = Matrix4x4.forward(pose)
	local position = Matrix4x4.translation(pose)
	local center = position + forward * 10

	return center
end

SpawnController._level_position = function (self)
	local targets = World.units_by_resource(self._world, "units/hub_elements/objective_unit")

	for _, target in ipairs(targets) do
		return Unit.world_position(target, 1)
	end
end

SpawnController._spawn_clan_rat = function (self)
	local position = self:_level_position() or self:_aim_position()
	local breed = Breeds.skaven_clan_rat
	local skaven_unit = Managers.state.spawn:spawn_enemy(breed, position, nil, nil, nil, nil, nil, nil)

	self._spawned_units[#self._spawned_units + 1] = skaven_unit
end

SpawnController._spawn_storm_vermin = function (self)
	local position = self:_aim_position()
	local breed = Breeds.skaven_storm_vermin
	local skaven_unit = Managers.state.spawn:spawn_enemy(breed, position, nil, nil, nil, nil, nil, nil)

	self._spawned_units[#self._spawned_units + 1] = skaven_unit
end

SpawnController._spawn_rat_ogre = function (self)
	local position = self:_aim_position()
	local breed = Breeds.skaven_rat_ogre
	local skaven_unit = Managers.state.spawn:spawn_enemy(breed, position, nil, nil, nil, nil, nil, nil)

	self._spawned_units[#self._spawned_units + 1] = skaven_unit
end

SpawnController._spawn_horde = function (self)
	local spawner_system = Managers.state.extension:system("spawner_system")
	local spawners = spawner_system:enabled_spawners()
	local num_spawners = #spawners
	local total_amount = Math.random(15, 20)
	local amount_per_spawner = math.floor(total_amount / num_spawners)
	local k = math.random(1, #spawners)
	local spawner = spawners[k]

	spawner_system:spawn_horde(spawner, amount_per_spawner, {
		Breeds.skaven_clan_rat
	})
end

SpawnController.destroy = function (self)
	self:_destroy_units()
end

SpawnController._destroy_units = function (self)
	for _, unit in ipairs(self._spawned_units) do
		if Unit.alive(unit) then
			World.destroy_unit(self._world, unit)
		end
	end

	self._spawned_units = {}
end
