-- chunkname: @script/lua/utils/perception_utils.lua

require("script/lua/utils/global_utils")
require("script/lua/utils/ai_utils")

PerceptionUtils = {}

local AiUtils_unit_alive = AiUtils.unit_alive
local unit_alive = Unit.alive
local unit_knocked_down = AiUtils.unit_knocked_down
local POSITION_LOOKUP = POSITION_LOOKUP
local AI_TARGET_UNITS = AI_TARGET_UNITS
local PLAYER_AND_BOT_UNITS = PLAYER_AND_BOT_UNITS
local PLAYER_AND_BOT_POSITIONS = PLAYER_AND_BOT_POSITIONS
local PLAYER_UNITS = PLAYER_UNITS
local AI_UTILS = AI_UTILS
local ScriptUnit_extension = ScriptUnit.extension
local DOGPILE_SCORE = 2.5
local DISABLED_SLOT_SCORE = 2.5
local ALL_SLOTS_DISABLED_SCORE = 600
local STICKY_AGGRO_RANGE_SQUARED = 5.0625
local HIGHER_STICKINESS_RANGE_SQUARED = 4
local DISTANCE_SCORE = 0.25

local function _calculate_horde_pick_closest_target_with_spillover_score(target_unit, target_current, previous_attacker, ai_unit_position, breed, perception_previous_attacker_stickyness_value)
	local target_type = Unit.get_data(target_unit, "target_type")
	local exceptions = target_type and breed.perception_exceptions and breed.perception_exceptions[target_type]

	if exceptions then
		return
	end

	local dogpile_count = 0
	local disabled_slots_count = 0
	local all_slots_disabled = false
	local is_previous_attacker = previous_attacker and previous_attacker == target_unit

	if ScriptUnit.has_extension(target_unit, "ai_slot_system") then
		local target_slot_extension = ScriptUnit.extension(target_unit, "ai_slot_system")

		if not target_slot_extension.valid_target then
			return
		end

		dogpile_count = target_slot_extension.slots_count

		local total_slots_count = target_slot_extension.total_slots_count

		disabled_slots_count = target_slot_extension.disabled_slots_count
		all_slots_disabled = disabled_slots_count == total_slots_count

		local status_ext = ScriptUnit.has_extension(target_unit, "status_system")
		local on_ladder = status_ext and status_ext:get_is_on_ladder()

		if on_ladder then
			local max_allowed = is_previous_attacker and total_slots_count or total_slots_count - 1

			if max_allowed < dogpile_count then
				all_slots_disabled = true
			end
		end
	end

	local target_unit_position = POSITION_LOOKUP[target_unit]
	local distance_sq = Vector3.distance_squared(ai_unit_position, target_unit_position)
	local aggro_extension = ScriptUnit.extension(target_unit, "aggro_system")
	local aggro_modifier = aggro_extension.aggro_modifier
	local is_knocked_down = unit_knocked_down(target_unit)

	if distance_sq < STICKY_AGGRO_RANGE_SQUARED and not is_knocked_down then
		dogpile_count = math.max(dogpile_count - 4, 0)
	end

	local stickyness_modifier

	stickyness_modifier = distance_sq < HIGHER_STICKINESS_RANGE_SQUARED and -5 or -2.5

	local score_dogpile = dogpile_count * DOGPILE_SCORE
	local score_distance = distance_sq * DISTANCE_SCORE
	local score_stickyness = target_unit == target_current and stickyness_modifier or 0
	local knocked_down_modifer = is_knocked_down and 5 or 0
	local previous_attacker_stickyness_value = is_previous_attacker and perception_previous_attacker_stickyness_value or 0
	local score_disabled_slots = disabled_slots_count * DISABLED_SLOT_SCORE
	local score_all_slots_disabled = all_slots_disabled and ALL_SLOTS_DISABLED_SCORE or 0
	local score = score_dogpile + score_distance + score_disabled_slots + score_all_slots_disabled + score_stickyness + previous_attacker_stickyness_value + knocked_down_modifer + aggro_modifier

	return score, distance_sq
end

PerceptionUtils.horde_pick_closest_target_with_spillover = function (ai_unit, blackboard, breed, t)
	assert(ScriptUnit.has_extension(ai_unit, "ai_slot_system"))

	local ai_unit_position = POSITION_LOOKUP[ai_unit]
	local target_current = blackboard.target_unit
	local best_target_unit
	local best_score = math.huge
	local targets = AI_TARGET_UNITS
	local perception_previous_attacker_stickyness_value = breed.perception_previous_attacker_stickyness_value
	local previous_attacker = blackboard.previous_attacker
	local distance_to_target_sq
	local using_override_target = false
	local override_targets = blackboard.override_targets

	for target_unit, end_of_override_t in pairs(override_targets) do
		local target_unit_alive = unit_alive(target_unit)
		local status_extension = target_unit_alive and ScriptUnit.extension(target_unit, "status_system")
		local is_incapacitated = target_unit_alive and status_extension and status_extension:is_disabled()

		if not target_unit_alive or end_of_override_t < t or is_incapacitated then
			override_targets[target_unit] = nil
		else
			local score, distance_sq = _calculate_horde_pick_closest_target_with_spillover_score(target_unit, target_current, previous_attacker, ai_unit_position, breed, perception_previous_attacker_stickyness_value)

			if score and score < best_score then
				best_score = score
				best_target_unit = target_unit
				distance_to_target_sq = distance_sq
				using_override_target = true
			end
		end
	end

	blackboard.using_override_target = using_override_target

	if not using_override_target then
		for i_target, target_unit in ipairs(targets) do
			local score, distance_sq = _calculate_horde_pick_closest_target_with_spillover_score(target_unit, target_current, previous_attacker, ai_unit_position, breed, perception_previous_attacker_stickyness_value)

			if score and score < best_score then
				best_score = score
				best_target_unit = target_unit
				distance_to_target_sq = distance_sq
			end
		end
	end

	return best_target_unit, distance_to_target_sq
end

PerceptionUtils.perception_regular = function (unit, blackboard, breed, pick_target_func, t)
	local target_unit = blackboard.target_unit
	local target_alive = AiUtils_unit_alive(target_unit)
	local best_enemy = pick_target_func(unit, blackboard, breed, t)

	if target_unit and target_alive and best_enemy == target_unit then
		-- Nothing
	else
		if best_enemy and best_enemy ~= target_unit then
			blackboard.previous_target_unit = blackboard.target_unit
			blackboard.target_unit = best_enemy
			blackboard.target_unit_found_time = t
			blackboard.slot = nil
			blackboard.slot_layer = nil
			blackboard.is_passive = false
		elseif blackboard.delayed_target_unit and AiUtils_unit_alive(blackboard.delayed_target_unit) and blackboard.target_unit == nil then
			blackboard.previous_target_unit = blackboard.target_unit
			blackboard.target_unit = blackboard.delayed_target_unit
			blackboard.target_unit_found_time = t
			blackboard.is_passive = false
		else
			blackboard.target_unit = nil
		end

		blackboard.delayed_target_unit = nil
	end
end
