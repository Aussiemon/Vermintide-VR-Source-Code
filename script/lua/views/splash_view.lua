-- chunkname: @script/lua/views/splash_view.lua

require("script/lua/simple_gui/simple_gui")
require("foundation/script/util/math")

local templates = require("script/lua/simple_gui/gui_templates")

class("SplashView")

local elements = {
	{
		name = "background",
		template_type = "rect",
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
		video_name = "fatshark_splash",
		name = "fatshark_splash",
		depends_on = "background",
		resource_name = "video/fatshark_splash",
		stop_sound_event = "Stop_fatshark_logo_sound",
		template_type = "video",
		disabled = false,
		start_sound_event = "Play_fatshark_logo_sound",
		offset = {
			0,
			0,
			10
		},
		on_next_splash = function (element, this)
			World.destroy_video_player(this._world, element.video_player)

			element.video_player = nil
		end
	},
	{
		material_name = "gw_splash",
		name = "splash_gw",
		template_type = "splash",
		depends_on = "background",
		disabled = true,
		offset = {
			0,
			0,
			10
		},
		color = {
			0,
			255,
			255,
			255
		}
	},
	{
		material_name = "intel",
		name = "intel",
		template_type = "bitmap",
		depends_on = "background",
		disabled = true,
		offset = {
			0,
			0,
			10
		},
		size = {
			720,
			720
		},
		color = {
			0,
			255,
			255,
			255
		}
	},
	{
		material_name = "autodesk_splash",
		name = "splash_autodesk",
		template_type = "splash",
		depends_on = "background",
		disabled = true,
		offset = {
			0,
			0,
			10
		},
		color = {
			0,
			255,
			255,
			255
		}
	},
	{
		material_name = "partners",
		name = "partners",
		template_type = "bitmap",
		depends_on = "background",
		disabled = true,
		offset = {
			0,
			0,
			10
		},
		size = {
			1920,
			1080
		},
		color = {
			0,
			255,
			255,
			255
		}
	},
	{
		material_name = "vermintide_logo_transparent",
		name = "partners",
		template_type = "bitmap",
		depends_on = "background",
		disabled = true,
		offset = {
			0,
			0,
			10
		},
		size = {
			1920,
			1080
		},
		color = {
			0,
			255,
			255,
			255
		}
	}
}

for _, element in ipairs(elements) do
	elements[element.name] = element
end

local splash_settings = {
	static = 2,
	fade_in = 0.75,
	total_timer = 3.5,
	fade_out = 0.75,
	splashes = {
		"fatshark_splash",
		"splash_gw",
		"intel",
		"splash_autodesk",
		"partners"
	}
}

SplashView.init = function (self)
	if not GameSettingsDevelopment.skip_splashes then
		self:_setup_gui()
		self:_fade_out()
	else
		self._splashes_done = true
	end

	self._timer = 0
	self._splash_index = 1
	self._any_pressed_delay = 0
	self._wwise_world = Wwise.wwise_world(GLOBAL_WORLD)
	self._vr_buttons = {
		SteamVR.BUTTON_MENU,
		SteamVR.BUTTON_TOUCH,
		SteamVR.BUTTON_TRIGGER,
		SteamVR.BUTTON_GRIP,
		SteamVR.BUTTON_SYSTEM,
		SteamVR.BUTTON_TOUCH_UP,
		SteamVR.BUTTON_TOUCH_DOWN,
		SteamVR.BUTTON_TOUCH_LEFT,
		SteamVR.BUTTON_TOUCH_RIGHT
	}
end

SplashView._fade_out = function (self)
	Managers.transition:force_fade_in()
	Managers.transition:fade_out(1)
end

SplashView._fade_in = function (self)
	self._splashes_done = true
end

SplashView._setup_gui = function (self)
	self._world = GLOBAL_WORLD
	self._size = {
		1000,
		1000
	}
	self._gui = World.create_world_gui(self._world, Matrix4x4.identity(), self._size[1], self._size[2], "material", "gui/atlas_materials/splash_atlas", "material", "video/fatshark_splash", "material", "gui/single_textures/partners", "material", "gui/single_textures/gui", "immediate")

	print("SplashView -> World.create_world_gui")
end

SplashView.update = function (self, dt, t)
	if GameSettingsDevelopment.skip_splashes then
		return
	end

	if not self._hmd_pose then
		local hmd_pose = Managers.vr:hmd_world_pose()
		local forward = hmd_pose.forward

		forward.z = 0
		self._starting_rotation = QuaternionBox(Quaternion.look(forward, Vector3.up()))
		self._hmd_pose = Matrix4x4Box(hmd_pose.head)
	else
		self:_update_gui_position(dt)
		self:_update_splashes(dt)
		self:_update_gui(dt)
	end
end

