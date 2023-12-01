-- chunkname: @script/lua/views/new_gameplay_view_definitions.lua

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
		name = "current_level",
		hover = true,
		depends_on = "background",
		horizontal_alignment = "center",
		vertical_alignment = "top",
		template_type = "bitmap",
		disabled = true,
		material_name = "preview_image_inn",
		material_func = function (element)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			566,
			316
		},
		offset = {
			0,
			-75,
			100
		},
		on_activate = function (element, this)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone then
				return
			end

			local level_name = element.level_name

			Managers.state.event:trigger("change_level", level_name, true)

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
		end,
		disabled_func = function (element, elements)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone then
				return true
			end

			return element.disabled
		end
	},
	{
		template_type = "bitmap",
		name = "current_level_hover",
		hover = false,
		depends_on = "current_level",
		material_name = "preview_image_selection",
		size = {
			572,
			322
		},
		offset = {
			0,
			0,
			-1
		},
		disabled_func = function (element, elements)
			if Managers.lobby and not Managers.lobby.server then
				return true
			end

			return elements[element.depends_on].disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "current_level_reload",
		hover = false,
		depends_on = "current_level",
		vertical_alignment = "center",
		template_type = "bitmap",
		material_name = "reload",
		size = {
			125,
			128
		},
		color = {
			196,
			255,
			255,
			255
		},
		offset = {
			0,
			0,
			1
		},
		disabled_func = function (element, elements)
			if Managers.lobby and not Managers.lobby.server then
				return true
			end

			return elements[element.depends_on].disabled
		end
	},
	{
		horizontal_alignment = "right",
		name = "multiplayer_level",
		hover = true,
		depends_on = "background",
		vertical_alignment = "top",
		template_type = "bitmap",
		disabled = true,
		material_name = "preview_image_multiplayer",
		size = {
			566,
			316
		},
		offset = {
			-150,
			-75,
			100
		},
		on_activate = function (element, this)
			if not Managers.lobby or Game.startup_commands.standalone then
				return
			elseif not Managers.lobby.server or #Managers.lobby:lobby_members() > 1 then
				Managers.state.event:trigger("disconnect")
			else
				Managers.lobby:enable_matchmaking(not Managers.lobby:is_matchmaking())
			end

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
		end,
		disabled_func = function (element)
			if not Managers.lobby or Game.startup_commands.standalone then
				return true
			else
				return element.disabled
			end
		end
	},
	{
		template_type = "bitmap",
		name = "multiplayer_level_hover",
		hover = false,
		depends_on = "multiplayer_level",
		material_name = "preview_image_selection",
		size = {
			572,
			322
		},
		offset = {
			0,
			0,
			-1
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		name = "multiplayer_level_icon",
		hover = false,
		depends_on = "multiplayer_level",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		template_type = "bitmap",
		material_func = function (element)
			if Managers.lobby and Managers.lobby:is_matchmaking() or Managers.lobby and not Managers.lobby.server then
				return "disconnect"
			elseif #Managers.lobby:lobby_members() > 1 then
				return "disconnect"
			else
				return "multiplayer_icon"
			end
		end,
		size = {
			125,
			128
		},
		color = {
			196,
			255,
			255,
			255
		},
		offset = {
			0,
			40,
			1
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		name = "multiplayer_text_disable",
		vertical_alignment = "bottom",
		depends_on = "multiplayer_level",
		font_size = 45,
		horizontal_alignment = "center",
		text = "Cancel Matchmaking",
		template_type = "small_header",
		offset = {
			0,
			50,
			1
		},
		colors = {
			255,
			255,
			168,
			0
		},
		disabled_func = function (element, elements)
			if Managers.lobby and Managers.lobby:is_matchmaking() then
				return elements[element.depends_on].disabled
			else
				return true
			end
		end
	},
	{
		horizontal_alignment = "center",
		name = "multiplayer_text_enable",
		vertical_alignment = "bottom",
		depends_on = "multiplayer_level",
		font_size = 45,
		text = "Start Matchmaking",
		template_type = "small_header",
		text_func = function (element)
			if not Managers.lobby then
				return element.text
			elseif not Managers.lobby.server then
				return "Disconnect"
			elseif #Managers.lobby:lobby_members() > 1 then
				return "Disconnect"
			else
				return element.text
			end
		end,
		offset = {
			0,
			50,
			1
		},
		colors = {
			255,
			255,
			168,
			0
		},
		disabled_func = function (element, elements)
			if Managers.lobby and not Managers.lobby:is_matchmaking() then
				return elements[element.depends_on].disabled
			else
				return true
			end
		end
	},
	{
		name = "level_1",
		hover = true,
		depends_on = "background",
		horizontal_alignment = "left",
		vertical_alignment = "bottom",
		template_type = "bitmap",
		disabled = true,
		material_name = "preview_image_cart",
		material_func = function (element)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			566,
			316
		},
		offset = {
			150,
			300,
			100
		},
		on_activate = function (element, this)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone then
				return
			end

			local level_name = element.level_name

			Managers.state.event:trigger("change_level", level_name, true)

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
		end,
		disabled_func = function (element, elements)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone then
				return true
			end

			return element.disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "level_1_play",
		hover = false,
		depends_on = "level_1",
		vertical_alignment = "center",
		template_type = "bitmap",
		material_name = "play",
		size = {
			125,
			125
		},
		color = {
			196,
			255,
			168,
			0
		},
		offset = {
			0,
			0,
			1
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		template_type = "bitmap",
		name = "level_1_hover",
		hover = false,
		depends_on = "level_1",
		material_name = "preview_image_selection",
		size = {
			572,
			322
		},
		offset = {
			0,
			0,
			-1
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		name = "level_2",
		hover = true,
		depends_on = "background",
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		template_type = "bitmap",
		disabled = true,
		material_name = "preview_image_drachenfels",
		material_func = function (element)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			566,
			316
		},
		offset = {
			0,
			300,
			100
		},
		on_activate = function (element, this)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return
			end

			local level_name = element.level_name

			Managers.state.event:trigger("change_level", level_name, true)

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
		end,
		disabled_func = function (element, elements)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return true
			end

			return element.disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "level_2_play",
		hover = false,
		depends_on = "level_2",
		vertical_alignment = "center",
		template_type = "bitmap",
		material_name = "play",
		size = {
			125,
			125
		},
		color = {
			196,
			255,
			168,
			0
		},
		offset = {
			0,
			0,
			1
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		template_type = "bitmap",
		name = "level_2_hover",
		hover = false,
		depends_on = "level_2",
		material_name = "preview_image_selection",
		size = {
			572,
			322
		},
		offset = {
			0,
			0,
			-1
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		name = "level_3",
		hover = true,
		depends_on = "background",
		horizontal_alignment = "right",
		vertical_alignment = "bottom",
		template_type = "bitmap",
		disabled = true,
		material_name = "preview_image_inn",
		material_func = function (element)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			566,
			316
		},
		offset = {
			-150,
			300,
			100
		},
		on_activate = function (element, this)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return
			end

			local level_name = element.level_name

			Managers.state.event:trigger("change_level", level_name, true)

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
		end,
		disabled_func = function (element, elements)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return true
			end

			return element.disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "level_3_play",
		hover = false,
		depends_on = "level_3",
		vertical_alignment = "center",
		template_type = "bitmap",
		material_name = "play",
		size = {
			125,
			125
		},
		color = {
			196,
			255,
			168,
			0
		},
		offset = {
			0,
			0,
			1
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		template_type = "bitmap",
		name = "level_3_hover",
		hover = false,
		depends_on = "level_3",
		material_name = "preview_image_selection",
		size = {
			572,
			322
		},
		offset = {
			0,
			0,
			-1
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		type = "bitmap",
		name = "i5_bg",
		hover = true,
		depends_on = "background",
		animated_offset = 0.05,
		horizontal_alignment = "left",
		vertical_alignment = "bottom",
		disabled = true,
		material_name = "button_bg_hover",
		offset = {
			313,
			75,
			99
		},
		size = {
			100,
			100
		},
		on_activate = function (element, this)
			Managers.differentiation:_set_mode(1)

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
		end
	},
	{
		type = "bitmap",
		name = "i5_check",
		depends_on = "i5_bg",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "button_bg_selection",
		offset = {
			0,
			0,
			1
		},
		size = {
			100,
			100
		},
		disabled_func = function (element, elements)
			return Managers.differentiation:current_mode().title ~= "Low" or elements[element.depends_on].disabled
		end
	},
	{
		type = "bitmap",
		name = "i7_bg",
		hover = true,
		depends_on = "background",
		animated_offset = 0.05,
		horizontal_alignment = "left",
		vertical_alignment = "bottom",
		disabled = true,
		material_name = "button_bg_hover",
		offset = {
			453,
			75,
			99
		},
		size = {
			100,
			100
		},
		on_activate = function (element, this)
			Managers.differentiation:_set_mode(2)

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
		end
	},
	{
		type = "bitmap",
		name = "i7_check",
		depends_on = "i7_bg",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "button_bg_selection",
		offset = {
			0,
			0,
			1
		},
		size = {
			100,
			100
		},
		disabled_func = function (element, elements)
			return Managers.differentiation:current_mode().title ~= "High" or elements[element.depends_on].disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "i5_text",
		vertical_alignment = "center",
		depends_on = "i5_bg",
		font_size = 42,
		text = "OFF",
		template_type = "small_header",
		offset = {
			0,
			0,
			1
		},
		colors = {
			cheeseburger_low = {
				96,
				255,
				168,
				0
			},
			cheeseburger_high = {
				255,
				255,
				168,
				0
			}
		},
		color_func = function (element)
			if Managers.differentiation:current_mode().title == "Low" then
				return element.colors.cheeseburger_high
			else
				return element.colors.cheeseburger_low
			end
		end,
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "i7_text",
		vertical_alignment = "center",
		depends_on = "i7_bg",
		font_size = 42,
		text = "ON",
		template_type = "small_header",
		offset = {
			0,
			0,
			1
		},
		colors = {
			cheeseburger_low = {
				96,
				255,
				168,
				0
			},
			cheeseburger_high = {
				255,
				255,
				168,
				0
			}
		},
		color_func = function (element)
			if Managers.differentiation:current_mode().title == "High" then
				return element.colors.cheeseburger_high
			else
				return element.colors.cheeseburger_low
			end
		end,
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		type = "bitmap",
		name = "private_bg",
		hover = true,
		depends_on = "background",
		horizontal_alignment = "center",
		animated_offset = 0.05,
		vertical_alignment = "bottom",
		disabled = true,
		material_name = "button_bg_hover",
		offset = {
			105,
			75,
			99
		},
		size = {
			156,
			156
		},
		disabled_func = function (element)
			if not Managers.lobby or Game.startup_commands.standalone then
				return true
			elseif Managers.lobby and not Managers.lobby.server or Managers.lobby and Managers.lobby:is_matchmaking() then
				return true
			elseif #Managers.lobby:lobby_members() > 1 then
				return true
			else
				return element.disabled
			end
		end,
		on_activate = function (element, this)
			if Game.startup_commands.standalone then
				return true
			elseif Managers.lobby and Managers.lobby.server and #Managers.lobby:lobby_members() == 1 then
				Managers.lobby:set_private(true)

				local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

				WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
			end
		end
	},
	{
		type = "bitmap",
		name = "private_check",
		horizontal_alignment = "center",
		depends_on = "private_bg",
		vertical_alignment = "center",
		material_name = "button_bg_selection",
		offset = {
			0,
			0,
			1
		},
		color = {
			255,
			255,
			255,
			255
		},
		size = {
			162,
			162
		},
		disabled_func = function (element, elements)
			if Managers.lobby and Managers.lobby:get_lobby_data("private") == "true" then
				return elements[element.depends_on].disabled
			else
				return true
			end
		end
	},
	{
		type = "bitmap",
		name = "public_bg",
		hover = true,
		depends_on = "background",
		horizontal_alignment = "center",
		animated_offset = 0.05,
		vertical_alignment = "bottom",
		disabled = true,
		material_name = "button_bg_hover",
		offset = {
			-95,
			75,
			99
		},
		size = {
			156,
			156
		},
		disabled_func = function (element)
			if not Managers.lobby or Game.startup_commands.standalone then
				return true
			elseif Managers.lobby and not Managers.lobby.server or Managers.lobby and Managers.lobby:is_matchmaking() then
				return true
			elseif #Managers.lobby:lobby_members() > 1 then
				return true
			else
				return element.disabled
			end
		end,
		on_activate = function (element, this)
			if Game.startup_commands.standalone then
				return true
			elseif Managers.lobby and Managers.lobby.server and #Managers.lobby:lobby_members() == 1 then
				Managers.lobby:set_private(false)

				local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

				WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
			end
		end
	},
	{
		type = "bitmap",
		name = "public_check",
		depends_on = "public_bg",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "button_bg_selection",
		offset = {
			0,
			0,
			1
		},
		size = {
			162,
			162
		},
		disabled_func = function (element, elements)
			if Managers.lobby and Managers.lobby:get_lobby_data("private") == "false" then
				return elements[element.depends_on].disabled
			else
				return true
			end
		end
	},
	{
		horizontal_alignment = "center",
		name = "private_text",
		vertical_alignment = "center",
		depends_on = "private_bg",
		font_size = 50,
		text = "Private",
		template_type = "small_header",
		offset = {
			0,
			0,
			1
		},
		colors = {
			cheeseburger_low = {
				96,
				255,
				168,
				0
			},
			cheeseburger_high = {
				255,
				255,
				168,
				0
			}
		},
		color_func = function (element)
			return Managers.lobby and Managers.lobby:get_lobby_data("private") == "true" and element.colors.cheeseburger_high or element.colors.cheeseburger_low
		end,
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "public_text",
		vertical_alignment = "center",
		depends_on = "public_bg",
		font_size = 50,
		text = "Public",
		template_type = "small_header",
		offset = {
			0,
			0,
			1
		},
		colors = {
			cheeseburger_low = {
				96,
				255,
				168,
				0
			},
			cheeseburger_high = {
				255,
				255,
				168,
				0
			}
		},
		color_func = function (element)
			return element.colors.cheeseburger_high
		end,
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
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
			Managers.state.event:trigger("close_menu")

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_exit_mono", source_id)
		end
	},
	{
		type = "bitmap",
		name = "exit_bg",
		hover = true,
		depends_on = "background",
		animated_offset = 0.05,
		horizontal_alignment = "right",
		vertical_alignment = "bottom",
		disabled = true,
		material_name = "button_bg",
		offset = {
			-179,
			75,
			99
		},
		size = {
			156,
			156
		},
		on_activate = function (element, this)
			Managers.state.event:trigger("quit_game")

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_exit_mono", source_id)
		end
	},
	{
		name = "help_bg",
		animated_offset = 0.05,
		hover = true,
		type = "bitmap",
		depends_on = "background",
		horizontal_alignment = "right",
		vertical_alignment = "bottom",
		disabled = true,
		material_name = "button_bg",
		offset = {
			-531,
			75,
			99
		},
		size = {
			156,
			156
		},
		on_activate = function (element, this)
			local pose = Managers.state.view:view("gameplay_view"):gui_pose()

			Managers.state.view:enable_view("how_to_play_view", true, pose)

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_exit_mono", source_id)
		end
	},
	{
		vertical_alignment = "center",
		name = "help_bg_icon",
		type = "bitmap",
		horizontal_alignment = "center",
		material_name = "help_icon",
		depends_on = "help_bg",
		size = {
			80,
			80
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		name = "credits_bg",
		animated_offset = 0.05,
		hover = true,
		type = "bitmap",
		depends_on = "background",
		horizontal_alignment = "right",
		vertical_alignment = "bottom",
		disabled = true,
		material_name = "button_bg",
		offset = {
			-355,
			75,
			99
		},
		size = {
			156,
			156
		},
		on_activate = function (element, this)
			local pose = Managers.state.view:view("gameplay_view"):gui_pose()

			Managers.state.view:enable_view("credits_view", true, pose)

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_exit_mono", source_id)
		end
	},
	{
		vertical_alignment = "center",
		name = "credits_bg_icon",
		type = "bitmap",
		horizontal_alignment = "center",
		material_name = "credits_icon",
		depends_on = "credits_bg",
		size = {
			80,
			80
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
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
	},
	{
		depends_on = "exit_bg",
		name = "exit_bg_icon",
		type = "bitmap",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "exit",
		size = {
			80,
			80
		},
		color = {
			255,
			255,
			0,
			0
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		type = "bitmap",
		name = "save",
		hover = true,
		depends_on = "level_3",
		animated_offset = 0.05,
		horizontal_alignment = "center",
		vertical_alignment = "center",
		disabled = true,
		material_name = "button_bg",
		offset = {
			0,
			-530,
			1
		},
		size = {
			200,
			100
		},
		on_activate = function (element, this)
			Application.set_user_setting("render_settings", "vr_target_scale", this._vr_target_scale or 1)
			Application.save_user_settings()

			this._vr_target_scale_popup_id = Managers.popup:queue_popup("Notice", "Render Quality Saved\n\n For these changes to take effect you need to restart the game.")
		end
	},
	{
		name = "save_text",
		vertical_alignment = "center",
		depends_on = "save",
		font_size = 50,
		horizontal_alignment = "center",
		text = "SAVE",
		template_type = "header",
		offset = {
			0,
			5,
			1
		},
		color = {
			255,
			255,
			168,
			0
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		type = "bitmap",
		name = "scrollbar",
		depends_on = "level_2",
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		disabled = true,
		material_name = "rect",
		offset = {
			0,
			-380,
			2
		},
		size = {
			700,
			10
		}
	},
	{
		type = "bitmap",
		name = "scroller",
		hover = true,
		depends_on = "scrollbar",
		animated_offset = 0.05,
		horizontal_alignment = "left",
		vertical_alignment = "center",
		disabled = true,
		material_name = "button_bg",
		offset = {
			((Application.user_setting("render_settings", "vr_target_scale") or 1) - 0.5) / 1 * 500,
			0,
			2
		},
		size = {
			200,
			100
		},
		on_activate_held = function (element, this, dt)
			local old_gui_pos = this._old_gui_pos:unbox()
			local gui_pos = this._gui_pos:unbox()
			local diff_in_pixels = gui_pos[1] - old_gui_pos[1]

			element.offset[1] = math.clamp(element.offset[1] + diff_in_pixels, 0, 700 - element.size[1])
			this._scroller_dirty = true
		end
	},
	{
		name = "render_quality_scale_text",
		vertical_alignment = "center",
		depends_on = "scroller",
		font_size = 50,
		horizontal_alignment = "center",
		template_type = "header",
		text = string.format("%.1f", tostring(Application.user_setting("render_settings", "vr_target_scale") or 1)),
		offset = {
			0,
			0,
			1
		},
		color = {
			255,
			255,
			168,
			0
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
		name = "background_canvas",
		depends_on = "background",
		type = "bitmap",
		material_name = "background",
		offset = {
			0,
			-175,
			0
		}
	},
	{
		vertical_alignment = "top",
		name = "logo",
		depends_on = "background",
		template_type = "bitmap",
		material_name = "vermintide_logo_transparent",
		horizontal_alignment = "left",
		size = {
			742.1999999999999,
			322.8
		},
		offset = {
			20,
			-75,
			2
		}
	},
	{
		horizontal_alignment = "right",
		name = "beta",
		text = "BETA",
		depends_on = "logo",
		vertical_alignment = "bottom",
		template_type = "header",
		offset = {
			0,
			0,
			1
		},
		color = {
			255,
			255,
			190,
			50
		},
		disabled_func = function ()
			return not GameSettingsDevelopment.beta
		end
	},
	{
		name = "demo",
		vertical_alignment = "bottom",
		depends_on = "logo",
		font_size = 63,
		horizontal_alignment = "right",
		text = "DEMO",
		template_type = "header",
		offset = {
			17,
			34,
			10
		},
		color = {
			255,
			0,
			186,
			212
		},
		disabled_func = function ()
			return Managers.unlock:is_dlc_unlocked("full_game")
		end
	},
	{
		name = "current_level",
		horizontal_alignment = "center",
		depends_on = "background",
		vertical_alignment = "top",
		template_type = "bitmap",
		material_name = "preview_image_inn",
		material_func = function (element)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			566,
			316
		},
		offset = {
			0,
			-75,
			2
		},
		disabled_func = function (element, elements)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone then
				return false
			end

			return element.disabled
		end
	},
	{
		name = "multiplayer_level",
		horizontal_alignment = "right",
		depends_on = "background",
		vertical_alignment = "top",
		template_type = "bitmap",
		material_name = "preview_image_multiplayer",
		material_func = function (element)
			if not Managers.lobby or Game.startup_commands.standalone then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			566,
			316
		},
		offset = {
			-150,
			-75,
			2
		},
		disabled_func = function (element, elements)
			if not Managers.lobby or Game.startup_commands.standalone then
				return false
			else
				return element.disabled
			end
		end
	},
	{
		horizontal_alignment = "center",
		name = "multiplayer_level_icon",
		hover = false,
		depends_on = "multiplayer_level",
		vertical_alignment = "center",
		template_type = "bitmap",
		material_name = "disconnect",
		size = {
			125,
			128
		},
		color = {
			196,
			255,
			255,
			255
		},
		offset = {
			0,
			40,
			1
		},
		disabled_func = function (element, elements)
			if not Managers.lobby then
				return false
			elseif not Managers.lobby.server then
				return false
			elseif #Managers.lobby:lobby_members() > 1 then
				return false
			else
				return true
			end
		end
	},
	{
		horizontal_alignment = "center",
		name = "multiplayer_search_icon",
		hover = false,
		depends_on = "multiplayer_level",
		vertical_alignment = "center",
		template_type = "bitmap_rotation",
		material_name = "reload",
		size = {
			125,
			128
		},
		color = {
			196,
			255,
			255,
			255
		},
		offset = {
			0,
			40,
			1
		},
		disabled_func = function (element, elements)
			if not Managers.lobby then
				return true
			else
				return Managers.lobby and not Managers.lobby:is_matchmaking()
			end
		end
	},
	{
		name = "multiplayer_text",
		vertical_alignment = "bottom",
		depends_on = "multiplayer_level",
		font_size = 45,
		horizontal_alignment = "center",
		text = "Searching...",
		template_type = "small_header",
		offset = {
			0,
			50,
			1
		},
		colors = {
			255,
			255,
			168,
			0
		},
		disabled_func = function (element, elements)
			if not Managers.lobby then
				return true
			else
				return Managers.lobby and not Managers.lobby:is_matchmaking()
			end
		end
	},
	{
		name = "multiplayer_text",
		vertical_alignment = "bottom",
		depends_on = "multiplayer_level",
		font_size = 60,
		horizontal_alignment = "center",
		text = "DISABLED",
		template_type = "small_header",
		offset = {
			0,
			40,
			1
		},
		colors = {
			255,
			255,
			168,
			0
		},
		disabled_func = function (element, elements)
			if not Managers.lobby or Game.startup_commands.standalone then
				return false
			else
				return true
			end
		end
	},
	{
		template_type = "bitmap",
		name = "multiplayer_level_matchmaking_mark",
		hover = false,
		depends_on = "multiplayer_level",
		material_name = "preview_image_selection",
		size = {
			572,
			322
		},
		offset = {
			0,
			0,
			-1
		},
		disabled_func = function (element, elements)
			if not Managers.lobby then
				return true
			else
				return not Managers.lobby:is_matchmaking()
			end
		end
	},
	{
		name = "divider",
		depends_on = "logo",
		type = "bitmap",
		material_name = "divider",
		size = {
			1730,
			3
		},
		offset = {
			235,
			-100,
			2
		}
	},
	{
		name = "level_1",
		horizontal_alignment = "left",
		depends_on = "background",
		vertical_alignment = "bottom",
		template_type = "bitmap",
		material_name = "preview_image_cart",
		material_func = function (element)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			566,
			316
		},
		offset = {
			150,
			300,
			2
		},
		disabled_func = function (element, elements)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone then
				return false
			end

			return element.disabled
		end
	},
	{
		name = "level_2",
		horizontal_alignment = "center",
		depends_on = "background",
		vertical_alignment = "bottom",
		template_type = "bitmap",
		material_name = "preview_image_drachenfels",
		material_func = function (element)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			566,
			316
		},
		offset = {
			0,
			300,
			2
		},
		disabled_func = function (element, elements)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return false
			end

			return element.disabled
		end
	},
	{
		name = "level_3",
		horizontal_alignment = "right",
		depends_on = "background",
		vertical_alignment = "bottom",
		template_type = "bitmap",
		material_name = "preview_image_inn",
		material_func = function (element)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			566,
			316
		},
		offset = {
			-150,
			300,
			2
		},
		disabled_func = function (element, elements)
			if Managers.lobby and not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return false
			end

			return element.disabled
		end
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
		name = "advanced_text",
		vertical_alignment = "bottom",
		depends_on = "level_1",
		font_size = 50,
		horizontal_alignment = "center",
		text = "Advanced CPU Extras",
		template_type = "header",
		offset = {
			0,
			-100,
			1
		},
		color = {
			255,
			255,
			168,
			0
		}
	},
	{
		name = "render_quality_text",
		vertical_alignment = "bottom",
		depends_on = "level_1",
		font_size = 60,
		horizontal_alignment = "center",
		text = "Render Quality Scale",
		template_type = "header",
		offset = {
			0,
			-390,
			1
		},
		color = {
			255,
			255,
			168,
			0
		}
	},
	{
		type = "bitmap",
		name = "scrollbar",
		horizontal_alignment = "center",
		depends_on = "level_2",
		vertical_alignment = "bottom",
		material_name = "rect",
		offset = {
			0,
			-380,
			2
		},
		size = {
			700,
			7.5
		},
		color = {
			255,
			255,
			168,
			0
		}
	},
	{
		vertical_alignment = "center",
		name = "scroller",
		type = "bitmap",
		depends_on = "scrollbar",
		material_name = "button_bg",
		horizontal_alignment = "left",
		offset = {
			((Application.user_setting("render_settings", "vr_target_scale") or 1) - 0.5) / 1 * 500,
			0,
			2
		},
		size = {
			200,
			100
		}
	},
	{
		name = "render_quality_scale_text",
		vertical_alignment = "center",
		depends_on = "scroller",
		font_size = 50,
		horizontal_alignment = "center",
		template_type = "header",
		text = string.format("%.1f", tostring(Application.user_setting("render_settings", "vr_target_scale") or 1)),
		offset = {
			0,
			0,
			1
		},
		color = {
			255,
			255,
			168,
			0
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		vertical_alignment = "bottom",
		name = "i5_bg",
		type = "bitmap",
		depends_on = "background",
		material_name = "button_bg",
		horizontal_alignment = "left",
		offset = {
			313,
			75,
			1
		},
		size = {
			100,
			100
		}
	},
	{
		type = "bitmap",
		name = "i5_check",
		depends_on = "i5_bg",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "button_bg_selection",
		offset = {
			0,
			0,
			1
		},
		size = {
			100,
			100
		},
		disabled_func = function (element, elements)
			return Managers.differentiation:current_mode().title ~= "Low" or elements[element.depends_on].disabled
		end
	},
	{
		vertical_alignment = "bottom",
		name = "i7_bg",
		type = "bitmap",
		depends_on = "background",
		material_name = "button_bg",
		horizontal_alignment = "left",
		offset = {
			453,
			75,
			1
		},
		size = {
			100,
			100
		}
	},
	{
		type = "bitmap",
		name = "i7_check",
		depends_on = "i7_bg",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "button_bg_selection",
		offset = {
			0,
			0,
			1
		},
		size = {
			100,
			100
		},
		disabled_func = function (element, elements)
			return Managers.differentiation:current_mode().title ~= "High" or elements[element.depends_on].disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "i5_text",
		vertical_alignment = "center",
		depends_on = "i5_bg",
		font_size = 42,
		text = "OFF",
		template_type = "small_header",
		offset = {
			0,
			0,
			1
		},
		colors = {
			cheeseburger_low = {
				96,
				255,
				168,
				0
			},
			cheeseburger_high = {
				255,
				255,
				168,
				0
			}
		},
		color_func = function (element)
			if Managers.differentiation:current_mode().title == "Low" then
				return element.colors.cheeseburger_high
			else
				return element.colors.cheeseburger_low
			end
		end,
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "i7_text",
		vertical_alignment = "center",
		depends_on = "i7_bg",
		font_size = 42,
		text = "ON",
		template_type = "small_header",
		offset = {
			0,
			0,
			1
		},
		colors = {
			cheeseburger_low = {
				20,
				255,
				168,
				0
			},
			cheeseburger_high = {
				255,
				255,
				168,
				0
			}
		},
		color_func = function (element)
			if Managers.differentiation:current_mode().title == "High" then
				return element.colors.cheeseburger_high
			else
				return element.colors.cheeseburger_low
			end
		end,
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		type = "bitmap",
		name = "private_bg",
		depends_on = "background",
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		material_name = "button_bg",
		offset = {
			105,
			75,
			1
		},
		size = {
			156,
			156
		},
		disabled_func = function (element)
			if not Managers.lobby or Game.startup_commands.standalone then
				return true
			elseif Managers.lobby and not Managers.lobby.server or Managers.lobby and Managers.lobby:is_matchmaking() then
				return true
			elseif #Managers.lobby:lobby_members() > 1 then
				return true
			else
				return element.disabled
			end
		end
	},
	{
		type = "bitmap",
		name = "private_check",
		depends_on = "private_bg",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "button_bg_selection",
		offset = {
			0,
			0,
			1
		},
		size = {
			162,
			162
		},
		disabled_func = function (element, elements)
			if Managers.lobby and Managers.lobby:get_lobby_data("private") == "true" then
				return elements[element.depends_on].disabled
			else
				return true
			end
		end
	},
	{
		type = "bitmap",
		name = "public_bg",
		depends_on = "background",
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		material_name = "button_bg",
		offset = {
			-95,
			75,
			1
		},
		size = {
			156,
			156
		},
		disabled_func = function (element)
			if not Managers.lobby or Game.startup_commands.standalone then
				return true
			elseif Managers.lobby and not Managers.lobby.server or Managers.lobby and Managers.lobby:is_matchmaking() then
				return true
			elseif #Managers.lobby:lobby_members() > 1 then
				return true
			else
				return element.disabled
			end
		end
	},
	{
		type = "bitmap",
		name = "public_check",
		depends_on = "public_bg",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "button_bg_selection",
		offset = {
			0,
			0,
			1
		},
		size = {
			162,
			162
		},
		disabled_func = function (element, elements)
			if Managers.lobby and Managers.lobby:get_lobby_data("private") == "false" then
				return elements[element.depends_on].disabled
			else
				return true
			end
		end
	},
	{
		horizontal_alignment = "center",
		name = "private_text",
		vertical_alignment = "center",
		depends_on = "private_bg",
		font_size = 50,
		text = "Private",
		template_type = "small_header",
		offset = {
			0,
			0,
			1
		},
		colors = {
			cheeseburger_low = {
				20,
				255,
				168,
				0
			},
			cheeseburger_high = {
				255,
				255,
				168,
				0
			}
		},
		color_func = function (element)
			return Managers.lobby and Managers.lobby:get_lobby_data("private") == "true" and element.colors.cheeseburger_high or element.colors.cheeseburger_low
		end,
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		horizontal_alignment = "center",
		name = "public_text",
		vertical_alignment = "center",
		depends_on = "public_bg",
		font_size = 50,
		text = "Public",
		template_type = "small_header",
		offset = {
			0,
			0,
			1
		},
		colors = {
			cheeseburger_low = {
				20,
				255,
				168,
				0
			},
			cheeseburger_high = {
				255,
				255,
				168,
				0
			}
		},
		color_func = function (element)
			return Managers.lobby and Managers.lobby:get_lobby_data("private") == "false" and element.colors.cheeseburger_high or element.colors.cheeseburger_low
		end,
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
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
		vertical_alignment = "bottom",
		name = "exit_bg",
		type = "bitmap",
		depends_on = "background",
		material_name = "button_bg",
		horizontal_alignment = "right",
		offset = {
			-179,
			75,
			99
		},
		size = {
			156,
			156
		}
	},
	{
		vertical_alignment = "bottom",
		name = "help_bg",
		type = "bitmap",
		depends_on = "background",
		material_name = "button_bg",
		horizontal_alignment = "right",
		offset = {
			-531,
			75,
			99
		},
		size = {
			156,
			156
		}
	},
	{
		depends_on = "help_bg",
		name = "help_bg_icon",
		type = "bitmap",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "help_icon",
		color = {
			96,
			255,
			255,
			255
		},
		size = {
			80,
			80
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		vertical_alignment = "bottom",
		name = "credits_bg",
		type = "bitmap",
		depends_on = "background",
		material_name = "button_bg",
		horizontal_alignment = "right",
		offset = {
			-355,
			75,
			99
		},
		size = {
			156,
			156
		}
	},
	{
		depends_on = "credits_bg",
		name = "credits_bg_icon",
		type = "bitmap",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "credits_icon",
		color = {
			96,
			255,
			255,
			255
		},
		size = {
			80,
			80
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		depends_on = "close_bg",
		name = "close_bg_icon",
		type = "bitmap",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "close",
		size = {
			110,
			110
		},
		color = {
			255,
			255,
			255,
			255
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		depends_on = "exit_bg",
		name = "exit_bg_icon",
		type = "bitmap",
		horizontal_alignment = "center",
		vertical_alignment = "center",
		material_name = "exit",
		size = {
			80,
			80
		},
		color = {
			96,
			255,
			255,
			255
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		vertical_alignment = "center",
		name = "save",
		type = "bitmap",
		depends_on = "level_3",
		material_name = "button_bg",
		horizontal_alignment = "center",
		offset = {
			0,
			-530,
			1
		},
		size = {
			200,
			100
		}
	},
	{
		name = "save_text",
		vertical_alignment = "center",
		depends_on = "save",
		font_size = 50,
		horizontal_alignment = "center",
		text = "SAVE",
		template_type = "header",
		offset = {
			0,
			5,
			1
		},
		color = {
			128,
			255,
			168,
			0
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	}
}

return {
	elements = elements,
	animated_elements = animated_elements
}
