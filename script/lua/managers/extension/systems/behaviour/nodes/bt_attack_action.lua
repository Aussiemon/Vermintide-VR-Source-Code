-- chunkname: @script/lua/managers/extension/systems/behaviour/nodes/bt_attack_action.lua

require("script/lua/managers/extension/systems/behaviour/nodes/bt_node")
class("BTAttackAction", "BTNode")

BTAttackAction.init = function (self, ...)
	BTAttackAction.super.init(self, ...)
end

BTAttackAction.name = "BTAttackAction"

BTAttackAction.enter = function (self, unit, blackboard, t)
	local action = self._tree_node.action_data

	blackboard.action = action
	blackboard.active_node = BTAttackAction
	blackboard.attack_finished = false
	blackboard.attack_aborted = false
	blackboard.attack_anim = action.default_attack.anims

	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

	ai_base_extension:anim_event("to_combat")

	blackboard.attacking_target = blackboard.target_unit

	blackboard.locomotion_extension:set_wanted_velocity(Vector3.zero())
	blackboard.navigation_extension:set_enabled(false)

	local breed = blackboard.breed

	if breed.use_backstab_vo then
		ai_base_extension:sound_event("Play_clan_rat_attack_vce")
	end
end

BTAttackAction.leave = function (self, unit, blackboard, t)
	if blackboard.move_state ~= "idle" then
		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

		ai_base_extension:anim_event("idle")

		blackboard.move_state = "idle"
	end

	local default_move_speed = AiUtils.get_default_breed_move_speed(unit, blackboard)
	local navigation_extension = blackboard.navigation_extension

	navigation_extension:set_enabled(true)
	navigation_extension:set_max_speed(default_move_speed)

	blackboard.active_node = nil
	blackboard.attacking_target = nil
	blackboard.attack_anim = nil
	blackboard.action = nil
end

BTAttackAction.run = function (self, unit, blackboard, t, dt)
	if not Unit.alive(blackboard.attacking_target) then
		return "done"
	end

	if blackboard.attack_aborted then
		return "done"
	end

	if blackboard.attack_finished then
		return "done"
	end

	self:attack(unit, t, dt, blackboard)

	return "running"
end

BTAttackAction.attack = function (self, unit, t, dt, blackboard)
	if blackboard.move_state ~= "attacking" then
		blackboard.move_state = "attacking"

		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

		ai_base_extension:anim_event(blackboard.attack_anim)
	end

	local locomotion = ScriptUnit.extension(unit, "locomotion_system")
	local rotation = LocomotionUtils.rotation_towards_unit_flat(unit, blackboard.attacking_target)

	locomotion:set_wanted_rotation(rotation)
end
