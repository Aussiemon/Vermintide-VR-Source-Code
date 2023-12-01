-- chunkname: @script/lua/views/popup_view_definitions.lua

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
		horizontal_alignment = "center",
		name = "popup_bg",
		depends_on = "background",
		type = "bitmap",
		vertical_alignment = "center",
		selectable = true,
		material_name = "popup_bg",
		root = true,
		offset = {
			0,
			0,
			1
		},
		size = {
			796,
			616
		}
	},
	{
		text = "This is a test",
		template_type = "header",
		name = "header",
		depends_on = "popup_bg",
		font_size = 80,
		horizontal_alignment = "center",
		vertical_alignment = "top",
		offset = {
			0,
			-60,
			0
		}
	},
	{
		horizontal_alignment = "center",
		name = "text",
		spacing = 40,
		depends_on = "popup_bg",
		font_size = 40,
		vertical_alignment = "center",
		text = "The quick brown fox jumps over the lazy dog The quick brown fox jumps over the lazy dog The quick brown fox jumps over the lazy dog The quick brown fox jumps over the lazy dog",
		template_type = "text_wrap",
		width = 500,
		offset = {
			-0,
			0,
			0
		}
	},
	{
		type = "bitmap",
		name = "ok_button",
		depends_on = "popup_bg",
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		selectable = true,
		material_name = "button_bg",
		offset = {
			0,
			100,
			1
		},
		size = {
			75,
			75
		},
		on_activate = function (element, this, dt)
			this._popup_done = true
		end
	},
	{
		type = "bitmap",
		name = "check",
		depends_on = "ok_button",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		selectable = true,
		material_name = "check",
		color_func = function (element)
			return {
				255,
				0,
				192 + math.sin(Application.time_since_launch() * 7.5) * 64,
				0
			}
		end,
		offset = {
			0,
			0,
			0
		},
		size = {
			40,
			40
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
			0
		},
		area_size = {
			2200,
			1200
		}
	}
}

return {
	elements = elements,
	selectable_elements = selectable_elements
}
