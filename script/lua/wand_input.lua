-- chunkname: @script/lua/wand_input.lua

require("foundation/script/util/table")
require("foundation/script/util/class")

local Bit = require("bit")
local SteamVR = stingray.SteamVR
local Matrix4x4 = stingray.Matrix4x4
local Quaternion = stingray.Quaternion
local QuaternionBox = stingray.QuaternionBox
local Vector3 = stingray.Vector3
local Unit = stingray.Unit

class("WandInput")

WandInput.BUTTONS = {
	[SteamVR.BUTTON_MENU] = {
		pressed = false,
		released = false,
		state = 0
	},
	[SteamVR.BUTTON_TOUCH] = {
		pressed = false,
		released = false,
		state = 0
	},
	[SteamVR.BUTTON_TRIGGER] = {
		pressed = false,
		released = false,
		state = 0
	},
	[SteamVR.BUTTON_GRIP] = {
		pressed = false,
		released = false,
		state = 0
	},
	[SteamVR.BUTTON_SYSTEM] = {
		pressed = false,
		released = false,
		state = 0
	},
	[SteamVR.BUTTON_TOUCH_UP] = {
		pressed = false,
		released = false,
		state = 0
	},
	[SteamVR.BUTTON_TOUCH_DOWN] = {
		pressed = false,
		released = false,
		state = 0
	},
	[SteamVR.BUTTON_TOUCH_LEFT] = {
		pressed = false,
		released = false,
		state = 0
	},
	[SteamVR.BUTTON_TOUCH_RIGHT] = {
		pressed = false,
		released = false,
		state = 0
	}
}
WandInput.INDICES = {
	menu = SteamVR.BUTTON_MENU,
	touch = SteamVR.BUTTON_TOUCH,
	trigger = SteamVR.BUTTON_TRIGGER,
	grip = SteamVR.BUTTON_GRIP,
	system = SteamVR.BUTTON_SYSTEM,
	touch_up = SteamVR.BUTTON_TOUCH_UP,
	touch_down = SteamVR.BUTTON_TOUCH_DOWN,
	touch_left = SteamVR.BUTTON_TOUCH_LEFT,
	touch_right = SteamVR.BUTTON_TOUCH_RIGHT
}

for k, v in pairs(WandInput.INDICES) do
	WandInput.INDICES[v] = k
end

WandInput.init = function (self, controller_index, wand_hand)
	self._controller_index = controller_index
	self._buttons = table.clone(WandInput.BUTTONS)
	self._wand_hand = wand_hand
	self._additional_wand_rotation_offset = QuaternionBox()
end

WandInput.update = function (self, dt)
	local buttons = self._buttons

	for button_index, data in pairs(buttons) do
		data.pressed = false
		data.released = false

		local state = SteamVR.controller_held(self._controller_index, button_index)

		data.held = state

		if not data.state and state then
			data.pressed = true
		elseif data.state and not state then
			data.released = true
		end

		data.state = state
	end

	if self._vibrate_time then
		self._vibrate_time = self._vibrate_time - dt

		self:trigger_feedback(self._vibrate_strength)

		if self._vibrate_time <= 0 then
			self._vibrate_time = nil
			self._vibrate_strength = nil
		end
	end
end

WandInput.set_wand_unit = function (self, unit)
	self._wand_unit = unit
end

WandInput.wand_hand = function (self)
	return self._wand_hand
end

WandInput.wand_unit_position = function (self, node_name)
	local unit = self._wand_unit
	local node_index = node_name and Unit.node(unit, node_name) or 1

	return Unit.world_position(unit, node_index)
end

WandInput.wand_unit_rotation = function (self, node_name)
	local unit = self._wand_unit
	local node_index = node_name and Unit.node(unit, node_name) or 1

	return Unit.world_rotation(unit, node_index)
end

WandInput.amount_pressed = function (self, button_name)
	return 0
end

WandInput.held = function (self, button_name, consume)
	local button_index = WandInput.INDICES[button_name]

	if consume then
		local value = self._buttons[button_index].held

		self._buttons[button_index].held = nil

		return value
	else
		return self._buttons[button_index].held
	end
end

WandInput.pressed = function (self, button_name, consume)
	local button_index = WandInput.INDICES[button_name]

	if consume then
		local value = self._buttons[button_index].pressed

		self._buttons[button_index].pressed = nil

		return value
	else
		return self._buttons[button_index].pressed
	end
end

WandInput.released = function (self, button_name, consume)
	local button_index = WandInput.INDICES[button_name]

	if consume then
		local value = self._buttons[button_index].released

		self._buttons[button_index].released = nil

		return value
	else
		return self._buttons[button_index].released
	end
end

WandInput.position = function (self)
	local pose = SteamVR.controller_world_pose(self._controller_index)

	return Matrix4x4.translation(pose)
end

WandInput.pose = function (self)
	return SteamVR.controller_world_pose(self._controller_index)
end

WandInput.forward = function (self)
	local pose = SteamVR.controller_world_pose(self._controller_index)
	local rotation = Matrix4x4.rotation(pose)

	return Quaternion.rotate(rotation, Vector3.forward())
end

WandInput.controller_index = function (self)
	return self._controller_index
end

WandInput.controller_value = function (self, button_name)
	local button_index = WandInput.INDICES[button_name]

	return SteamVR.controller_value(self._controller_index, button_index)
end

WandInput.vibrate = function (self, duration, strength)
	self._vibrate_time = duration
	self._vibrate_strength = strength
end

WandInput.trigger_feedback = function (self, duration)
	local duration = math.min(duration, 0.003999)

	SteamVR.controller_pulse(self._controller_index, duration)
end

WandInput.is_tracked = function (self)
	return SteamVR.is_controller_tracked(self._controller_index)
end

WandInput.set_additional_rotation_offset = function (self, offset)
	self._additional_wand_rotation_offset:store(offset or Quaternion.from_euler_angles_xyz(0, 0, 0))
end

WandInput.get_additional_rotation_offset = function (self)
	return self._additional_wand_rotation_offset:unbox()
end
