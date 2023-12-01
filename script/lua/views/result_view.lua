-- chunkname: @script/lua/views/result_view.lua

require("script/lua/simple_gui/simple_gui")

local templates = require("script/lua/simple_gui/gui_templates")
local definitions = require("script/lua/views/result_view_definitions")

class("ResultView")

ResultView.init = function (self, world, input, parent)
	self._world = world
	self._wwise_world = Wwise.wwise_world(world)
	self._scoreboard_scroll_offset_speed = 350
	self._scoreboard_scroll_offset = 0
	self._input = input
	self._parent = parent
	self._enabled = false
	self._animated_offset = 0
	self._scoreboard_index = 1
	self._scoreboard_enabled = false
	self._animations = {}
	self._end_offset = {
		-1.1,
		1.5,
		-0.6
	}
	self._added_peers = {}
	self._current_leaderboard_view = "global"

	self:_initialize_elements()
	self:_create_gui()
	self:_update_level_elements()

	self._score_mode = "local"
end

ResultView._initialize_elements = function (self, skip_elements)
	if not skip_elements then
		local elements = table.clone(definitions.elements)

		for _, element in ipairs(elements) do
			elements[element.name] = element
		end

		self._elements = elements
	end

	local selectable_elements = table.clone(definitions.selectable_elements)
	local reload_template = table.clone(definitions.reload_template)
	local play_template = table.clone(definitions.play_template)
	local hover_template = table.clone(definitions.hover_template)
	local scoreboard_elements = table.clone(definitions.scoreboard_elements)
	local scoreboard_element = table.clone(definitions.scoreboard_element)
	local scoreboard_name = table.clone(definitions.scoreboard_name)
	local scoreboard_kills = table.clone(definitions.scoreboard_kills)
	local scoreboard_headshots = table.clone(definitions.scoreboard_headshots)
	local scoreboard_time = table.clone(definitions.scoreboard_time)
	local scoreboard_score = table.clone(definitions.scoreboard_score)
	local scoreboard_position = table.clone(definitions.scoreboard_position)

	for _, element in ipairs(scoreboard_elements) do
		scoreboard_elements[element.name] = element

		if element.selectable_func and element.selectable_func(element, scoreboard_elements) or element.selectable then
			local selectable_element = table.clone(element)

			selectable_element.disabled = true
			selectable_element.hover = true
			selectable_element.offset[3] = selectable_element.offset[3] + 100
			selectable_elements[#selectable_elements + 1] = selectable_element
		end
	end

	for i = #selectable_elements, 1, -1 do
		local element = selectable_elements[i]

		selectable_elements[element.name] = element

		if not element.skip_hover_effect then
			local hover = table.clone(hover_template)

			hover.name = element.name .. "_hover"
			hover.size = element.size
			hover.offset[3] = hover.offset[3] + 5
			hover.depends_on = element.name
			selectable_elements[#selectable_elements + 1] = hover
			selectable_elements[hover.name] = hover
		end

		if element.reload_icon then
			local reload = table.clone(reload_template)

			reload.name = element.name .. "_reload"

			local size = element.size[1] < element.size[2] and element.size[1] or element.size[2]

			reload.size = {
				size * 0.5,
				size * 0.5
			}
			reload.offset[3] = reload.offset[3] + 1
			reload.depends_on = element.name
			selectable_elements[#selectable_elements + 1] = reload
			selectable_elements[reload.name] = reload
		elseif element.play_icon then
			local play = table.clone(play_template)

			play.name = element.name .. "_play"

			local size = element.size[1] < element.size[2] and element.size[1] or element.size[2]

			play.size = {
				size * 0.5,
				size * 0.5
			}
			play.offset[3] = play.offset[3] + 1
			play.depends_on = element.name
			selectable_elements[#selectable_elements + 1] = play
			selectable_elements[play.name] = play
		end
	end

	self._templates = templates
	self._reload_template = reload_template
	self._play_template = play_template
	self._hover_template = hover_template
	self._selectable_elements = selectable_elements
	self._scoreboard_elements = scoreboard_elements
	self._scoreboard_element = scoreboard_element
	self._scoreboard_name = scoreboard_name
	self._scoreboard_kills = scoreboard_kills
	self._scoreboard_headshots = scoreboard_headshots
	self._scoreboard_time = scoreboard_time
	self._scoreboard_score = scoreboard_score
	self._scoreboard_position = scoreboard_position
end

ResultView.cb_start_rotation = function (self)
	if self._enabled then
		WwiseWorld.trigger_event(self._wwise_world, "Play_hud_scoreboard_whoosh")
	end

	self:_add_animation(self._end_offset, "table", {
		-1.1,
		0.75,
		-0.6
	}, {
		-1.1,
		1,
		-0.25
	}, 1, math.easeOutCubic)

	local rot = self._starting_rotation_scoreboard:unbox()
	local starting_rotation = QuaternionBox(rot)

	self:_add_animation(self._starting_rotation_scoreboard, "Quaternion", starting_rotation, self._starting_rotation, 1, math.easeOutCubic)

	self._scoreboard_enabled = true

	if Managers.leaderboards:enabled() then
		Managers.leaderboards:get_global_leaderboard(self._parent._level_name, 1, 20, callback(self, "cb_leaderboard_fetched", "global"))
	end
end

ResultView.cb_leaderboard_fetched = function (self, leaderboard_type, results)
	self:_package_leaderboard_data(leaderboard_type, results)

	if self._current_leaderboard_view == leaderboard_type then
		for _, entry in pairs(self._leaderboards_data[leaderboard_type]) do
			self:add_element(entry.rank, entry.name, entry.kills, entry.headshots, entry.time_in_seconds, entry.score)
		end
	end
end

ResultView._package_leaderboard_data = function (self, leaderboard_type, results)
	self._leaderboards_data = self._leaderboards_data or {}
	self._leaderboards_data[leaderboard_type] = self._leaderboards_data[leaderboard_type] or {}

	local leaderboard_data = self._leaderboards_data[leaderboard_type]

	for _, score in ipairs(results.scores) do
		leaderboard_data[score.global_rank] = {
			rank = score.global_rank,
			name = score.name,
			kills = score.data[1],
			headshots = score.data[2],
			time_in_seconds = score.data[3],
			score = score.score
		}
	end
end

ResultView.add_element = function (self, position, name, kills, headshots, seconds_played, score)
	local element = table.clone(self._scoreboard_element)

	element.depends_on = element.name .. self._scoreboard_index - 1
	element.name = element.name .. self._scoreboard_index
	element.color = self._scoreboard_index % 2 == 1 and {
		96,
		255,
		168,
		0
	} or {
		60,
		196,
		196,
		196
	}
	self._scoreboard_elements[#self._scoreboard_elements + 1] = element
	self._scoreboard_elements[element.name] = element

	local position_element = table.clone(self._scoreboard_position)

	position_element.depends_on = element.name
	position_element.name = position_element.name .. self._scoreboard_index
	position_element.color = self._scoreboard_index % 2 == 1 and {
		255,
		128,
		128,
		128
	} or {
		196,
		255,
		168,
		0
	}
	position_element.offset[3] = position_element.offset[3] + 1
	position_element.text = position
	self._scoreboard_elements[#self._scoreboard_elements + 1] = position_element
	self._scoreboard_elements[position_element.name] = position_element

	local name_element = table.clone(self._scoreboard_name)

	name_element.depends_on = element.name
	name_element.name = name_element.name .. self._scoreboard_index
	name_element.color = self._scoreboard_index % 2 == 1 and {
		255,
		128,
		128,
		128
	} or {
		196,
		255,
		168,
		0
	}
	name_element.offset[3] = name_element.offset[3] + 1
	name_element.text = name
	self._scoreboard_elements[#self._scoreboard_elements + 1] = name_element
	self._scoreboard_elements[name_element.name] = name_element

	local score_element = table.clone(self._scoreboard_score)

	score_element.depends_on = element.name
	score_element.name = score_element.name .. self._scoreboard_index
	score_element.color = self._scoreboard_index % 2 == 1 and {
		255,
		128,
		128,
		128
	} or {
		196,
		255,
		168,
		0
	}
	score_element.offset[3] = score_element.offset[3] + 1
	score_element.text = score
	self._scoreboard_elements[#self._scoreboard_elements + 1] = score_element
	self._scoreboard_elements[score_element.name] = score_element

	local headshot_element = table.clone(self._scoreboard_headshots)

	headshot_element.depends_on = element.name
	headshot_element.name = headshot_element.name .. self._scoreboard_index
	headshot_element.color = self._scoreboard_index % 2 == 1 and {
		255,
		128,
		128,
		128
	} or {
		196,
		255,
		168,
		0
	}
	headshot_element.offset[3] = headshot_element.offset[3] + 1
	headshot_element.text = headshots
	self._scoreboard_elements[#self._scoreboard_elements + 1] = headshot_element
	self._scoreboard_elements[headshot_element.name] = headshot_element

	local kills_element = table.clone(self._scoreboard_kills)

	kills_element.depends_on = element.name
	kills_element.name = kills_element.name .. self._scoreboard_index
	kills_element.color = self._scoreboard_index % 2 == 1 and {
		255,
		128,
		128,
		128
	} or {
		196,
		255,
		168,
		0
	}
	kills_element.offset[3] = kills_element.offset[3] + 1
	kills_element.text = kills
	self._scoreboard_elements[#self._scoreboard_elements + 1] = kills_element
	self._scoreboard_elements[kills_element.name] = kills_element
	self._scoreboard_index = self._scoreboard_index + 1
end

ResultView.enable = function (self, enable, success)
	self._enabled = enable

	local hmd_pose = Managers.vr:hmd_world_pose()
	local forward = hmd_pose.forward
	local right = Matrix4x4.right(hmd_pose.head)
	local diagonal = Vector3.normalize(-forward + right)

	forward.z = 0
	right.z = 0
	diagonal.z = 0
	self._starting_rotation = QuaternionBox(Quaternion.look(forward, Vector3.up()))
	self._starting_rotation_scoreboard = QuaternionBox(Quaternion.look(diagonal, Vector3.up()))
	self._hmd_pose = Matrix4x4Box(hmd_pose.head)

	local tracking_pose = Managers.vr:tracking_space_pose()

	self._initial_tracking_pos = Vector3Box(Matrix4x4.translation(tracking_pose))
	self._animations = {}

	if self._enabled then
		self:_initialize_elements()
		self:_update_level_elements()
	end

	if self._enabled then
		WwiseWorld.trigger_event(self._wwise_world, "Play_hud_sign_whoosh")
	end

	self._success = success

	if success then
		self._elements.victory_image.material_name = "end_screen_banner_victory_en"

		self:_add_animation(self._elements.victory_image_bg, "color", {
			0,
			0,
			191,
			255
		}, {
			255,
			0,
			191,
			255
		}, 1.25, math.easeOutCubic, callback(self, "cb_start_rotation"))
	else
		self._elements.victory_image.material_name = "end_screen_banner_defeat_en"

		self:_add_animation(self._elements.victory_image_bg, "color", {
			0,
			255,
			0,
			0
		}, {
			255,
			255,
			0,
			0
		}, 1.25, math.easeOutCubic, callback(self, "cb_start_rotation"))
	end

	self:_add_animation(self._elements.victory_image, "size", {
		0,
		0
	}, {
		824,
		320
	}, 0.75, math.easeOutCubic)
	self:_add_animation(self._elements.victory_image_bg, "size", {
		0,
		0
	}, {
		1080,
		560
	}, 0.75, math.easeOutCubic)
	self:_add_animation(self._end_offset, "table", {
		-1.1,
		10.5,
		-0.6
	}, {
		-1.1,
		0.75,
		-0.6
	}, 0.75, math.easeOutCubic)

	if not self._enabled then
		self._animated_offset_dir = -1
		self._animated_offset = 0
	elseif Managers.leaderboards:enabled() then
		local score_tables = Managers.state.score:scores()
	end
end

ResultView._add_animation = function (self, element, field, start_value, end_value, time, func, callback)
	self._animations[#self._animations + 1] = {
		timer = 0,
		element = element,
		field = field,
		start_value = start_value,
		end_value = end_value,
		total_time = time,
		func = func,
		callback = callback
	}
end

ResultView.enabled = function (self)
	return self._enabled
end

ResultView._create_gui = function (self)
	self._world_gui_pos = Vector3Box(Vector3(0, 0, 0))
	self._gui_pose = Matrix4x4Box(Matrix4x4.identity())
	self._size = {
		1000,
		1000
	}
	self._gui = World.create_world_gui(self._world, self._gui_pose:unbox(), self._size[1], self._size[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
	self._gui_pos = Vector3Box(Vector3(0, 0, 0))
	self._gui_pose_scoreboard = Matrix4x4Box(Matrix4x4.identity())
	self._size_scoreboard = {
		1000,
		1000
	}
	self._gui_scoreboard = World.create_world_gui(self._world, self._gui_pose_scoreboard:unbox(), self._size_scoreboard[1], self._size_scoreboard[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
	self._size_animated_scoreboard = {
		1000,
		1000
	}
	self._gui_pose_animated_scoreboard = Matrix4x4Box(Matrix4x4.identity())
	self._gui_animated_scoreboard = World.create_world_gui(self._world, self._gui_pose_animated_scoreboard:unbox(), self._size_animated_scoreboard[1], self._size_animated_scoreboard[2], "material", "gui/single_textures/gui", "material", "gui/fonts/gw_fonts", "immediate")
end

ResultView._update_level_elements = function (self)
	local is_multiplayer = Managers.lobby and #Managers.lobby:lobby_members() > 1 or Managers.lobby and not Managers.lobby.server

	if is_multiplayer then
		local level_images = {
			{
				material_name = "preview_image_inn",
				level_name = "inn"
			},
			{
				material_name = "preview_image_drachenfels",
				level_name = "drachenfels"
			},
			{
				material_name = "preview_image_forest",
				level_name = "forest"
			}
		}

		for idx, data in ipairs(level_images) do
			level_images[data.level_name] = data
			data.idx = idx
		end

		local current_level_name = self._parent._level_name
		local current_level_material = level_images[current_level_name].material_name

		self._scoreboard_elements.current_level.material_name = current_level_material
		self._scoreboard_elements.current_level.level_name = current_level_name
		self._scoreboard_elements.current_level.material_name = current_level_material
		self._scoreboard_elements.current_level.level_name = current_level_name

		if self._selectable_elements.current_level then
			self._selectable_elements.current_level.material_name = current_level_material
			self._selectable_elements.current_level.level_name = current_level_name
		end

		for idx, level_data in ipairs(level_images) do
			self._scoreboard_elements["level_" .. idx].material_name = level_data.material_name
			self._scoreboard_elements["level_" .. idx].level_name = level_data.level_name

			if self._selectable_elements["level_" .. idx] then
				self._selectable_elements["level_" .. idx].material_name = level_data.material_name
				self._selectable_elements["level_" .. idx].level_name = level_data.level_name
			end
		end
	else
		local level_images = {
			{
				material_name = "preview_image_inn",
				level_name = "inn"
			},
			{
				material_name = "preview_image_drachenfels",
				level_name = "drachenfels"
			},
			{
				material_name = "preview_image_forest",
				level_name = "forest"
			},
			{
				material_name = "preview_image_cart",
				level_name = "cart"
			}
		}

		for idx, data in ipairs(level_images) do
			level_images[data.level_name] = data
			data.idx = idx
		end

		local current_level_name = self._parent._level_name
		local current_level_material = level_images[current_level_name].material_name

		self._scoreboard_elements.current_level.material_name = current_level_material
		self._scoreboard_elements.current_level.level_name = current_level_name

		if self._selectable_elements.current_level then
			self._selectable_elements.current_level.material_name = current_level_material
			self._selectable_elements.current_level.level_name = current_level_name
		end

		local idx = level_images[current_level_name].idx

		table.remove(level_images, idx)

		for idx, level_data in ipairs(level_images) do
			self._scoreboard_elements["level_" .. idx].material_name = level_data.material_name
			self._scoreboard_elements["level_" .. idx].level_name = level_data.level_name

			if self._selectable_elements["level_" .. idx] then
				self._selectable_elements["level_" .. idx].material_name = level_data.material_name
				self._selectable_elements["level_" .. idx].level_name = level_data.level_name
			end
		end
	end

	self._dirty = true
	DO_RELOAD = false
end

ResultView.reinitialize_scoreboard = function (self, leaderboard_type)
	self:_initialize_elements(true)
	self:_update_level_elements()

	self._scoreboard_index = 1
	self._scoreboard_scroll_offset_speed = 350
	self._scoreboard_scroll_offset = 0
	self._current_leaderboard_view = leaderboard_type

	Managers.leaderboards:set_current_leaderboard(leaderboard_type)

	if leaderboard_type == "global" then
		Managers.leaderboards:get_global_leaderboard(self._parent._level_name, 1, 20, callback(self, "cb_leaderboard_fetched", leaderboard_type))
	elseif leaderboard_type == "friends" then
		Managers.leaderboards:get_friend_leaderboard(self._parent._level_name, callback(self, "cb_leaderboard_fetched", leaderboard_type))
	elseif leaderboard_type == "local" then
		Managers.leaderboards:get_around_player_leaderboard(self._parent._level_name, callback(self, "cb_leaderboard_fetched", leaderboard_type))
	end
end

DO_RELOAD = true

ResultView.update = function (self, dt, t)
	if DO_RELOAD then
		self._scoreboard_index = 1
		self._scoreboard_scroll_offset_speed = 350
		self._scoreboard_scroll_offset = 0
		self._current_leaderboard_view = "global"
		self._current_selection_name = nil

		self:_initialize_elements(true)
		self:_update_level_elements()

		self._added_peers = {}

		if not Managers.lobby or Managers.lobby and not Managers.lobby:using_steam() then
			for i = 1, 20 do
				self:add_element(i, "Tazar", math.random(1, 255), math.random(1, 255), math.random(1, 255), math.random(1, 255))
			end
		elseif Managers.leaderboards:enabled() then
			Managers.leaderboards:get_global_leaderboard(self._parent._level_name, 1, 20, callback(self, "cb_leaderboard_fetched", "global"))
		end

		DO_RELOAD = false
	end

	Profiler.start("ResultView")

	if Managers.popup:has_popup() then
		return
	end

	if not self._enabled then
		return
	end

	self:_update_animations(dt, t)
	self:_update_position_on_gui(dt, t)
	self:_update_gui_position(dt, t)
	self:_update_selectable_animations(dt, t)
	self:_update_ui(dt, t)
	self:_update_input(dt, t)
	self:_update_scroller(dt, t)
	self:_update_scores(dt, t)
	Profiler.stop("ResultView")
end

ResultView._update_scores = function (self, dt, t)
	if Managers.lobby and Managers.lobby:using_steam() then
		return
	end

	local score_tables = Managers.state.score:scores()

	if self._score_mode == "local" then
		for peer_id, score_table in pairs(score_tables) do
			if not self._added_peers[peer_id] then
				local player_name = self:_player_name(peer_id)

				self:add_element(self._scoreboard_index, player_name, score_table.kills or 0, score_table.headshots or 0, score_table.score or (score_table.kills or 0) + (score_table.headshots or 0), score_table.time or 0)

				self._added_peers[peer_id] = true
			end
		end
	end
end

ResultView._player_name = function (self, peer_id)
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

ResultView._update_scroller = function (self, dt, t)
	self._scoreboard_elements.scoreboard_element_0.offset[2] = self._scoreboard_scroll_offset
	self._scoreboard_elements.scroller.offset[2] = -55 + self._scoreboard_scroll_offset / (math.max(self._scoreboard_index - 11, 0) * 50) * self._scoreboard_elements.scroller.scroll_distance
	self._selectable_elements.scroller.offset[2] = self._scoreboard_elements.scroller.offset[2]
end

ResultView._update_input = function (self, dt, t)
	if not self._scoreboard_enabled then
		return
	end

	if self._input_held then
		if self._input:get("held", "trigger", "any", true) then
			local element = self._selectable_elements[self._current_selection_name]

			element.on_activate_held(element, self, dt)

			return
		else
			self._input_held = false
		end
	end

	local gui_pos = self._gui_pos:unbox()

	for index, element in ipairs(self._selectable_elements) do
		if element.hover and not element.root then
			local pos = element.pos:unbox()
			local size = element.size:unbox()
			local end_pos = {
				pos.x + size.x,
				pos.y + size.y
			}

			if gui_pos.x >= pos.x and gui_pos.x <= pos.x + size.x and gui_pos.z >= pos.y and gui_pos.z <= pos.y + size.y then
				self._animated_offset_dir = 1

				if self._current_selection_name and self._current_selection_name ~= element.name then
					self._scoreboard_elements[self._current_selection_name].disabled = false
					self._selectable_elements[self._current_selection_name].disabled = true
					self._animated_offset = 0
					self._current_selection_name = nil
				end

				if not self._current_selection_name then
					local source_id = WwiseUtils.make_position_auto_source(self._world, self._world_gui_pos:unbox())

					WwiseWorld.trigger_event(self._wwise_world, "menu_hover_mono", source_id)
				end

				self._current_selection_name = element.name
				self._scoreboard_elements[self._current_selection_name].disabled = true
				self._selectable_elements[self._current_selection_name].disabled = false

				if element.on_activate_held and self._input:get("held", "trigger", "any", true) then
					element.on_activate_held(element, self, dt)

					self._input_held = true
				end

				if element.on_activate and self._input:get("pressed", "trigger", "any", true) then
					element.on_activate(element, self, dt)
				end

				return
			end
		end
	end

	self._animated_offset_dir = -1
end

ResultView._update_selectable_animations = function (self, dt, t)
	local offset = self._current_selection_name and self._selectable_elements[self._current_selection_name].animated_offset or 0.1

	self._animated_offset_dir = self._animated_offset_dir or -1
	self._animated_offset = math.clamp(self._animated_offset + self._animated_offset_dir * dt, 0, offset)

	if self._current_selection_name and self._animated_offset == 0 then
		self._scoreboard_elements[self._current_selection_name].disabled = false
		self._selectable_elements[self._current_selection_name].disabled = true
		self._current_selection_name = nil
	elseif self._animated_offset > 0 and offset > self._animated_offset then
		self._dirty = true
	end
end

local ANIMATIONS_TO_REMOVE = ANIMATIONS_TO_REMOVE or {}

ResultView._update_animations = function (self, dt, t)
	for idx, animation in ipairs(self._animations) do
		local element = animation.element
		local time_progress = animation.timer / animation.total_time
		local progress = animation.func(time_progress)
		local type = type(element[animation.field])

		if type == "number" then
			element[animation.field] = math.lerp(animation.start_value, animation.end_value, progress)
		elseif type == "table" then
			for key, _ in pairs(element[animation.field]) do
				element[animation.field][key] = math.lerp(animation.start_value[key], animation.end_value[key], progress)
			end
		elseif animation.field == "table" then
			for key, _ in pairs(element) do
				element[key] = math.lerp(animation.start_value[key], animation.end_value[key], progress)
			end
		elseif animation.field == "size" then
			element.size[1] = math.lerp(animation.start_value[1], animation.end_value[1], progress)
			element.size[2] = math.lerp(animation.start_value[2], animation.end_value[2], progress)
		elseif animation.field == "offset" then
			element.size[1] = math.lerp(animation.start_value[1], animation.end_value[1], progress)
			element.size[2] = math.lerp(animation.start_value[2], animation.end_value[2], progress)
			element.size[3] = math.lerp(animation.start_value[3], animation.end_value[3], progress)
		elseif animation.field == "Quaternion" then
			element:store(Quaternion.lerp(animation.start_value:unbox(), animation.end_value:unbox(), progress))
		end

		if time_progress >= 1 then
			ANIMATIONS_TO_REMOVE[#ANIMATIONS_TO_REMOVE + 1] = idx

			if animation.callback then
				animation.callback(element)
			end
		end

		animation.timer = animation.timer + dt
	end

	for i = #ANIMATIONS_TO_REMOVE, 1, -1 do
		table.remove(self._animations, ANIMATIONS_TO_REMOVE[1])
	end

	table.clear(ANIMATIONS_TO_REMOVE)
end

ResultView._update_position_on_gui = function (self, dt, t)
	local pos, dir
	local gui_pose = self._gui_pose_scoreboard:unbox()
	local gui_pos = Matrix4x4.translation(gui_pose)
	local gui_normal = Matrix4x4.forward(gui_pose)
	local plane = Plane.from_point_and_normal(gui_pos, gui_normal)

	if Managers.vr:hmd_active() then
		local wand = self._input:get_wand("right")
		local wand_unit = wand:wand_unit()
		local hand_pose = Unit.world_pose(wand_unit, Unit.node(wand_unit, "j_pointer"))

		pos = Matrix4x4.translation(hand_pose)
		dir = Matrix4x4.forward(hand_pose)
	else
		local hmd_pose = Managers.vr:hmd_world_pose()

		pos = Matrix4x4.translation(hmd_pose.head)
		dir = hmd_pose.forward
	end

	local distance_along_ray, is_ray_start_in_front_of_plane = Intersect.ray_plane(pos, dir, plane)

	if distance_along_ray then
		self._old_gui_pos = Vector3Box(self._gui_pos:unbox())

		local world_pos = pos + dir * distance_along_ray
		local pose = Matrix4x4.inverse(gui_pose)
		local local_pos = Matrix4x4.transform(pose, world_pos)

		gui_pos.x = local_pos.x / (1 / self._size[1])
		gui_pos.z = local_pos.z / (1 / self._size[2])

		local element = self._scoreboard_elements.test

		element.offset[1] = gui_pos.x - element.size[1] * 0.5
		element.offset[2] = gui_pos.z - element.size[2] * 0.5
		self._gui_pos = Vector3Box(gui_pos)
		self._world_gui_pos = Vector3Box(world_pos)
	end
end

ResultView._update_gui_position = function (self, dt, t)
	local hmd_pose = self._hmd_pose:unbox()

	if Matrix4x4.is_valid(hmd_pose) then
		local tracking_pose = Managers.vr:tracking_space_pose()
		local tracking_pos = Matrix4x4.translation(tracking_pose)
		local tracking_pos_diff = tracking_pos - self._initial_tracking_pos:unbox()
		local gui_pose = Matrix4x4.identity()
		local rot = self._starting_rotation and self._starting_rotation:unbox() or Quaternion.identity()

		Matrix4x4.set_rotation(gui_pose, rot)

		local offset = Quaternion.rotate(rot, Vector3(unpack(self._end_offset)))

		Matrix4x4.set_translation(gui_pose, Matrix4x4.translation(hmd_pose) + offset + tracking_pos_diff)
		Gui.move(self._gui, gui_pose)

		self._gui_pose = Matrix4x4Box(gui_pose)

		local scoreboard_gui_pose = Matrix4x4.identity()
		local rot = self._starting_rotation_scoreboard and self._starting_rotation_scoreboard:unbox() or Quaternion.identity()

		Matrix4x4.set_rotation(scoreboard_gui_pose, rot)

		local offset = Quaternion.rotate(rot, Vector3(-1.1, 1.1, -0.6))

		Matrix4x4.set_translation(scoreboard_gui_pose, Matrix4x4.translation(hmd_pose) + offset + tracking_pos_diff)
		Gui.move(self._gui_scoreboard, scoreboard_gui_pose)

		self._gui_pose_scoreboard = Matrix4x4Box(scoreboard_gui_pose)

		local animated_scoreboard_gui_pose = Matrix4x4.identity()

		Matrix4x4.set_rotation(animated_scoreboard_gui_pose, rot)

		local offset = Quaternion.rotate(rot, Vector3(-1.1, 1.1 - self._animated_offset, -0.6))

		Matrix4x4.set_translation(animated_scoreboard_gui_pose, Matrix4x4.translation(hmd_pose) + offset + tracking_pos_diff)
		Gui.move(self._gui_animated_scoreboard, animated_scoreboard_gui_pose)

		self._gui_pose_animated_scoreboard = Matrix4x4Box(animated_scoreboard_gui_pose)
	end
end

ResultView._update_ui = function (self, dt, t)
	for _, element in ipairs(self._elements) do
		SimpleGui.update_element(self._gui, element, self._elements, self._templates)
	end

	for _, element in ipairs(self._elements) do
		SimpleGui.render_element(self._gui, element)
	end

	if self._scoreboard_enabled then
		for _, element in ipairs(self._scoreboard_elements) do
			SimpleGui.update_element(self._gui_scoreboard, element, self._scoreboard_elements, self._templates)
		end

		for _, element in ipairs(self._selectable_elements) do
			SimpleGui.update_element(self._gui_animated_scoreboard, element, self._selectable_elements, self._templates)
		end

		for _, element in ipairs(self._scoreboard_elements) do
			SimpleGui.render_element(self._gui_scoreboard, element)
		end

		for _, element in ipairs(self._selectable_elements) do
			SimpleGui.render_element(self._gui_animated_scoreboard, element)
		end
	end
end

ResultView.destroy = function (self)
	World.destroy_gui(self._world, self._gui)

	self._gui = nil
end
