-- chunkname: @script/lua/vr_controller_mouse.lua

require("settings/weapon_setup")
require("script/lua/wand")
require("script/lua/head")
require("script/lua/wand_input_mouse")
require("script/lua/pie_menu")
class("VrControllerMouse")

VrControllerMouse.init = function (self, world, camera_unit, gameplay_extensions)
	self._wands = {}
	self._wands.right = Wand:new(world, WandInputMouse:new(0, world, camera_unit, "right"), "right")
	self._wands.left = Wand:new(world, WandInputMouse:new(1, world, camera_unit, "left"), "left")
	self._head = Head:new(world, gameplay_extensions)
end

VrControllerMouse.update = function (self, dt, t)
	for hand, wand in pairs(self._wands) do
		wand:update(dt, t)
	end

	self._head:update(dt, t)
end

VrControllerMouse.get = function (self, state, button, hand, consume)
	if not hand or hand == "any" then
		local left_input = self._wands.left:input()
		local right_input = self._wands.right:input()

		return left_input[state](left_input, button, consume) or right_input[state](right_input, button, consume)
	else
		fassert(self._wands[hand], "There is no wand for hand: %s", hand)

		local input = self._wands[hand]:input()

		return input[state](input, button, consume)
	end
end

VrControllerMouse.get_wand = function (self, hand)
	assert(hand == "left" or hand == "right")

	return self._wands[hand]
end

VrControllerMouse.destroy = function (self)
	self._wands.right:destroy()
	self._wands.left:destroy()
	self._head:destroy()
end
