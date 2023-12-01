-- chunkname: @script/lua/views/popup_view.lua

require("script/lua/simple_gui/simple_gui")

local templates = require("script/lua/simple_gui/gui_templates")
local definitions = require("script/lua/views/popup_view_definitions")

class("PopupView")

PopupView.init = function (self, world, parent)
	self._world = world
	self._wwise_world = Wwise.wwise_world(world)
	self._parent = parent
	self._enabled = false
	self._animated_offset = 0
	self._scoreboard_index = 1

	self:_create_gui()
	self:_initialize_elements()
end

PopupView._initialize_elements = function (self)
	local elements = table.clone(definitions.elements)
	local selectable_elements = table.clone(definitions.selectable_elements)

	for _, element in ipairs(elements) do
		elements[element.name] = element

		if element.selectable then
			local selectable_element = table.clone(element)

			selectable_element.disabled = true
			selectable_element.hover = true
			selectable_element.offset[3] = selectable_element.offset[3] + 100
			selectable_elements[#selectable_elements + 1] = selectable_element
		end
	end

	for i = #selectable_elements, 1, -1 do
		local element = selectable_elements[i]

		selectable_elements[element.name] = element
	end

	self._templates = templates
	self._elements = elements
	self._selectable_elements = selectable_elements

	if self._enabled and self._popup_data then
		self._elements.header.text = self._popup_data.header
		self._elements.text.text = self._popup_data.message
	end
end

PopupView.enable = function (self, enable, input, popup_data)
	self._enabled = enable
	self._popup_data = popup_data

	local hmd_pose = Managers.vr:hmd_world_pose()
	local forward = hmd_pose.forward

	forward.z = 0
	self._starting_rotation = QuaternionBox(Quaternion.look(forward, Vector3.up()))
	self._hmd_pose = Matrix4x4Box(hmd_pose.head)

	local tracking_pose = Managers.vr:tracking_space_pose()

	self._initial_tracking_pos = Vector3Box(Matrix4x4.translation(tracking_pose))

	if not Managers.vr:hmd_active() then
		local right_wand = input:get_wand("right")
		local left_wand = input:get_wand("left")

		right_wand:set_visibility(not self._enabled)
		left_wand:set_visibility(not self._enabled)
	end

	self._popup_done = nil
	self._popup_data = nil

	if self._enabled and popup_data then
		self._popup_data = popup_data
		self._elements.header.text = popup_data.header
		self._elements.text.text = popup_data.message
	end
end

PopupView.enabled = function (self)
	return self._enabled
end

PopupView._create_gui = function (self)
	self._gui_pos = Vector3Box(Vector3(0, 0, 0))
	self._gui_pose = Matrix4x4Box(Matrix4x4.identity())
	self._animated_gui_pose = Matrix4x4Box(Matrix4x4.identity())
	self._size = {
		1000,
		1000
	}
	self._gui = World.create_world_gui(self._world, self._gui_pose:unbox(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
	self._animated_gui = World.create_world_gui(self._world, self._animated_gui_pose:unbox(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
end

local DO_RELOAD = true

PopupView.update = function (self, dt, t, input)
	if DO_RELOAD then
		self:_initialize_elements()

		DO_RELOAD = false
	end

	if not self._enabled then
		return
	end

	self:_update_selectable_animations(dt, t, input)
	self:_update_position_on_gui(dt, t, input)
	self:_update_gui_position(dt, t, input)
	self:_update_ui(dt, t, input)
	self:_update_input(dt, t, input)

	return self._popup_done
end

PopupView._update_selectable_animations = function (self, dt, t, input)
	local offset = self._current_selection_name and self._selectable_elements[self._current_selection_name].animated_offset or 0.1

	self._animated_offset_dir = self._animated_offset_dir or -1
	self._animated_offset = math.clamp(self._animated_offset + self._animated_offset_dir * dt, 0, offset)

	if self._current_selection_name and self._animated_offset == 0 then
		self._elements[self._current_selection_name].disabled = false
		self._selectable_elements[self._current_selection_name].disabled = true
		self._current_selection_name = nil
	elseif self._animated_offset > 0 and offset > self._animated_offset then
		self._dirty = true
	end
end

PopupView._update_position_on_gui = function (self, dt, t, input)
	local pos, dir
	local gui_pose = self._gui_pose:unbox()
	local gui_pos = Matrix4x4.translation(gui_pose)
	local gui_normal = Matrix4x4.forward(gui_pose)
	local plane = Plane.from_point_and_normal(gui_pos, gui_normal)

	if Managers.vr:hmd_active() then
		local wand = input:get_wand("right")
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

		local element = self._elements.test

		element.offset[1] = gui_pos.x - element.size[1] * 0.5
		element.offset[2] = gui_pos.z - element.size[2] * 0.5
		self._gui_pos = Vector3Box(gui_pos)
		self._world_gui_pos = Vector3Box(world_pos)
	end
end

PopupView._update_gui_position = function (self, dt, t)
	local hmd_pose = self._hmd_pose:unbox()

	if Matrix4x4.is_valid(hmd_pose) then
		local tracking_pose = Managers.vr:tracking_space_pose()
		local tracking_pos = Matrix4x4.translation(tracking_pose)
		local tracking_pos_diff = tracking_pos - self._initial_tracking_pos:unbox()
		local gui_pose = Matrix4x4.identity()
		local animated_gui_pose = Matrix4x4.identity()
		local rot = self._starting_rotation and self._starting_rotation:unbox() or Quaternion.identity()

		Matrix4x4.set_rotation(gui_pose, rot)

		local offset = Quaternion.rotate(rot, Vector3(-1.1, 1, -0.6))

		Matrix4x4.set_translation(gui_pose, Matrix4x4.translation(hmd_pose) + offset + tracking_pos_diff)
		Gui.move(self._gui, gui_pose)

		self._gui_pose = Matrix4x4Box(gui_pose)

		local animated_gui_pose = Matrix4x4.identity()

		Matrix4x4.set_rotation(animated_gui_pose, rot)

		local offset = Quaternion.rotate(rot, Vector3(-1.1, 1 - self._animated_offset, -0.6))

		Matrix4x4.set_translation(animated_gui_pose, Matrix4x4.translation(hmd_pose) + offset + tracking_pos_diff)
		Gui.move(self._animated_gui, animated_gui_pose)

		self._animated_gui_pose = Matrix4x4Box(animated_gui_pose)
	end
end

PopupView._update_input = function (self, dt, t, input)
	if not self._enabled then
		return
	end

	if self._input_held then
		if input:get("held", "trigger", "any", true) then
			local element = self._selectable_elements[self._current_selection_name]

			element.on_activate_held(element, self, dt)

			return
		else
			self._input_held = false
		end
	end

	local gui_pos = self._gui_pos:unbox()

	for index, element in ipairs(self._selectable_elements) do
		if element.hover and not element.root then
			local pos = element.pos:unbox()
			local size = element.size:unbox()
			local end_pos = {
				pos.x + size.x,
				pos.y + size.y
			}

			if gui_pos.x >= pos.x and gui_pos.x <= pos.x + size.x and gui_pos.z >= pos.y and gui_pos.z <= pos.y + size.y then
				self._animated_offset_dir = 1

				if self._current_selection_name and self._current_selection_name ~= element.name then
					self._elements[self._current_selection_name].disabled = false
					self._selectable_elements[self._current_selection_name].disabled = true
					self._animated_offset = 0
					self._current_selection_name = nil
				end

				if not self._current_selection_name then
					local source_id = WwiseUtils.make_position_auto_source(self._world, self._world_gui_pos:unbox())

					WwiseWorld.trigger_event(self._wwise_world, "menu_hover_mono", source_id)
				end

				self._current_selection_name = element.name
				self._elements[self._current_selection_name].disabled = true
				self._selectable_elements[self._current_selection_name].disabled = false

				if element.on_activate_held and input:get("held", "trigger", "any", true) then
					element.on_activate_held(element, self, dt)

					self._input_held = true
				end

				if element.on_activate and input:get("pressed", "trigger", "any", true) then
					element.on_activate(element, self, dt)
				end

				return
			end
		end
	end

	self._animated_offset_dir = -1
end

PopupView.is_done = function (self)
	return self._popup_done
end

PopupView._update_ui = function (self, dt, t)
	for _, element in ipairs(self._elements) do
		SimpleGui.update_element(self._gui, element, self._elements, self._templates)
	end

	for _, element in ipairs(self._selectable_elements) do
		SimpleGui.update_element(self._gui, element, self._selectable_elements, self._templates)
	end

	for _, element in ipairs(self._elements) do
		SimpleGui.render_element(self._gui, element)
	end

	for _, element in ipairs(self._selectable_elements) do
		SimpleGui.render_element(self._animated_gui, element)
	end
end

PopupView.destroy = function (self)
	World.destroy_gui(self._world, self._gui)

	self._gui = nil
end
