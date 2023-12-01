-- chunkname: @script/lua/views/base_view_definitions.lua

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
		template_type = "rect",
		depends_on = "background",
		color = {
			196,
			10,
			10,
			10
		},
		offset = {
			0,
			0,
			1
		}
	},
	{
		vertical_alignment = "top",
		template_type = "rect",
		name = "canvas_edge_top",
		depends_on = "canvas",
		horizontal_alignment = "center",
		color = {
			255,
			255,
			168,
			0
		},
		offset = {
			0,
			10,
			-1
		},
		size = {
			2220,
			10
		}
	},
	{
		vertical_alignment = "center",
		template_type = "rect",
		name = "canvas_edge_left",
		depends_on = "canvas",
		horizontal_alignment = "left",
		color = {
			255,
			255,
			168,
			0
		},
		offset = {
			-10,
			0,
			-1
		},
		size = {
			10,
			1200
		}
	},
	{
		vertical_alignment = "center",
		template_type = "rect",
		name = "canvas_edge_right",
		depends_on = "canvas",
		horizontal_alignment = "right",
		color = {
			255,
			255,
			168,
			0
		},
		offset = {
			10,
			0,
			-1
		},
		size = {
			10,
			1200
		}
	},
	{
		vertical_alignment = "bottom",
		template_type = "rect",
		name = "canvas_edge_bottom",
		depends_on = "canvas",
		horizontal_alignment = "center",
		color = {
			255,
			255,
			168,
			0
		},
		offset = {
			0,
			0,
			1
		},
		size = {
			2220,
			10
		}
	}
}

for _, element in ipairs(elements) do
	elements[element.name] = element
end

return {
	elements = elements
}
