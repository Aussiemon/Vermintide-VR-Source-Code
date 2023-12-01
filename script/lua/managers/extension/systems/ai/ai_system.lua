-- chunkname: @script/lua/managers/extension/systems/ai/ai_system.lua

require("script/lua/managers/extension/systems/behaviour/behaviour_tree")
require("script/lua/managers/extension/systems/extension_system_base")
require("settings/breeds")
require("settings/level_settings")
require("settings/network_lookup")
require("script/lua/utils/perception_utils")

VISUAL_DEBUGGING_ENABLED = VISUAL_DEBUGGING_ENABLED or false

local script_data = script_data
local POSITION_LOOKUP = POSITION_LOOKUP
local Vector3_flat = Vector3.flat
local Vector3_distance = Vector3.distance
local Vector3_dot = Vector3.dot
local Vector3_normalize = Vector3.normalize
local Vector3_length = Vector3.length
local sqrt = math.sqrt
local unit_alive = Unit.alive
local ai_trees_created = false

class("AISystem", "ExtensionSystemBase")

AISystem.extension_list = {
	"AIBaseExtension",
	"AIHuskBaseExtension",
	"AILevelUnitBaseExtension"
}

AISystem.init = function (self, extension_system_creation_context, system_name, extension_list)
	AISystem.super.init(self, extension_system_creation_context, system_name, extension_list)

	self._behavior_trees = {}

	self:create_all_trees()

	if Managers.state.network then
		local network = Managers.lobby
		local is_server = network.server

		self._network_mode = is_server and "server" or "client"

		Managers.state.network:register_game_object_callback(self, "ai_unit", "ai_unit_game_object_created", "ai_unit_game_object_destroyed")
		Managers.state.network:register_game_object_callback(self, "ai_level_unit", "ai_level_unit_game_object_created", "ai_unit_game_object_destroyed")
		Managers.state.network:register_rpc_callbacks(self, "rpc_anim_event", "rpc_sound_event", "rpc_sync_anim_state_1", "rpc_sync_anim_state_3", "rpc_sync_anim_state_4", "rpc_sync_anim_state_5", "rpc_sync_anim_state_7", "rpc_sync_anim_state_9", "rpc_sync_anim_state_11")
	else
		self._network_mode = "local"
	end

	self._extension_init_context.network_mode = self._network_mode
	self._remote_units = {}
	self._game_object_ids = {}
	self._nav_world = GwNavWorld.create(Matrix4x4.identity())
	self._wwise_world = Wwise.wwise_world(self._world)

	if not script_data.navigation_thread_disabled then
		GwNavWorld.init_async_update(self._nav_world)
	end

	local level_name = self._level_name
	local level_settings = LevelSettings.levels[level_name]
	local level_resource = level_settings.resource_name

	self._nav_data = GwNavWorld.add_navdata(self._nav_world, level_resource)

	local enable_crowd_dispersion = not script_data.disable_crowd_dispersion

	if enable_crowd_dispersion then
		GwNavWorld.enable_crowd_dispersion(self._nav_world)
	end

	self.unit_extension_data = {}
	self.blackboards = {}
	self.ai_blackboard_updates = {}
	self.ai_blackboard_prioritized_updates = {}
	self.ai_update_index = 1
	self._units_to_destroy = {}
	self.ai_units_alive = {}
	self.ai_units_perception_continuous = {}
	self.ai_units_perception = {}
	self.ai_units_perception_prioritized = {}
	self.num_perception_units = 0
	self.number_ordinary_aggroed_enemies = 0
	self.number_special_aggored_enemies = 0
	self.start_prio_index = 1
	self._ai_level_units = {}
	self._ai_level_units_gameobjects_id = {}
end

AISystem.destroy = function (self)
	AISystem.super.destroy(self)

	if self.ai_debugger then
		self.ai_debugger:destroy()
	end

	if self._nav_data then
		GwNavWorld.remove_navdata(self._nav_data)
	end

	GwNavWorld.destroy(self._nav_world)
end