SplashView._update_gui_position = function (self, dt, t)
	local hmd_pose = self._hmd_pose and self._hmd_pose:unbox()

	if hmd_pose and Matrix4x4.is_valid(hmd_pose) then
		local gui_pose = Matrix4x4.identity()
		local animated_gui_pose = Matrix4x4.identity()
		local rot = self._starting_rotation and self._starting_rotation:unbox() or Quaternion.identity()

		Matrix4x4.set_rotation(gui_pose, rot)

		local offset = Quaternion.rotate(rot, Vector3(-1.1, 1.5, -0.6))

		Matrix4x4.set_translation(gui_pose, Matrix4x4.translation(hmd_pose) + offset)
		Gui.move(self._gui, gui_pose)
	end
end

SplashView._update_splashes = function (self, dt)
	if self._splash_index > #splash_settings.splashes then
		if not self._fading_in then
			self:_fade_in()
		end

		return
	end

	local current_splash = splash_settings.splashes[self._splash_index]
	local current_element = elements[current_splash]
	local wait = false

	if current_element.type == "texture_atlas" or current_element.type == "bitmap" then
		local alpha, percentage = 0, 0

		if self._timer <= splash_settings.fade_in then
			percentage = self._timer / splash_settings.fade_in
			alpha = math.lerp(0, 255, percentage)
		elseif self._timer < splash_settings.fade_in + splash_settings.static then
			alpha = 255
		elseif self._timer >= splash_settings.static + splash_settings.fade_in and self._timer <= splash_settings.total_timer then
			percentage = (self._timer - (splash_settings.static + splash_settings.fade_in)) / splash_settings.fade_out
			alpha = math.lerp(255, 0, percentage)
		else
			alpha = 0
		end

		current_element.color[1] = alpha
	elseif current_element.type == "video" then
		local alpha = 0

		wait = true

		if current_element.start_sound_event and not self._playing_sound then
			local hmd_pose = Managers.vr:hmd_world_pose()
			local head_pose = hmd_pose.head
			local head_pos = Matrix4x4.translation(head_pose)
			local sound_pos = head_pos + hmd_pose.forward * 1.5

			self._source_id = WwiseUtils.make_position_auto_source(self._world, sound_pos)
			self._sound_id = WwiseWorld.trigger_event(self._wwise_world, current_element.start_sound_event, self._source_id)
			self._stop_sound_event = current_element.stop_sound_event
			self._playing_sound = true
		end

		if self._timer < splash_settings.fade_in then
			local percentage = self._timer / splash_settings.fade_in

			alpha = math.lerp(0, 255, percentage)
		elseif current_element.video_done then
			self._playing_sound = WwiseWorld.is_playing(self._wwise_world, self._sound_id)

			if current_element.stop_sound_event and self._playing_sound then
				WwiseWorld.trigger_event(self._wwise_world, current_element.stop_sound_event, self._source_id)

				self._playing_sound = false
			end

			alpha = 0
			wait = false
		else
			alpha = 255
		end

		current_element.color[1] = alpha
	end

	self._timer = self._timer + dt

	if self._timer > splash_settings.total_timer and not wait or self:_any_pressed(dt) then
		current_element.disabled = true

		if current_element.on_next_splash then
			current_element.on_next_splash(current_element, self)
		end

		current_element.color[1] = 0
		self._splash_index = self._splash_index + 1
		self._playing_sound = WwiseWorld.is_playing(self._wwise_world, self._sound_id)

		if self._playing_sound and self._stop_sound_event then
			WwiseWorld.trigger_event(self._wwise_world, self._stop_sound_event, self._source_id)

			self._stop_sound_event = nil
			self._playing_sound = nil
		end

		local new_splash = splash_settings.splashes[self._splash_index]

		if new_splash then
			elements[new_splash].disabled = false
			self._timer = 0
		end
	end
end

SplashView._any_pressed = function (self, dt)
	self._any_pressed_delay = self._any_pressed_delay - dt

	if self._any_pressed_delay > 0 then
		return
	end

	local any_pressed = false

	for controller_index = 0, 1 do
		for _, button_index in pairs(self._vr_buttons) do
			if SteamVR.controller_released(controller_index, button_index) then
				any_pressed = true
			end
		end
	end

	any_pressed = Mouse.any_released() or Keyboard.any_released() or any_pressed

	if any_pressed then
		self._any_pressed_delay = 0.2
	end

	return any_pressed
end

SplashView._update_gui = function (self, dt)
	for _, element in ipairs(elements) do
		SimpleGui.update_element(self._gui, element, elements, templates, self._world)
	end

	for _, element in ipairs(elements) do
		SimpleGui.render_element(self._gui, element)
	end
end

SplashView._render_gui = function (self, dt)
	Gui.rect(self._gui, Vector3(0, 0, 0), Vector2(self._size[1], self._size[2]), Color(255, 255, 255))
end

SplashView.destroy = function (self)
	if not GameSettingsDevelopment.skip_splashes then
		print("SplashView -> World.destroy_gui")
		World.destroy_gui(self._world, self._gui)
	end
end

SplashView.is_done = function (self)
	return self._splashes_done
end
