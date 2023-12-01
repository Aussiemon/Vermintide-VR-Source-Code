-- chunkname: @script/lua/views/scoreboard_view.lua

require("script/lua/simple_gui/simple_gui")

local templates = require("script/lua/simple_gui/gui_templates")

class("ScoreboardView")

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
		text = "SCOREBOARD",
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
		text = "Name",
		template_type = "small_header",
		name = "name_header",
		depends_on = "background",
		offset = {
			100,
			650,
			0
		},
		area_size = {
			200,
			50
		}
	},
	{
		text = "Kills",
		template_type = "small_header",
		name = "kills_header",
		depends_on = "background",
		offset = {
			420,
			650,
			0
		},
		area_size = {
			200,
			50
		}
	},
	{
		text = "Headshots",
		template_type = "small_header",
		name = "headshots_header",
		depends_on = "background",
		offset = {
			600,
			650,
			0
		},
		area_size = {
			200,
			50
		}
	},
	{
		text = "Score",
		template_type = "small_header",
		name = "score_header",
		depends_on = "background",
		offset = {
			860,
			650,
			0
		},
		area_size = {
			200,
			50
		}
	},
	{
		template_type = "bitmap",
		name = "ready_player_1",
		depends_on = "name_header",
		disabled = true,
		material_name = "vote_marker",
		size = {
			60,
			60
		},
		offset = {
			-100,
			-100,
			0
		}
	},
	{
		text = "Player 1",
		template_type = "text",
		name = "name_player_1",
		depends_on = "name_header",
		offset = {
			0,
			-100,
			0
		}
	},
	{
		text = "0",
		template_type = "centered_text",
		name = "kills_player_1",
		depends_on = "kills_header",
		offset = {
			0,
			-100,
			0
		}
	},
	{
		text = "0",
		template_type = "centered_text",
		name = "headshots_player_1",
		depends_on = "headshots_header",
		offset = {
			0,
			-100,
			0
		}
	},
	{
		text = "0",
		template_type = "centered_text",
		name = "score_player_1",
		depends_on = "score_header",
		offset = {
			0,
			-100,
			0
		}
	},
	{
		template_type = "bitmap",
		name = "ready_player_2",
		depends_on = "name_header",
		disabled = true,
		material_name = "vote_marker",
		size = {
			60,
			60
		},
		offset = {
			-100,
			-200,
			0
		}
	},
	{
		text = "Player 2",
		template_type = "text",
		name = "name_player_2",
		depends_on = "name_header",
		offset = {
			10,
			-200,
			0
		}
	},
	{
		text = "0",
		template_type = "centered_text",
		name = "kills_player_2",
		depends_on = "kills_header",
		offset = {
			0,
			-200,
			0
		}
	},
	{
		text = "0",
		template_type = "centered_text",
		name = "headshots_player_2",
		depends_on = "headshots_header",
		offset = {
			0,
			-200,
			0
		}
	},
	{
		text = "0",
		template_type = "centered_text",
		name = "score_player_2",
		depends_on = "score_header",
		offset = {
			0,
			-200,
			0
		}
	},
	{
		text = "Close",
		template_type = "centered_selection",
		name = "option_one",
		depends_on = "selection",
		offset = {
			0,
			-250,
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
	function (self)
		self._enabled = not self._enabled
		self._selection_index = 1
		self._dirty = true
	end
}

local function debug_printf(...)
	if script_data.debug_scoring then
		printf(...)
	end
end

ScoreboardView.init = function (self, world, input, parent)
	self._world = world
	self._input = input
	self._parent = parent

	self:_create_gui()

	self._dirty = true
	self._selection_index = 1
	self._enabled = false
	self._selections = {
		"option_one"
	}

	local network = Managers.lobby

	if network then
		self._network_mode = network.server and "server" or "client"

		Managers.state.network:register_rpc_callbacks(self, "rpc_scoreboard_ready")
	else
		self._network_mode = "local"
	end
end

local TIME_UNTIL_NEXT_SELECTION = 10

ScoreboardView.enable = function (self, set, result)
	self._enabled = set
	self._selection_index = 1
	self._dirty = true

	if set then
		local key = Managers.vr:hmd_active() and "trigger" or "grip"

		if self._input:get("pressed", key, "any") then
			self._wait_for_key_pressed_release = true
		end
	end

	if result then
		result = result == "defeat" and "DEFEAT!" or "VICTORY!"
		elements.header.text = result
	else
		elements.header.text = "SCOREBOARD"
	end

	local end_conditions_met = Managers.state.game_mode:end_conditions_met()

	if end_conditions_met then
		elements.option_one.text = "Next"

		local network = Managers.lobby

		if network then
			local lobby_members = network:lobby_members()
			local num_lobby_members = #lobby_members

			if num_lobby_members > 1 then
				self._next_selection_timer = TIME_UNTIL_NEXT_SELECTION
				self._network_ready_list = {}

				for i, peer_id in ipairs(lobby_members) do
					self._network_ready_list[peer_id] = false
				end

				self:_unready_players()
			end
		end
	end
end

ScoreboardView._unready_players = function (self)
	elements.ready_player_1.disabled = true
	elements.ready_player_2.disabled = true
end

ScoreboardView.active = function (self)
	return self._enabled
end

ScoreboardView._activate_menu_option = function (self, index)
	menu_functions[index](self)
end

ScoreboardView._create_gui = function (self)
	self._size = {
		1000,
		1000
	}
	self._gui = World.create_world_gui(self._world, Matrix4x4.identity(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")

	print("ScoreboardView -> World.create_world_gui")
end

ScoreboardView.update = function (self, dt, t)
	self:_update_position(dt, t)
	self:_update_input(dt, t)
	self:_update_scores(dt, t)
	self:_update_ui(dt, t)
end

ScoreboardView._update_position = function (self, dt, t)
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

ScoreboardView._update_input = function (self, dt, t)
	if self._input:get("pressed", "system", "any") then
		local toggle_enable = self._enabled

		self:enable(toggle_enable)
	end

	if not self._enabled then
		return
	end

	if self._input:get("pressed", "touch_up", "any") and self._selection_index > 1 then
		self._selection_index = self._selection_index - 1
		self._dirty = true
	elseif self._input:get("pressed", "touch_down", "any") and self._selection_index < #self._selections then
		self._selection_index = self._selection_index + 1
		self._dirty = true
	end

	if self._wait_for_key_pressed_release then
		if self._input:get("released", "trigger", "any") then
			self._wait_for_key_pressed_release = false
		end
	elseif self._input:get("pressed", "trigger", "any") then
		if self._network_ready_list then
			local peer_id = Network.peer_id()

			self._network_ready_list[peer_id] = true

			self:_send_scoreboard_ready_to_lobby_members()
		else
			self:_activate_menu_option(self._selection_index)

			self._dirty = true
		end
	end

	local network_ready_list = self._network_ready_list

	if network_ready_list then
		local all_ready = true

		for peer_id, ready in pairs(network_ready_list) do
			if not ready then
				all_ready = false
			end
		end

		if all_ready and not self._close_menu_at then
			self._close_menu_at = t + 1
		end

		local timer_ready = self._next_selection_timer and self._next_selection_timer <= 0
		local close_menu_now = self._close_menu_at and t > self._close_menu_at

		if close_menu_now or timer_ready then
			self:_activate_menu_option(self._selection_index)

			self._next_selection_timer = nil
			self._dirty = true
		end
	end

	if self._dirty then
		elements.option_indicator.depends_on = self._selections[self._selection_index]
	end
end

ScoreboardView._update_scores = function (self, dt, t)
	if not self._enabled then
		return
	end

	elements.ready_player_2.disabled = true
	elements.name_player_2.disabled = true
	elements.kills_player_2.disabled = true
	elements.headshots_player_2.disabled = true
	elements.score_player_2.disabled = true

	local score_tables = Managers.state.score:scores()

	for peer_id, score in pairs(score_tables) do
		local player_index = self:_player_index(peer_id)
		local name = self:_player_name(peer_id)
		local kills = score.kills
		local headshots = score.headshots
		local score = kills + headshots
		local name_element = "name_player_" .. player_index
		local kills_element = "kills_player_" .. player_index
		local headshots_element = "headshots_player_" .. player_index
		local score_element = "score_player_" .. player_index

		elements[name_element].text = name
		elements[name_element].disabled = false
		elements[kills_element].text = kills
		elements[kills_element].disabled = false
		elements[headshots_element].text = headshots
		elements[headshots_element].disabled = false
		elements[score_element].text = score
		elements[score_element].disabled = false

		local network_ready_list = self._network_ready_list
		local is_ready = network_ready_list and network_ready_list[peer_id]

		if is_ready then
			local ready_element = "ready_player_" .. player_index

			elements[ready_element].disabled = false
		end
	end

	self._dirty = true
end

ScoreboardView._player_name = function (self, peer_id)
	if rawget(_G, "Steam") then
		return Steam.user_name(peer_id)
	elseif self._network_mode == "server" then
		return peer_id == Network.peer_id() and "Player 1" or "Player 2"
	elseif self._network_mode == "client" then
		return peer_id == Network.peer_id() and "Player 2" or "Player 1"
	else
		return "Player 1"
	end
end

ScoreboardView._player_index = function (self, peer_id)
	if self._network_mode == "local" then
		return 1
	else
		return peer_id == Network.peer_id() and 1 or 2
	end
end

ScoreboardView._update_ui = function (self, dt, t)
	if not self._enabled then
		return
	end

	if self._next_selection_timer then
		self:_update_next_selection_timer(dt)
	end

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

ScoreboardView._update_next_selection_timer = function (self, dt)
	local next_selection_timer = self._next_selection_timer - dt
	local element = elements.option_one
	local text

	if next_selection_timer >= 0 then
		local time_left = math.round_with_precision(next_selection_timer, 0)

		text = "Next (" .. time_left .. ")"
	else
		text = "Next"
	end

	if text ~= element.text then
		element.text = text
		self._dirty = true
	end

	self._next_selection_timer = next_selection_timer
end

ScoreboardView.destroy = function (self)
	print("ScoreboardView -> World.destroy_gui")
	World.destroy_gui(self._world, self._gui)

	self._gui = nil
end

ScoreboardView._send_scoreboard_ready_to_lobby_members = function (self)
	if self._scoreboard_ready_sent then
		return
	end

	local is_server = Managers.lobby.server

	if is_server then
		Managers.state.network:send_rpc_session_clients("rpc_scoreboard_ready")
		debug_printf("[server sent] rpc_scoreboard_ready")
	else
		Managers.state.network:send_rpc_session_host("rpc_scoreboard_ready")
		debug_printf("[client sent] rpc_scoreboard_ready")
	end

	self._scoreboard_ready_sent = true
end

ScoreboardView.rpc_scoreboard_ready = function (self, sender)
	self._network_ready_list[sender] = true

	local network_mode = Managers.lobby.server and "server" or "client"

	debug_printf("[%s recieved] rpc_scoreboard_ready", network_mode)
end