AISystem.ai_unit_game_object_created = function (self, object_type, session, game_object_id, owner)
	local breed_id = GameSession.game_object_field(session, game_object_id, "breed_index")
	local breed_name = BreedLookup[breed_id]
	local breed = Breeds[breed_name]
	local unit_name = breed.base_unit
	local position = GameSession.game_object_field(session, game_object_id, "position")
	local rotation = GameSession.game_object_field(session, game_object_id, "rotation")
	local inventory_init_data

	if breed.has_inventory then
		inventory_init_data = {
			inventory_template = breed.default_inventory_template
		}
	end

	local max_health = Managers.state.spawn:breed_max_health(breed_name)
	local extension_data = {
		AIHuskBaseExtension = {
			breed = breed,
			game_object_id = game_object_id
		},
		AIHuskLocomotionExtension = {
			breed = breed,
			game_object_id = game_object_id
		},
		HealthExtension = {
			health = max_health,
			ragdoll_on_death = breed.ragdoll_on_death,
			breed_name = breed_name
		},
		AIHitReactionExtension = {
			breed_name = breed_name
		},
		AIInventoryExtension = inventory_init_data
	}
	local unit = Managers.state.spawn:spawn_unit(unit_name, extension_data, position, rotation)

	self._remote_units[game_object_id] = unit
	self._game_object_ids[unit] = game_object_id
end

AISystem.ai_unit_game_object_destroyed = function (self, object_type, session, game_object_id, owner)
	local unit = self._remote_units[game_object_id]

	Managers.state.extension:unregister_unit(unit)
	Managers.state.spawn:mark_for_deletion(unit)
end

AISystem.ai_level_unit_game_object_created = function (self, object_type, session, game_object_id, owner)
	local unit_level_id = GameSession.game_object_field(session, game_object_id, "unit_level_id")
	local unit = self._ai_level_units[unit_level_id]

	if unit then
		self._remote_units[game_object_id] = unit
		self._game_object_ids[unit] = game_object_id

		printf("[CLIENT] gameobject created callback ai_level_unit with unit_level_id %d game_object_id %d", unit_level_id, game_object_id)
	else
		self._ai_level_units_gameobjects_id[unit_level_id] = game_object_id

		printf("[CLIENT] gameobject created callback ai_level_unit with unit_level_id %d game_object_id %d, unit not created on client yet", unit_level_id, game_object_id)
	end
end

