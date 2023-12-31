﻿-- chunkname: @script/lua/managers/extension/systems/sound_environment_system.lua

class("SoundEnvironmentSystem", "ExtensionSystemBase")

local RPCS = {}
local SOURCE_WEIGHT = 0.5
local LISTENER_WEIGHT = 1 - SOURCE_WEIGHT

SoundEnvironmentSystem.extension_list = {}

SoundEnvironmentSystem.init = function (self, entity_system_creation_context, system_name, extensions)
	SoundEnvironmentSystem.super.init(self, entity_system_creation_context, system_name, extensions)

	local world = self._world
	local wwise_world = Wwise.wwise_world(world)

	self.wwise_world = wwise_world

	WwiseWorld.reset_aux_environment(self.wwise_world)

	self._environments = {}
	self._fade_environments = {}
	self._current_environment = nil

	local ambient_sound_event = ""
	local global_environment_fade_time
	local aux_bus_name = "environment_reverb_outside"
	local environment_state = "interior"

	self:register_sound_environment("global", -1, ambient_sound_event, global_environment_fade_time, aux_bus_name, environment_state)
	self:enter_environment(0, "global")

	self._updated_sources = {}
	self._num_sources = 0
	self._current_source_index = 0
end

local environment_base = {
	aux_bus_name = "",
	prio = 0,
	fade_time = 0,
	volume_name = "",
	ambient_sound_event_stop = "",
	ambient_sound_event_start = "",
	fade_info = {
		current_value = 0
	}
}

SoundEnvironmentSystem.register_sound_environment = function (self, volume_name, prio, ambient_sound_event, fade_time, aux_bus_name, environment_state)
	assert(self._environments[volume_name] == nil, "Already registered sound environment with name %q", volume_name)

	local environment = self._environments[volume_name] or table.clone(environment_base)

	environment.prio = prio

	if ambient_sound_event ~= "" then
		environment.ambient_sound_event_start = "Play_" .. ambient_sound_event
		environment.ambient_sound_event_stop = "Stop_" .. ambient_sound_event
	end

	environment.fade_time = fade_time or 1

	assert(aux_bus_name, "Sound environment lacks auxiliary bus")

	environment.player_aux_bus_name = aux_bus_name
	environment.source_aux_bus_name = aux_bus_name .. "_source"

	assert(environment_state, "Have to set environment state")

	environment.environment_state = environment_state
	self._environments[volume_name] = environment
end

SoundEnvironmentSystem._highest_prio_environment_at_position = function (self, position)
	local level = self._level
	local highest_prio = -math.huge
	local highest_prio_env_name

	for volume_name, data in pairs(self._environments) do
		local prio = data.prio

		if highest_prio < prio and Level.is_point_inside_volume(level, volume_name, position) then
			highest_prio = data.prio
			highest_prio_env_name = volume_name
		end
	end

	return highest_prio_env_name
end

SoundEnvironmentSystem.set_source_environment = function (self, source, position)
	local volume_name = self:_highest_prio_environment_at_position(position)
	local environments = self._environments
	local bus_name = environments[volume_name or "global"].source_aux_bus_name
	local wwise_world = self.wwise_world

	assert(bus_name, "No source aux environment in %s", volume_name or "global")
	WwiseWorld.reset_environment_for_source(wwise_world, source)
	WwiseWorld.set_environment_for_source(wwise_world, source, bus_name, SOURCE_WEIGHT)

	local fade_environments = self._fade_environments
	local added_current_environment = false
	local current_environment_name = self._current_environment

	for volume_name, _ in pairs(fade_environments) do
		local environment = environments[volume_name]
		local fade_info = environment.fade_info

		WwiseWorld.set_environment(wwise_world, environment.player_aux_bus_name, fade_info.current_value * LISTENER_WEIGHT)

		added_current_environment = added_current_environment or volume_name == current_environment_name
	end

	if not added_current_environment then
		local environment = self._environments[current_environment_name]

		WwiseWorld.set_environment(wwise_world, environment.player_aux_bus_name, LISTENER_WEIGHT)
	end

	return bus_name
end

SoundEnvironmentSystem.register_source_environment_update = function (self, source, unit, object)
	self._updated_sources[#self._updated_sources + 1] = {
		unit = unit,
		source = source,
		node = object and Unit.node(unit, object) or 0
	}
	self._num_sources = self._num_sources + 1
end

SoundEnvironmentSystem.unregister_source_environment_update = function (self, source)
	local num_sources = self._num_sources

	for i = 1, num_sources do
		local data = self._updated_sources[i]

		if data.source == source then
			table.remove(self._updated_sources, i)

			local current_index = self._current_source_index

			if i < current_index then
				self._current_source_index = current_index - 1
			end

			self._num_sources = num_sources - 1

			return
		end
	end
end

local UPDATE_MAX_AMOUNT = 3

