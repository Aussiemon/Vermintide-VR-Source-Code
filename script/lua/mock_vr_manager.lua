-- chunkname: @script/lua/mock_vr_manager.lua

class("MockVrManager")

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
local Bit = require("bit")
local Keyboard = stingray.Keyboard
local WwiseWorld = stingray.WwiseWorld

MockVrManager.init = function (self, near, far)
	self._world = GLOBAL_WORLD
	self._enabled = false
	self._is_initialized = false
	self._near = near
	self._far = far

	self:initialize(near, far)
end

MockVrManager.hmd_active = function (self)
	return false
end

MockVrManager.initialize = function (self, near, far)
	print(" ******************************************** ")
	print(" Setup Mock Vr ")
	print(" ******************************************** ")

	self._camera_unit = World.spawn_unit(self._world, "core/units/camera")
	self._camera = Unit.camera(self._camera_unit, "camera")
	self._viewport = Application.create_viewport(self._world, "default")

	Camera.set_near_range(self._camera, near)
	Camera.set_far_range(self._camera, far)

	self._freeflight_pose = Matrix4x4Box()
	self._fix_camera = false
	self._debug_camera_unit = World.spawn_unit(self._world, "core/units/camera")
	self._debug_camera = Unit.camera(self._debug_camera_unit, "camera")

	self:enable()
	Window.set_focus()

	self._wwise_world = Wwise.wwise_world(GLOBAL_WORLD)
end

MockVrManager.reinitialize = function (self)
	print(" ******************************************** ")
	print(" Reinitialize Mock Vr ")
	print(" ******************************************** ")

	self._world = GLOBAL_WORLD
	self._camera_unit = World.spawn_unit(self._world, "core/units/camera")
	self._camera = Unit.camera(self._camera_unit, "camera")
	self._viewport = Application.create_viewport(self._world, "default")

	Camera.set_near_range(self._camera, self._near)
	Camera.set_far_range(self._camera, self._far)

	self._debug_camera_unit = World.spawn_unit(self._world, "core/units/camera")
	self._debug_camera = Unit.camera(self._debug_camera_unit, "camera")
	self._tracking_space_unit = nil
	self._freeflight_pose = Matrix4x4Box()
	self._wwise_world = Wwise.wwise_world(GLOBAL_WORLD)
end

MockVrManager.enable = function (self)
	self._enabled = true
end

MockVrManager.update = function (self, dt)
	self:_update_freeflight(dt)

	local pose = self:hmd_world_pose()

	if not self._fix_camera then
		Unit.set_local_pose(self._camera_unit, 1, pose.left_eye)
		PhysicsWorld.set_observer(World.physics_world(self._world), pose.head)
	else
		Unit.set_local_pose(self._debug_camera_unit, 1, pose.left_eye)
	end

	local k_key_id = stingray.Keyboard.button_id("k")
	local isPressed = stingray.Keyboard.pressed(k_key_id)

	if isPressed ~= false then
		self._fix_camera = not self._fix_camera

		if self._fix_camera then
			World.set_frustum_inspector_camera(self._world, self._debug_camera)

			self._old_pose = self._freeflight_pose
		else
			World.set_frustum_inspector_camera(self._world, nil)

			self._freeflight_pose = self._old_pose
		end
	end
end

MockVrManager._update_freeflight = function (self, dt)
	local input = get_motion_input()
	local base_pose = self._freeflight_pose:unbox()
	local q = compute_rotation(base_pose, input, dt)
	local pose = Matrix4x4.from_quaternion(q)

	self._translation_speed = math.max((self._translation_speed or 1) + Mouse.axis(stingray.Mouse.axis_id("wheel")).y * 100 * dt, 0)

	local p = compute_translation(base_pose, input, q, dt, self._translation_speed)

	Matrix4x4.set_translation(pose, p)
	self._freeflight_pose:store(pose)
end

MockVrManager.tracking_space_pose = function (self)
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

