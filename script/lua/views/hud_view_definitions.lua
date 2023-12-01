-- chunkname: @script/lua/views/hud_view_definitions.lua

local menu_elements = {
	{
		name = "background",
		template_type = "world_rect",
		disabled = true,
		color = {
			255,
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
			400,
			400
		}
	},
	{
		name = "menu_text",
		horizontal_alignment = "center",
		depends_on = "background",
		font_size = 15,
		vertical_alignment = "center",
		material = "gw_head_64_world",
		text = "Open/Close Menu",
		template_type = "small_header",
		offset = {
			0,
			15,
			1
		},
		colors = {
			255,
			255,
			168,
			0
		}
	}
}
local touch_elements = {
	{
		name = "background",
		template_type = "world_rect",
		disabled = true,
		color = {
			255,
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
			400,
			400
		}
	},
	{
		name = "option_1_text",
		horizontal_alignment = "center",
		depends_on = "background",
		font_size = 15,
		vertical_alignment = "center",
		material = "gw_head_64_world",
		text = "Teleport",
		template_type = "small_header",
		offset = {
			-50,
			15,
			2
		},
		colors = {
			255,
			255,
			168,
			0
		}
	},
	{
		name = "option_2_text",
		horizontal_alignment = "center",
		depends_on = "background",
		font_size = 15,
		vertical_alignment = "center",
		material = "gw_head_64_world",
		text = "Drop Item",
		template_type = "small_header",
		offset = {
			-50,
			-5,
			2
		},
		colors = {
			255,
			255,
			168,
			0
		}
	},
	{
		name = "circle",
		depends_on = "background",
		type = "bitmap",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "touchpad",
		size = {
			40,
			40
		},
		offset = {
			0,
			0,
			1
		},
		colors = {
			255,
			255,
			168,
			0
		}
	}
}
local grip_elements = {
	{
		name = "background",
		template_type = "world_rect",
		disabled = true,
		color = {
			128,
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
			400,
			400
		}
	},
	{
		name = "grip_text",
		horizontal_alignment = "left",
		depends_on = "background",
		font_size = 15,
		vertical_alignment = "bottom",
		material = "gw_head_64_world",
		text = "Reload Pistol",
		template_type = "small_header",
		offset = {
			5,
			0,
			1
		},
		colors = {
			255,
			255,
			168,
			0
		}
	}
}
local trigger_elements = {
	{
		name = "background",
		template_type = "world_rect",
		disabled = true,
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
		area_size = {
			400,
			400
		}
	},
	{
		name = "trigger_text",
		horizontal_alignment = "left",
		depends_on = "background",
		font_size = 15,
		vertical_alignment = "bottom",
		material = "gw_head_64_world",
		text = "Grab/Fire/Confirm",
		template_type = "small_header",
		offset = {
			10,
			0,
			1
		},
		colors = {
			255,
			255,
			168,
			0
		}
	}
}

return {
	menu_elements = menu_elements,
	touch_elements = touch_elements,
	grip_elements = grip_elements,
	trigger_elements = trigger_elements
}
