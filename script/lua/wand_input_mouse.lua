-- chunkname: @script/lua/wand_input_mouse.lua

require("foundation/script/util/table")
require("foundation/script/util/class")

local World = stingray.World
local Mouse = stingray.Mouse
local Keyboard = stingray.Keyboard
local Unit = stingray.Unit
local Matrix4x4 = stingray.Matrix4x4
local Quaternion = stingray.Quaternion
local QuaternionBox = stingray.QuaternionBox
local Vector3 = stingray.Vector3

class("WandInputMouse")

local function mouse_button_state(button_name)
	return Mouse.button(Mouse.button_id(button_name))
end

local function keyboard_button_state(button_name)
	return Keyboard.button(Keyboard.button_id(button_name))
end

local function unassigned_button_state()
	return 0
end

WandInputMouse.BUTTONS_LEFT_HAND = {
	trigger = {
		key = "left",
		released = false,
		state = 0,
		pressed = false,
		state_func = mouse_button_state
	},
	menu = {
		released = false,
		pressed = false,
		state = 0,
		state_func = unassigned_button_state
	},
	grip = {
		key = "z",
		released = false,
		state = 0,
		pressed = false,
		state_func = keyboard_button_state
	},
	touch = {
		released = false,
		pressed = false,
		state = 0,
		state_func = unassigned_button_state
	},
	system = {
		released = false,
		pressed = false,
		state = 0,
		state_func = unassigned_button_state
	},
	toggle_freeze = {
		key = "f1",
		released = false,
		state = 0,
		pressed = false,
		state_func = keyboard_button_state
	},
	touch_up = {
		key = "f",
		released = false,
		state = 0,
		pressed = false,
		state_func = keyboard_button_state
	},
	touch_down = {
		key = "v",
		released = false,
		state = 0,
		pressed = false,
		state_func = keyboard_button_state
	},
	touch_left = {
		released = false,
		pressed = false,
		state = 0,
		state_func = unassigned_button_state
	},
	touch_right = {
		released = false,
		pressed = false,
		state = 0,
		state_func = unassigned_button_state
	}
}
WandInputMouse.BUTTONS_RIGHT_HAND = {
	trigger = {
		key = "right",
		released = false,
		state = 0,
		pressed = false,
		state_func = mouse_button_state
	},
	menu = {
		key = "middle",
		released = false,
		state = 0,
		pressed = false,
		state_func = mouse_button_state
	},
	grip = {
		key = "x",
		released = false,
		state = 0,
		pressed = false,
		state_func = keyboard_button_state
	},
	touch = {
		released = false,
		pressed = false,
		state = 0,
		state_func = unassigned_button_state
	},
	system = {
		key = "tab",
		released = false,
		state = 0,
		pressed = false,
		state_func = keyboard_button_state
	},
	toggle_freeze = {
		key = "f2",
		released = false,
		state = 0,
		pressed = false,
		state_func = keyboard_button_state
	},
	touch_up = {
		key = "g",
		released = false,
		state = 0,
		pressed = false,
		state_func = keyboard_button_state
	},
	touch_down = {
		key = "b",
		released = false,
		state = 0,
		pressed = false,
		state_func = keyboard_button_state
	},
	touch_left = {
		released = false,
		pressed = false,
		state = 0,
		state_func = unassigned_button_state
	},
	touch_right = {
		released = false,
		pressed = false,
		state = 0,
		state_func = unassigned_button_state
	}
}

WandInputMouse.init = function (self, controller_index, world, camera_unit, wand_hand)
	self._controller_index = controller_index

	if wand_hand == "right" then
		self._buttons = table.clone(WandInputMouse.BUTTONS_RIGHT_HAND)
	else
		self._buttons = table.clone(WandInputMouse.BUTTONS_LEFT_HAND)
	end

	self._world = world
	self._camera_unit = camera_unit
	self._wand_hand = wand_hand
	self._frozen = false
	self._frozen_pose = Matrix4x4Box()
	self._additional_wand_rotation_offset = QuaternionBox()
end

