-- chunkname: @script/lua/managers/extension/systems/behaviour/nodes/bt_conditions.lua

BTConditions = BTConditions or {}

local unit_alive = Unit.alive
local ScriptUnit = ScriptUnit

BTConditions.always_true = function (blackboard)
	return true
end

BTConditions.always_false = function (blackboard)
	return false
end

BTConditions.spawn = function (blackboard)
	return blackboard.spawn
end

BTConditions.blocked = function (blackboard)
	return blackboard.blocked
end

BTConditions.can_see_target = function (blackboard)
	return unit_alive(blackboard.target_unit)
end

BTConditions.target_reached = function (blackboard)
	local attacking_target = blackboard.special_attacking_target or blackboard.attacking_target

	if attacking_target then
		return true
	end

	local target_unit = blackboard.target_unit
	local target_dist = blackboard.target_dist
	local target_is_player = ScriptUnit.extension(target_unit, "head_system")
	local breed = blackboard.breed
	local reach_distance = target_is_player and breed.reach_distance or breed.door_reach_distance
	local in_reach_distance = target_dist <= reach_distance

	return in_reach_distance
end

BTConditions.wait_slot_reached = function (blackboard)
	return blackboard.wait_slot_distance and blackboard.wait_slot_distance <= 2
end

BTConditions.level_ended = function (blackboard)
	return Managers.state.game_mode:end_conditions_met()
end

BTConditions.is_dead = function (blackboard)
	return blackboard.is_dead
end

BTConditions.at_smartobject = function (blackboard)
	local smartobject_is_next = blackboard.next_smart_object_data.next_smart_object_id ~= nil
	local is_in_smartobject_range = blackboard.is_in_smartobject_range
	local is_smart_objecting = blackboard.is_smart_objecting

	return smartobject_is_next and is_in_smartobject_range or is_smart_objecting
end

BTConditions.at_climb_smartobject = function (blackboard)
	local smart_object_type = blackboard.next_smart_object_data.smart_object_type
	local is_smart_object_ledge = smart_object_type == "ledges" or smart_object_type == "ledges_with_fence"
	local is_climbing = blackboard.is_climbing

	return is_smart_object_ledge or is_climbing
end
