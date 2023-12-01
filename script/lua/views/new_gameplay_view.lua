-- chunkname: @script/lua/views/new_gameplay_view.lua

require("script/lua/simple_gui/simple_gui")

local templates = require("script/lua/simple_gui/gui_templates")
local elements_table = require("script/lua/views/new_gameplay_view_definitions")
local elements = elements_table.elements
local animated_elements = elements_table.animated_elements

class("NewGameplayView")

local menu_functions = {
	function (this)
		this._input_blocked = true
		this._new_state = StateLoading
	end,
	function (this)
		this._params.join_any = true
		this._input_blocked = true
		this._new_state = StateLoading
	end,
	function (this, element)
		if not element.active then
			-- Nothing
		end

		if rawget(_G, "Steam") then
			this._params.join_any = true
			this._input_blocked = true
			this._new_state = StateLoading
		else
			this:switch_view("InputIPView")
		end
	end,
	function (this)
		this:switch_view("CreditsView")
	end,
	function (this)
		this._input_blocked = true
		Game.quit = true
	end
}

NewGameplayView.init = function (self, world, input, parent)
	self._world = world
	self._wwise_world = Wwise.wwise_world(world)
	self._input = input
	self._parent = parent
	self._animated_offset = 0.5
	self._vr_target_scale = Application.user_setting("render_settings", "vr_target_scale") or 1

	self:_create_gui()

	self._dirty = true

	self:enable(false)
end

NewGameplayView._initiate_elements = function (self)
	local self_elements = table.clone(elements)
	local self_animated_elements = table.clone(animated_elements)

	for _, element in ipairs(self_elements) do
		self_elements[element.name] = element
	end

	for _, element in ipairs(self_animated_elements) do
		self_animated_elements[element.name] = element
	end

	self._elements = self_elements
	self._animated_elements = self_animated_elements
end

NewGameplayView.gui_pose = function (self)
	local tracking_pose = Managers.vr:tracking_space_pose()
	local tracking_pos = Matrix4x4.translation(tracking_pose)
	local tracking_pos_diff = tracking_pos - self._initial_tracking_pos:unbox()
	local translation = Matrix4x4.translation(self._hmd_pose:unbox())
	local new_pos = translation + tracking_pos_diff
	local tm = self._hmd_pose:unbox()

	Matrix4x4.set_translation(tm, new_pos)

	return Matrix4x4Box(tm)
end

NewGameplayView.enable = function (self, set, input_disabled)
	self._enabled = set
	self._input_disabled = input_disabled

	local hmd_pose = Managers.vr:hmd_world_pose()
	local forward = hmd_pose.forward

	forward.z = 0
	self._starting_rotation = QuaternionBox(Quaternion.look(forward, Vector3.up()))
	self._hmd_pose = Matrix4x4Box(hmd_pose.head)

	local tracking_pose = Managers.vr:tracking_space_pose()

	self._initial_tracking_pos = Vector3Box(Matrix4x4.translation(tracking_pose))

	if not self._enabled then
		self._animated_offset_dir = -1
		self._animated_offset = 0
	end

	self:_initiate_elements()
	self:_update_level_elements()

	if Managers.lobby then
		self._num_players = #Managers.lobby:lobby_members()
	end
end

NewGameplayView.active = function (self)
	return self._enabled
end

NewGameplayView.activate_menu_option = function (self, index, element)
	menu_functions[index](self._parent, element)
end

