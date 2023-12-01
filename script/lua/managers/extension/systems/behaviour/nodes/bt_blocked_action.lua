-- chunkname: @script/lua/managers/extension/systems/behaviour/nodes/bt_blocked_action.lua

require("script/lua/managers/extension/systems/behaviour/nodes/bt_node")
class("BTBlockedAction", "BTNode")

BTBlockedAction.name = "BTBlockedAction"

BTBlockedAction.init = function (self, ...)
	BTBlockedAction.super.init(self, ...)
end

BTBlockedAction.enter = function (self, unit, blackboard, t)
	local action = self._tree_node.action_data
	local navigation_extension = ScriptUnit.extension(unit, "ai_navigation_system")

	navigation_extension:set_enabled(false)

	blackboard.blocked = {
		id = blackboard.blocked
	}

	local anim_table = action.blocked_anims
	local block_anim = anim_table[Math.random(1, #anim_table)]
	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

	ai_base_extension:anim_event("to_combat")
	ai_base_extension:anim_event(block_anim)
	LocomotionUtils.set_animation_driven_movement(unit, true, true)

	local locomotion = ScriptUnit.extension(unit, "locomotion_system")

	locomotion:set_rotation_speed(100)
	locomotion:set_wanted_velocity(Vector3(0, 0, 0))
	locomotion:set_affected_by_gravity(true)

	blackboard.spawn_to_running = nil
end

BTBlockedAction.leave = function (self, unit, blackboard, t, dt, new_action)
	blackboard.blocked = nil

	LocomotionUtils.set_animation_driven_movement(unit, false)

	local locomotion = ScriptUnit.extension(unit, "locomotion_system")

	locomotion:set_rotation_speed(10)
	locomotion:set_wanted_rotation(nil)
	locomotion:set_affected_by_gravity(false)

	local navigation_extension = ScriptUnit.extension(unit, "ai_navigation_system")

	navigation_extension:set_enabled(true)
end

BTBlockedAction.run = function (self, unit, blackboard, t, dt)
	return "running"
end