SoundEnvironmentSystem._update_source_environments = function (self)
	local num_sources = self._num_sources
	local amount_to_update = math.min(num_sources, UPDATE_MAX_AMOUNT)
	local current_index = math.min(self._current_source_index, num_sources)
	local updated_sources = self._updated_sources

	for i = 1, amount_to_update do
		current_index = current_index % num_sources + 1

		local data = updated_sources[current_index]
		local pos = Unit.world_position(data.unit, data.node)
		local bus_name = self:set_source_environment(data.source, pos)
	end

	self._current_index = current_index
end

SoundEnvironmentSystem.update = function (self, dt, t)
	local pose = Managers.vr:hmd_world_pose().head
	local position = Matrix4x4.translation(pose)

	WwiseWorld.set_listener(self.wwise_world, Wwise.LISTENER_0, pose)

	local highest_prio_env_name = self:_highest_prio_environment_at_position(position)

	if highest_prio_env_name then
		if highest_prio_env_name ~= self._current_environment then
			self:enter_environment(t, highest_prio_env_name, self._current_environment)
		end
	elseif self._current_environment ~= "global" then
		self:enter_environment(t, "global", self._current_environment)
	end

	self:_update_fade(t)
	self:_update_source_environments()
end

SoundEnvironmentSystem._update_fade = function (self, t)
	local wwise_world = self.wwise_world
	local environments = self._environments
	local fade_environments = self._fade_environments

	for volume_name, _ in pairs(fade_environments) do
		local environment = environments[volume_name]
		local fade_info = environment.fade_info
		local fade_start = fade_info.fade_start
		local fade_time = fade_info.fade_time
		local current_time = t - fade_start

		local function clamp(value, min, max)
			if max < value then
				return max
			elseif value < min then
				return min
			else
				return value
			end
		end

		local delta = clamp(current_time / fade_time, 0, 1)
		local start_value = fade_info.start_value
		local target_value = fade_info.target_value

		local function lerp(a, b, p)
			return a * (1 - p) + b * p
		end

		local value = lerp(start_value, target_value, delta)

		fade_info.current_value = value

		WwiseWorld.set_environment(wwise_world, environment.player_aux_bus_name, value * LISTENER_WEIGHT)

		if value == target_value then
			fade_environments[volume_name] = nil
		end
	end
end

SoundEnvironmentSystem._add_fade_environment = function (self, t, volume_name, fade_time, target_value)
	local environment = self._environments[volume_name]
	local fade_info = environment.fade_info

	fade_info.fade_start = t
	fade_info.fade_time = fade_time
	fade_info.start_value = fade_info.current_value
	fade_info.target_value = target_value
	self._fade_environments[volume_name] = true
end

local MAX_FADE_ENVIRONMENTS = 3

SoundEnvironmentSystem._clamp_num_fade_environments = function (self)
	local num_envs = 0
	local least_env_name
	local least_env_value = math.huge

	for env_name, _ in pairs(self._fade_environments) do
		num_envs = num_envs + 1

		local fade_info = self._environments[env_name].fade_info
		local current_value = fade_info.current_value

		if fade_info.target_value == 0 and current_value < least_env_value then
			least_env_value = current_value
			least_env_name = env_name
		end
	end

	assert(num_envs <= MAX_FADE_ENVIRONMENTS + 1, "Too many environments, cleanup failed.")

	if num_envs > MAX_FADE_ENVIRONMENTS then
		local env = self._environments[least_env_name]
		local fade_info = env.fade_info

		fade_info.current_value = 0
		self._fade_environments[least_env_name] = nil

		WwiseWorld.set_environment(self.wwise_world, env.player_aux_bus_name, 0)
	end
end

SoundEnvironmentSystem.enter_environment = function (self, t, volume_name, current_environment_name)
	local environment = self._environments[volume_name]
	local fade_time = environment.fade_time
	local fade_info = environment.fade_info

	if fade_info.current_value > 0 then
		local current_value = fade_info.current_value
		local target_value = 1
		local delta = target_value - current_value

		fade_time = fade_time * delta

		if fade_time < 0.001 then
			fade_time = 0.001
		end
	end

	self:_add_fade_environment(t, volume_name, fade_time, 1)

	if current_environment_name then
		self:_add_fade_environment(t, current_environment_name, fade_time, 0)
	end

	self:_clamp_num_fade_environments()
	Wwise.set_state("interior_exterior", environment.environment_state)

	local wwise_world = self.wwise_world

	if current_environment_name then
		local current_environment = self._environments[current_environment_name]
		local ambient_sound_event_stop = current_environment.ambient_sound_event_stop

		if ambient_sound_event_stop then
			WwiseWorld.trigger_event(wwise_world, ambient_sound_event_stop)
		end
	end

	local ambient_sound_event_start = environment.ambient_sound_event_start

	if ambient_sound_event_start then
		WwiseWorld.trigger_event(wwise_world, ambient_sound_event_start)
	end

	self._current_environment = volume_name
end