WandInputMouse.update = function (self, dt)
	local buttons = self._buttons

	for button_name, data in pairs(buttons) do
		data.pressed = false
		data.released = false

		local state = data.state_func(data.key)

		data.held = state ~= 0

		if data.state == 0 and state ~= 0 then
			data.pressed = true
		elseif data.state ~= 0 and state == 0 then
			data.released = true
		end

		data.state = state
	end

	if buttons.toggle_freeze.pressed then
		self._frozen = not self._frozen

		self._frozen_pose:store(self:pose())
	end
end

WandInputMouse.set_wand_unit = function (self, unit)
	self._wand_unit = unit
end

WandInputMouse.wand_hand = function (self)
	return self._wand_hand
end

WandInputMouse.wand_unit_position = function (self, node_name)
	local unit = self._wand_unit
	local node_index = node_name and Unit.node(unit, node_name) or 1

	return Unit.world_position(unit, node_index)
end

WandInputMouse.wand_unit_rotation = function (self, node_name)
	local unit = self._wand_unit
	local node_index = node_name and Unit.node(unit, node_name) or 1

	return Unit.world_rotation(unit, node_index)
end

WandInputMouse.amount_pressed = function (self, button_name)
	return 0
end

WandInputMouse.held = function (self, button_name, consume)
	if consume then
		local value = self._buttons[button_name].held

		self._buttons[button_name].held = nil

		return value
	else
		return self._buttons[button_name].held
	end
end

WandInputMouse.pressed = function (self, button_name, consume)
	if consume then
		local value = self._buttons[button_name].pressed

		self._buttons[button_name].pressed = nil

		return value
	else
		return self._buttons[button_name].pressed
	end
end

WandInputMouse.released = function (self, button_name, consume)
	if consume then
		local value = self._buttons[button_name].released

		self._buttons[button_name].released = nil

		return value
	else
		return self._buttons[button_name].released
	end
end

local function controller_world_pose(camera_unit, wand_hand)
	local pose = Matrix4x4.copy(Unit.world_pose(camera_unit, 1))
	local position = Matrix4x4.translation(pose)
	local position_offset = Matrix4x4.forward(pose) * 2

	position_offset = position_offset + Matrix4x4.right(pose) * (wand_hand == "left" and -0.8 or 0.3)

	local position_final = position + position_offset

	Matrix4x4.set_translation(pose, position_final)

	local rotation = Matrix4x4.rotation(pose)
	local rotation_offset_left = Quaternion.axis_angle(Vector3.right(), math.pi * 0.5)
	local rotation_offset_right = Quaternion.axis_angle(Vector3.right(), math.pi * 0.15)
	local rotation_final = wand_hand == "left" and Quaternion.multiply(rotation, rotation_offset_left) or Quaternion.multiply(rotation, rotation_offset_right)

	Matrix4x4.set_rotation(pose, rotation_final)

	return pose
end

WandInputMouse.position = function (self)
	local pose

	if self._frozen then
		pose = self._frozen_pose:unbox()
	else
		pose = controller_world_pose(self._camera_unit, self._wand_hand)
	end

	return Matrix4x4.translation(pose)
end

WandInputMouse.pose = function (self)
	if self._frozen then
		return self._frozen_pose:unbox()
	else
		return controller_world_pose(self._camera_unit, self._wand_hand)
	end
end

WandInputMouse.forward = function (self)
	local pose = Unit.world_pose(self._camera_unit, 1)
	local rotation = Matrix4x4.rotation(pose)

	return Quaternion.rotate(rotation, Vector3.forward())
end

WandInputMouse.controller_index = function (self)
	return self._controller_index
end

WandInputMouse.controller_value = function (self, button_name)
	return 0, 0
end

WandInputMouse.vibrate = function (self, duration, strength)
	return
end

WandInputMouse.trigger_feedback = function (self, duration)
	return
end

WandInputMouse.is_tracked = function (self)
	return false
end

WandInputMouse.set_additional_rotation_offset = function (self, offset)
	self._additional_wand_rotation_offset:store(offset or Quaternion.from_euler_angles_xyz(0, 0, 0))
end

WandInputMouse.get_additional_rotation_offset = function (self)
	return self._additional_wand_rotation_offset:unbox()
end
