-- chunkname: @script/lua/tests/rag_doll_controller.lua

class("RagDollController")

local World = stingray.World
local PhysicsWorld = stingray.PhysicsWorld
local Matrix4x4 = stingray.Matrix4x4
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local Quaternion = stingray.Quaternion
local Actor = stingray.Actor
local Mesh = stingray.Mesh

RagDollController.init = function (self, world, wand_input, button, wand_unit)
	self._world = world
	self._wand_input = wand_input
	self._spawn_button = button
	self._wand_unit = wand_unit
	self._spawned_units = {}
	self._wave_count = 0
end

RagDollController.set_wand_unit = function (self, wand_unit)
	self._wand_unit = wand_unit
end

RagDollController._destroy_ragdolls = function (self)
	for _, unit in ipairs(self._spawned_units) do
		if Unit.alive(unit) then
			World.destroy_unit(self._world, unit)
		end
	end

	self._spawned_units = {}
end

RagDollController.update = function (self, dt, t)
	local spawn_button = self._spawn_button
	local spawn_pressed = self._wand_input:pressed(spawn_button)

	if spawn_pressed then
		if self._wave_count < 4 then
			self:_spawn_wave()

			self._wave_count = self._wave_count + 1
		else
			self:_destroy_ragdolls()

			self._wave_count = 0
		end
	end
end

RagDollController._aim_position = function (self)
	local pose = Unit.world_pose(self._wand_unit, Unit.node(self._wand_unit, "j_pointer"))
	local forward = Matrix4x4.forward(pose)
	local position = Matrix4x4.translation(pose)
	local center = position + forward * 3

	return center
end

RagDollController._level_position = function (self)
	local targets = World.units_by_resource(self._world, "units/hub_elements/objective_unit")

	for _, target in ipairs(targets) do
		return Unit.world_position(target, 1)
	end
end

RagDollController._spawn_wave = function (self)
	local center = self:_level_position() or self:_aim_position()
	local side_amount = 3
	local step = 1
	local offset = side_amount / step

	for ii = 1, side_amount do
		for jj = 1, side_amount do
			local pos = center + Vector3(ii * step - offset, jj * step - offset, 0)

			self:_spawn_ragdoll(pos)
		end
	end
end

RagDollController._spawn_ragdoll = function (self, position)
	position.z = 3

	local pose = Matrix4x4.identity()

	Matrix4x4.set_translation(pose, position)

	local world = self._world
	local skaven_unit = World.spawn_unit(world, "units/beings/enemies/skaven_rat_ogre/chr_skaven_rat_ogre", pose)

	Unit.animation_event(skaven_unit, "ragdoll")

	self._spawned_units[#self._spawned_units + 1] = skaven_unit
end

RagDollController.destroy = function (self)
	self:_destroy_ragdolls()
end
