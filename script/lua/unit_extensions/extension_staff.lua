-- chunkname: @script/lua/unit_extensions/extension_staff.lua

require("script/lua/staff_positions")

local Bit = require("bit")
local SteamVR = stingray.SteamVR
local Unit = stingray.Unit
local World = stingray.World
local Vector3Box = stingray.Vector3Box
local Vector3 = stingray.Vector3
local Actor = stingray.Actor

ExtensionStaff = ExtensionStaff or {}

ExtensionStaff.new = function (self, vr_system, unit, controller_index)
	local tab = {}

	for k, v in pairs(ExtensionStaff) do
		tab[k] = v
	end

	tab._unit = unit
	tab._positions = StaffPositions:new(unit, "fx_02")
	tab._controller_index = controller_index
	tab._vr_system = vr_system
	tab._spawn_pos = Vector3Box()
	self._switch_weapon_cooldown = 0.5

	return tab
end

ExtensionStaff.update = function (self, dt)
	self._positions:update(dt)

	local unit = self._unit
	local input = SteamVRSystem.controller_input(self._vr_system, self._controller_index)
	local touch_state = false

	self._switch_weapon_cooldown = self._switch_weapon_cooldown and math.max(0, self._switch_weapon_cooldown - dt) or 2

	if self._switch_weapon_cooldown == 0 then
		touch_state = Bit.band(input.pressed_buttons, SteamVR.BUTTON_TOUCH) ~= 0
	end

	if touch_state == 0 and self._touch_pressed == true then
		self._touch_pressed = false
	end

	if touch_state and not self._touch_pressed then
		self._touch_pressed = true

		return true
	end

	local trigger_state = Bit.band(input.pressed_buttons, SteamVR.BUTTON_TRIGGER) ~= 0

	if trigger_state and not self._trigger_pressed then
		self._trigger_pressed = true
	end

	if self._trigger_pressed then
		local pos, dir = self._positions:current_direction()

		if Vector3.distance(self._spawn_pos:unbox(), pos) > 0.05 then
			local world = Unit.world(unit)

			self._spawn_pos:store(pos)
			self._vr_system:trigger_controller_feedback(self._controller_index, 0.001)
		end

		if not trigger_state then
			self._trigger_pressed = false
		end
	end
end
