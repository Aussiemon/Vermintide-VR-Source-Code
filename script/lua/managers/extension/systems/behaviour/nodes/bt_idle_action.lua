-- chunkname: @script/lua/managers/extension/systems/behaviour/nodes/bt_idle_action.lua

require("script/lua/managers/extension/systems/behaviour/nodes/bt_node")
require("script/lua/utils/ai_anim_utils")
require("script/lua/utils/locomotion_utils")
class("BTIdleAction", "BTNode")

BTIdleAction.name = "BTIdleAction"

BTIdleAction.init = function (self, ...)
	BTIdleAction.super.init(self, ...)
end

BTIdleAction.enter = function (self, unit, blackboard, t)
	local network_manager = Managers.state.network
	local animation = blackboard.idle_animation or "idle"
	local action = self._tree_node.action_data

	blackboard.action = action

	AiAnimUtils.set_idle_animation_merge(unit, blackboard)

	if blackboard.is_passive then
		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

		ai_base_extension:anim_event("to_passive")
	end

	if blackboard.move_state ~= "idle" then
		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

		ai_base_extension:anim_event(animation)

		blackboard.move_state = "idle"
	end

	blackboard.navigation_extension:set_enabled(false)
	blackboard.locomotion_extension:set_wanted_velocity(Vector3.zero())
end

BTIdleAction.leave = function (self, unit, blackboard, t)
	AiAnimUtils.reset_animation_merge(unit)
	blackboard.navigation_extension:set_enabled(true)
end

local Unit_alive = Unit.alive

BTIdleAction.run = function (self, unit, blackboard, t, dt)
	local target_unit = blackboard.target_unit

	if Unit_alive(target_unit) then
		local rot = LocomotionUtils.rotation_towards_unit_flat(unit, target_unit)

		blackboard.locomotion_extension:set_wanted_rotation(rot)
	end

	return "running"
end
