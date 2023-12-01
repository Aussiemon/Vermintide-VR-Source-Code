-- chunkname: @script/lua/simple_gui/simple_gui.lua

class("SimpleGui")

local AVAILABLE_ATLASES = AVAILABLE_ATLASES or {
	splash_atlas = require("gui/atlas_settings/splash_atlas")
}
local ATLAS_LOOKUP = {}

for atlas_name, _ in pairs(AVAILABLE_ATLASES) do
	local atlas = rawget(_G, atlas_name)

	for name, _ in pairs(atlas) do
		fassert(not ATLAS_LOOKUP[name], "[SimpleGui] texture name (%s) already added", name)

		ATLAS_LOOKUP[name] = atlas_name
	end
end

SimpleGui.atlas_settings = function (material_name)
	local atlas_name = ATLAS_LOOKUP[material_name]
	local atlas = rawget(_G, atlas_name)

	return atlas[material_name], atlas_name
end

SimpleGui.update_element = function (gui, element, elements, templates, world, dt, t)
	local template = templates[element.template_type]

	if template then
		for name, value in pairs(template) do
			if not element[name] then
				if type(value) == "table" then
					element[name] = table.clone(value)
				else
					element[name] = value
				end
			end
		end
	end

	local pos = Vector3(0, 0, 0)
	local area_size = element.area_size

	if element.depends_on then
		local dependent_element = elements[element.depends_on]

		if not dependent_element then
			Application.error("ERROR: " .. element.name)
			table.dump(element, "ELEMENT", 4, Application.error)
		end

		area_size = dependent_element.size:unbox()
		pos = dependent_element.pos:unbox()
	elseif not area_size then
		fassert("You need to specify and area_size for the element or depend on an elmeent that specifies an area size")
	end

	if element.active_func then
		element.active = element.active_func(element)
	elseif element.active == nil then
		element.active = true
	end

	element.area_size = element.area_size or area_size

	local extents = Vector2(area_size[1], area_size[2])

	if element.type == "text" or element.type == "stepper" then
		local text = element.text_func and element.text_func(element) or element.text
		local min, max = Gui.text_extents(gui, text, element.font, element.font_size)

		extents = Vector2(max[1] - min[1], max[2] - min[2])
	elseif element.type == "text_wrap" then
		local whitespace, soft_dividers, return_dividers = " ", "-+&/*", "\n"
		local reuse_global_table = true
		local rows = Gui.word_wrap(gui, element.text, element.font, element.font_size, element.width, whitespace, soft_dividers, return_dividers, false)

		element.texts = rows

		if type(element.texts) == "string" then
			element.texts = {
				element.texts
			}
		end

		extents = Vector2(element.width, element.spacing * #element.texts)
	elseif element.type == "texture_atlas" then
		local atlas_settings, atlas_name = SimpleGui.atlas_settings(element.material_name)

		element.atlas_settings = atlas_settings
		element.atlas_name = atlas_name
		extents = Vector2(atlas_settings.size[1], atlas_settings.size[2])
	elseif element.size then
		extents = Vector2(element.size[1], element.size[2])
	end

	if element.type == "bitmap_rotation" then
		local degree_angle = element.angle
		local speed = element.speed

		element.angle = (degree_angle + element.speed * dt) % 360
	end

	local horizontal_alignment = element.horizontal_alignment
	local vertical_alignment = element.vertical_alignment

	if horizontal_alignment == "center" then
		pos[1] = pos[1] + area_size[1] * 0.5 - extents[1] * 0.5
	elseif horizontal_alignment == "right" then
		pos[1] = pos[1] + area_size[1] - extents[1]
	end

	if vertical_alignment == "center" then
		pos[2] = pos[2] + area_size[2] * 0.5 - extents[2] * 0.5
	elseif vertical_alignment == "top" then
		pos[2] = pos[2] + area_size[2] - extents[2]
	end

	if element.offset then
		pos = pos + Vector3(element.offset[1], element.offset[2], element.offset[3])
	end

	if element.type == "video" and not element.video_player and not element.disabled then
		element.video_player = World.create_video_player(world, element.resource_name, element.loop)
	end

	local color = {
		255,
		255,
		255,
		255
	}

	if element.color_func then
		color = element.color_func(element)
	elseif element.color then
		assert(#element.color == 4, "[TitleView] You need to specify all ARGB channels")

		color = element.color
	end

	element.color = color
	element.pos = Vector3Box(pos)
	element.size = Vector2Box(extents)

	if element.disabled_func then
		element.disabled = element.disabled_func(element, elements)
	else
		element.disabled = element.disabled
	end
end

SimpleGui.render_element = function (gui, element)
	if element.disabled then
		return
	end

	local type = element.type

	if type then
		SimpleGui[type](gui, element)
	end
end

SimpleGui.text = function (gui, element)
	local text = element.text_func and element.text_func(element) or element.text
	local pos = element.pos:unbox()
	local color = Color(element.color[1] * (element.active and 1 or 0.25), element.color[2], element.color[3], element.color[4])

	Gui.text(gui, text, element.font, element.font_size, element.material, pos, color)
end

SimpleGui.text_wrap = function (gui, element)
	local pos = element.pos:unbox()
	local color = Color(element.color[1] * (element.active and 1 or 0.25), element.color[2], element.color[3], element.color[4])

	for i = #element.texts, 1, -1 do
		local local_pos = Vector3(pos[1], pos[2], pos[3])
		local min, max = Gui.text_extents(gui, element.texts[i], element.font, element.font_size)
		local local_width = max[1] - min[1]

		local_pos[1] = local_pos[1] + (element.width - local_width) * 0.5

		Gui.text(gui, element.texts[i], element.font, element.font_size, element.material, local_pos, color)

		pos[2] = pos[2] + element.spacing
	end
end

SimpleGui.rect = function (gui, element)
	local pos = element.pos:unbox()
	local color = Color(element.color[1] * (element.active and 1 or 0.25), element.color[2], element.color[3], element.color[4])
	local size = element.size:unbox()

	Gui.rect(gui, pos, size, color)
end

SimpleGui.texture_atlas = function (gui, element)
	local pos = element.pos:unbox()
	local color = Color(element.color[1] * (element.active and 1 or 0.25), element.color[2], element.color[3], element.color[4])
	local size = element.size:unbox()
	local atlas_settings = element.atlas_settings

	Gui.bitmap_uv(gui, element.atlas_name, Vector3(atlas_settings.uv00[1], atlas_settings.uv00[2], 0), Vector3(atlas_settings.uv11[1], atlas_settings.uv11[2], 0), pos, size, color)
end

SimpleGui.video = function (gui, element)
	local color = Color(element.color[1] * (element.active and 1 or 0.25), element.color[2], element.color[3], element.color[4])
	local pos = element.pos:unbox()
	local size = element.size:unbox()

	Gui.video(gui, element.video_name, element.video_player, pos, size, color)

	element.video_done = VideoPlayer.current_frame(element.video_player) == VideoPlayer.number_of_frames(element.video_player)
end

SimpleGui.bitmap = function (gui, element)
	local pos = element.pos:unbox()
	local size = element.size:unbox()
	local color = Color(element.color[1] * (element.active and 1 or 0.25), element.color[2], element.color[3], element.color[4])
	local material_name = element.material_func and element.material_func(element) or element.material_name

	Gui.bitmap(gui, material_name, pos, size, color)
end

SimpleGui.bitmap_rotation = function (gui, element)
	local pos = element.pos:unbox()
	local size = element.size:unbox()
	local color = Color(element.color[1] * (element.active and 1 or 0.25), element.color[2], element.color[3], element.color[4])
	local material_name = element.material_func and element.material_func(element) or element.material_name
	local pivot = Vector3(size[1] * 0.5, size[2] * 0.5, 0)
	local tm = Rotation2D(pos, math.degrees_to_radians(element.angle), pos + pivot)

	Gui.bitmap_3d(gui, element.material_name, tm, Vector3(0, 0, 0), pos[3], size, color)
end

SimpleGui.bitmap_uv = function (gui, element)
	local pos = element.pos:unbox()
	local size = element.size:unbox()
	local color = Color(element.color[1] * (element.active and 1 or 0.25), element.color[2], element.color[3], element.color[4])

	Gui.bitmap_uv(gui, element.material_name, Vector3(element.uv00[1], element.uv00[2], 0), Vector3(element.uv11[1], element.uv11[2], 0), pos, size, color)
end

SimpleGui.stepper = function (gui, element)
	local pos = element.pos:unbox()
	local size = element.size:unbox()
	local color = Color(element.color[1] * (element.active and 1 or 0.25), element.color[2], element.color[3], element.color[4])

	Gui.text(gui, element.text, element.font, element.font_size, element.material, pos, color)

	local stepper_spacing = element.stepper_spacing
	local option_index = element.option_index
	local option = element.options[option_index]
	local layer = pos[3]

	pos = Vector3(pos[1] + size[1] + stepper_spacing * 2, pos[2], pos[3])

	if option_index > 1 then
		local triangle_pos = Vector3(pos[1], 0, pos[2])

		Gui.triangle(gui, triangle_pos + Vector3(size[2] * 0.5, 0, size[2] * 0.5), triangle_pos + Vector3(size[2] * 0.5, 0, 0), triangle_pos + Vector3(0, 0, size[2] * 0.25), 50, color)
	end

	pos = pos + Vector3(stepper_spacing + size[2] * 0.5, 0, 0)

	Gui.text(gui, option, element.font, element.font_size, element.material, pos, color)

	if option_index < #element.options then
		local min, max = Gui.text_extents(gui, option, element.font, element.font_size)
		local length = max[1] - min[1]
		local triangle_pos = Vector3(pos[1] + length + stepper_spacing, 0, pos[2])

		Gui.triangle(gui, triangle_pos + Vector3(0, 0, size[2] * 0.5), triangle_pos + Vector3(0, 0, 0), triangle_pos + Vector3(size[2] * 0.5, 0, size[2] * 0.25), 50, color)
	end
end
