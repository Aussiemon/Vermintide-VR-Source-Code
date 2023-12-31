﻿-- chunkname: @script/lua/unit_extensions/ai/ai_navigation_extension.lua

local NAVIGATION_NAVMESH_RADIUS = 0.38

script_data.debug_ai_movement = script_data.debug_ai_movement

class("AINavigationExtension")

AINavigationExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._nav_world = extension_init_data.nav_world
	self._unit = unit
	self._enabled = true
	self._max_speed = 0
	self._current_speed = 0
	self._wanted_destination = Vector3Box(Unit.local_position(unit, 1))
	self._destination = Vector3Box()
	self._debug_position_when_starting_search = Vector3Box()
	self._using_smartobject = false
	self._next_smartobject_interval = GwNavSmartObjectInterval.create(self._nav_world)
	self._failed_move_attempts = 0
	self._wait_timer = 0
	self._raycast_timer = 0

	print("### AINavigationExtension:init")
end

AINavigationExtension.extensions_ready = function (self)
	local unit = self._unit
	local blackboard = Unit.get_data(unit, "blackboard")
	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
	local blackboard = ai_base_extension:blackboard()

	self._blackboard = blackboard
	blackboard.next_smart_object_data = {
		entrance_pos = Vector3Box(),
		exit_pos = Vector3Box()
	}
	self._far_pathing_allowed = blackboard.breed.cannot_far_path ~= true
end

AINavigationExtension.destroy = function (self)
	self:release_bot()
	GwNavSmartObjectInterval.destroy(self._next_smartobject_interval)
end

AINavigationExtension.release_bot = function (self)
	if self._nav_bot then
		GwNavBot.destroy(self._nav_bot)

		self._nav_bot = nil
	end

	if self._navtag_layer_cost_table then
		GwNavTagLayerCostTable.destroy(self._navtag_layer_cost_table)
		GwNavTraverseLogicData.destroy(self._traverse_logic)

		self._navtag_layer_cost_table = nil
		self._traverse_logic = nil
	end
end

AINavigationExtension.init_position = function (self)
	local nav_world = self._nav_world
	local unit = self._unit
	local breed = Unit.get_data(unit, "breed")
	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
	local blackboard = ai_base_extension:blackboard()
	local height = 1.6
	local speed = blackboard.run_speed
	local pos = Unit.local_position(self._unit, 1)

	self._nav_bot = GwNavBot.create(nav_world, height, NAVIGATION_NAVMESH_RADIUS, speed, pos)
	self._max_speed = speed

	self._destination:store(pos)
	self._wanted_destination:store(pos)

	self._is_avoiding = breed.use_avoidance == true

	GwNavBot.set_use_avoidance(self._nav_bot, self._is_avoiding)

	if not breed.ignore_nav_propagation_box then
		GwNavBot.set_propagation_box(self._nav_bot, 30)
	end

	self._navtag_layer_cost_table = GwNavTagLayerCostTable.create()
	self._traverse_logic = GwNavTraverseLogicData.create(nav_world)

	GwNavTraverseLogicData.set_navtag_layer_cost_table(self._traverse_logic, self._navtag_layer_cost_table)

	local allowed_layers = {}

	if breed.allowed_layers then
		table.merge(allowed_layers, breed.allowed_layers)
	end

	table.merge(allowed_layers, NAV_TAG_VOLUME_LAYER_COST_AI)
	AiUtils.initialize_cost_table(self._navtag_layer_cost_table, allowed_layers)
	GwNavBot.set_navtag_layer_cost_table(self._nav_bot, self._navtag_layer_cost_table)
end

AINavigationExtension.traverse_logic = function (self)
	return self._traverse_logic
end

AINavigationExtension.nav_world = function (self)
	return self._nav_world
end

AINavigationExtension.desired_velocity = function (self)
	return GwNavBot.output_velocity(self._nav_bot)
end

AINavigationExtension.set_enabled = function (self, enabled)
	self._enabled = enabled

	if not enabled then
		self._is_following_path = false
	end
end

AINavigationExtension.set_avoidance_enabled = function (self, enabled)
	if self._nav_bot == nil then
		return
	end

	self._is_avoiding = enabled

	GwNavBot.set_use_avoidance(self._nav_bot, enabled)
