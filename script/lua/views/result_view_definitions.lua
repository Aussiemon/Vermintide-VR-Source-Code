-- chunkname: @script/lua/views/result_view_definitions.lua

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
			500
		},
		area_size = {
			2200,
			1200
		}
	},
	{
		template_type = "bitmap",
		name = "victory_image",
		depends_on = "background",
		material_name = "end_screen_banner_victory_en",
		size = {
			824,
			320
		},
		offset = {
			0,
			0,
			2
		}
	},
	{
		template_type = "bitmap",
		name = "victory_image_bg",
		depends_on = "victory_image",
		material_name = "end_screen_banner_effect",
		size = {
			1080,
			560
		},
		offset = {
			0,
			-20,
			-1
		},
		color = {
			0,
			0,
			191,
			255
		}
	}
}
local scoreboard_elements = {
	{
		name = "background",
		template_type = "rect",
		disabled = true,
		color = {
			192,
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
		name = "current_level",
		horizontal_alignment = "right",
		depends_on = "background",
		reload_icon = true,
		vertical_alignment = "top",
		template_type = "bitmap",
		material_name = "preview_image_inn",
		material_func = function (element)
			if not Managers.lobby then
				return element.material_name
			elseif Managers.lobby and Game.startup_commands.standalone then
				if Managers.lobby.server then
					return element.material_name
				else
					return element.material_name .. "_grayscale"
				end
			elseif Managers.lobby and Managers.lobby.server and #Managers.lobby:lobby_members() < 2 then
				return element.material_name
			else
				return "preview_image_multiplayer"
			end
		end,
		size = {
			424.5,
			237
		},
		offset = {
			-100,
			-150,
			2
		},
		selectable_func = function (element, elements)
			if not Managers.lobby then
				return true
			elseif Managers.lobby.server or not Game.startup_commands.standalone then
				return true
			else
				return false
			end
		end,
		on_activate = function (element, this)
			if Managers.lobby and Managers.lobby.server then
				if #Managers.lobby:lobby_members() > 1 and not Game.startup_commands.standalone then
					Managers.state.event:trigger("disconnect")
				else
					local level_name = element.level_name

					Managers.state.event:trigger("change_level", level_name, true)
				end
			else
				Managers.state.event:trigger("disconnect")
			end

			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono")
		end,
		disabled_func = function (element, elements)
			return element.disabled
		end
	},
	{
		name = "disconnect_icon",
		hover = false,
		depends_on = "current_level",
		skip_hover_effect = true,
		horizontal_alignment = "center",
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
		selectable_func = function (element, elements)
			if Managers.lobby and Game.startup_commands.standalone then
				return false
			else
				return true
			end
		end,
		disabled_func = function (element, elements)
			if not Managers.lobby then
				return true
			elseif (not Managers.lobby.server or #Managers.lobby:lobby_members() > 1) and not Game.startup_commands.standalone then
				return elements[element.depends_on].disabled
			else
				return true
			end
		end
	},
	{
		name = "multiplayer_text_enable",
		hover = false,
		depends_on = "current_level",
		font_size = 45,
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		text = "Disconnect",
		template_type = "small_header",
		skip_hover_effect = true,
		offset = {
			0,
			50,
			1
		},
		selectable_func = function (element, elements)
			if Managers.lobby and Game.startup_commands.standalone then
				return false
			else
				return true
			end
		end,
		colors = {
			255,
			255,
			168,
			0
		},
		disabled_func = function (element, elements)
			if not Managers.lobby then
				return true
			elseif not Managers.lobby.server and Game.startup_commands.standalone then
				return true
			elseif not Managers.lobby.server or #Managers.lobby:lobby_members() > 1 and not Game.startup_commands.standalone then
				return elements[element.depends_on].disabled
			else
				return true
			end
		end
	},
	{
		vertical_alignment = "center",
		name = "divider",
		depends_on = "background",
		type = "bitmap",
		horizontal_alignment = "center",
		material_name = "divider",
		size = {
			1730,
			3
		},
		offset = {
			0,
			150,
			2
		}
	},
	{
		name = "level_3",
		horizontal_alignment = "right",
		depends_on = "background",
		vertical_alignment = "bottom",
		template_type = "bitmap",
		play_icon = true,
		material_name = "preview_image_cart",
		material_func = function (element)
			if not Managers.lobby then
				return element.material_name
			elseif not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			339.59999999999997,
			189.6
		},
		offset = {
			-100,
			50,
			2
		},
		selectable_func = function (element, elements)
			if Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return false
			elseif not Managers.lobby then
				return true
			elseif Managers.lobby.server then
				return true
			else
				return false
			end
		end,
		on_activate = function (element, this)
			local level_name = element.level_name

			Managers.state.event:trigger("change_level", level_name, true)
			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono")
		end
	},
	{
		name = "level_2",
		horizontal_alignment = "right",
		depends_on = "level_3",
		vertical_alignment = "bottom",
		template_type = "bitmap",
		play_icon = true,
		material_name = "preview_image_drachenfels",
		material_func = function (element)
			if not Managers.lobby then
				return element.material_name
			elseif not Managers.lobby.server or Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			339.59999999999997,
			189.6
		},
		offset = {
			0,
			208,
			2
		},
		selectable_func = function (element, elements)
			if Game.startup_commands.standalone or not Managers.unlock:is_dlc_unlocked("full_game") then
				return false
			elseif not Managers.lobby then
				return true
			elseif Managers.lobby.server then
				return true
			else
				return false
			end
		end,
		on_activate = function (element, this)
			local level_name = element.level_name

			Managers.state.event:trigger("change_level", level_name, true)
			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono")
		end
	},
	{
		name = "level_1",
		horizontal_alignment = "right",
		depends_on = "background",
		vertical_alignment = "bottom",
		template_type = "bitmap",
		play_icon = true,
		material_name = "preview_image_inn",
		material_func = function (element)
			if not Managers.lobby then
				return element.material_name
			elseif not Managers.lobby.server or Game.startup_commands.standalone then
				return element.material_name .. "_grayscale"
			else
				return element.material_name
			end
		end,
		size = {
			339.59999999999997,
			189.6
		},
		offset = {
			-100,
			466,
			2
		},
		selectable_func = function (element, elements)
			if Game.startup_commands.standalone then
				return false
			elseif not Managers.lobby then
				return true
			elseif Managers.lobby.server then
				return true
			else
				return false
			end
		end,
		on_activate = function (element, this)
			local level_name = element.level_name

			Managers.state.event:trigger("change_level", level_name, true)
			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono")
		end
	},
	{
		vertical_alignment = "bottom",
		template_type = "rect",
		horizontal_alignment = "center",
		depends_on = "background",
		name = "scoreboard_canvas",
		color = {
			60,
			10,
			10,
			10
		},
		offset = {
			-100,
			75,
			5
		},
		size = {
			1200,
			500,
			2
		}
	},
	{
		depends_on = "background",
		name = "scoreboard_canvas_mask",
		type = "bitmap",
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		material_name = "mask",
		color = {
			255,
			255,
			255,
			255
		},
		offset = {
			-100,
			75,
			700
		},
		size = {
			1200,
			500,
			2
		}
	},
	{
		vertical_alignment = "top",
		name = "scoreboard_element_0",
		horizontal_alignment = "center",
		depends_on = "scoreboard_canvas",
		template_type = "rect",
		disabled = true,
		offset = {
			0,
			0,
			-1
		},
		size = {
			0,
			0,
			2
		}
	},
	{
		vertical_alignment = "top",
		template_type = "rect",
		name = "canvas_edge_top",
		depends_on = "scoreboard_canvas",
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
			1200,
			5
		}
	},
	{
		vertical_alignment = "center",
		template_type = "rect",
		name = "canvas_edge_left",
		depends_on = "scoreboard_canvas",
		horizontal_alignment = "left",
		color = {
			255,
			255,
			168,
			0
		},
		offset = {
			-4,
			0,
			-1
		},
		size = {
			5,
			500
		}
	},
	{
		vertical_alignment = "center",
		template_type = "rect",
		name = "canvas_edge_right",
		depends_on = "scoreboard_canvas",
		horizontal_alignment = "right",
		color = {
			255,
			255,
			168,
			0
		},
		offset = {
			4,
			0,
			-1
		},
		size = {
			5,
			500
		}
	},
	{
		vertical_alignment = "bottom",
		template_type = "rect",
		name = "canvas_edge_bottom",
		depends_on = "scoreboard_canvas",
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
			1200,
			5
		}
	},
	{
		vertical_alignment = "top",
		name = "scoreboard_placement_icon",
		depends_on = "scoreboard_canvas",
		type = "bitmap",
		horizontal_alignment = "left",
		material_name = "placement",
		offset = {
			0,
			105,
			5
		},
		size = {
			96,
			96,
			2
		}
	},
	{
		vertical_alignment = "top",
		name = "scoreboard_player_icon",
		depends_on = "scoreboard_canvas",
		type = "bitmap",
		horizontal_alignment = "left",
		material_name = "player",
		offset = {
			150,
			105,
			5
		},
		size = {
			96,
			96,
			2
		}
	},
	{
		vertical_alignment = "top",
		name = "scoreboard_score_icon",
		depends_on = "scoreboard_canvas",
		type = "bitmap",
		horizontal_alignment = "right",
		material_name = "score",
		offset = {
			0,
			105,
			5
		},
		size = {
			96,
			96,
			2
		}
	},
	{
		vertical_alignment = "top",
		name = "scoreboard_headshots_icon",
		depends_on = "scoreboard_score_icon",
		type = "bitmap",
		horizontal_alignment = "right",
		material_name = "headshots",
		offset = {
			-150,
			0,
			5
		},
		size = {
			96,
			96,
			2
		}
	},
	{
		vertical_alignment = "top",
		name = "scoreboard_kills_icon",
		depends_on = "scoreboard_headshots_icon",
		type = "bitmap",
		horizontal_alignment = "right",
		material_name = "kills",
		offset = {
			-150,
			0,
			5
		},
		size = {
			96,
			96,
			2
		}
	},
	{
		horizontal_alignment = "center",
		name = "scroll_canvas",
		depends_on = "background",
		vertical_alignment = "bottom",
		template_type = "rect",
		selectable = true,
		root = true,
		color = {
			196,
			10,
			10,
			10
		},
		offset = {
			550,
			75,
			5
		},
		size = {
			50,
			500,
			2
		}
	},
	{
		vertical_alignment = "top",
		template_type = "rect",
		name = "scroll_canvas_edge_top",
		depends_on = "scroll_canvas",
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
			50,
			5
		}
	},
	{
		vertical_alignment = "center",
		template_type = "rect",
		name = "scroll_canvas_edge_left",
		depends_on = "scroll_canvas",
		horizontal_alignment = "left",
		color = {
			255,
			255,
			168,
			0
		},
		offset = {
			-4,
			0,
			-1
		},
		size = {
			5,
			500
		}
	},
	{
		vertical_alignment = "center",
		template_type = "rect",
		name = "scroll_canvas_edge_right",
		depends_on = "scroll_canvas",
		horizontal_alignment = "right",
		color = {
			255,
			255,
			168,
			0
		},
		offset = {
			4,
			0,
			-1
		},
		size = {
			5,
			500
		}
	},
	{
		vertical_alignment = "bottom",
		template_type = "rect",
		name = "scroll_canvas_edge_bottom",
		depends_on = "scroll_canvas",
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
			50,
			5
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
		depends_on = "scroll_canvas",
		name = "scroll_up",
		type = "bitmap",
		animated_offset = 0.05,
		horizontal_alignment = "center",
		vertical_alignment = "top",
		selectable = true,
		material_name = "scrollbar_arrow_01",
		color = {
			255,
			255,
			255,
			255
		},
		offset = {
			0,
			-10,
			5
		},
		size = {
			40,
			40,
			2
		},
		on_activate_held = function (element, this, dt)
			this._scoreboard_scroll_offset = math.max(this._scoreboard_scroll_offset - this._scoreboard_scroll_offset_speed * dt, 0)

			WwiseWorld.trigger_event(this._wwise_world, "menu_exit_mono")
		end
	},
	{
		depends_on = "scroll_canvas",
		name = "scroll_down",
		type = "bitmap",
		animated_offset = 0.05,
		horizontal_alignment = "center",
		vertical_alignment = "bottom",
		selectable = true,
		material_name = "scrollbar_arrow_02",
		color = {
			255,
			255,
			255,
			255
		},
		offset = {
			0,
			10,
			5
		},
		size = {
			40,
			40,
			2
		},
		on_activate_held = function (element, this, dt)
			this._scoreboard_scroll_offset = math.min(this._scoreboard_scroll_offset + this._scoreboard_scroll_offset_speed * dt, math.max(this._scoreboard_index - 11, 0) * 50)

			WwiseWorld.trigger_event(this._wwise_world, "menu_exit_mono")
		end
	},
	{
		horizontal_alignment = "center",
		name = "scroller",
		depends_on = "scroll_canvas",
		type = "bitmap",
		animated_offset = 0.025,
		scroll_distance = -290,
		vertical_alignment = "top",
		selectable = true,
		material_name = "scrollbar",
		offset = {
			0,
			-55,
			5
		},
		size = {
			40,
			100,
			2
		},
		on_activate_held = function (element, this, dt)
			local old_gui_pos = this._old_gui_pos:unbox()
			local gui_pos = this._gui_pos:unbox()
			local diff_in_pixels = gui_pos[3] - old_gui_pos[3]

			element.offset[2] = math.clamp(element.offset[2] + diff_in_pixels, -345, -55)
			this._scoreboard_elements.scroller.offset[2] = element.offset[2]
			this._scoreboard_scroll_offset = math.max(this._scoreboard_index - 11, 0) * 50 * (math.abs(element.offset[2]) - 55) / math.abs(element.scroll_distance)
		end
	},
	{
		name = "global_leaderboard_button",
		type = "bitmap",
		depends_on = "background",
		horizontal_alignment = "left",
		animated_offset = 0.05,
		vertical_alignment = "bottom",
		selectable = true,
		material_name = "button_bg",
		colors = {
			enabled = {
				255,
				255,
				255,
				255
			},
			disabled = {
				255,
				96,
				96,
				96
			}
		},
		color_func = function (element)
			return Managers.leaderboards:current_leaderboard() == "global" and element.colors.enabled or element.colors.disabled
		end,
		offset = {
			250,
			465,
			5
		},
		size = {
			110,
			110,
			2
		},
		disabled_func = function (element, elements)
			if Managers.leaderboards:enabled() then
				return element.disabled
			else
				return true
			end
		end,
		on_activate = function (element, this, dt)
			if Managers.leaderboards:enabled() then
				this:reinitialize_scoreboard("global")
			end

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
		end
	},
	{
		name = "global_leaderboard_icon",
		type = "bitmap",
		depends_on = "global_leaderboard_button",
		horizontal_alignment = "center",
		animated_offset = 0.05,
		vertical_alignment = "center",
		selectable = true,
		skip_hover_effect = true,
		material_name = "button_icon_global",
		colors = {
			enabled = {
				255,
				255,
				255,
				255
			},
			disabled = {
				255,
				96,
				96,
				96
			}
		},
		color_func = function (element)
			return Managers.leaderboards:current_leaderboard() == "global" and element.colors.enabled or element.colors.disabled
		end,
		offset = {
			0,
			0,
			5
		},
		size = {
			80,
			80,
			3
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		name = "friends_leaderboard_button",
		type = "bitmap",
		depends_on = "global_leaderboard_button",
		horizontal_alignment = "center",
		animated_offset = 0.05,
		vertical_alignment = "center",
		selectable = true,
		material_name = "button_bg",
		colors = {
			enabled = {
				255,
				255,
				255,
				255
			},
			disabled = {
				255,
				96,
				96,
				96
			}
		},
		color_func = function (element)
			return Managers.leaderboards:current_leaderboard() == "friends" and element.colors.enabled or element.colors.disabled
		end,
		offset = {
			0,
			-130,
			5
		},
		size = {
			110,
			110,
			2
		},
		disabled_func = function (element, elements)
			if Managers.leaderboards:enabled() then
				return element.disabled
			else
				return true
			end
		end,
		on_activate = function (element, this, dt)
			if Managers.leaderboards:enabled() then
				this:reinitialize_scoreboard("friends")
			end

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
		end
	},
	{
		name = "friends_leaderboard_icon",
		type = "bitmap",
		depends_on = "friends_leaderboard_button",
		horizontal_alignment = "center",
		animated_offset = 0.05,
		vertical_alignment = "center",
		selectable = true,
		skip_hover_effect = true,
		material_name = "button_icon_friends",
		colors = {
			enabled = {
				255,
				255,
				255,
				255
			},
			disabled = {
				255,
				96,
				96,
				96
			}
		},
		color_func = function (element)
			return Managers.leaderboards:current_leaderboard() == "friends" and element.colors.enabled or element.colors.disabled
		end,
		offset = {
			0,
			0,
			5
		},
		size = {
			80,
			80,
			3
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	},
	{
		name = "local_leaderboard_button",
		type = "bitmap",
		depends_on = "friends_leaderboard_button",
		horizontal_alignment = "center",
		animated_offset = 0.05,
		vertical_alignment = "center",
		selectable = true,
		material_name = "button_bg",
		colors = {
			enabled = {
				255,
				255,
				255,
				255
			},
			disabled = {
				255,
				96,
				96,
				96
			}
		},
		color_func = function (element)
			return Managers.leaderboards:current_leaderboard() == "local" and element.colors.enabled or element.colors.disabled
		end,
		offset = {
			0,
			-130,
			5
		},
		size = {
			110,
			110,
			2
		},
		disabled_func = function (element, elements)
			if Managers.leaderboards:enabled() then
				return element.disabled
			else
				return true
			end
		end,
		on_activate = function (element, this, dt)
			if Managers.leaderboards:enabled() then
				this:reinitialize_scoreboard("local")
			end

			local source_id = WwiseUtils.make_position_auto_source(this._world, this._world_gui_pos:unbox())

			WwiseWorld.trigger_event(this._wwise_world, "menu_select_mono", source_id)
		end
	},
	{
		name = "local_leaderboard_icon",
		type = "bitmap",
		depends_on = "local_leaderboard_button",
		horizontal_alignment = "center",
		animated_offset = 0.05,
		vertical_alignment = "center",
		selectable = true,
		skip_hover_effect = true,
		material_name = "button_icon_local",
		colors = {
			enabled = {
				255,
				255,
				255,
				255
			},
			disabled = {
				255,
				96,
				96,
				96
			}
		},
		color_func = function (element)
			return Managers.leaderboards:current_leaderboard() == "local" and element.colors.enabled or element.colors.disabled
		end,
		offset = {
			0,
			0,
			5
		},
		size = {
			80,
			80,
			3
		},
		disabled_func = function (element, elements)
			return elements[element.depends_on].disabled
		end
	}
}
local reload_template = {
	horizontal_alignment = "center",
	name = "",
	hover = false,
	depends_on = "",
	vertical_alignment = "center",
	template_type = "bitmap",
	material_name = "reload",
	size = {
		125,
		128
	},
	color = {
		128,
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
		if Managers.lobby and (not Managers.lobby.server or #Managers.lobby:lobby_members() > 1) then
			if Managers.lobby.server and Game.startup_commands.standalone then
				return elements[element.depends_on].disabled
			else
				return true
			end
		else
			return elements[element.depends_on].disabled
		end
	end
}
local play_template = {
	horizontal_alignment = "center",
	name = "",
	hover = false,
	depends_on = "",
	vertical_alignment = "center",
	template_type = "bitmap",
	material_name = "play",
	size = {
		125,
		125
	},
	color = {
		128,
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
}
local hover_template = {
	template_type = "bitmap",
	name = "",
	hover = false,
	depends_on = "",
	material_name = "preview_image_selection",
	size = {
		0,
		0
	},
	offset = {
		0,
		0,
		-1
	},
	disabled_func = function (element, elements)
		return elements[element.depends_on].disabled
	end
}
local selectable_elements = {
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
	}
}
local scoreboard_element = {
	depends_on = "",
	name = "scoreboard_element_",
	type = "bitmap",
	horizontal_alignment = "center",
	vertical_alignment = "bottom",
	material_name = "masked_rect",
	color = {
		128,
		255,
		168,
		0
	},
	offset = {
		0,
		-50,
		0
	},
	size = {
		1200,
		50,
		2
	}
}
local scoreboard_position = {
	text = "",
	name = "scoreboard_position_",
	template_type = "small_header_masked",
	depends_on = "",
	horizontal_alignment = "left",
	vertical_alignment = "center",
	offset = {
		20,
		0,
		0
	}
}
local scoreboard_name = {
	text = "",
	name = "scoreboard_name_",
	template_type = "small_header_masked",
	depends_on = "",
	horizontal_alignment = "left",
	vertical_alignment = "center",
	offset = {
		150,
		5,
		0
	}
}
local scoreboard_score = {
	text = "",
	name = "scoreboard_score_",
	template_type = "small_header_masked",
	depends_on = "",
	horizontal_alignment = "right",
	vertical_alignment = "center",
	offset = {
		-30,
		0,
		0
	}
}
local scoreboard_time = {
	text = "",
	name = "scoreboard_time_",
	template_type = "small_header_masked",
	depends_on = "",
	horizontal_alignment = "right",
	vertical_alignment = "center",
	offset = {
		-180,
		0,
		0
	}
}
local scoreboard_headshots = {
	text = "",
	name = "scoreboard_headshots_",
	template_type = "small_header_masked",
	depends_on = "",
	horizontal_alignment = "right",
	vertical_alignment = "center",
	offset = {
		-180,
		0,
		0
	}
}
local scoreboard_kills = {
	text = "",
	name = "scoreboard_kills_",
	template_type = "small_header_masked",
	depends_on = "",
	horizontal_alignment = "right",
	vertical_alignment = "center",
	offset = {
		-330,
		0,
		0
	}
}

return {
	elements = elements,
	scoreboard_elements = scoreboard_elements,
	selectable_elements = selectable_elements,
	reload_template = reload_template,
	play_template = play_template,
	hover_template = hover_template,
	scoreboard_element = scoreboard_element,
	scoreboard_name = scoreboard_name,
	scoreboard_kills = scoreboard_kills,
	scoreboard_headshots = scoreboard_headshots,
	scoreboard_time = scoreboard_time,
	scoreboard_score = scoreboard_score,
	scoreboard_position = scoreboard_position
}