NewGameplayView._create_gui = function (self)
	self._world_gui_pos = Vector3Box(Vector3(0, 0, 0))
	self._gui_pos = Vector3Box(Vector3(0, 0, 0))
	self._gui_pose = Matrix4x4Box(Matrix4x4.identity())
	self._size = {
		1000,
		1000
	}
	self._gui = World.create_world_gui(self._world, self._gui_pose:unbox(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
	self._animated_gui = World.create_world_gui(self._world, self._gui_pose:unbox(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")

	print("NewGameplayView -> World.create_world_gui")
end

local DO_RELOAD = true

NewGameplayView.update = function (self, dt, t)
	Profiler.start("NewGuiView")

	if DO_RELOAD then
		self:_initiate_elements()
		self:_update_level_elements()
	end

	if Managers.popup:has_popup() then
		return
	end

	if self._enabled then
		self:_update_position_on_gui(dt, t)
		self:_update_gui_position(dt, t)
		self:_update_animations(dt, t)
		self:_update_lobby_members(dt, t)
		self:_update_scroller(dt, t)
		self:_update_ui(dt, t)
	end

	self:_update_input(dt, t)
	Profiler.stop("NewGuiView")
end

NewGameplayView._update_scroller = function (self, dt, t)
	if self._scroller_dirty then
		local scroller_offset = self._animated_elements.scroller.offset[1]

		self._elements.scroller.offset[1] = scroller_offset
		self._vr_target_scale = 0.5 + scroller_offset / 500 * 1
		self._vr_target_scale = math.floor(self._vr_target_scale * 10 + 0.5) / 10
		self._elements.render_quality_scale_text.text = string.format("%.1f", self._vr_target_scale)
		self._animated_elements.render_quality_scale_text.text = string.format("%.1f", self._vr_target_scale)
		self._scroller_dirty = false
	end
end

NewGameplayView._update_level_elements = function (self)
	local is_multiplayer = Managers.lobby and #Managers.lobby:lobby_members() > 1 or Managers.lobby and not Managers.lobby.server

	if is_multiplayer then
		local level_images = {
			{
				material_name = "preview_image_inn",
				level_name = "inn"
			},
			{
				material_name = "preview_image_drachenfels",
				level_name = "drachenfels"
			},
			{
				material_name = "preview_image_forest",
				level_name = "forest"
			}
		}

		for idx, data in ipairs(level_images) do
			level_images[data.level_name] = data
			data.idx = idx
		end

		local current_level_name = self._parent._level_name
		local current_level_material = level_images[current_level_name].material_name

		self._elements.current_level.material_name = current_level_material
		self._elements.current_level.level_name = current_level_name
		self._animated_elements.current_level.material_name = current_level_material
		self._animated_elements.current_level.level_name = current_level_name

		for idx, level_data in ipairs(level_images) do
			self._elements["level_" .. idx].material_name = level_data.material_name
			self._elements["level_" .. idx].level_name = level_data.level_name
			self._animated_elements["level_" .. idx].material_name = level_data.material_name
			self._animated_elements["level_" .. idx].level_name = level_data.level_name
		end
	else
		local level_images = {
			{
				material_name = "preview_image_inn",
				level_name = "inn"
			},
			{
				material_name = "preview_image_drachenfels",
				level_name = "drachenfels"
			},
			{
				material_name = "preview_image_forest",
				level_name = "forest"
			},
			{
				material_name = "preview_image_cart",
				level_name = "cart"
			}
		}

		for idx, data in ipairs(level_images) do
			level_images[data.level_name] = data
			data.idx = idx
		end

		local current_level_name = self._parent._level_name
		local current_level_material = level_images[current_level_name].material_name

		self._elements.current_level.material_name = current_level_material
		self._elements.current_level.level_name = current_level_name
		self._animated_elements.current_level.material_name = current_level_material
		self._animated_elements.current_level.level_name = current_level_name

		local idx = level_images[current_level_name].idx

		table.remove(level_images, idx)

		for idx, level_data in ipairs(level_images) do
			self._elements["level_" .. idx].material_name = level_data.material_name
			self._elements["level_" .. idx].level_name = level_data.level_name
			self._animated_elements["level_" .. idx].material_name = level_data.material_name
			self._animated_elements["level_" .. idx].level_name = level_data.level_name
		end
	end

	self._dirty = true
	DO_RELOAD = false
end

NewGameplayView._update_position_on_gui = function (self, dt, t)
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
		self._old_gui_pos = Vector3Box(self._gui_pos:unbox())

		local world_pos = pos + dir * distance_along_ray
		local pose = Matrix4x4.inverse(gui_pose)
		local local_pos = Matrix4x4.transform(pose, world_pos)

		gui_pos.x = local_pos.x / (1 / self._size[1])
		gui_pos.z = local_pos.z / (1 / self._size[2])

		if self._elements.mouse_pos then
			self._elements.mouse_pos.text = string.format("X: %d   Y: %d", gui_pos.x, gui_pos.z)
		end

		local element = self._elements.test

		element.offset[1] = gui_pos.x - element.size[1] * 0.5
		element.offset[2] = gui_pos.z - element.size[2] * 0.5
		self._gui_pos = Vector3Box(gui_pos)
		self._world_gui_pos = Vector3Box(world_pos)
		self._dirty = true
	end
end

NewGameplayView._update_gui_position = function (self, dt, t)
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

NewGameplayView._update_input = function (self, dt, t)
	if self._input_disabled then
		return
	end

	if self._enabled then
		if self._input_held then
			if self._input:get("held", "trigger", "any", true) then
				local element = self._animated_elements[self._current_selection_name]

				element.on_activate_held(element, self, dt)

				return
			else
				self._input_held = false
			end
		end

		self:_check_position(t)

		if self._current_selection_name and self._input:get("pressed", "trigger", "any", true) then
			local element = self._animated_elements[self._current_selection_name]

			if element.on_activate_held and self._input:get("held", "trigger", "any", true) then
				element.on_activate_held(element, self, dt)

				self._input_held = true
			end

			if element.on_activate then
				element.on_activate(element, self)
			end

			self._dirty = true
		end
	end

	if self._input:get("pressed", "menu", "any") then
		Managers.state.view:enable_view("gameplay_view", false)
	end
end

NewGameplayView._check_position = function (self, t)
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

NewGameplayView._update_animations = function (self, dt, t)
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

NewGameplayView._update_lobby_members = function (self, dt, t)
	if not Managers.lobby then
		return
	end

	local num_players = #Managers.lobby:lobby_members()

	if num_players ~= self._num_players then
		self:_initiate_elements()
		self:_update_level_elements()

		self._num_players = num_players

		print("REINITIATE")
	end
end

NewGameplayView._update_ui = function (self, dt, t)
	if not self._dirty then
		-- Nothing
	end

	for _, element in ipairs(self._elements) do
		SimpleGui.update_element(self._gui, element, self._elements, templates, self._world, dt, t)
	end

	do
		local test = animated_elements

		for _, element in ipairs(self._animated_elements) do
			SimpleGui.update_element(self._animated_gui, element, self._animated_elements, templates, self._world, dt, t)
		end

		self._dirty = false
	end

	for _, element in ipairs(self._elements) do
		SimpleGui.render_element(self._gui, element)
	end

	for _, element in ipairs(self._animated_elements) do
		SimpleGui.render_element(self._animated_gui, element)
	end
end

NewGameplayView.destroy = function (self)
	print("NewGameplayView -> World.destroy_gui")
	World.destroy_gui(self._world, self._gui)

	self._gui = nil
end
