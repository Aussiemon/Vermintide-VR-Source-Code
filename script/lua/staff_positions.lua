-- chunkname: @script/lua/staff_positions.lua

StaffPositions = StaffPositions or {}

local Unit = stingray.Unit
local Vector3Box = stingray.Vector3Box

StaffPositions.new = function (self, unit, node)
	local tab = {}

	for k, v in pairs(StaffPositions) do
		tab[k] = v
	end

	tab._unit = unit
	tab._node = Unit.node(unit, node)
	tab._positions = {}
	tab._time = 0

	return tab
end

StaffPositions.update = function (self, dt)
	if not Unit.alive(self._unit) then
		return
	end

	self._time = self._time + dt

	local pos = Unit.world_position(self._unit, self._node)
	local positions = self._positions
	local box = Vector3Box()

	box:store(pos)
	table.insert(positions, {
		position = box,
		expires = self._time + 1
	})

	for ii, position in ipairs(positions) do
		local expires = position.expires

		if expires < self._time then
			table.remove(positions, ii)
		end
	end
end

StaffPositions.current_direction = function (self)
	local positions = self._positions
	local latest = positions[#self._positions].position:unbox()
	local oldest = positions[1].position:unbox()

	return latest, latest - oldest
end
