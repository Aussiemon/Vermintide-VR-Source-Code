-- chunkname: @script/lua/views/how_to_play_view_definitions.lua

local elements = {
	{
		name = "background",
		template_type = "rect",
		disabled = true,
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
			2200,
			1200
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
			-20,
			-20,
			999
		},
		size = {
			40,
			40
		},
		area_size = {
			2200,
			1200
		}
	},
	{
		name = "canvas",
		depends_on = "background",
		type = "bitmap",
		material_name = "background",
		offset = {
			0,
			0,
			1
		}
	},
	{
		horizontal_alignment = "right",
		name = "exit_button",
		depends_on = "background",
		type = "bitmap",
		animated_offset = 0.05,
		vertical_alignment = "top",
		selectable = true,
		material_name = "button_bg",
		offset = {
			75,
			75,
			5
		},
		size = {
			156,
			156
		},
		on_activate = function (element, this, dt)
			Managers.state.view:enable_view("how_to_play_view", false)
		end
	},
	{
		horizontal_alignment = "right",
		name = "arrow_right_button",
		depends_on = "background",
		type = "bitmap",
		vertical_alignment = "bottom",
		selectable = true,
		material_name = "button_bg",
		offset = {
			-75,
			200,
			5
		},
		size = {
			156,
			156
		},
		on_activate = function (element, this, dt)
			if this._current_index < #this._help_screens then
				this._current_index = this._current_index + 1
				this._elements.how_to_play.material_name = this._help_screens[this._current_index]
			end
		end
	},
	{
		horizontal_alignment = "right",
		name = "arrow_left_button",
		depends_on = "arrow_right_button",
		type = "bitmap",
		vertical_alignment = "bottom",
		selectable = true,
		material_name = "button_bg",
		offset = {
			-170,
			0,
			5
		},
		size = {
			156,
			156
		},
		on_activate = function (element, this, dt)
			if this._current_index > 1 then
				this._current_index = this._current_index - 1
				this._elements.how_to_play.material_name = this._help_screens[this._current_index]
			end
		end
	},
	{
		horizontal_alignment = "center",
		name = "exit_icon",
		hover = false,
		type = "bitmap",
		depends_on = "exit_button",
		vertical_alignment = "center",
		selectable = true,
		material_name = "close",
		offset = {
			0,
			0,
			2
		},
		size = {
			110,
			110
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "arrow_right",
		hover = false,
		depends_on = "arrow_right_button",
		text = ">",
		vertical_alignment = "center",
		template_type = "small_header",
		selectable = true,
		offset = {
			0,
			0,
			2
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "arrow_left",
		hover = false,
		depends_on = "arrow_left_button",
		text = "<",
		vertical_alignment = "center",
		template_type = "small_header",
		selectable = true,
		offset = {
			0,
			0,
			2
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	}
}
local selectable_elements = {
	{
		name = "background",
		template_type = "rect",
		disabled = true,
		color = {
			0,
			255,
			255,
			255
		},
		offset = {
			0,
			0,
			5
		},
		area_size = {
			2200,
			1200
		}
	}
}
local hover_template = {
	template_type = "bitmap",
	name = "",
	hover = false,
	depends_on = "",
	material_name = "button_bg_selection",
	size = {
		0,
		0
	},
	offset = {
		0,
		0,
		1
	},
	disabled_func = function (element, elements)
		return elements[element.depends_on].disabled
	end
}
local how_to_play_template = {
	vertical_alignment = "center",
	name = "how_to_play",
	depends_on = "background",
	type = "bitmap",
	material_name = "",
	horizontal_alignment = "center",
	color = {
		150,
		255,
		255,
		255
	},
	offset = {
		0,
		0,
		1
	}
}

return {
	elements = elements,
	selectable_elements = selectable_elements,
	hover_template = hover_template,
	how_to_play_template = how_to_play_template
}
