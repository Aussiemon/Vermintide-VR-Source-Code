-- chunkname: @script/lua/views/base_view.lua

require("script/lua/simple_gui/simple_gui")

local templates = require("script/lua/simple_gui/gui_templates")
local element_table = require("script/lua/views/base_view_definitions")
local elements = element_table.elements

class("BaseView")

BaseView.init = function (self, world, input, parent)
	self._world = world
	self._input = input
	self._parent = parent
	self._enabled = false

	self:_create_gui()
	self:_create_laser()
end

BaseView.enable = function (self, enable)
	self._enabled = enable

	local hmd_pose = Managers.vr:hmd_world_pose()
	local forward = hmd_pose.forward

	forward.z = 0
	self._starting_rotation = QuaternionBox(Quaternion.look(forward, Vector3.up()))
	self._hmd_pose = Matrix4x4Box(hmd_pose.head)

	if not Managers.vr:hmd_active() then
		local right_wand = self._input:get_wand("right")
		local left_wand = self._input:get_wand("left")

		right_wand:set_visibility(not self._enabled)
		left_wand:set_visibility(not self._enabled)
		Unit.set_unit_visibility(self._laser_unit, false)
	else
		Unit.set_unit_visibility(self._laser_unit, self._enabled)
	end
end

BaseView.enabled = function (self)
	return self._enabled
end

BaseView._create_laser = function (self)
	self._laser_unit = World.spawn_unit(self._world, "content/models/vr/laser")

	Unit.set_unit_visibility(self._laser_unit, false)
end

BaseView._create_gui = function (self)
	self._gui_pos = Vector3Box(Vector3(0, 0, 0))
	self._gui_pose = Matrix4x4Box(Matrix4x4.identity())
	self._size = {
		1000,
		1000
	}
	self._gui = World.create_world_gui(self._world, self._gui_pose:unbox(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
end

BaseView.update = function (self, dt, t)
	if not self._enabled then
		return
	end

	self:_update_position_on_gui(dt, t)
	self:_update_gui_position(dt, t)
	self:_update_laser(dt, t)
	self:_update_ui(dt, t)
end

BaseView._update_position_on_gui = function (self, dt, t)
	local pos, dir
	local gui_pose = self._gui_pose:unbox()
	local gui_pos = Matrix4x4.translation(gui_pose)
	local gui_normal = Matrix4x4.forward(gui_pose)
	local plane = Plane.from_point_and_normal(gui_pos, gui_normal)

	if Managers.vr:hmd_active() then
		local wand = self._input:get_wand("right")
		local wand_unit = wand:wand_unit()
		local hand_pose = Unit.world_pose(wand_unit, Unit.node(wand_unit, "j_pointer"))

		pos = Matrix4x4.translation(hand_pose)
		dir = Matrix4x4.forward(hand_pose)
	else
		local hmd_pose = Managers.vr:hmd_world_pose()

		pos = Matrix4x4.translation(hmd_pose.head)
		dir = hmd_pose.forward
	end

	local distance_along_ray, is_ray_start_in_front_of_plane = Intersect.ray_plane(pos, dir, plane)

	if distance_along_ray then
		local world_pos = pos + dir * distance_along_ray
		local pose = Matrix4x4.inverse(gui_pose)
		local local_pos = Matrix4x4.transform(pose, world_pos)

		gui_pos.x = local_pos.x / (1 / self._size[1])
		gui_pos.z = local_pos.z / (1 / self._size[2])

		local element = elements.test

		element.offset[1] = gui_pos.x
		element.offset[2] = gui_pos.z
		self._gui_pos = Vector3Box(gui_pos)
	end
end

BaseView._update_gui_position = function (self, dt, t)
	local hmd_pose = self._hmd_pose:unbox()

	if Matrix4x4.is_valid(hmd_pose) then
		local gui_pose = Matrix4x4.identity()
		local animated_gui_pose = Matrix4x4.identity()
		local rot = self._starting_rotation and self._starting_rotation:unbox() or Quaternion.identity()

		Matrix4x4.set_rotation(gui_pose, rot)

		local offset = Quaternion.rotate(rot, Vector3(-1.1, 1.5, -0.6))

		Matrix4x4.set_translation(gui_pose, Matrix4x4.translation(hmd_pose) + offset)
		Gui.move(self._gui, gui_pose)

		self._gui_pose = Matrix4x4Box(gui_pose)
	end
end

BaseView._update_laser = function (self, dt, t)
	local right_wand_unit = self._input:get_wand("right"):wand_unit()
	local base_pose = Unit.world_pose(right_wand_unit, Unit.node(right_wand_unit, "j_pointer"))
	local laser_pose = base_pose

	Matrix4x4.set_scale(laser_pose, Vector3(0.03, 1000, 0.03))
	Unit.set_local_pose(self._laser_unit, 1, laser_pose)
	World.update_unit(self._world, self._laser_unit)
end

BaseView._update_ui = function (self, dt, t)
	for _, element in ipairs(elements) do
		SimpleGui.update_element(self._gui, element, elements, templates)
	end

	for _, element in ipairs(elements) do
		SimpleGui.render_element(self._gui, element)
	end
end

BaseView.destroy = function (self)
	World.destroy_gui(self._world, self._gui)

	self._gui = nil
end
