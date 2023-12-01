-- chunkname: @script/lua/unit_extensions/ai/ai_base_extension.lua

require("script/lua/unit_extensions/ai/ai_brain")
require("script/lua/utils/ai_utils")
require("settings/network_lookup")

local alive = Unit.alive
local PLAYER_AND_BOT_UNITS = PLAYER_AND_BOT_UNITS

class("AIBaseExtension")

AIBaseExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._world = extension_init_context.world
	self._unit = unit
	self._nav_world = extension_init_data.nav_world
	self._wwise_world = Wwise.wwise_world(self._world)

	local ai_system = Managers.state.extension:system("ai_system")
	local spawn_type = extension_init_data.spawn_type
	local is_horde = spawn_type == "horde_hidden" or spawn_type == "horde"
	local breed = extension_init_data.breed

	Unit.set_data(unit, "breed", breed)

	self._breed = breed

	local is_passive = breed.initial_is_passive == nil and true or breed.initial_is_passive
	local blackboard = {}

	blackboard.world = extension_init_context.world
	blackboard.unit = unit
	blackboard.move_orders = {}
	blackboard.nav_world = self._nav_world
	blackboard.node_data = {}
	blackboard.running_nodes = {}
	blackboard.is_passive = is_passive
	blackboard.system_api = extension_init_context.system_api
	blackboard.group_blackboard = ai_system.group_blackboard
	blackboard.target_dist = math.huge
	blackboard.spawn_type = spawn_type
	blackboard.is_in_attack_cooldown = false
	blackboard.attack_cooldown_at = 0
	blackboard.override_targets = {}
	blackboard.breed = breed

	local level_name = extension_init_context.level_name

	blackboard.level_name = level_name

	local run_speeds = breed.run_speed
	local run_speed = run_speeds[level_name] or run_speeds.default

	blackboard.run_speed = run_speed

	local blackboard_init_data = breed.blackboard_init_data

	if blackboard_init_data then
		table.merge(blackboard, blackboard_init_data)
	end

	self._blackboard = blackboard

	local target = extension_init_data.target

	printf("### TARGET %s", target)

	if target then
		self:set_override_target(target)
	end

	self:_init_perception(breed, is_horde)
	self:_init_brain(breed, is_horde)
	self:_init_size_variation(unit, breed, level_name)

	local variation_setting = breed.variation_setting

	if variation_setting then
		AiUtils.set_unit_variation(unit, variation_setting)
	end

	if Managers.state.network then
		self.anim_event = self.anim_event_network
		self.sound_event = self.sound_event_network
	else
		self.anim_event = self.anim_event_local
		self.sound_event = self.sound_event_local
	end

	if Managers.lobby then
		self._network_type_info_position = Network.type_info("position")
	else
		self._network_type_info_position = {
			max = 1200,
			min = -1200
		}
	end
end

AIBaseExtension.set_override_target = function (self, target)
	local blackboard = self._blackboard
	local target_list = {
		target
	}

	if target == "player_2" then
		target_list = {
			"player_2",
			"player_1"
		}
	end

	local target_unit
	local entities = Managers.state.extension:get_entities("AggroExtension")

	for i, target in ipairs(target_list) do
		for unit, extension in pairs(entities) do
			local name = Unit.has_data(unit, "name") and Unit.get_data(unit, "name")

			if name and name == target then
				target_unit = unit

				break
			end
		end
	end

	if target_unit then
		local override_target_time = math.huge

		blackboard.override_targets[target_unit] = override_target_time
	else
		error("Level unit used for ai target is missing. Unit.data name: " .. target .. ". The unit need the AggroExtension to be a valid target")
	end
end

AIBaseExtension.breed = function (self)
	return self._breed
end

AIBaseExtension.destroy = function (self)
	self._brain:destroy()
end

AIBaseExtension.extensions_ready = function (self, world, unit)
	self.health_extension = ScriptUnit.extension(unit, "health_system")
	self.locomotion = ScriptUnit.extension(unit, "locomotion_system")
	self.navigation = ScriptUnit.extension(unit, "ai_navigation_system")
	self._blackboard.navigation_extension = ScriptUnit.extension(unit, "ai_navigation_system")
	self._blackboard.locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")
end

AIBaseExtension.update = function (self, unit, dt, t)
	self:_update_game_object(unit, dt, t)
end

AIBaseExtension._update_game_object = function (self, unit)
	local position = Unit.world_position(unit, 1)
	local rotation = Unit.world_rotation(unit, 1)
	local in_session = Managers.state.network and Managers.state.network:state() == "in_session"

	if in_session and self.game_object_id then
		local position_is_network_safe = self:_network_safe_position(position)

		if not position_is_network_safe then
			Managers.state.extension:unregister_unit(unit)
			Managers.state.spawn:mark_for_deletion(unit)

			return
		end

		local session = Managers.state.network:session()
		local object_id = self.game_object_id

		GameSession.set_game_object_field(session, object_id, "position", position)
		GameSession.set_game_object_field(session, object_id, "rotation", rotation)
	elseif in_session then
		local session = Managers.state.network:session()
		local breed = self._breed
		local breed_name = breed.name
		local breed_index = BreedReverseLookup[breed_name]

		self.game_object_id = Managers.state.network:create_game_object("ai_unit", {
			has_teleported = 1,
			position = position,
			rotation = rotation,
			breed_index = breed_index
		})
	end
end

