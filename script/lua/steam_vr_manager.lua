-- chunkname: @script/lua/steam_vr_manager.lua

class("SteamVrManager")

local Application = stingray.Application
local Window = stingray.Window
local Viewport = stingray.Viewport
local World = stingray.World
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local Quaternion = stingray.Quaternion
local Matrix4x4 = stingray.Matrix4x4
local Matrix4x4Box = stingray.Matrix4x4Box
local Camera = stingray.Camera
local ShadingEnvironment = stingray.ShadingEnvironment
local SteamVR = stingray.SteamVR
local Bit = require("bit")
local WwiseWorld = stingray.WwiseWorld

SteamVrManager.init = function (self, near, far, hmd_rt)
	self._world = GLOBAL_WORLD
	self._enabled = false
	self._is_initialized = false
	self._blit_world = Application.new_world()

	local shading_env = World.create_shading_environment(self._blit_world, "core/stingray_renderer/environments/midday/midday")

	World.set_data(self._blit_world, "shading_environment", shading_env)

	self._near = near
	self._far = far
	self._hmd_rt = hmd_rt

	return self:initialize(near, far, hmd_rt)
end

SteamVrManager.hmd_active = function (self)
	return true
end

SteamVrManager.initialize = function (self, near, far, hmd_rt)
	print(" ******************************************** ")
	print(" Setup Steam Vr ")
	print(" ******************************************** ")

	self._vr_main_camera_unit = World.spawn_unit(self._world, "core/units/camera")
	self._vr_main_camera = Unit.camera(self._vr_main_camera_unit, "camera")

	Camera.set_near_range(self._vr_main_camera, near)
	Camera.set_far_range(self._vr_main_camera, far)

	self._is_initialized = SteamVR.initialize(self._hmd_rt, self._vr_main_camera, self._world)

	if not self._is_initialized then
		World.destroy_unit(self._world, self._vr_main_camera_unit)
		Application.release_world(self._blit_world)

		return
	end

	self._vr_blit_camera_unit = World.spawn_unit(self._blit_world, "core/units/camera")
	self._vr_blit_camera = Unit.camera(self._vr_blit_camera_unit, "camera")
	self._vr_viewport_main = Application.create_viewport(self._world, "vr_main")
	self._vr_viewport_blit = Application.create_viewport(self._blit_world, "vr_blit")

	local size_x, size_y = Application.render_setting("vr_hmd_resolution")
	local scale = Application.render_setting("vr_target_scale")

	self._vr_window = Window.open({
		visible = false,
		width = size_x * scale,
		height = size_y * scale
	})

	Camera.set_mode(self._vr_blit_camera, Camera.STEREO)
	Camera.set_vertical_fov(self._vr_blit_camera, Camera.vertical_fov(self._vr_blit_camera, 1), 2)
	self:enable()
	Window.set_focus()

	self._wwise_world = Wwise.wwise_world(GLOBAL_WORLD)
end

SteamVrManager.reinitialize = function (self)
	print(" ******************************************** ")
	print(" Reinitialize Steam Vr ")
	print(" ******************************************** ")

	self._world = GLOBAL_WORLD
	self._vr_main_camera_unit = World.spawn_unit(self._world, "core/units/camera")
	self._vr_main_camera = Unit.camera(self._vr_main_camera_unit, "camera")

	Camera.set_near_range(self._vr_main_camera, self._near)
	Camera.set_far_range(self._vr_main_camera, self._far)
	SteamVR.set_camera(self._vr_main_camera, self._world)

	self._vr_blit_camera_unit = World.spawn_unit(self._blit_world, "core/units/camera")
	self._vr_blit_camera = Unit.camera(self._vr_blit_camera_unit, "camera")
	self._vr_viewport_main = Application.create_viewport(self._world, "vr_main")
	self._vr_viewport_blit = Application.create_viewport(self._blit_world, "vr_blit")

	Camera.set_mode(self._vr_blit_camera, Camera.STEREO)
	Camera.set_vertical_fov(self._vr_blit_camera, Camera.vertical_fov(self._vr_blit_camera, 1), 2)
	self:set_tracking_space_unit(nil)

	self._wwise_world = Wwise.wwise_world(GLOBAL_WORLD)
end

SteamVrManager.world = function (self)
	return self._world
end

SteamVrManager.enable = function (self)
	if not SteamVR then
		return
	end

	if not self or not self._is_initialized then
		return
	end

	self._enabled = true

	Application.set_render_setting("vr_enabled", "true")
	Application.set_render_setting("vr_mask_enabled", "true")
end

SteamVrManager.update = function (self)
	Profiler.start("SteamVrManager:update()")

	local tracking_pose = self:tracking_space_pose()

	SteamVR.set_tracking_space_pose(tracking_pose)

	local pose = self:hmd_world_pose()

	PhysicsWorld.set_observer(World.physics_world(self._world), pose.head)
	Profiler.stop("SteamVrManager:update()")
end

