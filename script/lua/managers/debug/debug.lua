-- chunkname: @script/lua/managers/debug/debug.lua

local font_size = 26
local font = "debug"
local font_mtrl = "core/performance_hud/debug"
local remove_list = {}

Debug = Debug or {}

Debug.setup = function (world)
	Debug.active = true
	Debug.world = world
	Debug.gui = World.create_screen_gui(world, "material", "core/performance_hud/gui", "immediate")
	Debug.debug_texts = {}
	Debug.sticky_texts = {}
	Debug.line_objects = {}

	Debug.create_line_object("default")

	Debug.world_sticky_texts = {}
	Debug.world_sticky_index = 0
	Debug.num_world_sticky_texts = 0
end

Debug.create_line_object = function (name)
	local disable_depth_test = false

	Debug.line_objects[name] = World.create_line_object(Debug.world, disable_depth_test)

	return Debug.line_objects[name]
end

Debug.update = function (dt, t)
	if not Debug.active or script_data and script_data.disable_debug_draw then
		return
	end

	local show_debug_text_background = not script_data.hide_debug_text_background
	local res_x, res_y = Application.resolution()
	local gui = Debug.gui
	local pos = res_y - 100
	local text_color = Color(120, 220, 0)

	for i = 1, #Debug.debug_texts do
		local data = Debug.debug_texts[i]
		local text = data.text
		local instance_text_color = data.color
		local text_pos = Vector3(10, pos, 700)

		Gui.text(gui, text, font_mtrl, font_size, font, text_pos, instance_text_color and instance_text_color:unbox() or text_color)

		if show_debug_text_background then
			local text_min, text_max = Gui.text_extents(gui, text, font_mtrl, font_size)

			Gui.rect(gui, text_pos + Vector3(-5, -6, -100), Vector2(text_max.x - text_min.x + 20, font_size + 2), Color(75, 0, 0, 0))
		end

		pos = pos - (font_size + 2)
		Debug.debug_texts[i] = nil
	end

	local sticky_texts = Debug.sticky_texts
	local num_sticky = #sticky_texts

	if num_sticky > 0 then
		local i = 1

		while i <= num_sticky do
			local text, display_time = unpack(sticky_texts[i])

			Gui.text(gui, text, font_mtrl, font_size, font, Vector3(10, pos, 700), text_color)

			pos = pos - (font_size + 2)

			if display_time < t then
				table.remove(sticky_texts, i)

				num_sticky = num_sticky - 1
			else
				i = i + 1
			end
		end
	end

	Debug.update_world_sticky_texts()

	local w = Debug.world

	for lo_name, lo in pairs(Debug.line_objects) do
		LineObject.dispatch(w, lo)
	end
end

Debug.cond_text = function (c, ...)
	if c then
		Debug.text(...)
	end
end

Debug.text = function (...)
	if not Debug.active then
		return
	end

	table.insert(Debug.debug_texts, {
		text = string.format(...)
	})
end

Debug.colored_text = function (color, ...)
	if not Debug.active then
		return
	end

	table.insert(Debug.debug_texts, {
		text = string.format(...),
		color = ColorBox(color)
	})
end

local max_world_sticky = 64
local debug_colors = {
	red = {
		255,
		0,
		0
	},
	green = {
		0,
		200,
		0
	},
	blue = {
		0,
		0,
		200
	},
	white = {
		255,
		255,
		255
	},
	yellow = {
		200,
		200,
		0
	},
	teal = {
		0,
		200,
		200
	},
	purple = {
		200,
		0,
		160
	}
}

Debug.update_world_sticky_texts = function ()
	if not Managers.state.debug_text then
		return
	end

	local world_gui = Managers.state.debug_text._world_gui
	local wt = Debug.world_sticky_texts
	local num_texts = Debug.num_world_sticky_texts
	local tm = Matrix4x4.identity()

	for i = 1, num_texts do
		local item = wt[i]
		local text = item[1]

		Gui.text_3d(world_gui, text, font_mtrl, 0.3, font, tm, Vector3(item[2], item[3], item[4]), 1, Color(item[5], item[6], item[7]))
		QuickDrawer:sphere(Vector3(item[2], item[3], item[4]), 0.03)
	end
end

Debug.world_sticky_text = function (pos, text, color_name)
	if not Debug.active then
		return
	end

	local wt = Debug.world_sticky_texts
	local index = Debug.world_sticky_index

	index = index + 1

	if index > max_world_sticky then
		index = 1
	end

	Debug.num_world_sticky_texts = math.clamp(Debug.num_world_sticky_texts + 1, 0, max_world_sticky)

	local color = debug_colors[color_name] or debug_colors.white

	if wt[index] then
		wt[index][1] = text
		wt[index][2] = pos[1]
		wt[index][3] = pos[3]
		wt[index][4] = pos[2]
		wt[index][5] = color[1]
		wt[index][6] = color[2]
		wt[index][7] = color[3]
	else
		wt[index] = {
			text,
			pos[1],
			pos[3],
			pos[2],
			color[1],
			color[2],
			color[3]
		}
	end

	Debug.world_sticky_index = index
end

Debug.reset_sticky_world_texts = function ()
	Debug.num_world_sticky_texts = 0
	Debug.world_sticky_index = 0
end

Debug.sticky_text = function (...)
	if not Debug.active then
		return
	end

	local t = {
		...
	}
	local delay = 3

	delay = t[#t - 1] == "delay" and t[#t] or delay

	table.insert(Debug.sticky_texts, {
		string.format(...),
		Managers.time:time("game") + delay
	})
end

Debug.drawer = function (name, disabled)
	name = name or "default"

	local lo = Debug.line_objects[name]

	lo = lo or Debug.create_line_object(name)

	return DebugDrawer:new(lo, to_boolean(not disabled))
end

Debug.teardown = function ()
	Debug.active = false

	local w = Debug.world

	for lo_name, lo in pairs(Debug.line_objects) do
		World.destroy_line_object(w, lo)
	end

	table.clear(Debug.line_objects)
	World.destroy_gui(Debug.world, Debug.gui)

	Debug.gui = nil
end
