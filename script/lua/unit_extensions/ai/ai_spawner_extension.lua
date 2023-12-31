﻿-- chunkname: @script/lua/unit_extensions/ai/ai_spawner_extension.lua

require("settings/breeds")
class("AISpawnerExtension")

AI_TEST_COUNTER = 0

AISpawnerExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._spawner_system = Managers.state.extension:system("spawner_system")
	self._config = {}
	self._world = extension_init_context.world
	self._unit = unit
	self._spawned_units = 0
	self._max_amount = 0

	if Unit.has_data(unit, "spawner_settings") then
		local spawner_name = self:check_for_enabled()

		if spawner_name ~= nil then
			local terror_event_id = Unit.get_data(unit, "terror_event_id")

			terror_event_id = (not terror_event_id or terror_event_id ~= "") and terror_event_id

			local hidden = Unit.get_data(unit, "hidden")

			self._spawner_system:register_enabled_spawner(unit, terror_event_id, hidden)

			local i = 0
			local animation_events = {}

			while Unit.has_data(unit, "spawner_settings", spawner_name, "animation_events", i) do
				animation_events[#animation_events + 1] = Unit.get_data(unit, "spawner_settings", spawner_name, "animation_events", i)
				i = i + 1
			end

			self._config = {
				name = spawner_name,
				animation_events = animation_events,
				node = Unit.get_data(unit, "spawner_settings", spawner_name, "node"),
				spawn_rate = Unit.get_data(unit, "spawner_settings", spawner_name, "spawn_rate")
			}
			self._next_spawn = 0
		end
	else
		local terror_event_id = Unit.get_data(self._unit, "terror_event_id")

		terror_event_id = (not terror_event_id or terror_event_id ~= "") and terror_event_id

		self._spawner_system:register_raw_spawner(self._unit, terror_event_id)
	end
end

AISpawnerExtension.check_for_enabled = function (self)
	local i = 1
	local name = "spawner"

	repeat
		name = "spawner" .. i

		if Unit.has_data(self._unit, "spawner_settings", name) then
			if Unit.get_data(self._unit, "spawner_settings", name, "enabled") then
				return name
			end
		else
			return nil
		end

		i = i + 1
	until true
end

AISpawnerExtension.add_breeds = function (self, breed_list)
	self._breed_list = self._breed_list or {}

	table.append(self._breed_list, breed_list)

	self._max_amount = #self._breed_list
end

AISpawnerExtension.on_activate = function (self, amount, breeds, breed_list)
	if breed_list then
		self:add_breeds(breed_list)
	else
		self._breed_list = nil
		self._breeds = breeds
		self._max_amount = self._max_amount + amount
	end
end

AISpawnerExtension.on_deactivate = function (self)
	self._max_amount = 0
	self._spawned_units = 0

	self._spawner_system:deactivate_spawner(self._unit)
end

AISpawnerExtension.update = function (self, unit, input, dt, context, t)
	if t > self._next_spawn then
		if self._spawned_units < self._max_amount then
			self:spawn_unit()

			self._next_spawn = t + 1 / self._config.spawn_rate
		else
			self:on_deactivate()
		end
	end
end

AISpawnerExtension.spawn_rate = function (self)
	return self._config.spawn_rate
end

AISpawnerExtension.spawn_unit = function (self)
	local breed, group_template, target, breed_name

	if self._breed_list then
		local size = #self._breed_list
		local data = self._breed_list[size]

		if type(data) == "table" then
			breed_name = data[1]
			group_template = data[2]
			target = data[3]
		else
			breed_name = data
		end

		breed = Breeds[breed_name]
		self._breed_list[size] = nil
	else
		local index = math.random(1, #self._breeds)

		breed = self._breeds[index]
	end

	local unit = self._unit

	Unit.flow_event(unit, "lua_spawn")

	local spawn_category = "ai_spawner"
	local node = Unit.node(unit, self._config.node)
	local parent_index = Unit.scene_graph_parent(unit, node)
	local parent_world_rotation = Unit.world_rotation(unit, parent_index)
	local spawn_node_rotation = Unit.local_rotation(unit, node)
	local spawn_rotation = Quaternion.multiply(parent_world_rotation, spawn_node_rotation)
	local spawn_pos = Unit.world_position(unit, node)
	local animation_events = self._config.animation_events
	local spawn_animation = animation_events and animation_events[math.random(#animation_events)]
	local spawner_name = self:get_spawner_name()
	local spawn_type = breed_name == "skaven_rat_ogre" and "special" or "horde"
	local inventory_template

	Managers.state.spawn:spawn_enemy(breed, spawn_pos, spawn_rotation, spawn_category, spawn_animation, spawn_type, inventory_template, group_template, target)

	self._spawned_units = self._spawned_units + 1

	self._spawner_system:add_waiting_to_spawn(-1)
end

AISpawnerExtension.get_spawner_name = function (self)
	return self._config.name
end

AISpawnerExtension.destroy = function (self)
	return
end