MockVrManager.set_tracking_space_pose = function (self, pose)
	print("Moving play area to", pose)

	if not self._tracking_space_pose then
		self._tracking_space_pose = Matrix4x4Box()
	end

	self._tracking_space_pose:store(pose)

	self._tracking_space_unit = nil
	self._tracking_space_unit_node = nil
end

MockVrManager.do_teleport = function (self, unit)
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

MockVrManager.set_tracking_space_unit = function (self, unit, node_name)
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

MockVrManager.is_hmd_inside_playable_area = function (self)
	local pose = self._freeflight_pose:unbox()
	local translation = Matrix4x4.translation(pose)
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

MockVrManager.disable = function (self)
	self._enabled = false
end

MockVrManager.is_enabled = function (self)
	return self._enabled
end

MockVrManager.is_hmd_tracked = function (self)
	return false
end

MockVrManager.destroy = function (self)
	self:disable()
	World.destroy_unit(self._world, self._camera_unit)
	World.destroy_unit(self._world, self._debug_camera_unit)
	Application.destroy_viewport(self._world, self._viewport)

	self._is_initialized = false
end

MockVrManager.hmd_local_pose = function (self)
	local pose = self._freeflight_pose:unbox()

	return {
		forward = Matrix4x4.forward(pose),
		left_eye = pose,
		right_eye = pose,
		head = pose
	}
end

MockVrManager.hmd_world_pose = function (self)
	local base_pose = self._freeflight_pose:unbox()
	local pose = Matrix4x4.multiply(base_pose, self:tracking_space_pose())

	return {
		forward = Matrix4x4.forward(pose),
		left_eye = pose,
		right_eye = pose,
		head = pose
	}
end

MockVrManager.render = function (self, shading_environment, shading_callback)
	local shading_environment = shading_environment or World.get_data(self._world, "shading_environment")
	local shading_callback = shading_callback or World.get_data(self._world, "shading_callback")

	Application.render_world(self._world, self._camera, self._viewport, shading_environment)

	if shading_callback then
		shading_callback(self._world, shading_environment)
	end
end

MockVrManager.create_vr_controller = function (self, world, gameplay_extensions)
	self._vr_controller = VrControllerMouse:new(world, self._camera_unit, gameplay_extensions)

	return self._vr_controller
end

MockVrManager.get_vr_controller = function (self)
	return self._vr_controller
end

function get_motion_input()
	local pan = stingray.Mouse.axis(stingray.Mouse.axis_id("mouse"))
	local move = Vector3(Keyboard.button(Keyboard.button_id("d")) - Keyboard.button(Keyboard.button_id("a")), Keyboard.button(Keyboard.button_id("w")) - Keyboard.button(Keyboard.button_id("s")), Keyboard.button(Keyboard.button_id("e")) - Keyboard.button(Keyboard.button_id("q")))

	return {
		move = move,
		pan = pan
	}
end

function compute_rotation(base_pose, input, dt)
	local q_original = Matrix4x4.rotation(base_pose)
	local m_original = Matrix4x4.from_quaternion(q_original)
	local q_identity = Quaternion.identity()
	local q_yaw = Quaternion(Vector3(0, 0, 1), -Vector3.x(input.pan) * 0.2 * dt)
	local q_pitch = Quaternion(Matrix4x4.x(m_original), -Vector3.y(input.pan) * 0.1 * dt)
	local q_frame = Quaternion.multiply(q_yaw, q_pitch)
	local q_new = Quaternion.multiply(q_frame, q_original)

	return q_new
end

function compute_translation(base_pose, input, q, dt, translation_speed)
	local input_move = input.move
	local pose = Matrix4x4.from_quaternion(q)
	local pos = Matrix4x4.translation(base_pose)
	local frame_vel

	frame_vel = Vector3(0, 0, 0)

	local translation_speed = Vector3(1.5, 1.5, 1.5) * (translation_speed or 1)

	if Keyboard.button(Keyboard.button_id("left shift")) == 1 then
		translation_speed = translation_speed * 5
	end

	local frame_move = Vector3.multiply_elements(input_move, translation_speed) * dt + frame_vel
	local move = stingray.Matrix4x4.transform(pose, frame_move)

	return pos + move
end
