-- chunkname: @script/lua/views/credits_view_definitions.lua

local animated_elements = {
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
		type = "bitmap",
		name = "close_bg",
		hover = true,
		depends_on = "background",
		animated_offset = 0.05,
		horizontal_alignment = "right",
		vertical_alignment = "top",
		disabled = true,
		material_name = "button_bg",
		offset = {
			75,
			75,
			99
		},
		size = {
			156,
			156
		},
		on_activate = function (element, this)
			Managers.state.view:enable_view("credits_view", false)

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_exit_mono", source_id)
		end
	},
	{
		type = "bitmap",
		name = "close_bg_icon",
		depends_on = "close_bg",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "close",
		size = {
			110,
			110
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
}
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
		vertical_alignment = "top",
		name = "top_gradient",
		depends_on = "background",
		type = "bitmap",
		material_name = "gradient",
		horizontal_alignment = "center",
		size = {
			2200,
			200
		},
		offset = {
			0,
			-100,
			1
		}
	},
	{
		vertical_alignment = "center",
		name = "center_mask",
		depends_on = "background",
		type = "bitmap",
		material_name = "mask",
		horizontal_alignment = "center",
		size = {
			2200,
			600
		},
		offset = {
			0,
			0,
			1
		}
	},
	{
		type = "bitmap_uv",
		name = "bottom_gradient",
		depends_on = "background",
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		material_name = "gradient",
		size = {
			2200,
			200
		},
		offset = {
			0,
			100,
			1
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
		vertical_alignment = "top",
		name = "close_bg",
		type = "bitmap",
		depends_on = "background",
		material_name = "button_bg",
		horizontal_alignment = "right",
		offset = {
			75,
			75,
			99
		},
		size = {
			156,
			156
		}
	},
	{
		vertical_alignment = "center",
		name = "close_bg_icon",
		type = "bitmap",
		horizontal_alignment = "center",
		material_name = "close",
		depends_on = "close_bg",
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
		name = "credits_element_0",
		depends_on = "background",
		type = "bitmap",
		vertical_alignment = "bottom",
		disabled = true,
		material_name = "rect",
		size = {
			2200,
			0
		},
		offset = {
			0,
			0,
			10
		}
	}
}
local credits_element = {
	template_type = "credits_person",
	name = "credits_element_",
	depends_on = "credits_element_0",
	offset = {
		0,
		0,
		0
	},
	disabled_func = function (element)
		local pos = element.pos:unbox()

		if pos[2] < 0 or pos[2] > 1200 then
			return true
		end
	end
}

return {
	elements = elements,
	animated_elements = animated_elements,
	credits_element = credits_element
}