end

AINavigationExtension.set_max_speed = function (self, speed)
	if self._nav_bot == nil then
		return
	end

	if self._max_speed == speed then
		return
	end

	self._max_speed = speed

	GwNavBot.set_max_desired_linear_speed(self._nav_bot, speed)
end

AINavigationExtension.get_max_speed = function (self)
	return self._max_speed
end

AINavigationExtension.set_navbot_position = function (self, position)
	GwNavBot.update_position(self._nav_bot, position)
end

AINavigationExtension.move_to = function (self, pos)
	if self._nav_bot == nil then
		return
	end

	if self._blackboard.far_path_target then
		self._backup_destination:store(pos)

		return
	end

	self._wanted_destination:store(pos)

	self._failed_move_attempts = 0
	self._is_path_found = false
end

AINavigationExtension.stop = function (self)
	local unit = self._unit
	local position = POSITION_LOOKUP[unit]

	self:move_to(position)
end

AINavigationExtension.number_failed_move_attempts = function (self)
	return self._failed_move_attempts
end

AINavigationExtension.is_following_path = function (self)
	return self._is_following_path
end

AINavigationExtension.is_computing_path = function (self)
	return self._is_computing_path
end

AINavigationExtension.reset_destination = function (self)
	if self._nav_bot == nil then
		return
	end

	local unit = self._unit
	local position = POSITION_LOOKUP[unit]

	self._wanted_destination:store(position)
	self._destination:store(position)

	self._failed_move_attempts = 0
	self._is_path_found = false

	GwNavBot.compute_new_path(self._nav_bot, position)
end

AINavigationExtension.destination = function (self)
	return self._wanted_destination:unbox()
end

AINavigationExtension.distance_to_destination = function (self, position)
	position = position or Unit.local_position(self._unit, 1)

	return Vector3.distance(position, self._wanted_destination:unbox())
end

local navigation_stop_distance_before_destinaton = 0.3

AINavigationExtension.has_reached_destination = function (self, reach_distance)
	reach_distance = reach_distance or navigation_stop_distance_before_destinaton

	local distance = self:distance_to_destination()

	return distance < reach_distance
end

AINavigationExtension.next_smart_object_data = function (self)
	return self._next_smart_object_data
end

AINavigationExtension.use_smart_object = function (self, do_use)
	if self._nav_bot == nil then
		return
	end

	local success

	if do_use then
		assert(self._blackboard.next_smart_object_data.next_smart_object_id ~= nil, "Tried to use smart object with a nil smart object id")

		success = GwNavBot.enter_manual_control(self._nav_bot, self._next_smartobject_interval)

		if not success then
			print("FAIL CANNOT GET SMART OBJECT CONTROL")
		end
	else
		success = GwNavBot.exit_manual_control(self._nav_bot)

		if not success then
			print("FAIL CANNOT RELEASE SMART OBJECT CONTROL. CLEARING FOLLOWED PATH...")
			GwNavBot.clear_followed_path(self._nav_bot)
		end
	end

	local using_smart_object = do_use and success

	self._using_smartobject = using_smart_object
	self._blackboard.using_smart_object = using_smart_object

	return success
end

AINavigationExtension.is_using_smart_object = function (self)
	return self._using_smartobject
end

AINavigationExtension.allow_layer = function (self, layer_name, layer_allowed)
	if self._nav_bot == nil then
		return
	end

	local layer_id = LAYER_ID_MAPPING[layer_name]

	if layer_allowed then
		GwNavTagLayerCostTable.allow_layer(self._navtag_layer_cost_table, layer_id)
	else
		GwNavTagLayerCostTable.forbid_layer(self._navtag_layer_cost_table, layer_id)
	end
end

AINavigationExtension.set_layer_cost = function (self, layer_name, layer_cost)
	if self._nav_bot == nil then
		return
	end

	local layer_id = LAYER_ID_MAPPING[layer_name]

	GwNavTagLayerCostTable.set_layer_cost_multiplier(self._navtag_layer_cost_table, layer_id, layer_cost)
end