AIBaseExtension._network_safe_position = function (self, pos)
	local network_type_info_position = self._network_type_info_position
	local pos_min = network_type_info_position.min
	local pos_max = network_type_info_position.max
	local pos_x = pos.x
	local pos_y = pos.y
	local pos_z = pos.z
	local in_range_x = pos_min <= pos_x and pos_x <= pos_max
	local in_range_y = pos_min <= pos_y and pos_y <= pos_max
	local in_range_z = pos_min <= pos_z and pos_z <= pos_max
	local in_range = in_range_x and in_range_y and in_range_z

	return in_range
end

AIBaseExtension.get_overlap_context = function (self)
	if self._overlap_context then
		self._overlap_context.num_hits = 0
	else
		self._overlap_context = {
			has_gotten_callback = false,
			spine_node = false,
			num_hits = 0,
			overlap_units = {}
		}

		GarbageLeakDetector.register_object(self._overlap_context, "ai_overlap_context")
	end

	return self._overlap_context
end

AIBaseExtension.set_properties = function (self, params)
	for _, property in pairs(params) do
		local prop_name, prop_value = property:match("(%S+) (%S+)")
		local prop_type = type(self._breed.properties[prop_name])

		if prop_type == "table" then
			prop_value = AIProperties

			local prop_iterator = property:gmatch("(%S+)")

			prop_iterator()

			for i = 1, 10 do
				local index = prop_iterator()

				if index == nil then
					break
				end

				fassert(prop_value[index], "Table index %q not found in AIProperties", index)

				prop_value = prop_value[index]
			end
		elseif prop_type == "number" then
			prop_value = tonumber(prop_value)
		elseif prop_type == "boolean" then
			prop_value = to_boolean(prop_value)
		end

		self._breed.properties[prop_name] = prop_value
	end
end

AIBaseExtension._init_perception = function (self, breed, is_horde)
	if breed.perception then
		self._perception_func_name = is_horde and breed.horde_perception or breed.perception
	else
		self._perception_func_name = "perception_regular"
	end

	if breed.target_selection then
		self._target_selection_func_name = is_horde and breed.horde_target_selection or breed.target_selection
	else
		self._target_selection_func_name = "pick_closest_target_with_spillover"
	end
end

AIBaseExtension._init_event_handler = function (self)
	if self._breed.event then
		local class_name = self._breed.event.class_name

		self._event_handler = _G[class_name]:new(self._unit)
	else
		self._event_handler = AIEventHandler:new(self._unit)
	end
end

AIBaseExtension._init_brain = function (self, breed, is_horde)
	local behavior = is_horde and breed.horde_behavior or breed.behavior

	self._brain = AIBrain:new(self._world, self._unit, self._blackboard, self._breed, behavior)
end

AIBaseExtension._init_size_variation = function (self, unit, breed, level_name)
	local size_variation_range_table = breed.size_variation_range
	local size_variation_range = size_variation_range_table[level_name] or size_variation_range_table.default

	if size_variation_range then
		local size_variation_normalized = math.random()
		local size_variation = math.lerp(size_variation_range[1], size_variation_range[2], size_variation_normalized)

		self._size_variation = size_variation
		self._size_variation_normalized = size_variation_normalized

		local root_node = Unit.node(unit, "root_point")

		Unit.set_local_scale(unit, root_node, Vector3(size_variation, size_variation, size_variation))
	else
		self._size_variation = 1
		self._size_variation_normalized = 1
	end
end

AIBaseExtension.locomotion = function (self)
	return self._locomotion
end

AIBaseExtension.navigation = function (self)
	return self._navigation
end

AIBaseExtension.brain = function (self)
	return self._brain
end

AIBaseExtension.breed = function (self)
	return self._breed
end

AIBaseExtension.blackboard = function (self)
	return self._blackboard
end

AIBaseExtension.size_variation = function (self)
	return self._size_variation, self._size_variation_normalized
end

AIBaseExtension.force_enemy_detection = function (self, t)
	local num_targets = #PLAYER_AND_BOT_UNITS

	if num_targets == 0 then
		return
	end

	local target = Math.random(1, num_targets)
	local random_enemy = PLAYER_AND_BOT_UNITS[target]

	if random_enemy then
		self:enemy_aggro(self._unit, random_enemy)
	end
end

AIBaseExtension.current_action_name = function (self)
	local blackboard = self._blackboard

	return blackboard.action and blackboard.action.name or "n/a"
end

AIBaseExtension.anim_event = function (self)
	error("function is redefined in init() to either *_network or *_local")
end

AIBaseExtension.anim_event_network = function (self, event)
	local in_session = Managers.state.network and Managers.state.network:state() == "in_session"
	local game_object_id = self.game_object_id

	if in_session and game_object_id then
		local event_id = AnimationEventLookup[event]

		Managers.state.network:send_rpc_clients("rpc_anim_event", event_id, game_object_id)
	end

	self:anim_event_local(event)
end

AIBaseExtension.anim_event_local = function (self, event)
	local unit = self._unit

	Unit.animation_event(unit, event)
end

AIBaseExtension.sound_event = function (self)
	error("function is redefined in init() to either *_network or *_local")
end

AIBaseExtension.sound_event_network = function (self, event)
	local in_session = Managers.state.network and Managers.state.network:state() == "in_session"
	local game_object_id = self.game_object_id

	if in_session and game_object_id then
		local event_id = SoundEventLookup[event]

		Managers.state.network:send_rpc_clients("rpc_sound_event", event_id, game_object_id)
	end

	return self:sound_event_local(event)
end

AIBaseExtension.sound_event_local = function (self, event)
	local unit = self._unit
	local wwise_world = self._wwise_world
	local position = POSITION_LOOKUP[unit]
	local wwise_playing_id, wwise_source_id = WwiseWorld.trigger_event(wwise_world, event, position)

	return wwise_playing_id, wwise_source_id
end