SteamVrManager.tracking_space_pose = function (self)
	if self._tracking_space_pose then
		return self._tracking_space_pose:unbox()
	elseif self._tracking_space_unit then
		local pose = Unit.world_pose(self._tracking_space_unit, self._tracking_space_unit_node)

		Matrix4x4.set_scale(pose, Vector3(1, 1, 1))

		return pose
	else
		return Matrix4x4.identity()
	end
end

SteamVrManager.do_teleport = function (self, unit)
	if self:is_enabled() then
		if not Unit.alive(self._last_teleported_unit) then
			self._last_teleported_unit = nil
		end

		if self._last_teleported_unit then
			if self._last_teleported_unit == unit then
				return
			end

			Unit.flow_event(self._last_teleported_unit, "teleported_from")
		end

		self._last_teleported_unit = unit

		Managers.transition:fade_in(10, function ()
			self:set_tracking_space_unit(unit)
			Managers.transition:fade_out(10)
			Unit.flow_event(unit, "teleported_to")
		end)
		WwiseWorld.trigger_event(self._wwise_world, "Play_player_shadow_teleport", unit)
	end
end

SteamVrManager.set_tracking_space_pose = function (self, pose)
	print("Moving play area to", pose)

	if not self._tracking_space_pose then
		self._tracking_space_pose = Matrix4x4Box()
	end

	self._tracking_space_pose:store(pose)

	self._tracking_space_unit = nil
	self._tracking_space_unit_node = nil
end

SteamVrManager.set_tracking_space_unit = function (self, unit, node_name)
	print("Moving play area to", unit, node_name)

	self._tracking_space_unit = unit

	local node = 1

	if node_name and Unit.has_node(unit, node_name) then
		node = Unit.node(unit, node_name)
	end

	self._tracking_space_unit_node = node
	self._tracking_space_pose = nil
	self._last_teleported_unit = unit
end

SteamVrManager.is_hmd_inside_playable_area = function (self)
	local head, _, _ = SteamVR.hmd_local_pose()
	local translation = Matrix4x4.translation(head)
	local x, y, z = math.abs(translation.x), math.abs(translation.y), math.abs(translation.z)
	local is_inside = true

	if x > 1.5 then
		is_inside = false
	end

	if y > 1.5 then
		is_inside = false
	end

	if z > 2.5 then
		is_inside = false
	end

	return is_inside
end

SteamVrManager.disable = function (self)
	if not SteamVR then
		return
	end

	if not self or not self._is_initialized then
		return
	end

	self._enabled = false

	Application.set_render_setting("vr_enabled", "false")
	Application.set_render_setting("vr_mask_enabled", "false")
end

SteamVrManager.is_enabled = function (self)
	return self._enabled
end

SteamVrManager.is_hmd_tracked = function (self)
	if not SteamVR then
		return false
	end

	if not self or not self._is_initialized then
		return false
	end

	return SteamVR.is_hmd_tracked()
end

SteamVrManager.destroy = function (self)
	if not SteamVR then
		return
	end

	if not self then
		return
	end

	if self._vr_window then
		Window.close(self._vr_window)

		self._vr_window = nil
	end

	if not self._is_initialized then
		return
	end

	self:disable()
	SteamVR.shutdown()
	World.destroy_unit(self._world, self._vr_main_camera_unit)
	World.destroy_unit(self._blit_world, self._vr_blit_camera_unit)
	Application.destroy_viewport(self._world, self._vr_viewport_main)
	Application.destroy_viewport(self._blit_world, self._vr_viewport_blit)
	Application.release_world(self._blit_world)

	self._is_initialized = false
end

SteamVrManager.hmd_local_pose = function (self)
	if not SteamVR then
		return nil
	end

	if not self or not self._is_initialized then
		return nil
	end

	head, left, right = SteamVR.hmd_local_pose()

	return {
		forward = Matrix4x4.forward(head),
		left_eye = left,
		right_eye = right,
		head = head
	}
end

SteamVrManager.hmd_world_pose = function (self)
	if not SteamVR then
		return nil
	end

	if not self or not self._is_initialized then
		return nil
	end

	Profiler.start("SteamVR.hmd_world_pose()")

	local head, left, right = SteamVR.hmd_world_pose()

	Profiler.stop("SteamVR.hmd_world_pose()")

	return {
		forward = Matrix4x4.forward(head),
		left_eye = left,
		right_eye = right,
		head = head
	}
end

SteamVrManager.render = function (self, shading_environment, shading_callback)
	local shading_environment = shading_environment or World.get_data(self._world, "shading_environment")
	local shading_callback = shading_callback or World.get_data(self._world, "shading_callback")

	if not SteamVR then
		return
	end

	if not self or not self._enabled then
		return
	end

	Application.render_world(self._world, self._vr_main_camera, self._vr_viewport_main, shading_environment, self._vr_window)
	Application.render_world(self._blit_world, self._vr_blit_camera, self._vr_viewport_blit, World.get_data(self._blit_world, "shading_environment"))

	if shading_callback then
		shading_callback(self._world, shading_environment)
	end
end

SteamVrManager.create_vr_controller = function (self, world, gameplay_extensions)
	self._vr_controller = VrController:new(world, gameplay_extensions)

	return self._vr_controller
end

SteamVrManager.get_vr_controller = function (self)
	return self._vr_controller
end
