-- chunkname: @script/lua/managers/extension/systems/behaviour/nodes/bt_clan_rat_follow_action.lua

require("script/lua/managers/extension/systems/behaviour/nodes/bt_node")
require("script/lua/utils/global_utils")
class("BTClanRatFollowAction", "BTNode")

local LEAVE_WALK_DISTANCE_SQ = 9
local ENTER_WALK_DISTANCE_SQ = 4
local LATERAL_DISTANCE_FACTOR = 0.01
local WALK_MAX_TARGET_VELOCITY = 4
local CHASE_MIN_REQUIRED_MOVEMENT_DISTANCE = 2
local CHASE_MAX_TARGET_DISTANCE = 10
local CHASE_MAX_SPEED_INCREASE = 2
local CHASE_DEACCELERATION_DISTANCE = 1
local MATCH_TARGET_SPEED_INTERPOLATION_FACTOR = 0.2
local RUN_SPEED_INTERPOLATION_FACTOR = 0.15
local POSITION_LOOKUP = POSITION_LOOKUP
local Vector3_length = Vector3.length

BTClanRatFollowAction.init = function (self, ...)
	BTClanRatFollowAction.super.init(self, ...)

	self.next_time_to_trigger_running_dialogue = 0
	self.triggered_units = {}
end

BTClanRatFollowAction.name = "BTClanRatFollowAction"

BTClanRatFollowAction.enter = function (self, unit, blackboard, t)
	blackboard.action = self._tree_node.action_data
	blackboard.time_to_next_evaluate = t + 0.5

	if blackboard.sneaky then
		blackboard.time_to_next_friend_alert = t + 99999
	else
		blackboard.time_to_next_friend_alert = t + 0.3
	end

	local destination = blackboard.navigation_extension:destination()

	blackboard.navigation_extension:move_to(destination)

	local ai_slot_system = Managers.state.extension:system("ai_slot_system")

	ai_slot_system:do_slot_search(unit, true)

	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

	ai_base_extension:anim_event("to_combat")

	local locomotion_extension = blackboard.locomotion_extension
	local rot = LocomotionUtils.rotation_towards_unit_flat(unit, blackboard.target_unit)

	locomotion_extension:set_wanted_rotation(rot)

	local breed = blackboard.breed
	local walk_only = breed.walk_only
	local run_only = breed.run_only

	if run_only then
		return
	end

	local rat_pos = POSITION_LOOKUP[unit]

	if self:_should_walk(breed, destination, rat_pos, ENTER_WALK_DISTANCE_SQ, rot) then
		local dir = blackboard.navigation_extension:desired_velocity()
		local walk_anim = self:_calculate_walk_animation(Quaternion.right(rot), Quaternion.forward(rot), dir, rat_pos)

		if walk_anim then
			blackboard.walking = true
			blackboard.walk_timer = walk_only and math.huge or t + 3 + 1 * Math.random()

			AiAnimUtils.set_walk_animation_merge(unit, blackboard)
			ai_base_extension:anim_event(walk_anim)

			blackboard.walking_animation = walk_anim
		end
	end
end

BTClanRatFollowAction._should_walk = function (self, breed, destination, self_pos, max_distance_sq, rotation_towards_target)
	local walk_only = breed.walk_only

	if walk_only then
		return true
	end

	local diff_vector = destination - self_pos
	local direct_distance = Vector3.dot(Quaternion.forward(rotation_towards_target), diff_vector)
	local lateral_distance = Vector3.dot(Quaternion.right(rotation_towards_target), diff_vector)
	local distance_sq = direct_distance^2 + (lateral_distance * LATERAL_DISTANCE_FACTOR)^2

	return distance_sq < max_distance_sq
end

BTClanRatFollowAction.leave = function (self, unit, blackboard, t)
	blackboard.move_state = nil

	self:set_start_move_animation_lock(unit, false)

	blackboard.start_anim_locked = nil
	blackboard.anim_cb_rotation_start = nil
	blackboard.anim_cb_move = nil
	blackboard.start_anim_done = nil
	blackboard.anim_lock_fallback_time = nil
	blackboard.deacceleration_factor = nil

	local breed = blackboard.breed
	local walk_only = breed.walk_only

	if blackboard.walking and not walk_only then
		blackboard.walking = nil

		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

		ai_base_extension:anim_event("move_fwd")
	end

	local default_move_speed = AiUtils.get_default_breed_move_speed(unit, blackboard)
	local navigation_extension = blackboard.navigation_extension

	navigation_extension:set_max_speed(default_move_speed)

	self.triggered_units[unit] = nil

	AiAnimUtils.reset_animation_merge(unit)
