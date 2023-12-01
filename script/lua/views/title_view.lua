-- chunkname: @script/lua/views/title_view.lua

require("script/lua/simple_gui/simple_gui")

local templates = require("script/lua/simple_gui/gui_templates")

class("TitleView")

local elements = {
	{
		name = "background",
		template_type = "rect",
		color = {
			0,
			255,
			255,
			255
		},
		offset = {
			0,
			0,
			0
		},
		area_size = {
			1000,
			1000
		}
	},
	{
		name = "test",
		type = "bitmap",
		material_name = "dot",
		color = {
			255,
			255,
			168,
			0
		},
		offset = {
			0,
			0,
			500
		},
		size = {
			2,
			2
		},
		area_size = {
			1000,
			1000
		}
	},
	{
		vertical_alignment = "top",
		template_type = "bitmap",
		depends_on = "background",
		material_name = "gradient",
		name = "upper_gradient",
		color = {
			255,
			255,
			0,
			0
		},
		offset = {
			0,
			0,
			0
		},
		size = {
			1000,
			100
		}
	},
	{
		name = "lower_gradient",
		depends_on = "background",
		vertical_alignment = "bottom",
		template_type = "bitmap_uv",
		material_name = "gradient",
		color = {
			255,
			255,
			0,
			0
		},
		offset = {
			0,
			0,
			0
		},
		size = {
			1000,
			100
		},
		uv00 = {
			0,
			1
		},
		uv11 = {
			1,
			0
		}
	},
	{
		name = "inner_mask",
		template_type = "bitmap",
		depends_on = "background",
		material_name = "mask",
		color = {
			255,
			0,
			0,
			0
		},
		size = {
			1000,
			800
		},
		offset = {
			0,
			0,
			1
		}
	},
	{
		name = "inner_background",
		template_type = "bitmap",
		depends_on = "background",
		material_name = "masked_rect",
		color = {
			196,
			0,
			0,
			0
		},
		size = {
			950,
			1000
		}
	},
	{
		name = "masked_left_strip",
		template_type = "bitmap",
		depends_on = "background",
		material_name = "masked_rect",
		horizontal_alignment = "left",
		color = {
			196,
			0,
			0,
			0
		},
		offset = {
			0,
			0,
			0
		},
		size = {
			15,
			1000
		}
	},
	{
		name = "masked_right_strip",
		template_type = "bitmap",
		depends_on = "background",
		material_name = "masked_rect",
		horizontal_alignment = "right",
		color = {
			196,
			0,
			0,
			0
		},
		offset = {
			0,
			0,
			0
		},
		size = {
			15,
			1000
		}
	},
	{
		name = "selection",
		template_type = "rect",
		depends_on = "background",
		color = {
			0,
			0,
			0,
			0
		},
		offset = {
			0,
			0,
			0
		},
		size = {
			400,
			1000
		}
	},
	{
		text = "MAIN MENU",
		template_type = "header",
		name = "header",
		depends_on = "background",
		offset = {
			-100,
			-150,
			0
		}
	},
	{
		name = "option_two",
		text = "Level",
		depends_on = "header",
		horizontal_alignment = "left",
		vertical_alignment = "top",
		template_type = "stepper",
		offset = {
			0,
			-150,
			0
		},
		color = {
			255,
			255,
			255,
			255
		},
		options = LevelSettings.level_sequence,
		option_index = table.find(LevelSettings.level_sequence, LevelSettings.default_level) or 1,
		handle_input = function (element, input)
			if input:get("pressed", "touch_left", "any") then
				element.option_index = math.max(element.option_index - 1, 1)
				LevelSettings.default_level = element.options[element.option_index]

				return true
			elseif input:get("pressed", "touch_right", "any") then
				element.option_index = math.min(element.option_index + 1, #element.options)
				LevelSettings.default_level = element.options[element.option_index]

				return true
			end
		end
	},
	{
		text = "Host Game",
		template_type = "selection",
		name = "option_one",
		depends_on = "selection",
		offset = {
			0,
			0,
			0
		}
	},
	{
		text = "Join Any Game",
		template_type = "selection",
		name = "option_two",
		depends_on = "option_one",
		offset = {
			0,
			-75,
			0
		}
	},
	{
		text = "Join By Ip",
		template_type = "selection",
		name = "option_three",
		depends_on = "option_two",
		offset = {
			0,
			-75,
			0
		},
		active_func = function (element)
			return Game.startup_commands.network == "lan"
		end
	},
	{
		text = "Credits",
		template_type = "selection",
		name = "option_four",
		depends_on = "option_three",
		offset = {
			0,
			-75,
			0
		}
	},
	{
		text = "Quit",
		template_type = "selection",
		name = "option_five",
		depends_on = "option_four",
		offset = {
			0,
			-75,
			0
		}
	},
	{
		vertical_alignment = "none",
		name = "option_indicator",
		template_type = "bitmap",
		depends_on = "option_one",
		horizontal_alignment = "none",
		material_name = "indicator",
		offset = {
			-50,
			0,
			1
		},
		size = {
			40,
			40
		}
	}
}

for _, element in ipairs(elements) do
	elements[element.name] = element
end

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

TitleView.init = function (self, world, input, parent)
	self._world = world
	self._input = input
	self._parent = parent

	self:_create_gui()

	self._dirty = true
	self._selection_index = 1
	self._selections = {
		"option_one",
		"option_two",
		"option_three",
		"option_four",
		"option_five"
	}
	elements.option_indicator.depends_on = self._selections[self._selection_index]
end

TitleView.activate_menu_option = function (self, index, element)
	menu_functions[index](self._parent, element)
end

TitleView._create_gui = function (self)
	self._gui_pos = Vector3Box(Vector3(0, 0, 0))
	self._gui_pose = Matrix4x4Box(Matrix4x4.identity())
	self._size = {
		1000,
		1000
	}
	self._gui = World.create_world_gui(self._world, self._gui_pose:unbox(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")

	print("TitleView -> World.create_world_gui")
end

TitleView.update = function (self, dt, t)
	if not self._drawer then
		self._drawer = Debug:drawer("title_view", false)
	else
		self._drawer:reset()

		local gui_pose = self._gui_pose:unbox()
		local gui_pos = Matrix4x4.translation(gui_pose)
		local gui_normal = Matrix4x4.forward(gui_pose)
		local plane = Plane.from_point_and_normal(gui_pos, gui_normal)
		local hmd_pose = Managers.vr:hmd_world_pose()
		local pos = Matrix4x4.translation(hmd_pose.head)
		local dir = hmd_pose.forward
		local distance_along_ray, is_ray_start_in_front_of_plane = Intersect.ray_plane(pos, dir, plane)
		local sphere_pos = pos + dir * distance_along_ray
		local pose = Matrix4x4.inverse(gui_pose)
		local local_pos = Matrix4x4.transform(pose, sphere_pos)

		gui_pos.x = local_pos.x / (1 / self._size[1])
		gui_pos.z = local_pos.z / (1 / self._size[2])
		self._dirty = true

		local element = elements.test

		element.offset[1] = gui_pos.x
		element.offset[2] = gui_pos.z
		self._gui_pos = Vector3Box(gui_pos)
	end

	self:_update_position(dt, t)
	self:_update_ui(dt, t)
	self:_update_input(dt, t)
end

TitleView._update_position = function (self, dt, t)
	local hmd_pose = Managers.vr:hmd_world_pose()

	if Matrix4x4.is_valid(hmd_pose.head) then
		local pose = hmd_pose.head
		local gui_pose = Matrix4x4.identity()

		Matrix4x4.set_translation(gui_pose, Matrix4x4.translation(pose) + Vector3(-0.5, 2.5, -0.5))

		if Matrix4x4.is_valid(pose) then
			Gui.move(self._gui, gui_pose)

			self._gui_pose = Matrix4x4Box(gui_pose)
		end
	end
end

TitleView._update_input = function (self, dt, t)
	self:_check_position()

	for _, element in pairs(elements) do
		if element.handle_input then
			self._dirty = element.handle_input(element, self._input) or self._dirty
		end
	end

	if self._input:get("pressed", "trigger", "any", true) then
		local element_name = self._selections[self._selection_index]
		local current_element = elements[element_name]

		self:activate_menu_option(self._selection_index, current_element)

		self._dirty = true
	end

	if self._dirty then
		elements.option_indicator.depends_on = self._selections[self._selection_index]
	end
end

TitleView._check_position = function (self)
	local gui_pos = self._gui_pos:unbox()

	for index, element_name in pairs(self._selections) do
		local element = elements[element_name]

		if element then
			local pos = element.pos:unbox()
			local size = element.size:unbox()
			local end_pos = {
				pos.x + size.x,
				pos.y + size.y
			}

			if gui_pos.x >= pos.x and gui_pos.x <= pos.x + size.x and gui_pos.z >= pos.y and gui_pos.z <= pos.y + size.y then
				self._selection_index = index
				elements.option_indicator.depends_on = self._selections[self._selection_index]

				break
			end
		end
	end
end

TitleView._update_ui = function (self, dt, t)
	if self._dirty then
		for _, element in ipairs(elements) do
			SimpleGui.update_element(self._gui, element, elements, templates)
		end

		self._dirty = false
	end

	for _, element in ipairs(elements) do
		SimpleGui.render_element(self._gui, element)
	end
end

TitleView.destroy = function (self)
	print("TitleView -> World.destroy_gui")
	World.destroy_gui(self._world, self._gui)

	self._gui = nil
end