AISystem.on_add_extension = function (self, world, unit, extension_name, extension_init_data)
	local extension = AISystem.super.on_add_extension(self, world, unit, extension_name, extension_init_data)

	self.unit_extension_data[unit] = extension

	if not extension.is_husk and extension_name ~= "AILevelUnitBaseExtension" then
		if not extension.is_bot then
			self.ai_blackboard_updates[#self.ai_blackboard_updates + 1] = unit
		end

		self.blackboards[unit] = extension:blackboard()

		self:set_default_blackboard_values(unit, extension:blackboard())
	end

	if extension_name == "AIBaseExtension" then
		self.ai_units_alive[unit] = extension

		local breed = extension._breed

		if breed.perception_continuous then
			self.ai_units_perception_continuous[unit] = extension
		else
			self.ai_units_perception[unit] = extension
		end

		self.num_perception_units = self.num_perception_units + 1
	end

	if extension_name == "AILevelUnitBaseExtension" then
		local unit_level_id = extension.unit_level_id
		local game_object_id = self._ai_level_units_gameobjects_id[unit_level_id]

		if game_object_id then
			self._remote_units[game_object_id] = unit
			self._game_object_ids[unit] = game_object_id

			printf("[%s] created unit with level id %d, mapping it to game_object_id %d", string.upper(self._network_mode), unit_level_id, game_object_id)
		else
			printf("[%s] created unit with level id %d, no game_object_id", string.upper(self._network_mode), unit_level_id)
		end

		self._ai_level_units[unit_level_id] = unit
	end

	return extension
end

AISystem.set_default_blackboard_values = function (self, unit, blackboard)
	blackboard.destination_dist = 0
	blackboard.current_health_percent = 1
	blackboard.have_slot = 0
	blackboard.wait_slot_distance = math.huge
	blackboard.target_dist = math.huge
	blackboard.target_dist_z = math.huge
	blackboard.target_dist_xy_sq = math.huge
	blackboard.ally_distance = math.huge
	blackboard.slot_dist_z = math.huge
	blackboard.move_speed = 0
	blackboard.total_slots_count = 0
	blackboard.target_speed_away = 0
end

AISystem.on_remove_extension = function (self, unit, extension_name)
	local game_object_id = self._game_object_ids[unit]

	if game_object_id then
		self._game_object_ids[unit] = nil
		self._remote_units[game_object_id] = nil
	end

	self:on_freeze_extension(unit, extension_name)
	AISystem.super.on_remove_extension(self, unit, extension_name)
end

AISystem.on_freeze_extension = function (self, unit, extension_name)
	if self.unit_extension_data[unit] == nil then
		return
	end

	self.unit_extension_data[unit] = nil

	local ai_blackboard_updates = self.ai_blackboard_updates
	local ai_blackboard_updates_n = #ai_blackboard_updates
	local ai_blackboard_prioritized_updates = self.ai_blackboard_prioritized_updates
	local ai_blackboard_prioritized_updates_n = #ai_blackboard_prioritized_updates

	for i = 1, ai_blackboard_updates_n do
		if ai_blackboard_updates[i] == unit then
			ai_blackboard_updates[i] = ai_blackboard_updates[ai_blackboard_updates_n]
			ai_blackboard_updates[ai_blackboard_updates_n] = nil
		end
	end

	for i = 1, ai_blackboard_prioritized_updates_n do
		if ai_blackboard_prioritized_updates[i] == unit then
			ai_blackboard_prioritized_updates[i] = ai_blackboard_prioritized_updates[ai_blackboard_prioritized_updates_n]
			ai_blackboard_prioritized_updates[ai_blackboard_prioritized_updates_n] = nil
		end
	end

	self.blackboards[unit] = nil
	self.ai_units_alive[unit] = nil
	self.ai_units_perception[unit] = nil
	self.ai_units_perception_continuous[unit] = nil
	self.ai_units_perception_prioritized[unit] = nil

	if extension_name == "AIBaseExtension" then
		self.num_perception_units = self.num_perception_units - 1
	end
end

AISystem.register_prioritized_perception_unit_update = function (self, unit, ai_extension)
	self.ai_units_perception_prioritized[unit] = ai_extension
end

AISystem.update = function (self, dt, t)
	Profiler.start("AISystem")
	AISystem.super.update(self, dt, t)
	self:update_alive()
	self:update_perception(t, dt)
	self:update_brains(t, dt)
	Profiler.start("GwNavWorld.update")
	GwNavWorld.update(self._nav_world, dt)
	Profiler.stop("GwNavWorld.update")
	Profiler.stop("AISystem")
end

AISystem.update_alive = function (self)
	Profiler.start("update_alive")

	for unit, extension in pairs(self.ai_units_alive) do
		local is_alive = extension.health_extension:is_alive()

		if not is_alive then
			self.ai_units_alive[unit] = nil
			self.ai_units_perception[unit] = nil
			self.ai_units_perception_continuous[unit] = nil
			self.ai_units_perception_prioritized[unit] = nil
		end
	end

	Profiler.stop("update_alive")
end

AISystem.update_perception = function (self, t, dt)
	if script_data.disable_ai_perception then
		return
	end

	Profiler.start("update_perception")

	local PerceptionUtils = PerceptionUtils
	local ai_units_perception = self.ai_units_perception

	Profiler.start("continuous")

	for unit, extension in pairs(self.ai_units_perception_continuous) do
		local blackboard = extension._blackboard
		local breed = extension._breed
		local perception_continuous_name = breed.perception_continuous
		local perception_function = PerceptionUtils[perception_continuous_name]

		Profiler.start(perception_continuous_name)

		local needs_perception = perception_function(unit, blackboard, breed, t, dt)

		ai_units_perception[unit] = needs_perception and extension or nil

		Profiler.stop(perception_continuous_name)
	end

	Profiler.stop("continuous")
	Profiler.start("prioritized perception")

	local ai_units_perception_prioritized = self.ai_units_perception_prioritized

	for unit, extension in pairs(ai_units_perception_prioritized) do
		local blackboard = extension._blackboard
		local breed = extension._breed
		local target_selection_func_name = extension._target_selection_func_name
		local perception_func_name = extension._perception_func_name
		local perception_function = PerceptionUtils[perception_func_name]
		local target_selection_function = PerceptionUtils[target_selection_func_name]

		Profiler.start(target_selection_func_name)
		perception_function(unit, blackboard, breed, target_selection_function, t, dt)
		Profiler.stop(target_selection_func_name)

		ai_units_perception_prioritized[unit] = nil
	end

	Profiler.stop("prioritized perception")
	Profiler.start("perception")

	local current_perception_unit = self.current_perception_unit

	current_perception_unit = self.ai_units_perception[current_perception_unit] ~= nil and current_perception_unit or nil

	local TIME_BETWEEN_UPDATE = 1
	local num_perception_units = self.num_perception_units
	local num_to_update = math.ceil(num_perception_units * dt / TIME_BETWEEN_UPDATE)

	for i = 1, num_to_update do
		current_perception_unit = next(ai_units_perception, current_perception_unit)

		if current_perception_unit == nil then
			break
		end

		local extension = ai_units_perception[current_perception_unit]
		local blackboard = extension._blackboard
		local breed = extension._breed
		local target_selection_func_name = extension._target_selection_func_name
		local perception_func_name = extension._perception_func_name
		local perception_function = PerceptionUtils[perception_func_name]
		local target_selection_function = PerceptionUtils[target_selection_func_name]

		Profiler.start(target_selection_func_name)
		perception_function(current_perception_unit, blackboard, breed, target_selection_function, t, dt)
		Profiler.stop(target_selection_func_name)
	end

	Profiler.stop("perception")

	self.current_perception_unit = current_perception_unit

	Profiler.stop("update_perception")
end

local PRIORITIZED_DISTANCE = 10

local function update_blackboard(unit, blackboard, nav_world, t, dt)
	assert(blackboard)

	local POSITION_LOOKUP = POSITION_LOOKUP

	if blackboard.is_in_attack_cooldown then
		blackboard.is_in_attack_cooldown = t < blackboard.attack_cooldown_at
	end

	local destination = blackboard.navigation_extension:destination()
	local current_position = POSITION_LOOKUP[unit]

	blackboard.destination_dist = Vector3_distance(current_position, destination)

	local ai_slot_system = Managers.state.extension:system("ai_slot_system")

	blackboard.have_slot = ai_slot_system:ai_unit_have_slot(unit) and 1 or 0
	blackboard.wait_slot_distance = ai_slot_system:ai_unit_wait_slot_distance(unit)
	blackboard.total_slots_count = ai_slot_system.total_slots_count

	local target_unit = blackboard.target_unit
	local target_alive = unit_alive(target_unit)
	local breed = blackboard.breed
	local locomotion_extension = blackboard.locomotion_extension

	blackboard.is_falling = locomotion_extension and locomotion_extension:is_falling()
	blackboard.move_speed = locomotion_extension and locomotion_extension.move_speed

	if blackboard.next_smart_object_data then
		local smart_object_type = blackboard.next_smart_object_data.smart_object_type

		if smart_object_type == "doors" or smart_object_type == "planks" then
			local door_system = blackboard.door_system or Managers.state.entity:system("door_system")
			local door_unit = blackboard.next_smart_object_data.smart_object_data.unit
			local door_is_open = door_system.unit_extension_data[door_unit].current_state ~= "closed"

			blackboard.next_smart_object_data.disabled = door_is_open
		end
	end

	if target_alive then
		local unit_position = POSITION_LOOKUP[unit]
		local target_position = POSITION_LOOKUP[target_unit]
		local altitude = GwNavQueries.triangle_from_position(nav_world, target_position, 0.5, 20)
		local target_position_on_nav_mesh = altitude and Vector3(target_position.x, target_position.y, altitude) or target_position - Vector3.up() * 1.25
		local offset = target_position_on_nav_mesh - unit_position
		local z = offset.z
		local x = offset.x
		local y = offset.y
		local flat_sq = x * x + y * y

		blackboard.target_dist_z = z
		blackboard.target_dist_xy_sq = flat_sq

		local target_dist = sqrt(flat_sq + z * z)
		local inside_priority_distance = target_dist < PRIORITIZED_DISTANCE

		blackboard.target_dist = target_dist
		blackboard.target_dist_flat = sqrt(flat_sq)

		local slot_pos = ai_slot_system:ai_unit_slot_position(unit) or current_position

		blackboard.slot_dist_z = slot_pos.z - current_position.z

		return inside_priority_distance
	else
		blackboard.target_unit = nil
		blackboard.target_dist = math.huge
		blackboard.target_dist_z = math.huge
		blackboard.target_dist_xy_sq = math.huge
		blackboard.slot_dist_z = math.huge
	end

	return false
end

AISystem.update_brains = function (self, t, dt)
	Profiler.start("update_brains")

	for unit, extension in pairs(self.ai_units_alive) do
		local bt = extension._brain._bt
		local blackboard = extension._blackboard

		update_blackboard(unit, blackboard, self._nav_world, t, dt)

		local result = bt:root():evaluate(unit, blackboard, t, dt)
	end

	Profiler.stop("update_brains")
end

AISystem.nav_world = function (self)
	return self._nav_world
end

AISystem.get_tri_on_navmesh = function (self, pos)
	return GwNavQueries.triangle_from_position(self._nav_world, pos, 30, 30)
end

AISystem.create_all_trees = function (self)
	ai_trees_created = true

	for tree_name, root in pairs(BreedBehaviors) do
		local tree = BehaviorTree:new(root, tree_name)

		self._behavior_trees[tree_name] = tree
	end
end

AISystem.behavior_tree = function (self, tree_name)
	return self._behavior_trees[tree_name]
end

AISystem.remote_unit = function (self, game_object_id)
	local unit = self._remote_units[game_object_id]

	return unit
end

AISystem.game_object_id = function (self, unit)
	local game_object_id = self._game_object_ids[unit]

	fassert(game_object_id, "AISystem:unit_game_object_id no game_object_id matching unit")

	return game_object_id
end

AISystem.rpc_anim_event = function (self, sender, event_id, game_object_id)
	local unit = self:remote_unit(game_object_id)
	local event = AnimationEventLookup[event_id]

	Unit.animation_event(unit, event)
end

AISystem.rpc_sound_event = function (self, sender, event_id, game_object_id)
	local unit = self:remote_unit(game_object_id)
	local event = SoundEventLookup[event_id]
	local wwise_world = self._wwise_world
	local position = POSITION_LOOKUP[unit]
	local wwise_playing_id, wwise_source_id = WwiseWorld.trigger_event(wwise_world, event, position)
end

AISystem.rpc_sync_anim_state = function (self, sender, game_object_id, ...)
	local unit = self:remote_unit(game_object_id)

	Unit.animation_set_state(unit, ...)
end

AISystem.rpc_sync_anim_state_1 = AISystem.rpc_sync_anim_state
AISystem.rpc_sync_anim_state_3 = AISystem.rpc_sync_anim_state
AISystem.rpc_sync_anim_state_4 = AISystem.rpc_sync_anim_state
AISystem.rpc_sync_anim_state_5 = AISystem.rpc_sync_anim_state
AISystem.rpc_sync_anim_state_7 = AISystem.rpc_sync_anim_state
AISystem.rpc_sync_anim_state_9 = AISystem.rpc_sync_anim_state
AISystem.rpc_sync_anim_state_11 = AISystem.rpc_sync_anim_state