end

local Unit_alive = Unit.alive

BTClanRatFollowAction.run = function (self, unit, blackboard, t, dt)
	Profiler.start("BTClanRatFollowAction")

	if not Unit_alive(blackboard.target_unit) then
		Profiler.stop()

		return "done"
	end

	if blackboard.walking then
		Profiler.start("follow-walk")
		self:_update_walking(unit, blackboard, dt, t)
		Profiler.stop("follow-walk")
	end

	if not blackboard.walking and not blackboard.start_anim_done then
		Profiler.start("follow-start-anim")

		if not blackboard.start_anim_locked then
			self:start_move_animation(unit, blackboard)

			blackboard.anim_lock_fallback_time = t
		end

		if blackboard.anim_cb_rotation_start then
			self:start_move_rotation(unit, blackboard, t, dt)
		end

		if blackboard.anim_cb_move or blackboard.anim_lock_fallback_time and t >= blackboard.anim_lock_fallback_time then
			blackboard.anim_cb_move = false
			blackboard.move_state = "moving"
			blackboard.anim_lock_fallback_time = nil

			self:set_start_move_animation_lock(unit, false)

			blackboard.start_anim_locked = nil
			blackboard.start_anim_done = true

			AiAnimUtils.set_move_animation_merge(unit, blackboard)
		end

		Profiler.stop("follow-start-anim")
	else
		self:follow(unit, blackboard, t, dt)
	end

	Profiler.start("reach-dest")

	local should_evaluate
	local navigation_extension = blackboard.navigation_extension

	if t > blackboard.time_to_next_evaluate or navigation_extension:has_reached_destination() then
		local prioritized_update = blackboard.have_slot == 1 and blackboard.attacks_done == 0

		should_evaluate = "evaluate"
		blackboard.time_to_next_evaluate = prioritized_update and t + 0.1 or t + 0.5
	end

	Profiler.stop("reach-dest")
	Profiler.stop()

	return "running", should_evaluate
end

BTClanRatFollowAction._update_walking = function (self, unit, blackboard, dt, t)
	local breed = blackboard.breed
	local walk_only = breed.walk_only
	local target = blackboard.target_unit
	local rot

	if walk_only then
		rot = Unit.world_rotation(unit, 1)
	else
		local locomotion_extension = blackboard.locomotion_extension

		rot = LocomotionUtils.rotation_towards_unit_flat(unit, target)

		locomotion_extension:set_wanted_rotation(rot)
	end

	local self_pos = POSITION_LOOKUP[unit]
	local target_locomotion = ScriptUnit.has_extension(target, "locomotion_system")
	local velocity_away = target_locomotion and target_locomotion.average_velocity and Vector3.dot(target_locomotion:average_velocity(), Vector3.normalize(POSITION_LOOKUP[target] - self_pos))

	if not self:_should_walk(breed, blackboard.navigation_extension:destination(), self_pos, LEAVE_WALK_DISTANCE_SQ, rot) or t > blackboard.walk_timer or velocity_away and velocity_away > WALK_MAX_TARGET_VELOCITY then
		blackboard.walking = false

		return
	end

	local dir = blackboard.navigation_extension:desired_velocity()
	local walk_anim = self:_calculate_walk_animation(Quaternion.right(rot), Quaternion.forward(rot), dir, self_pos)

	if walk_anim ~= blackboard.walking_animation then
		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

		ai_base_extension:anim_event(walk_anim)

		blackboard.walking_animation = walk_anim
	end
end

BTClanRatFollowAction._calculate_walk_animation = function (self, right_vector, forward_vector, dir, pos)
	local right_dot = Vector3.dot(right_vector, dir)
	local fwd_dot = Vector3.dot(forward_vector, dir)
	local abs_right = math.abs(right_dot)
	local abs_fwd = math.abs(fwd_dot)
	local anim
	local color = Color(255, 0, 0)

	anim = abs_fwd < abs_right and right_dot > 0 and "move_right_walk" or abs_fwd < abs_right and "move_left_walk" or fwd_dot > 0 and "move_fwd_walk" or "move_bwd_walk"

	return anim
end

