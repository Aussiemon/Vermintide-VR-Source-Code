-- chunkname: @script/lua/views/gameplay_view.lua

require("script/lua/simple_gui/simple_gui")

local templates = require("script/lua/simple_gui/gui_templates")

class("GameplayView")

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
		}
	},
	{
		text = "VERMINTIDE VR",
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
		text = "INGAME MENU",
		template_type = "sub_header",
		name = "sub_header",
		depends_on = "header",
		offset = {
			-0,
			-90,
			0
		}
	},
	{
		text = "WAITING ON HOST...",
		template_type = "text",
		name = "server_text",
		depends_on = "header",
		disabled = true,
		offset = {
			90,
			-90,
			0
		}
	},
	{
		text = "Resume Level",
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
		text = "Restart Level",
		template_type = "selection",
		name = "option_two",
		depends_on = "selection",
		offset = {
			0,
			-100,
			0
		},
		active_func = function (element)
			if Managers.lobby then
				return Managers.lobby.server
			else
				return true
			end
		end
	},
	{
		text = "CPU Effects Quality",
		template_type = "stepper",
		name = "option_three",
		depends_on = "option_two",
		offset = {
			0,
			-100,
			0
		},
		options = Managers.differentiation:mode_name_list(),
		option_index = table.find(Managers.differentiation:mode_name_list(), Managers.differentiation:current_mode().title),
		handle_input = function (element, input)
			if input:get("pressed", "touch_left", "any") then
				element.option_index = math.max(element.option_index - 1, 1)

				return true
			elseif input:get("pressed", "touch_right", "any") then
				element.option_index = math.min(element.option_index + 1, #element.options)

				return true
			end
		end
	},
	{
		text = "Quit to Main Menu",
		template_type = "selection",
		name = "option_four",
		depends_on = "option_three",
		offset = {
			0,
			-100,
			0
		}
	},
	{
		text = "Complete Level",
		template_type = "selection",
		name = "option_five",
		depends_on = "option_four",
		offset = {
			0,
			-100,
			0
		},
		active_func = function (element)
			if Managers.lobby then
				return Managers.lobby.server
			else
				return true
			end
		end
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

local menu_options = menu_options or {
	function (self, element)
		local end_conditions_met = Managers.state.game_mode:end_conditions_met()

		if end_conditions_met then
			self._ready_for_next_level = true

			local sequence = LevelSettings.level_sequence
			local current_index = table.find(sequence, self._level_name)
			local next_index = (current_index or 0) % #sequence + 1
			local next_level = sequence[next_index]

			self._parent._end_conditions_met = next_level
		else
			self:enable(false)
		end
	end,
	function (self, element)
		Managers.state.event:trigger("change_level", self._level_name, true)
	end,
	function (self, element)
		Managers.differentiation:_set_mode(element.option_index)
	end,
	function (self, element)
		self._parent._exit_to_main_menu = true
	end,
	function (self, element)
		Managers.state.game_mode:set_end_conditions_met("defeat")
	end
}

GameplayView.init = function (self, world, input, parent)
	self._world = world
	self._input = input
	self._parent = parent
	self._enabled = false
	self._dirty = true
	self._level_name = parent._level_name
	self._ready_for_next_level = false

	self:_create_gui()

	self._selection_index = 1
	self._selections = {
		"option_one",
		"option_two",
		"option_three",
		"option_four",
		"option_five"
	}
end

GameplayView.enable = function (self, set)
	self._enabled = set

	self:_update_menu_options()
end

GameplayView.active = function (self)
	return self._enabled
end

GameplayView.ready_for_next_level = function (self)
	return self._ready_for_next_level
end

GameplayView.activate_menu_option = function (self, index, element)
	menu_options[index](self, element)
end

GameplayView._create_gui = function (self)
	self._size = {
		1000,
		1000
	}
	self._gui = World.create_world_gui(self._world, Matrix4x4.identity(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")

	print("GameplayView -> World.create_world_gui")
end

GameplayView.update = function (self, dt, t)
	self:_update_input(dt, t)

	self._dirty = true

	if self._enabled then
		self:_update_ui(dt, t)
	end
end

GameplayView._update_menu_options = function (self)
	local end_conditions_met = Managers.state.game_mode:end_conditions_met()
	local network_client = Managers.lobby and not Managers.lobby.server

	if end_conditions_met then
		elements.option_one.text = "Next Level"
		elements.option_one.active = not network_client
	else
		elements.option_one.text = "Resume Level"
		elements.option_one.active = true
	end

	if script_data.debug_show_complete_level and not end_conditions_met then
		elements.option_five.disabled = false

		if network_client then
			self._selections = {
				"option_three",
				"option_four",
				"option_five"
			}
		else
			self._selections = {
				"option_one",
				"option_two",
				"option_three",
				"option_four",
				"option_five"
			}
		end
	else
		elements.option_five.disabled = true

		if network_client then
			self._selections = {
				"option_three",
				"option_four"
			}
		else
			self._selections = {
				"option_one",
				"option_two",
				"option_three",
				"option_four"
			}
		end
	end

	self._selection_index = 1
	self._dirty = true
end

GameplayView._update_input = function (self, dt, t)
	if self._enabled then
		if self._input:get("pressed", "touch_up", "any") and self._selection_index > 1 then
			self._selection_index = self._selection_index - 1
			self._dirty = true
		elseif self._input:get("pressed", "touch_down", "any") and self._selection_index < #self._selections then
			self._selection_index = self._selection_index + 1
			self._dirty = true
		end

		local current_element_name = self._selections[self._selection_index]
		local current_element = elements[current_element_name]

		if current_element.handle_input then
			self._dirty = current_element.handle_input(current_element, self._input) or self._dirty
		end

		if self._input:get("pressed", "trigger", "any") and current_element.active then
			self:activate_menu_option(self._selection_index, current_element)

			self._enabled = false
			self._selection_index = 1
			self._dirty = true
		end
	end

	if self._dirty then
		elements.option_indicator.depends_on = self._selections[self._selection_index]
	end
end

GameplayView._update_ui = function (self, dt, t)
	local end_conditions_met = Managers.state.game_mode:end_conditions_met()
	local network_client = Managers.lobby and not Managers.lobby.server

	if end_conditions_met and network_client then
		self:_update_server_text(dt, t)
	end

	if self._dirty then
		for _, element in ipairs(elements) do
			SimpleGui.update_element(self._gui, element, elements, templates)
		end

		self._dirty = false
	end

	self:_update_position(dt, t)

	for _, element in ipairs(elements) do
		SimpleGui.render_element(self._gui, element)
	end
end

GameplayView._update_position = function (self, dt, t)
	local hmd_pose = Managers.vr:hmd_world_pose()

	if Matrix4x4.is_valid(hmd_pose.head) then
		local pose = hmd_pose.head
		local right = Matrix4x4.right(pose)
		local up = Matrix4x4.up(pose)

		Matrix4x4.set_translation(pose, Matrix4x4.translation(pose) + hmd_pose.forward * 2 + right * -0.5 + up * -0.5)

		if Matrix4x4.is_valid(pose) then
			Gui.move(self._gui, pose)
		end
	end
end

GameplayView._update_server_text = function (self, dt, t)
	local dots = t * 1.5 % 4
	local server_text = "WAITING ON HOST"

	for i = 1, dots do
		server_text = server_text .. "."
	end

	if elements.server_text.disabled then
		elements.server_text.disabled = false
		elements.sub_header.disabled = true
	end

	if elements.server_text.text ~= server_text then
		elements.server_text.text = server_text
		self._dirty = true
	end
end

GameplayView.destroy = function (self)
	print("GameplayView -> World.destroy_gui")
	World.destroy_gui(self._world, self._gui)

	self._gui = nil
end
