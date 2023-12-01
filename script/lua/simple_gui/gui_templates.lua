-- chunkname: @script/lua/simple_gui/gui_templates.lua

local templates = {
	rect = {
		vertical_alignment = "center",
		horizontal_alignment = "center",
		material_name = "rect",
		type = "bitmap"
	},
	world_rect = {
		vertical_alignment = "center",
		horizontal_alignment = "center",
		type = "rect"
	},
	header = {
		vertical_alignment = "top",
		font = "gui/fonts/gw_head_64",
		horizontal_alignment = "center",
		type = "text",
		font_size = 100,
		material = "gw_head_64",
		color = {
			255,
			255,
			168,
			0
		}
	},
	small_header = {
		vertical_alignment = "bottom",
		font = "gui/fonts/gw_head_64",
		horizontal_alignment = "left",
		type = "text",
		font_size = 60,
		material = "gw_head_64",
		color = {
			255,
			255,
			168,
			0
		}
	},
	small_header_masked = {
		vertical_alignment = "bottom",
		font = "gui/fonts/gw_head_64",
		horizontal_alignment = "left",
		type = "text",
		font_size = 40,
		material = "gw_head_64_masked",
		color = {
			255,
			255,
			168,
			0
		}
	},
	credits_header = {
		vertical_alignment = "bottom",
		font = "gui/fonts/gw_head_64",
		horizontal_alignment = "center",
		type = "text",
		font_size = 100,
		material = "gw_head_64_masked",
		color = {
			255,
			255,
			255,
			255
		}
	},
	credits_title = {
		vertical_alignment = "bottom",
		font = "gui/fonts/gw_head_64",
		horizontal_alignment = "center",
		type = "text",
		font_size = 40,
		material = "gw_head_64_masked",
		color = {
			255,
			255,
			168,
			0
		}
	},
	credits_person = {
		vertical_alignment = "bottom",
		font = "gui/fonts/gw_head_64",
		horizontal_alignment = "center",
		type = "text",
		font_size = 60,
		material = "gw_head_64_masked",
		color = {
			255,
			255,
			255,
			255
		}
	},
	credits_legal = {
		vertical_alignment = "bottom",
		font = "gui/fonts/gw_head_32",
		horizontal_alignment = "center",
		type = "text",
		font_size = 35,
		material = "gw_head_32_masked",
		color = {
			248,
			248,
			248,
			255
		}
	},
	sub_header = {
		vertical_alignment = "bottom",
		font = "gui/fonts/gw_head_64",
		horizontal_alignment = "center",
		type = "text",
		font_size = 60,
		material = "gw_head_64",
		color = {
			255,
			255,
			255,
			255
		}
	},
	text_wrap = {
		horizontal_alignment = "center",
		spacing = 60,
		type = "text_wrap",
		font_size = 60,
		material = "gw_head_64",
		vertical_alignment = "bottom",
		font = "gui/fonts/gw_head_64",
		width = 500,
		color = {
			255,
			255,
			168,
			0
		}
	},
	text = {
		vertical_alignment = "bottom",
		font = "gui/fonts/gw_head_64",
		horizontal_alignment = "left",
		type = "text",
		font_size = 60,
		material = "gw_head_64",
		color = {
			255,
			255,
			255,
			255
		}
	},
	centered_text = {
		vertical_alignment = "bottom",
		font = "gui/fonts/gw_head_64",
		horizontal_alignment = "center",
		type = "text",
		font_size = 60,
		material = "gw_head_64",
		color = {
			255,
			255,
			255,
			255
		}
	},
	video = {
		vertical_alignment = "center",
		loop = false,
		type = "video",
		horizontal_alignment = "center",
		size = {
			1920,
			1080
		}
	},
	splash = {
		vertical_alignment = "center",
		horizontal_alignment = "center",
		material_name = "gw_splash",
		type = "texture_atlas"
	},
	bitmap = {
		vertical_alignment = "center",
		horizontal_alignment = "center",
		type = "bitmap"
	},
	bitmap_uv = {
		vertical_alignment = "center",
		horizontal_alignment = "center",
		type = "bitmap_uv"
	},
	bitmap_rotation = {
		speed = 400,
		horizontal_alignment = "center",
		vertical_alignment = "center",
		type = "bitmap_rotation",
		angle = 3.14
	},
	selection = {
		vertical_alignment = "center",
		font = "gui/fonts/gw_body_64",
		horizontal_alignment = "left",
		type = "text",
		font_size = 70,
		material = "gw_body_64",
		color = {
			255,
			255,
			168,
			0
		}
	},
	centered_selection = {
		vertical_alignment = "center",
		font = "gui/fonts/gw_body_64",
		horizontal_alignment = "center",
		type = "text",
		font_size = 70,
		material = "gw_body_64",
		color = {
			255,
			255,
			168,
			0
		}
	},
	stepper = {
		vertical_alignment = "center",
		font = "gui/fonts/gw_body_64",
		horizontal_alignment = "left",
		type = "stepper",
		font_size = 70,
		stepper_spacing = 50,
		material = "gw_body_64",
		color = {
			255,
			255,
			168,
			0
		}
	}
}

return templates
