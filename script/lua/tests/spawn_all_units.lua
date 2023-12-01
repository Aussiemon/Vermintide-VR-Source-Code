-- chunkname: @script/lua/tests/spawn_all_units.lua

class("SpawnAllUnits")

SpawnAllUnits.init = function (self)
	self._index = 1

	Managers.package:load("require_units", "require_units")
	require("require_units_list")
end

SpawnAllUnits._destroy_loaded_unit = function (self)
	if self._loaded_unit then
		print("destroying", self._loaded_unit)

		if Unit.alive(self._loaded_unit) then
			World.destroy_unit(self._world, self._loaded_unit)
		else
			print("dead unit")
		end

		self._loaded_unit = nil
	end
end

SpawnAllUnits.update = function (self)
	self:_destroy_loaded_unit()

	self._index = self._index + 1

	if self._index <= #RequireUnitsList then
		local unit_name = RequireUnitsList[self._index]

		print("spawning", unit_name)

		self._loaded_unit = World.spawn_unit(self._world, unit_name, Vector3(0, 0, 0))
	end
end

SpawnAllUnits.destroy = function (self)
	self:_destroy_loaded_unit()
end
