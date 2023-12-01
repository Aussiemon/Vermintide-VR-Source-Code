-- chunkname: @script/lua/views/hud_view.lua

require("script/lua/simple_gui/simple_gui")

local templates = require("script/lua/simple_gui/gui_templates")
local element_table = require("script/lua/views/hud_view_definitions")
local menu_elements = element_table.menu_elements
local touch_elements = element_table.touch_elements
local grip_elements = element_table.grip_elements
local trigger_elements = element_table.trigger_elements

class("HUDView")

HUDView.init = function (self, world, input, parent)
	self._world = world
	self._input = input
	self._parent = parent
	self._enabled = false

	self:_create_gui()
	self:_setup_elements()
end

HUDView._setup_elements = function (self)
	self._menu_elements = table.clone(menu_elements)
	self._touch_elements = table.clone(touch_elements)
	self._grip_elements = table.clone(grip_elements)
	self._trigger_elements = table.clone(trigger_elements)

	for _, element in ipairs(self._menu_elements) do
		self._menu_elements[element.name] = element
	end

	for _, element in ipairs(self._touch_elements) do
		self._touch_elements[element.name] = element
	end

	for _, element in ipairs(self._grip_elements) do
		self._grip_elements[element.name] = element
	end

	for _, element in ipairs(self._trigger_elements) do
		self._trigger_elements[element.name] = element
	end

	DO_RELOAD = false
end

HUDView.enable = function (self, enable, pose)
	self._enabled = enable

	local hmd_pose = Managers.vr:hmd_world_pose()
	local forward = hmd_pose.forward

	forward.z = 0
	self._starting_rotation = QuaternionBox(Quaternion.look(forward, Vector3.up()))
	self._hmd_pose = Matrix4x4Box(hmd_pose.head)
end

HUDView.enabled = function (self)
	return self._enabled
end

HUDView._create_gui = function (self)
	self._size = {
		1000,
		1000
	}
	self._menu_gui = World.create_world_gui(self._world, Matrix4x4.identity(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
	self._touch_gui = World.create_world_gui(self._world, Matrix4x4.identity(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
	self._grip_gui = World.create_world_gui(self._world, Matrix4x4.identity(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
	self._trigger_gui = World.create_world_gui(self._world, Matrix4x4.identity(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
end

local DO_RELOAD = true

HUDView.update = function (self, dt, t)
	if DO_RELOAD then
		self:_setup_elements()
	end

	if not self._enabled then
		return
	end

	self:_update_gui_position(dt, t)
	self:_update_ui(dt, t)
end

HUDView._update_gui_position = function (self, dt, t)
	local wand = self._input:get_wand("right")
	local tm = wand:input():pose()
	local right = Matrix4x4.right(tm)
	local up = Matrix4x4.up(tm)
	local forward = Matrix4x4.forward(tm)
	local generic_wand_unit = wand:generic_wand_unit()
	local menu_pose = Unit.local_pose(generic_wand_unit, Unit.node(generic_wand_unit, "p_menu_btn"))

	menu_pose = Matrix4x4.multiply(menu_pose, tm)

	Matrix4x4.set_translation(menu_pose, Matrix4x4.translation(menu_pose) - right * 0.2 - forward * 0.2)
	Gui.move(self._menu_gui, menu_pose)

	local touch_pose = Unit.local_pose(generic_wand_unit, Unit.node(generic_wand_unit, "p_trackpad"))

	touch_pose = Matrix4x4.multiply(touch_pose, tm)

	Matrix4x4.set_translation(touch_pose, Matrix4x4.translation(touch_pose) - right * 0.2 - forward * 0.2 + up * 0.035)
	Gui.move(self._touch_gui, touch_pose)

	local grip_pose = Unit.local_pose(generic_wand_unit, Unit.node(generic_wand_unit, "p_gripper"))
	local grip_right = Matrix4x4.right(grip_pose)
	local grip_up = Matrix4x4.up(grip_pose)
	local grip_forward = Matrix4x4.forward(grip_pose)

	grip_pose = Matrix4x4.multiply(grip_pose, tm)

	Gui.move(self._grip_gui, grip_pose)

	local trigger_pose = Unit.local_pose(generic_wand_unit, Unit.node(generic_wand_unit, "p_trigger"))

	trigger_pose = Matrix4x4.multiply(trigger_pose, tm)

	Gui.move(self._trigger_gui, trigger_pose)
end

HUDView._update_ui = function (self, dt, t)
	for _, element in ipairs(self._menu_elements) do
		SimpleGui.update_element(self._menu_gui, element, self._menu_elements, templates)
	end

	for _, element in ipairs(self._touch_elements) do
		SimpleGui.update_element(self._touch_gui, element, self._touch_elements, templates)
	end

	for _, element in ipairs(self._grip_elements) do
		SimpleGui.update_element(self._touch_gui, element, self._grip_elements, templates)
	end

	for _, element in ipairs(self._trigger_elements) do
		SimpleGui.update_element(self._touch_gui, element, self._trigger_elements, templates)
	end

	for _, element in ipairs(self._menu_elements) do
		SimpleGui.render_element(self._menu_gui, element)
	end

	for _, element in ipairs(self._touch_elements) do
		SimpleGui.render_element(self._touch_gui, element)
	end

	for _, element in ipairs(self._grip_elements) do
		SimpleGui.render_element(self._grip_gui, element)
	end

	for _, element in ipairs(self._trigger_elements) do
		SimpleGui.render_element(self._trigger_gui, element)
	end
end

HUDView.destroy = function (self)
	World.destroy_gui(self._world, self._menu_gui)
	World.destroy_gui(self._world, self._touch_gui)
	World.destroy_gui(self._world, self._grip_gui)
	World.destroy_gui(self._world, self._trigger_gui)

	self._menu_gui = nil
	self._touch_gui = nil
	self._grip_gui = nil
	self._trigger_gui = nil
end
