-- chunkname: @script/lua/managers/sizzle_reel/sizzle_reel_manager.lua

class("SizzleReelManager")

local VIDEO_RESOURCE = "video/sizzle_reel"
local VIDEO_MATERIAL = "sizzle_reel_offscreen"
local SIZZLE_REEL_TIMER = 60

SizzleReelManager.init = function (self)
	self:_setup_world()
	self:_reset_variables()
	self:_setup_vr_buttons()
end

SizzleReelManager._setup_world = function (self)
	self._world = Application.new_world()

	local shading_env = World.create_shading_environment(self._world, "core/stingray_renderer/environments/midday/midday")

	World.set_data(self._world, "shading_environment", shading_env)

	self._camera_unit = World.spawn_unit(self._world, "core/units/camera")
	self._camera = Unit.camera(self._camera_unit, "camera")
	self._viewport = Application.create_viewport(self._world, "overlay")
	self._gui = World.create_screen_gui(self._world, "material", "video/sizzle_reel", "immediate")
end

SizzleReelManager._setup_vr_buttons = function (self)
	if not rawget(_G, "SteamVR") then
		return
	end

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

SizzleReelManager._reset_variables = function (self)
	self._right_controller_pos = Vector3Box(0, 0, 0)
	self._left_controller_pos = Vector3Box(0, 0, 0)
	self._hmd_pos = Vector3Box(0, 0, 0)
	self._sizzle_reel_timer = 0
	self._current_state = "update_idle"
end

SizzleReelManager.update = function (self, dt)
	self[self._current_state](self, dt)
	World.update(self._world, dt)
end

SizzleReelManager.render = function (self, dt)
	if self._video_player then
		Application.render_world(self._world, self._camera, self._viewport, World.get_data(self._world, "shading_environment"))
	end
end

SizzleReelManager.update_idle = function (self, dt)
	if self._video_player then
		World.destroy_video_player(self._world, self._video_player)

		self._video_player = nil
	end

	if not self:_any_pressed() then
		self._sizzle_reel_timer = self._sizzle_reel_timer + dt
	else
		self._sizzle_reel_timer = 0
	end

	if self._sizzle_reel_timer >= SIZZLE_REEL_TIMER then
		self._current_state = "update_playing"
	end
end

SizzleReelManager.update_playing = function (self, dt)
	if not self._video_player then
		self._video_player = World.create_video_player(self._world, VIDEO_RESOURCE, true)
	else
		local w, h = Gui.resolution()

		Gui.video(self._gui, VIDEO_MATERIAL, self._video_player, Vector2(0, 0, 999), Vector2(w, h))
	end

	if self:_any_pressed() then
		self._current_state = "update_idle"
		self._sizzle_reel_timer = 0
	end
end

SizzleReelManager._any_pressed = function (self)
	if rawget(_G, "SteamVR") then
		for controller_index = 0, 1 do
			for _, button_index in pairs(self._vr_buttons) do
				if SteamVR.controller_held(controller_index, button_index) then
					-- Nothing
				end
			end
		end

		local hmd_pose = SteamVR.hmd_world_pose()
		local right_controller_world_pose = SteamVR.controller_world_pose(0)
		local left_controller_world_pose = SteamVR.controller_world_pose(1)
		local hmd_pos = Matrix4x4.translation(hmd_pose)
		local right_pos = Matrix4x4.translation(right_controller_world_pose)
		local left_pos = Matrix4x4.translation(left_controller_world_pose)
		local old_hmd_pos = self._hmd_pos:unbox()
		local old_right_pos = self._right_controller_pos:unbox()
		local old_left_pos = self._left_controller_pos:unbox()
		local moved_hmd = Vector3.distance_squared(old_hmd_pos, hmd_pos) > 5.625e-05
		local moved_right = Vector3.distance_squared(old_right_pos, right_pos) > 5.625e-05
		local moved_left = Vector3.distance_squared(old_left_pos, left_pos) > 5.625e-05

		self._hmd_pos = Vector3Box(hmd_pos)
		self._right_controller_pos = Vector3Box(right_pos)
		self._left_controller_pos = Vector3Box(left_pos)

		if moved_hmd or moved_right or moved_left then
			return true
		end
	end

	return Mouse.any_pressed() or Keyboard.any_pressed()
end

SizzleReelManager.destroy = function (self)
	if self._video_player then
		World.destroy_video_player(self._world, self._video_player)
	end

	World.destroy_gui(self._world, self._gui)

	self._gui = nil

	World.destroy_unit(self._world, self._camera_unit)
	Application.release_world(self._world)
end
