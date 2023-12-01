-- chunkname: @script/lua/templates/animation_callback_templates.lua

AnimationCallbackTemplates = {}
AnimationCallbackTemplates.client = {}
AnimationCallbackTemplates.server = {}

AnimationCallbackTemplates.server.anim_cb_spawn_finished = function (unit, param)
	if not ScriptUnit.has_extension(unit, "ai_system") then
		return
	end

	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
	local blackboard = ai_base_extension:blackboard()

	blackboard.spawning_finished = true
end

AnimationCallbackTemplates.server.anim_cb_damage = function (unit, param)
	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

	if not ai_base_extension then
		return
	end

	if ai_base_extension.is_level_unit then
		ai_base_extension:level_unit_anim_cb_damage()

		return
	end

	local blackboard = ai_base_extension:blackboard()
	local target_unit = blackboard.smash_door and blackboard.smash_door.target_unit or blackboard.attacking_target or blackboard.special_attacking_target or blackboard.drag_target_unit
	local action = blackboard.action

	if not action then
		print("Missing blackboard.action in anim_cb_damage() callback")

		return
	end

	local damage = action.damage

	if not damage then
		print("Missing damage in action %s in anim_cb_damage() callback", action.name)

		return
	end

	if blackboard.attack_aborted then
		return
	end

	if blackboard.active_node and blackboard.active_node.anim_cb_damage then
		blackboard.active_node:anim_cb_damage(unit, blackboard)

		return
	end

	if not Unit.alive(target_unit) or not Unit.alive(unit) then
		return
	end

	if not action.unblockable and AiUtils.check_parry(unit, target_unit) then
		return
	end

	local damage_table = action.damage
	local level_name = blackboard.level_name
	local damage = damage_table[level_name] or damage_table.default
	local damage_type = action.damage_type

	if not ScriptUnit.has_extension(unit, "health_system") then
		return
	end

	local health_extension = ScriptUnit.extension(target_unit, "health_system")
	local params = {
		ai_attack = true,
		damage_type = damage_type
	}

	health_extension:add_damage(damage, params)

	if blackboard.active_node and blackboard.active_node.attack_success then
		blackboard.active_node:attack_success(unit, blackboard)
	end

	blackboard.anim_cb_damage = true
end

AnimationCallbackTemplates.server.anim_cb_special_damage = AnimationCallbackTemplates.server.anim_cb_damage
AnimationCallbackTemplates.server.anim_cb_ratogre_slam = AnimationCallbackTemplates.server.anim_cb_damage

AnimationCallbackTemplates.server.anim_cb_attack_finished = function (unit, param)
	if not ScriptUnit.has_extension(unit, "ai_system") then
		return
	end

	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

	if not ai_base_extension or ai_base_extension.is_level_unit then
		return
	end

	local blackboard = ai_base_extension:blackboard()

	blackboard.attacks_done = blackboard.attacks_done + 1
	blackboard.attack_finished = true
end

AnimationCallbackTemplates.server.anim_cb_shout_finished = function (unit, param)
	if not ScriptUnit.has_extension(unit, "ai_system") then
		return
	end

	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
	local blackboard = ai_base_extension:blackboard()

	blackboard.anim_cb_shout_finished = true
end

AnimationCallbackTemplates.server.anim_cb_jump_climb_finished = function (unit, param)
	if not ScriptUnit.has_extension(unit, "ai_system") then
		return
	end

	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
	local blackboard = ai_base_extension:blackboard()

	blackboard.jump_climb_finished = true
end

AnimationCallbackTemplates.server.anim_cb_stunned_finished = function (unit, param)
	if not ScriptUnit.has_extension(unit, "ai_system") then
		return
	end

	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
	local blackboard = ai_base_extension:blackboard()

	blackboard.blocked = nil
end
