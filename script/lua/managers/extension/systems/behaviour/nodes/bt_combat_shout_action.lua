-- chunkname: @script/lua/managers/extension/systems/behaviour/nodes/bt_combat_shout_action.lua

require("script/lua/managers/extension/systems/behaviour/nodes/bt_node")
class("BTCombatShoutAction", "BTNode")

BTCombatShoutAction.init = function (self, ...)
	BTCombatShoutAction.super.init(self, ...)
end

BTCombatShoutAction.name = "BTCombatShoutAction"

BTCombatShoutAction.enter = function (self, unit, blackboard, t)
	local action = self._tree_node.action_data

	blackboard.action = action
	blackboard.anim_cb_shout_finished = nil

	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

	ai_base_extension:anim_event("to_combat")
	ai_base_extension:anim_event(action.shout_anim)

	local navigation_extension = blackboard.navigation_extension

	navigation_extension:set_enabled(false)
	blackboard.locomotion_extension:set_wanted_velocity(Vector3(0, 0, 0))

	if blackboard.target_unit then
		local rotation = LocomotionUtils.rotation_towards_unit_flat(unit, blackboard.target_unit)
		local locomotion = ScriptUnit.extension(unit, "locomotion_system")

		locomotion:set_wanted_rotation(rotation)
	end
end

BTCombatShoutAction.leave = function (self, unit, blackboard, t)
	blackboard.update_timer = 0

	local navigation_extension = blackboard.navigation_extension

	navigation_extension:set_enabled(true)
end

BTCombatShoutAction.run = function (self, unit, blackboard, t, dt)
	if blackboard.target_unit then
		local locomotion_extension = blackboard.locomotion_extension
		local rot = LocomotionUtils.rotation_towards_unit_flat(unit, blackboard.target_unit)

		locomotion_extension:set_wanted_rotation(rot)
	end

	if blackboard.anim_cb_shout_finished then
		return "done"
	end

	return "running"
end
