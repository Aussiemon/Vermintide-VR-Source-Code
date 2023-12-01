-- chunkname: @script/lua/managers/extension/systems/behaviour/nodes/bt_storm_vermin_attack_action.lua

require("script/lua/managers/extension/systems/behaviour/nodes/bt_node")
class("BTStormVerminAttackAction", "BTNode")

BTStormVerminAttackAction.init = function (self, ...)
	BTStormVerminAttackAction.super.init(self, ...)
end

BTStormVerminAttackAction.name = "BTStormVerminAttackAction"

BTStormVerminAttackAction.enter = function (self, unit, blackboard, t)
	local action = self._tree_node.action_data

	blackboard.action = action
	blackboard.active_node = BTStormVerminAttackAction
	blackboard.attack_range = action.range
	blackboard.attack_finished = false
	blackboard.attack_aborted = false

	local target_unit = blackboard.target_unit

	blackboard.target_unit_status_extension = ScriptUnit.has_extension(target_unit, "status_system") and ScriptUnit.extension(target_unit, "status_system") or nil

	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

	ai_base_extension:anim_event("to_combat")

	local navigation_extension = blackboard.navigation_extension

	blackboard.navigation_extension:set_enabled(false)
	blackboard.locomotion_extension:set_wanted_velocity(Vector3.zero())

	blackboard.special_attacking_target = blackboard.target_unit

	self:_init_attack(unit, blackboard, t)
end

BTStormVerminAttackAction._init_attack = function (self, unit, blackboard, t)
	local action = blackboard.action
	local attack_anim = action.attack_anim

	if type(attack_anim) == "table" then
		local random_anim = Math.random(#attack_anim)

		attack_anim = attack_anim[random_anim]
	end

	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

	ai_base_extension:anim_event(attack_anim)

	blackboard.move_state = "attacking"

	local rotation = LocomotionUtils.rotation_towards_unit_flat(unit, blackboard.special_attacking_target)

	blackboard.attack_rotation = QuaternionBox(rotation)
	blackboard.attack_rotation_update_timer = t + action.rotation_time
end

BTStormVerminAttackAction.leave = function (self, unit, blackboard, t)
	blackboard.move_state = nil

	blackboard.navigation_extension:set_enabled(true)

	blackboard.target_unit_status_extension = nil
	blackboard.update_timer = 0
	blackboard.active_node = nil
	blackboard.attack_aborted = nil
	blackboard.attack_rotation = nil
	blackboard.attack_rotation_update_timer = nil
	blackboard.special_attacking_target = nil
end

BTStormVerminAttackAction.run = function (self, unit, blackboard, t, dt)
	if Unit.alive(blackboard.special_attacking_target) then
		self:attack(unit, t, dt, blackboard)
	end

	if blackboard.attack_finished then
		return "done"
	end

	return "running"
end

BTStormVerminAttackAction.attack = function (self, unit, t, dt, blackboard)
	local locomotion = ScriptUnit.extension(unit, "locomotion_system")

	if t < blackboard.attack_rotation_update_timer and blackboard and blackboard.target_unit_status_extension and not blackboard.target_unit_status_extension:get_is_dodging() then
		local rotation = LocomotionUtils.rotation_towards_unit_flat(unit, blackboard.special_attacking_target)

		blackboard.attack_rotation = QuaternionBox(rotation)
	end

	locomotion:set_wanted_rotation(blackboard.attack_rotation:unbox())
end

local debug_drawer_info = {
	mode = "retained",
	name = "BTStormVerminAttackAction"
}
