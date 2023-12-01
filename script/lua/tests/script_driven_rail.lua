-- chunkname: @script/lua/tests/script_driven_rail.lua

local World = stingray.World
local Vector3Box = stingray.Vector3Box
local Unit = stingray.Unit

class("ScriptDrivenRail")

ScriptDrivenRail.init = function (self, world, wand_input)
	self._world = world
	self._wand_input = wand_input
	self._speed = Vector3Box(0, 1, 0)
end

ScriptDrivenRail._find_cart = function (self)
	local carts = World.units_by_resource(self._world, "units/architecture/dwarf/dwarf_rail_cart_04")

	for _, cart in ipairs(carts) do
		if Unit.get_data(cart, "script_driven") then
			print("found cart!")

			self._cart = cart
		end
	end

	local boxes = World.units_by_resource(self._world, "units/whitebox/whitebox_cube_1x1_invis")

	for _, box in ipairs(boxes) do
		if Unit.get_data(box, "script_driven") then
			print("found box!")

			self._box = box
		end
	end
end

ScriptDrivenRail._start = function (self)
	self._running = true
end

ScriptDrivenRail.update = function (self, dt)
	if not self._cart then
		self:_find_cart()

		return
	end

	if self._wand_input:pressed("touch") then
		self:_start()
	end

	if not self._running then
		return
	end

	local speed = self._speed:unbox()
	local position = Unit.local_position(self._cart, 1)
	local new_position = position + speed * dt

	Unit.set_local_position(self._cart, 1, new_position)

	position = Unit.local_position(self._box, 1)
	new_position = position + speed * dt

	Unit.set_local_position(self._box, 1, new_position)
end
