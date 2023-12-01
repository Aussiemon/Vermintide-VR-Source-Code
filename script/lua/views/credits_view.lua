-- chunkname: @script/lua/views/credits_view.lua

require("script/lua/views/credits")

local templates = require("script/lua/simple_gui/gui_templates")
local credits_definition = require("script/lua/views/credits_view_definitions")

class("CreditsView")

CreditsView.init = function (self, world, input, parent)
	self._world = world
	self._wwise_world = Wwise.wwise_world(world)
	self._input = input
	self._parent = parent
	self._credits_offset = 0
	self._animated_offset = 0.5

	self:_setup_gui()
	self:_initiate_elements()
	self:enable(false)
end

CreditsView._initiate_elements = function (self)
	self._elements = table.clone(credits_definition.elements)
	self._animated_elements = table.clone(credits_definition.animated_elements)
	self._credits_entry = table.clone(credits_definition.credits_element)

	self:_add_credits()
	self:_prepare_elements()
end

CreditsView._add_credits = function (self)
	local old_type, spacing = nil, -100

	for idx, entry in ipairs(Credits) do
		local settings = CreditsSettings[entry.type]
		local element = table.clone(self._credits_entry)

		element.template_type = settings.template
		element.depends_on = element.name .. idx - 1
		element.name = element.name .. idx

		if old_type then
			spacing = CreditsOffsets[old_type][entry.type]
		end

		element.offset[2] = spacing
		element.text = entry.text
		self._elements[#self._elements + 1] = element
		old_type = entry.type
	end
end

CreditsView._prepare_elements = function (self)
	for _, element in ipairs(self._elements) do
		self._elements[element.name] = element
	end

	for _, element in ipairs(self._animated_elements) do
		self._animated_elements[element.name] = element
	end
end

CreditsView.enabled = function (self)
	return self._enabled
end

CreditsView.enable = function (self, enable, pose)
	self._enabled = enable
	self._credits_offset = 0

	if pose then
		local forward = Matrix4x4.forward(pose:unbox())

		forward.z = 0
		self._starting_rotation = QuaternionBox(Quaternion.look(forward, Vector3.up()))
		self._hmd_pose = pose
	else
		local hmd_pose = Managers.vr:hmd_world_pose()
		local forward = hmd_pose.forward

		forward.z = 0
		self._starting_rotation = QuaternionBox(Quaternion.look(forward, Vector3.up()))
		self._hmd_pose = Matrix4x4Box(hmd_pose.head)
	end

	local tracking_pose = Managers.vr:tracking_space_pose()

	self._initial_tracking_pos = Vector3Box(Matrix4x4.translation(tracking_pose))
end

CreditsView._setup_gui = function (self)
	self._world_gui_pos = Vector3Box(Vector3(0, 0, 0))
	self._gui_pos = Vector3Box(Vector3(0, 0, 0))
	self._gui_pose = Matrix4x4Box(Matrix4x4.identity())
	self._size = {
		1000,
		1000
	}
	self._gui = World.create_world_gui(self._world, self._gui_pose:unbox(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
	self._animated_gui = World.create_world_gui(self._world, self._gui_pose:unbox(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")

	print("CreditsView -> World.create_world_gui")
end

local DO_RELOAD = true

CreditsView.update = function (self, dt, t)
	if DO_RELOAD then
		self._credits_offset = 0

		self:_initiate_elements()

		DO_RELOAD = false
	end

	if Managers.popup:has_popup() then
		return
	end

	Profiler.start("Credits")

	if self._enabled then
		Profiler.start("_update_position_on_gui")
		self:_update_position_on_gui(dt, t)
		Profiler.stop("_update_position_on_gui")
		Profiler.start("_update_gui_position")
		self:_update_gui_position(dt, t)
		Profiler.stop("_update_gui_position")
		Profiler.start("_update_animations")
		self:_update_animations(dt, t)
		Profiler.stop("_update_animations")
		Profiler.start("_update_ui")
		self:_update_ui(dt, t)
		Profiler.stop("_update_ui")
		Profiler.start("_update_input")
		self:_update_input(dt, t)
		Profiler.stop("_update_input")
		Profiler.start("_update_scroll")
		self:_update_scroll(dt, t)
		Profiler.stop("_update_scroll")
	end

	Profiler.stop("Credits")
end

CreditsView._update_position_on_gui = function (self, dt, t)
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

		local element = self._elements.test

		element.offset[1] = gui_pos.x - element.size[1] * 0.5
		element.offset[2] = gui_pos.z - element.size[2] * 0.5
		self._gui_pos = Vector3Box(gui_pos)
		self._world_gui_pos = Vector3Box(world_pos)
	end
end

CreditsView._update_gui_position = function (self, dt, t)
	local hmd_pose = self._hmd_pose:unbox()

	if Matrix4x4.is_valid(hmd_pose) then
		local tracking_pose = Managers.vr:tracking_space_pose()
		local tracking_pos = Matrix4x4.translation(tracking_pose)
		local tracking_pos_diff = tracking_pos - self._initial_tracking_pos:unbox()
		local gui_pose = Matrix4x4.identity()
		local animated_gui_pose = Matrix4x4.identity()
		local rot = self._starting_rotation and self._starting_rotation:unbox() or Quaternion.identity()

		Matrix4x4.set_rotation(gui_pose, rot)

		local offset = Quaternion.rotate(rot, Vector3(-1.1, 1.5, -0.6))

		Matrix4x4.set_translation(gui_pose, Matrix4x4.translation(hmd_pose) + offset + tracking_pos_diff)
		Gui.move(self._gui, gui_pose)

		self._gui_pose = Matrix4x4Box(gui_pose)

		Matrix4x4.set_rotation(animated_gui_pose, rot)

		local offset = Quaternion.rotate(rot, Vector3(-1.1, 1.5 - self._animated_offset, -0.6))

		Matrix4x4.set_translation(animated_gui_pose, Matrix4x4.translation(hmd_pose) + offset + tracking_pos_diff)
		Gui.move(self._animated_gui, animated_gui_pose)
	end
end

CreditsView._update_animations = function (self, dt, t)
	local offset = self._current_selection_name and self._animated_elements[self._current_selection_name].animated_offset or 0.1

	self._animated_offset_dir = self._animated_offset_dir or -1
	self._animated_offset = math.clamp(self._animated_offset + self._animated_offset_dir * dt, 0, offset)

	if self._current_selection_name and self._animated_offset == 0 then
		self._elements[self._current_selection_name].disabled = false
		self._animated_elements[self._current_selection_name].disabled = true
		self._current_selection_name = nil
	elseif self._animated_offset > 0 and offset > self._animated_offset then
		self._dirty = true
	end
end

CreditsView._update_ui = function (self, dt, t)
	Profiler.start("update_elements")

	for _, element in ipairs(self._elements) do
		SimpleGui.update_element(self._gui, element, self._elements, templates, self._world, dt, t)
	end

	Profiler.stop("update_elements")
	Profiler.start("update_animated_elements")

	for _, element in ipairs(self._animated_elements) do
		SimpleGui.update_element(self._animated_gui, element, self._animated_elements, templates, self._world, dt, t)
	end

	Profiler.stop("update_animated_elements")
	Profiler.start("render_elements")

	for _, element in ipairs(self._elements) do
		SimpleGui.render_element(self._gui, element)
	end

	Profiler.stop("render_elements")
	Profiler.start("render_animated_elements")

	for _, element in ipairs(self._animated_elements) do
		SimpleGui.render_element(self._animated_gui, element)
	end

	Profiler.stop("render_animated_elements")
end

CreditsView._update_input = function (self, dt, t)
	if self._enabled then
		self:_check_position(dt, t)

		if self._current_selection_name and self._input:get("pressed", "trigger", "any", true) then
			local element = self._animated_elements[self._current_selection_name]

			if element.on_activate then
				element.on_activate(element, self)
			end
		end

		if self._input:get("pressed", "menu", "any") then
			Managers.state.view:enable_view("credits_view", false)
		end
	end
end

CreditsView._update_scroll = function (self, dt, t)
	self._credits_offset = self._credits_offset + CreditsSettings.speed * dt
	self._elements.credits_element_0.offset[2] = self._credits_offset

	if self._elements["credits_element_" .. #Credits] then
		local pos = self._elements["credits_element_" .. #Credits].pos:unbox()

		if pos[2] > 1200 then
			Managers.state.view:enable_view("credits_view", false)
		end
	end
end

CreditsView._check_position = function (self, dt, t)
	local gui_pos = self._gui_pos:unbox()
	local test = self._animated_elements

	for index, element in ipairs(self._animated_elements) do
		if element.hover then
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
					self._animated_elements[self._current_selection_name].disabled = true
					self._animated_offset = 0
					self._current_selection_name = nil
				end

				if not self._current_selection_name then
					local source_id = WwiseUtils.make_position_auto_source(self._world, self._world_gui_pos:unbox())

					WwiseWorld.trigger_event(self._wwise_world, "menu_hover_mono", source_id)
				end

				self._current_selection_name = element.name
				self._elements[self._current_selection_name].disabled = true
				self._animated_elements[self._current_selection_name].disabled = false

				return
			end
		end
	end

	self._animated_offset_dir = -1
end

CreditsView._update_positions = function (self, dt)
	self._starting_pos = self._starting_pos + CreditsSettings.speed * dt

	local hmd_pose = Managers.vr:hmd_world_pose()

	if Matrix4x4.is_valid(hmd_pose.head) then
		local pose = hmd_pose.head
		local forward = Matrix4x4.forward(pose)
		local right = Matrix4x4.right(pose)
		local up = Matrix4x4.up(pose)
		local gui_pose = Matrix4x4.identity()

		Matrix4x4.set_translation(gui_pose, Matrix4x4.translation(pose) + Vector3(0, 0.5, 0))

		if Matrix4x4.is_valid(pose) then
			Gui.move(self._gui, gui_pose)
		end
	end
end

CreditsView._render_elements = function (self)
	return
end

CreditsView.destroy = function (self)
	print("CreditsView -> World.destroy_gui")
	World.destroy_gui(self._world, self._gui)

	self._gui = nil
end
