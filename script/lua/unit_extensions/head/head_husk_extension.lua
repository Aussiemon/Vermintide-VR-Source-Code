-- chunkname: @script/lua/unit_extensions/head/head_husk_extension.lua

class("HeadHuskExtension")

HeadHuskExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._unit = unit
	self._world = extension_init_context.world

	local id = extension_init_data.game_object_id

	self.game_object_id = id

	Managers.state.network:set_game_object_unit(unit, id)

	local pos = Unit.local_position(unit, 1)

	self._last_position = Vector3Box(pos)
	self._next_position = Vector3Box(pos)

	local rot = Unit.local_rotation(unit, 1)

	self._last_rotation = QuaternionBox(rot)
	self._next_rotation = QuaternionBox(rot)
	self._next_time = Managers.time:time("game")
	self.is_husk = true

	if self._network_mode ~= "client" then
		Unit.set_data(unit, "name", "player_2")
	end
end

local DURATION = 0.037037037037037035
local EPSILON = 1e-05

HeadHuskExtension.update = function (self, unit, dt, t)
	local session = Managers.state.network:session()

	if session then
		local network_pos = GameSession.game_object_field(session, self.game_object_id, "position")
		local network_rot = GameSession.game_object_field(session, self.game_object_id, "rotation")
		local last_pos = self._last_position:unbox()
		local next_pos = self._next_position:unbox()
		local last_rot = self._last_rotation:unbox()
		local next_rot = self._next_rotation:unbox()
		local moved = Vector3.distance(next_pos, network_pos) > EPSILON or not Quaternion.equal(next_rot, network_rot)

		if moved then
			last_pos = Unit.local_position(unit, 1)
			next_pos = network_pos
			last_rot = Unit.local_rotation(unit, 1)
			next_rot = network_rot

			self._last_position:store(last_pos)
			self._next_position:store(next_pos)
			self._last_rotation:store(last_rot)
			self._next_rotation:store(next_rot)

			self._next_time = t + DURATION
		end

		local new_pos, new_rot

		if t > self._next_time then
			new_pos = next_pos
			new_rot = next_rot
		else
			local time_left = self._next_time - t
			local lerp_t = time_left / DURATION

			new_pos = Vector3.lerp(next_pos, last_pos, lerp_t)
			new_rot = Quaternion.lerp(next_rot, last_rot, lerp_t)
		end

		Unit.set_local_position(unit, 1, new_pos)
		Unit.set_local_rotation(unit, 1, new_rot)
	end
end

HeadHuskExtension.destroy = function (self)
	return
end
