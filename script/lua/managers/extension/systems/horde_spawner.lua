-- chunkname: @script/lua/managers/extension/systems/horde_spawner.lua

class("HordeSpawner")

local horde_sectors = {
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{}
}
local hidden_sectors = {
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{}
}
local num_sectors = #horde_sectors
local found_cover_points = {}
local temp_horde_spawners = {}
local temp_hidden_spawners = {}

HordeSpawner.init = function (self, world, cover_points_broadphase)
	self.hordes = {}
	self.lookup_horde = {}
	self.conflict_director = Managers.state.conflict
	self.num_paced_hordes = 0
	self.world = world
	CurrentHordeSettings.ambush.max_size = self:max_composition_size(CurrentHordeSettings.ambush.composition_type)
	CurrentHordeSettings.vector.max_size = self:max_composition_size(CurrentHordeSettings.vector.composition_type)
end

local function remove_index_from_array(array, index)
	local end_index = #array

	array[index] = array[end_index]
	array[end_index] = nil
end

local function copy_array(a, b)
	local source_size = #a
	local dest_size = #b

	for i = 1, source_size do
		b[i] = a[i]
	end

	for i = source_size + 1, dest_size do
		b[i] = nil
	end
end

HordeSpawner.horde = function (self, horde_type, composition_lookup)
	Profiler.start("horde_spawner")

	self.composition_lookup = composition_lookup

	if not horde_type then
		if CurrentHordeSettings.mix_paced_hordes then
			if self.num_paced_hordes % 2 == 0 then
				horde_type = math.random() < CurrentHordeSettings.chance_of_vector and "vector" or "ambush"
			else
				horde_type = self.last_paced_horde_type == "vector" and "ambush" or "vector"
			end
		else
			horde_type = math.random() < CurrentHordeSettings.chance_of_vector and "vector" or "ambush"
		end
	end

	print("horde requested: ", horde_type)

	if horde_type == "vector" then
		self:execute_vector_horde()
	else
		self:execute_ambush_horde()
	end

	Profiler.stop()
end

HordeSpawner.execute_fallback = function (self, horde_type, fallback, reason)
	if fallback then
		if script_data.debug_player_intensity then
			self.conflict_director.pacing:annotate_graph("Failed horde", "red")
		end

		print("Failed to start horde, all fallbacks failed at this place")

		return
	end

	print(reason)

	if horde_type == "ambush" then
		self:execute_vector_horde("fallback")
	elseif horde_type == "vector" then
		self:execute_ambush_horde("fallback")
	end
end

HordeSpawner.execute_event_horde = function (self, t, terror_event_id, composition_type, limit_spawners, silent, group_template, target)
	local composition = CurrentHordeSettings.compositions[composition_type]
	local horde = {
		horde_type = "event",
		composition_type = composition_type,
		limit_spawners = limit_spawners,
		terror_event_id = terror_event_id,
		start_time = t + (composition.start_time or 4),
		end_time = t + (composition.start_time or 4) + 20,
		silent = silent,
		group_template = group_template,
		target = target
	}
	local hordes = self.hordes
	local id = #hordes + 1

	hordes[id] = horde

	return horde
end

HordeSpawner.max_composition_size = function (self, composition_name)
	local max_size = 0
	local composition = CurrentHordeSettings.compositions[composition_name]

	for i = 1, #composition do
		local variant = composition[i]
		local breeds = variant.breeds
		local max_variant_size = 0

		for j = 1, #breeds, 2 do
			local breed_name = breeds[i]
			local amount = breeds[i + 1]
			local n = type(amount) == "table" and math.max(amount[1], amount[2]) or amount

			max_variant_size = max_variant_size + n
		end

		if max_size < max_variant_size then
			max_size = max_variant_size
		end
	end

	return max_size
end

HordeSpawner.running_horde = function (self, t)
	return self._running_horde_type
end

HordeSpawner.update_event_horde = function (self, horde, t)
	if not horde.started then
		if t > horde.start_time then
			local spawner_system = Managers.state.extension:system("spawner_system")
			local success, amount = spawner_system:spawn_horde_from_terror_event_id(horde.terror_event_id, horde.composition_type, horde.limit_spawners, horde.group_template, horde.target)

			if success then
				horde.started = true
				horde.amount = amount
			else
				horde.failed = true

				print("event horde failed")

				return true
			end
		end
	elseif t > horde.end_time then
		print("event horde ends!")

		return true
	end

	return false
end

HordeSpawner.update_horde = function (self, horde, t)
	if not horde.started then
		if t > horde.start_time then
			local horde_spawns = horde.horde_spawns

			if horde_spawns then
				local breeds = CurrentHordeSettings.breeds

				for i = 1, #horde_spawns do
					local horde_spawn = horde_spawns[i]
					local spawn_rate = self.spawner_system:spawn_horde(horde_spawn.spawner, horde_spawn.num_to_spawn, breeds, horde_spawn.spawn_list, horde.group_template)

					horde_spawn.all_done_spawned_time = t + 1 / spawn_rate * horde_spawn.num_to_spawn
				end
			end

			horde.started = true
		else
			if script_data.debug_terror then
				Debug.text("Horde in: %.2f", horde.start_time - t)
			end

			return
		end
	end

	local horde_spawns = horde.horde_spawns

	if horde_spawns then
		for j = 1, #horde_spawns do
			local horde_spawn = horde_spawns[j]

			if not horde_spawn.done and t > horde_spawn.all_done_spawned_time then
				horde_spawn.done = true
				horde.spawned = horde.spawned + horde_spawn.num_to_spawn
			end
		end
	end

	if script_data.debug_terror then
		Debug.text("HORDE spawned: %d", horde.spawned)
	end

	if horde.spawned >= horde.num_to_spawn then
		return true
	end
end

HordeSpawner.update = function (self, t, dt)
	local hordes = self.hordes
	local num_hordes = #hordes

	self._running_horde_type = nil

	local i = 1

	while i <= num_hordes do
		local horde = hordes[i]
		local done

		if horde.horde_type == "vector" or horde.horde_type == "ambush" then
			self._running_horde_type = horde.horde_type
			done = self:update_horde(horde, t)
		else
			done = self:update_event_horde(horde, t)

			if not horde.silent then
				self._running_horde_type = "event"
			end
		end

		if done then
			hordes[i] = hordes[num_hordes]
			hordes[num_hordes] = nil
			num_hordes = num_hordes - 1
		else
			i = i + 1
		end
	end

	if script_data.debug_hordes then
		self:debug_hordes(t)
	end
end

HordeSpawner.debug_hordes = function (self, t)
	local s = "Hordes - current: (" .. tostring(self._running_horde_type or "?") .. ") "
	local hordes = self.hordes

	for i = 1, #hordes do
		local horde = hordes[i]
		local horde_type = horde.horde_type
		local silent = horde.silent

		s = s .. horde_type .. (horde.silent and "(silent), " or ", ")
	end

	Debug.text(s)
end