BTClanRatFollowAction.follow = function (self, unit, blackboard, t, dt)
	Profiler.start("follow-follow")

	local breed = blackboard.breed
	local target_unit = blackboard.target_unit
	local target_distance = blackboard.target_dist
	local weapon_reach = breed.weapon_reach or 2
	local new_speed = 0
	local target_locomotion = ScriptUnit.has_extension(target_unit, "locomotion_system")
	local locomotion_extension = blackboard.locomotion_extension
	local current_speed = Vector3.length(locomotion_extension:current_velocity())

	if blackboard.walking then
		blackboard.deacceleration_factor = nil
		new_speed = breed.walk_speed
	elseif target_distance < 2 * weapon_reach then
		blackboard.deacceleration_factor = nil

		local lerp_value = math.max((target_distance - weapon_reach) / weapon_reach, 0)
		local target_velocity = target_locomotion and target_locomotion.average_velocity and target_locomotion:average_velocity() or Vector3.zero()
		local target_speed = Vector3.length(target_velocity) or 0
		local wanted_speed = target_speed > breed.walk_speed and target_speed or breed.walk_speed

		new_speed = math.lerp(wanted_speed, blackboard.run_speed, lerp_value)
	elseif (current_speed > blackboard.run_speed + 0.1 or blackboard.deacceleration_factor) and target_distance < 2 * weapon_reach + CHASE_DEACCELERATION_DISTANCE then
		local deaccelearation_distance_left = target_distance - weapon_reach

		if not blackboard.deacceleration_factor then
			blackboard.deacceleration_factor = (current_speed - blackboard.run_speed) / deaccelearation_distance_left
		end

		new_speed = blackboard.deacceleration_factor * deaccelearation_distance_left + blackboard.run_speed
	else
		blackboard.deacceleration_factor = nil

		local interpolation_factor = RUN_SPEED_INTERPOLATION_FACTOR
		local wanted_speed = self:_calculate_run_speed(unit, target_unit, blackboard, target_locomotion)
		local sign = math.sign(wanted_speed - current_speed)

		current_speed = sign > 0 and current_speed < blackboard.run_speed and target_distance > weapon_reach + 0.5 and blackboard.run_speed or current_speed
		new_speed = math.min(current_speed + sign * interpolation_factor * dt, wanted_speed)
	end

	local navigation_extension = blackboard.navigation_extension

	navigation_extension:set_max_speed(new_speed)
	Profiler.stop("follow-follow")
end

BTClanRatFollowAction._calculate_run_speed = function (self, unit, target_unit, blackboard, target_locomotion)
	local target_distance = blackboard.target_dist
	local destination_distance = blackboard.destination_dist
	local chase_factor = 0

	if target_locomotion and destination_distance > CHASE_MIN_REQUIRED_MOVEMENT_DISTANCE and target_distance < CHASE_MAX_TARGET_DISTANCE then
		local current_position = POSITION_LOOKUP[unit]
		local navigation_extension = blackboard.navigation_extension
		local destination = navigation_extension:destination()
		local target_velocity = target_locomotion:average_velocity()
		local move_direction = Vector3.normalize(destination - current_position)
		local target_move_direction = Vector3.normalize(target_velocity)
		local dot = Vector3.dot(target_move_direction, move_direction)

		chase_factor = math.clamp(dot, 0, 1)
	end

	local breed = blackboard.breed
	local new_speed = blackboard.run_speed + CHASE_MAX_SPEED_INCREASE * chase_factor

	return new_speed
end

BTClanRatFollowAction.start_move_animation = function (self, unit, blackboard)
	self:set_start_move_animation_lock(unit, true)

	local animation_name = AiAnimUtils.get_start_move_animation(unit, blackboard, blackboard.action)
	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

	ai_base_extension:anim_event(animation_name)

	blackboard.move_animation_name = animation_name
	blackboard.start_anim_locked = true
end

BTClanRatFollowAction.start_move_rotation = function (self, unit, blackboard, t, dt)
	if blackboard.move_animation_name == "move_start_fwd" then
		self:set_start_move_animation_lock(unit, false)

		local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")
		local rot = LocomotionUtils.rotation_towards_unit_flat(unit, blackboard.target_unit)

		locomotion_extension:set_wanted_rotation(rot)
	else
		blackboard.anim_cb_rotation_start = false

		local rot_scale = AiAnimUtils.get_animation_rotation_scale(unit, blackboard, blackboard.action)

		LocomotionUtils.set_animation_rotation_scale(unit, rot_scale)
	end
end

BTClanRatFollowAction.set_start_move_animation_lock = function (self, unit, should_lock_ani)
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	if should_lock_ani then
		locomotion_extension:use_lerp_rotation(false)
		LocomotionUtils.set_animation_driven_movement(unit, true)
	else
		locomotion_extension:use_lerp_rotation(true)
		LocomotionUtils.set_animation_driven_movement(unit, false)
		LocomotionUtils.set_animation_rotation_scale(unit, 1)
	end
end
