-- chunkname: @script/lua/pie_menu.lua

require("foundation/script/util/class")

local World = stingray.World
local Vector3 = stingray.Vector3
local Vector3Box = stingray.Vector3Box
local SteamVR = stingray.SteamVR
local Quaternion = stingray.Quaternion
local QuaternionBox = stingray.QuaternionBox
local Unit = stingray.Unit
local Matrix4x4 = stingray.Matrix4x4
local LineObject = stingray.LineObject
local Color = stingray.Color

class("PieMenu")

PieMenu.init = function (self, world, vr_system, wand_input, options)
	self._world = world
	self._vr_system = vr_system
	self._wand_input = wand_input
	self._offset = 1.5
	self._radius = 0.8
	self._line_object = World.create_line_object(world)

	self:_init_render(options)
end

PieMenu._init_render = function (self, options)
	local hmd_pose = SteamVRSystem.hmd_world_pose(self._vr_system)
	local forward_without_pitch = Vector3(hmd_pose.forward.x, hmd_pose.forward.y, 0)
	local hmd_position = Matrix4x4.translation(hmd_pose.right_eye)
	local base_position = hmd_position + Vector3.normalize(forward_without_pitch) * self._offset

	self._base_position = Vector3Box()

	self._base_position:store(base_position)

	self._forward = Vector3Box()

	self._forward:store(forward_without_pitch)

	local slice_angle = 2 * math.pi / (#options - 1)
	local rotation = Quaternion.axis_angle(forward_without_pitch, slice_angle)
	local spawn_vector = Vector3.up()

	self._options = {}

	for ii, option in ipairs(options) do
		spawn_vector = Quaternion.rotate(rotation, spawn_vector)

		local spawn_pos = base_position + spawn_vector * self._radius
		local unit = World.spawn_unit(self._world, option.unit, spawn_pos)
		local pose, size = Unit.box(unit)
		local scale_factor = 1 / Vector3.length(size)
		local scale = Vector3(scale_factor, scale_factor, scale_factor) / 6

		Unit.set_local_scale(unit, 1, scale)

		local min_angle = slice_angle * ii - slice_angle / 2
		local max_angle = slice_angle * ii + slice_angle / 2
		local base_scale = Vector3Box()

		base_scale:store(scale)

		self._options[#self._options + 1] = {
			unit = unit,
			option = option,
			min_angle = min_angle,
			max_angle = max_angle,
			base_scale = base_scale
		}
	end
end

PieMenu._update_render = function (self, selected, intersection)
	LineObject.reset(self._line_object)

	if selected then
		if self._selected ~= selected then
			if self._selected then
				Unit.set_local_scale(self._selected.unit, 1, self._selected.base_scale:unbox())
			end

			Unit.set_local_scale(selected.unit, 1, selected.base_scale:unbox() * 2)

			self._selected = selected
		end
	elseif self._selected then
		if self._selected then
			Unit.set_local_scale(self._selected.unit, 1, self._selected.base_scale:unbox())
		end

		self._selected = selected
	end

	if intersection then
		LineObject.add_sphere(self._line_object, Color(255, 255, 255), intersection, 0.1)
	end

	LineObject.dispatch(self._world, self._line_object)
end

PieMenu._find_selected = function (self, intersection)
	local selected
	local distance = math.huge

	for ii, option in ipairs(self._options) do
		local unit = option.unit
		local pos = Unit.local_position(unit, 1)
		local unit_distance = Vector3.length(intersection - pos)

		if unit_distance < distance then
			selected = option
			distance = unit_distance
		end
	end

	if distance > self._radius * math.pi * 2 / (#self._options * 2) then
		selected = nil
	end

	return selected
end

PieMenu._intersection = function (self, p0, l0, n, l)
	local l_to_p = p0 - l0
	local dividend = Vector3.dot(l_to_p, n)
	local divisor = Vector3.dot(l, n)

	if divisor == 0 then
		return Vector3(0, 0, 0)
	end

	local d = dividend / divisor

	return l0 + l * d
end

PieMenu.update = function (self, dt)
	local wand_pos = self._wand_input:position()
	local wand_dir = self._wand_input:forward()
	local intersection = self:_intersection(self._base_position:unbox(), wand_pos, self._forward:unbox(), wand_dir)
	local selected

	if intersection then
		selected = self:_find_selected(intersection)
	else
		print("no intersection", self._base_position:unbox(), wand_pos, self._forward:unbox(), wand_dir)
	end

	self:_update_render(selected, intersection)
end

PieMenu.selected = function (self)
	if self._selected then
		return self._selected.option
	end
end

PieMenu.destroy = function (self)
	LineObject.reset(self._line_object)
	LineObject.dispatch(self._world, self._line_object)
	World.destroy_line_object(self._world, self._line_object)

	for _, option in ipairs(self._options) do
		World.destroy_unit(self._world, option.unit)
	end
end
