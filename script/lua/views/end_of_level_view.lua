-- chunkname: @script/lua/views/end_of_level_view.lua

require("script/lua/simple_gui/simple_gui")

local templates = require("script/lua/simple_gui/gui_templates")

class("EndOfLevelView")

local elements = {
	{
		name = "background",
		template_type = "rect",
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
		},
		area_size = {
			400,
			1000
		}
	},
	{
		text = "END OF LEVEL",
		template_type = "header",
		name = "header",
		depends_on = "background",
		offset = {
			0,
			-150,
			0
		}
	},
	{
		text = "Next Level",
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
		text = "Retry",
		template_type = "selection",
		name = "option_two",
		depends_on = "option_one",
		offset = {
			0,
			-100,
			0
		}
	},
	{
		text = "Exit to Menu",
		template_type = "selection",
		name = "option_three",
		depends_on = "option_two",
		offset = {
			0,
			-100,
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

		Managers.transition:fade_in(1, callback(this, "cb_fade_in_done"))

		this._params = {
			next_state = StateGameplay,
			level_name = this._in_params.level_name,
			old_level_name = this._in_params.old_level_name,
			permission_to_enter_game = this._in_params.permission_to_enter_game
		}
		this._new_state = StateLoading
	end,
	function (this)
		this._input_blocked = true

		Managers.transition:fade_in(1, callback(this, "cb_fade_in_done"))

		this._params = {
			next_state = StateGameplay,
			level_name = this._in_params.old_level_name,
			old_level_name = this._in_params.old_level_name,
			permission_to_enter_game = this._in_params.permission_to_enter_game
		}
		this._new_state = StateLoading
	end,
	function (this)
		this._input_blocked = true, Managers.transition:fade_in(1, callback(this, "cb_fade_in_done"))
		this._params = {
			exit_to_menu = true,
			permission_to_enter_game = true,
			old_level_name = this._in_params.old_level_name,
			next_state = StateTitleScreen
		}
		this._new_state = StateLoading
	end
}

EndOfLevelView.init = function (self, world, input, parent)
	self._world = world
	self._input = input
	self._parent = parent

	self:_create_gui()

	self._dirty = true
	self._selection_index = 1
	self._selections = {
		"option_one",
		"option_two",
		"option_three"
	}
end

EndOfLevelView._activate_menu_option = function (self, index)
	menu_functions[index](self._parent)
end

EndOfLevelView._create_gui = function (self)
	self._size = {
		1000,
		1000
	}
	self._gui = World.create_world_gui(self._world, Matrix4x4.identity(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")

	print("EndOfLevelView -> World.create_world_gui")
end

EndOfLevelView.update = function (self, dt, t)
	self:_update_position(dt, t)
	self:_update_input(dt, t)
	self:_update_ui(dt, t)
end

EndOfLevelView._update_position = function (self, dt, t)
	local hmd_pose = Managers.vr:hmd_world_pose()

	if Matrix4x4.is_valid(hmd_pose.head) then
		local pose = hmd_pose.head
		local right = Matrix4x4.right(pose)
		local up = Matrix4x4.up(pose)

		Matrix4x4.set_translation(pose, Matrix4x4.translation(pose) + hmd_pose.forward * 2 + right * -0.5 + up * -0.5)

		if Matrix4x4.is_valid(hmd_pose.head) then
			Gui.move(self._gui, pose)
		end
	end
end

EndOfLevelView._update_input = function (self, dt, t)
	if self._input:get("pressed", "touch_up", "any") and self._selection_index > 1 then
		self._selection_index = self._selection_index - 1
		self._dirty = true
	elseif self._input:get("pressed", "touch_down", "any") and self._selection_index < #self._selections then
		self._selection_index = self._selection_index + 1
		self._dirty = true
	end

	if self._input:get("pressed", "trigger", "any") then
		self:_activate_menu_option(self._selection_index)

		self._dirty = true
	end

	if self._dirty then
		elements.option_indicator.depends_on = self._selections[self._selection_index]
	end
end

EndOfLevelView._update_ui = function (self, dt, t)
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

EndOfLevelView.destroy = function (self)
	print("EndOfLevelView -> World.destroy_gui")
	World.destroy_gui(self._world, self._gui)

	self._gui = nil
end
