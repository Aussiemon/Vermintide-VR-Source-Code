-- chunkname: @script/lua/managers/extension/systems/behaviour/nodes/bt_spawning_action.lua

require("script/lua/managers/extension/systems/behaviour/nodes/bt_node")
require("script/lua/utils/ai_utils")
require("script/lua/utils/locomotion_utils")
class("BTSpawningAction", "BTNode")

BTSpawningAction.init = function (self, ...)
	BTSpawningAction.super.init(self, ...)
end

BTSpawningAction.name = "BTSpawningAction"

local unit_alive = Unit.alive

BTSpawningAction.enter = function (self, unit, blackboard, t)
	Unit.set_animation_root_mode(unit, "ignore")

	if blackboard.spawn_type == "horde" then
		local ai_extension = ScriptUnit.extension(unit, "ai_system")
		local animation_translation_scale = 1 / ai_extension:size_variation()

		LocomotionUtils.set_animation_translation_scale(unit, Vector3(animation_translation_scale, animation_translation_scale, animation_translation_scale))

		local locomotion_extension = blackboard.locomotion_extension

		locomotion_extension:use_lerp_rotation(false)
		locomotion_extension:set_movement_type("script_driven")
		LocomotionUtils.set_animation_driven_movement(unit, true)
		locomotion_extension:set_affected_by_gravity(false)
	else
		blackboard.spawning_finished = true
	end

	local is_horde = blackboard.spawn_type == "horde" or blackboard.spawn_type == "horde_hidden"
	local breed = blackboard.breed
	local wield_inventory_on_spawn = breed.wield_inventory_on_spawn

	if (is_horde or wield_inventory_on_spawn) and ScriptUnit.has_extension(unit, "ai_inventory_system") then
		local ai_inventory_system = Managers.state.extension:system("ai_inventory_system")

		ai_inventory_system:inventory_wield(unit)
	end

	local spawn_animation = blackboard.spawn_animation or "idle"
	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

	ai_base_extension:anim_event(spawn_animation)

	blackboard.spawn_last_pos = Vector3Box(POSITION_LOOKUP[unit])
	blackboard.spawn_immovable_time = 0
end

BTSpawningAction.leave = function (self, unit, blackboard, t)
	blackboard.spawn = nil
	blackboard.spawning_finished = nil
	blackboard.spawn_last_pos = nil

	local ai_navigation = blackboard.navigation_extension

	ai_navigation:init_position()

	if blackboard.spawn_type == "horde" or blackboard.spawn_type == "horde_hidden" then
		local ai_extension = ScriptUnit.extension(unit, "ai_system")

		ai_extension:force_enemy_detection(t)

		if unit_alive(blackboard.target_unit) then
			local ai_slot_system = Managers.state.extension:system("ai_slot_system")

			ai_slot_system:do_slot_search(unit, true)
		else
			blackboard.target_unit = nil
		end
	end

	local locomotion_extension = blackboard.locomotion_extension

	locomotion_extension:set_movement_type("snap_to_navmesh")

	if blackboard.spawn_type == "horde" then
		locomotion_extension:use_lerp_rotation(true)
		LocomotionUtils.set_animation_driven_movement(unit, false, false)

		blackboard.spawn_landing_state = nil
		blackboard.jump_climb_finished = nil
	end

	if blackboard.constrained_on_client then
		blackboard.constrained_on_client = nil

		LocomotionUtils.constrain_on_clients(unit, false, Vector3.zero(), Vector3.zero())
	end

	LocomotionUtils.set_animation_translation_scale(unit, Vector3(1, 1, 1))
end

BTSpawningAction.run = function (self, unit, blackboard, t, dt)
	local locomotion_extension = blackboard.locomotion_extension
	local spawning_finished = blackboard.spawning_finished
	local nav_world = blackboard.nav_world
	local current_pos = POSITION_LOOKUP[unit]

	if spawning_finished and not blackboard.spawn_landing_state then
		local altitude = GwNavQueries.triangle_from_position(nav_world, current_pos, 0.5, 20)

		if altitude then
			local spawn_position = Vector3(current_pos.x, current_pos.y, altitude)

			locomotion_extension:teleport_to(spawn_position, Unit.local_rotation(unit, 1))

			return "done"
		else
			locomotion_extension:set_affected_by_gravity(true)
			locomotion_extension:set_movement_type("script_driven")

			blackboard.spawn_landing_state = "falling"
			altitude = GwNavQueries.triangle_from_position(nav_world, current_pos, 0, 20)

			if altitude then
				local min_pos = Vector3(current_pos.x, current_pos.y, altitude)

				LocomotionUtils.constrain_on_clients(unit, true, min_pos, current_pos)

				blackboard.constrained_on_client = true
				blackboard.landing_destination = Vector3Box(current_pos.x, current_pos.y, altitude)
			else
				if Application.build() ~= "release" then
					QuickDrawerStay:sphere(current_pos + Vector3.up(), 1, Colors.get("orange"))
					QuickDrawerStay:vector(current_pos, Vector3.down(), Colors.get("orange"))
					QuickDrawerStay:vector(current_pos, Vector3.down() * 20, Colors.get("orange"))
					Debug.world_sticky_text(current_pos, "BTSpawningAction couldn't find place to land.", Colors.get("orange"))
				end

				local damage_type = "forced"
				local damage_direction = Vector3(0, 0, -1)

				AiUtils.kill_unit(unit, nil, nil, damage_type, damage_direction)

				return
			end
		end
	end

	if blackboard.spawn_landing_state == "falling" then
		local fall_speed = locomotion_extension:current_velocity().z
		local landing_destination = blackboard.landing_destination:unbox()
		local next_height = current_pos.z + fall_speed * dt * 2

		if next_height < landing_destination.z then
			locomotion_extension:teleport_to(landing_destination, Unit.local_rotation(unit, 1))
			locomotion_extension:set_movement_type("snap_to_navmesh")
			LocomotionUtils.set_animation_driven_movement(unit, true, false)

			local ai_base_extension = ScriptUnit.extension(unit, "ai_system")

			ai_base_extension:anim_event("jump_down_land")

			blackboard.spawn_landing_state = "landing"
		end
	elseif blackboard.spawn_landing_state == "landing" and blackboard.jump_climb_finished then
		return "done"
	end

	return "running"
end
