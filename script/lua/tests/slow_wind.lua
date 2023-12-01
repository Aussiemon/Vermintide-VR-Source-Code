-- chunkname: @script/lua/tests/slow_wind.lua

class("SlowWind")

SlowWind.init = function (self, world, level_name)
	self._world = world
	self._physics_world = World.physics_world(world)
	self._vector_field = World.vector_field(world, "wind")
	self._effects = {}

	local level_settings = LevelSettings.levels[level_name]
	local strength = level_settings.wind_strength or 2
	local settings = self:_settings(world)

	self:_add_vector_field(Vector4(strength, strength, strength, 0), Vector4(1, 1, 1, 0), settings)

	strength = strength / 2

	self:_add_vector_field(Vector4(strength * 2, strength, strength, 0), Vector4(1.25, 0.5, 0.5, 0), settings)

	strength = strength / 4

	self:_add_vector_field(Vector4(strength, strength * 2, strength, 0), Vector4(2.5, 2.5, 2.5, 0), settings)
end

SlowWind._add_vector_field = function (self, strength, frequency, settings)
	local parameters = {
		amplitude = strength,
		wave_vector = Vector4(2, 0, 0, 0),
		frequency = frequency,
		phase = Vector4(1, 0, 0, 0),
		time = Vector4(1, 0, 0, 0)
	}
	local effect_id = VectorField.add(self._vector_field, "core/entities/vector_fields/global_sine/global_sine", parameters, settings)

	table.insert(self._effects, effect_id)
end

SlowWind._settings = function (self, world)
	local min_pos = Vector3(math.huge, math.huge, math.huge)
	local max_pos = Vector3(-math.huge, -math.huge, -math.huge)
	local units = World.units(world)

	for _, unit in pairs(units) do
		if Unit.is_a(unit, "prototype") then
			break
		end

		local pos = Unit.world_position(unit, 1)

		if min_pos.x > pos.x then
			min_pos.x = pos.x
		end

		if min_pos.y > pos.y then
			min_pos.y = pos.y
		end

		if min_pos.z > pos.z then
			min_pos.z = pos.z
		end

		if max_pos.x < pos.x then
			max_pos.x = pos.x
		end

		if max_pos.y < pos.y then
			max_pos.y = pos.y
		end

		if max_pos.z < pos.z then
			max_pos.z = pos.z
		end
	end

	local settings = {
		min = min_pos,
		max = max_pos,
		duration = math.huge
	}

	return settings
end

SlowWind.update = function (self)
	return
end

SlowWind.destroy = function (self)
	for i = 1, #self._effects do
		VectorField.remove(self._vector_field, self._effects[i])
	end
end
