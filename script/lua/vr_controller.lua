-- chunkname: @script/lua/vr_controller.lua

require("settings/weapon_setup")
require("script/lua/wand")
require("script/lua/head")
require("script/lua/wand_input")
require("script/lua/pie_menu")
require("script/lua/wand_hand_mapper")
class("VrController")

VrController.init = function (self, world, gameplay_extensions)
	self._wands = {}
	self._wands.right = Wand:new(world, WandInput:new(0, "right"), "right")
	self._wands.left = Wand:new(world, WandInput:new(1, "left"), "left")
	self._head = Head:new(world, gameplay_extensions)
	self._wand_hand_mapper = WandHandMapper:new()

	self._wand_hand_mapper:register_wand(self._wands.right)
	self._wand_hand_mapper:register_wand(self._wands.left)
end

VrController.update = function (self, dt, t)
	for hand, wand in pairs(self._wands) do
		wand:update(dt, t)
	end

	self._head:update(dt, t)
	self._wand_hand_mapper:update()
end

VrController.get = function (self, state, button, hand)
	if not hand or hand == "any" then
		local left_input = self._wands.left:input()
		local right_input = self._wands.right:input()

		return left_input[state](left_input, button) or right_input[state](right_input, button)
	else
		fassert(self._wands[hand], "There is no wand for hand: %s", hand)

		local input = self._wands[hand]:input()

		return input[state](input, button)
	end
end

VrController.get_wand = function (self, hand)
	assert(hand == "left" or hand == "right")

	return self._wands[hand]
end

VrController.destroy = function (self)
	self._wands.right:destroy()
	self._wands.left:destroy()
	self._head:destroy()
end
