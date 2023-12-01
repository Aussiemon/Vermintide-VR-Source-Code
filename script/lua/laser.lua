-- chunkname: @script/lua/laser.lua

class("Laser")

local World = stingray.World
local PhysicsWorld = stingray.PhysicsWorld
local Matrix4x4 = stingray.Matrix4x4
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local Quaternion = stingray.Quaternion
local Actor = stingray.Actor
local Mesh = stingray.Mesh

Laser.init = function (self, world, wand_input, button, wand_unit)
	self._world = world
	self._wand_input = wand_input
	self._laser_button = button
	self._wand_unit = wand_unit
	self._laser_unit = World.spawn_unit(world, "content/models/vr/laser")

	Unit.set_unit_visibility(self._laser_unit, false)
end

Laser._target = function (self, target_unit)
	if self._target_unit ~= target_unit then
		if self._target_unit then
			self:_stop_highlight(self._target_unit)
		end

		if target_unit then
			self:_start_highlight(target_unit)
		end

		self._target_unit = target_unit
	end
end

local highlightParams = {
	name = "M_Glow",
	params_teleport = {
		{
			"color",
			"vector3",
			0.408,
			0.749,
			0.067
		}
	},
	params_load_level = {
		{
			"color",
			"vector3",
			0.1,
			0.408,
			0.749
		}
	},
	params_off = {
		{
			"color",
			"vector3",
			1,
			1,
			1
		}
	}
}

Laser._start_highlight = function (self, unit)
	Unit.flow_event(unit, "start_target_highlight")
end

Laser._stop_highlight = function (self, unit)
	Unit.flow_event(unit, "stop_target_highlight")
end

local outlineParams = {
	name = "M_Glow",
	params_on = {
		{
			"alpha",
			"scalar",
			0
		}
	},
	params_off = {
		{
			"alpha",
			"scalar",
			0
		}
	}
}

Laser._show_laser_targets = function (self)
	local targets = World.units_by_resource(self._world, "content/assets/interior/locationMarker/LocationMarker")

	for _, unit in pairs(targets) do
		Unit.flow_event(unit, "start_show")
	end
end

Laser._hide_laser_targets = function (self)
	local targets = World.units_by_resource(self._world, "content/assets/interior/locationMarker/LocationMarker")

	for _, unit in pairs(targets) do
		Unit.flow_event(unit, "stop_show")
	end
end

Laser.set_wand_unit = function (self, wand_unit)
	self._wand_unit = wand_unit
end

Laser._raycast = function (self, base_pose)
	local start = Matrix4x4.translation(base_pose)
	local direction = Quaternion.forward(Matrix4x4.rotation(base_pose))
	local physics_world = World.physics_world(self._world)
	local collision, position, distance, normal, actor = PhysicsWorld.raycast(physics_world, start, direction, "closest", "collision_filter", "filter_location_marker_check")

	if collision then
		local unit = Actor.unit(actor)

		return actor
	end
end

Laser.update = function (self, dt)
	local laser_button = self._laser_button

	if self._wand_input:pressed(laser_button) then
		Unit.set_unit_visibility(self._laser_unit, true)

		self._point_state = "pointing"

		self:_show_laser_targets()
	elseif self._wand_input:released(laser_button) then
		Unit.set_unit_visibility(self._laser_unit, false)
		self:_target(nil)

		self._point_state = nil

		local base_pose = Unit.world_pose(self._wand_unit, Unit.node(self._wand_unit, "j_pointer"))
		local actor = self:_raycast(base_pose)

		if actor then
			local unit = Actor.unit(actor)

			Managers.vr:do_teleport(unit)
		end

		self:_hide_laser_targets()
	end

	if self._point_state == "pointing" then
		local base_pose = Unit.world_pose(self._wand_unit, Unit.node(self._wand_unit, "j_pointer"))
		local laser_pose = base_pose

		Matrix4x4.set_scale(laser_pose, Vector3(0.03, 1000, 0.03))
		Unit.set_local_pose(self._laser_unit, 1, laser_pose)

		local actor = self:_raycast(base_pose)

		if actor then
			local unit = Actor.unit(actor)

			self:_target(unit)
		else
			self:_target(nil)
		end
	end
end
