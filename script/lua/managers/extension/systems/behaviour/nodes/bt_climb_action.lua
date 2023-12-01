-- chunkname: @script/lua/managers/extension/systems/behaviour/nodes/bt_climb_action.lua

require("script/lua/managers/extension/systems/behaviour/nodes/bt_node")
class("BTClimbAction", "BTNode")

BTClimbAction.init = function (self, ...)
	BTClimbAction.super.init(self, ...)
end

BTClimbAction.name = "BTClimbAction"

local function randomize(event)
	if type(event) == "table" then
		return event[Math.random(1, #event)]
	else
		return event
	end
end

BTClimbAction.enter = function (self, unit, blackboard, t)
	local unit_position = POSITION_LOOKUP[unit]
	local next_smart_object_data = blackboard.next_smart_object_data
	local entrance_pos = next_smart_object_data.entrance_pos:unbox()
	local exit_pos = next_smart_object_data.exit_pos:unbox()
	local smart_object_data = next_smart_object_data.smart_object_data
	local ledge_position = Vector3Aux.unbox(smart_object_data.ledge_position)

	blackboard.smart_object_data = smart_object_data
	blackboard.ledge_position = Vector3Box(ledge_position)
	blackboard.climb_upwards = true
	blackboard.climb_entrance_pos = Vector3Box(entrance_pos)
	blackboard.climb_exit_pos = Vector3Box(exit_pos)

	if not smart_object_data.is_on_edge then
		if smart_object_data.ledge_position1 then
			local ledge_position1 = Vector3Aux.unbox(smart_object_data.ledge_position1)
			local ledge_position2 = Vector3Aux.unbox(smart_object_data.ledge_position2)
			local closest_ledge_position = Vector3.distance_squared(ledge_position1, entrance_pos) < Vector3.distance_squared(ledge_position2, entrance_pos) and ledge_position1 or ledge_position2

			blackboard.climb_jump_height = closest_ledge_position.z - entrance_pos.z

			blackboard.ledge_position:store(closest_ledge_position)
		else
			blackboard.climb_jump_height = ledge_position.z - entrance_pos.z

			if blackboard.climb_jump_height < 0 then
				smart_object_data.is_on_edge = true
			end
		end
	end

	if smart_object_data.is_on_edge then
		if entrance_pos.z > exit_pos.z then
			blackboard.climb_jump_height = entrance_pos.z - exit_pos.z
			blackboard.climb_upwards = false
		else
			blackboard.climb_jump_height = exit_pos.z - entrance_pos.z
		end
	end

	assert(blackboard.climb_jump_height >= 0, "Ledge with non-positive climb height=%.2f at %s -> %s", blackboard.climb_jump_height, tostring(entrance_pos), tostring(exit_pos))

	blackboard.climb_ledge_lookat_direction = Vector3Box(Vector3.normalize(Vector3.flat(exit_pos - entrance_pos)))

	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	locomotion_extension:set_affected_by_gravity(false)
	locomotion_extension:set_movement_type("snap_to_navmesh")
	locomotion_extension:set_rotation_speed(10)

	blackboard.climb_state = "moving_to_within_smartobject_range"
end

BTClimbAction.leave = function (self, unit, blackboard, t)
	blackboard.climb_spline_ground = nil
	blackboard.climb_spline_ledge = nil
	blackboard.climb_entrance_pos = nil
	blackboard.climb_state = nil
	blackboard.climb_upwards = nil
	blackboard.is_climbing = nil
	blackboard.climb_jump_height = nil
	blackboard.climb_ledge_lookat_direction = nil
	blackboard.climb_entrance_pos = nil
	blackboard.climb_exit_pos = nil
	blackboard.is_smart_objecting = nil
	blackboard.jump_climb_finished = nil
	blackboard.climb_align_end_time = nil
	blackboard.smart_object_data = nil
	blackboard.ledge_position = nil
	blackboard.climb_moving_to_enter_entrance_timeout = nil

	LocomotionUtils.set_animation_translation_scale(unit, Vector3(1, 1, 1))
	LocomotionUtils.constrain_on_clients(unit, false, Vector3.zero(), Vector3.zero())
	LocomotionUtils.set_animation_driven_movement(unit, false)

	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	locomotion_extension:set_movement_type("snap_to_navmesh")
	locomotion_extension:set_affected_by_gravity(true)

	local navigation_extension = ScriptUnit.extension(unit, "ai_navigation_system")

	navigation_extension:set_enabled(true)

	if navigation_extension:is_using_smart_object() then
		local success = navigation_extension:use_smart_object(false)
	end
end

BTClimbAction.run = function (self, unit, blackboard, t, dt)
	local navigation_extension = ScriptUnit.extension(unit, "ai_navigation_system")
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")
	local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
	local unit_position = POSITION_LOOKUP[unit]
	local climb_state_current = blackboard.climb_state
	local is_on_edge = blackboard.smart_object_data.is_on_edge

	if script_data.ai_debug_smartobject then
		Debug.text("BTClimbAction state=%s", blackboard.climb_state)
		Debug.text("BTClimbAction entrance_pos=%s", tostring(blackboard.climb_entrance_pos:unbox()))
		Debug.text("BTClimbAction exit_pos=        %s", tostring(blackboard.climb_exit_pos:unbox()))
		Debug.text("BTClimbAction pos=            %s", tostring(POSITION_LOOKUP[unit]))
		QuickDrawer:sphere(blackboard.climb_entrance_pos:unbox(), 0.3, Colors.get("red"))
		QuickDrawer:sphere(blackboard.climb_exit_pos:unbox(), 0.3, Colors.get("red"))
		QuickDrawer:sphere(unit_position, 0.3 + math.sin(t * 5) * 0.01, Colors.get("purple"))
	end

	if blackboard.smart_object_data ~= blackboard.next_smart_object_data.smart_object_data then
		return "failed"
	end

	if blackboard.climb_state == "moving_to_within_smartobject_range" then
		local dist = Vector3.distance_squared(blackboard.climb_entrance_pos:unbox(), unit_position)
		local target_dir = Vector3.normalize(navigation_extension:desired_velocity())

		if Vector3.length(Vector3.flat(target_dir)) < 0.05 and Vector3.dot(target_dir, Vector3.normalize(blackboard.climb_exit_pos:unbox() - unit_position)) > 0.99 then
			blackboard.climb_moving_to_enter_entrance_timeout = blackboard.climb_moving_to_enter_entrance_timeout or t + 0.3
		else
			blackboard.climb_moving_to_enter_entrance_timeout = nil
		end

		if dist < 1 or blackboard.climb_moving_to_enter_entrance_timeout and t > blackboard.climb_moving_to_enter_entrance_timeout then
			locomotion_extension:set_wanted_velocity(Vector3(0, 0, 0))
			locomotion_extension:set_movement_type("script_driven")
			navigation_extension:set_enabled(false)

			if navigation_extension:use_smart_object(true) then
				blackboard.is_smart_objecting = true
				blackboard.is_climbing = true
				blackboard.climb_state = "moving_to_to_entrance"
			else
				print("BTClimbAction - failing to use smart object")

				return "failed"
			end
		elseif script_data.ai_debug_smartobject then
			QuickDrawer:circle(blackboard.climb_entrance_pos:unbox(), 1, Vector3.up())
		end
	end

	if blackboard.climb_state == "moving_to_to_entrance" then
		local entrance_pos = blackboard.climb_entrance_pos:unbox()
		local vector_to_target = entrance_pos - unit_position
		local distance_to_target = Vector3.length(vector_to_target)

		if distance_to_target > 0.1 then
			local breed = blackboard.breed
			local walk_only = breed.walk_only
			local speed = walk_only and blackboard.walk_speed or blackboard.run_speed

			if distance_to_target < speed * dt then
				speed = distance_to_target / dt
			end

			local direction_to_target = Vector3.normalize(vector_to_target)

			locomotion_extension:set_wanted_velocity(direction_to_target * speed)

			local look_direction_wanted = blackboard.climb_ledge_lookat_direction:unbox()

			locomotion_extension:set_wanted_rotation(Quaternion.look(look_direction_wanted))

			if script_data.ai_debug_smartobject then
				QuickDrawer:vector(unit_position + Vector3.up() * 0.3, vector_to_target)
				QuickDrawer:sphere(entrance_pos, 0.3, Colors.get("red"))
			end
		else
			local look_direction_wanted = blackboard.climb_ledge_lookat_direction:unbox()

			locomotion_extension:teleport_to(entrance_pos, Quaternion.look(look_direction_wanted))

			unit_position = entrance_pos

			locomotion_extension:set_wanted_velocity(Vector3.zero())

			local exit_pos = blackboard.climb_exit_pos:unbox()
			local ledge_position = blackboard.ledge_position:unbox() + Vector3.up()

			LocomotionUtils.constrain_on_clients(unit, true, Vector3.min(entrance_pos, exit_pos), Vector3.max(ledge_position, Vector3.max(entrance_pos, exit_pos)))
			LocomotionUtils.set_animation_driven_movement(unit, true)

			if blackboard.climb_upwards or not is_on_edge then
				local ai_extension = ScriptUnit.extension(unit, "ai_system")
				local animation_length = 1
				local animation_translation_scale = 1 / ai_extension:size_variation()
				local jump_anim_thresholds = SmartObjectSettings.templates[blackboard.breed.smart_object_template].jump_up_anim_thresholds
				local climb_jump_height = blackboard.climb_jump_height

				for i = 1, #jump_anim_thresholds do
					local jump_anim_threshold = jump_anim_thresholds[i]

					if climb_jump_height < jump_anim_threshold.height_threshold then
						local jump_anim_name = is_on_edge and jump_anim_threshold.animation_edge or jump_anim_threshold.animation_fence

						ai_base_extension:anim_event(randomize(jump_anim_name))

						local anim_distance = jump_anim_threshold.vertical_length

						animation_translation_scale = animation_translation_scale * climb_jump_height / anim_distance

						break
					end
				end

				LocomotionUtils.set_animation_translation_scale(unit, Vector3(1, 1, animation_translation_scale))
				locomotion_extension:set_wanted_velocity(Vector3(0, 0, 0))

				blackboard.climb_state = "waiting_for_finished_climb_anim"
			else
				local jump_anim_thresholds = SmartObjectSettings.templates[blackboard.breed.smart_object_template].jump_down_anim_thresholds
				local climb_jump_height = math.abs(blackboard.climb_jump_height)

				for i = 1, #jump_anim_thresholds do
					local jump_anim_threshold = jump_anim_thresholds[i]

					if climb_jump_height < jump_anim_threshold.height_threshold then
						local jump_anim_name = is_on_edge and jump_anim_threshold.animation_edge or jump_anim_threshold.animation_fence

						ai_base_extension:anim_event(randomize(jump_anim_name))

						break
					end
				end

				blackboard.climb_state = "waiting_to_reach_ground"
			end
		end
	end

	if blackboard.climb_state == "waiting_for_finished_climb_anim" then
		local action_data = self._tree_node.action_data

		if blackboard.jump_climb_finished then
			blackboard.jump_climb_finished = nil

			local exit_pos = blackboard.climb_exit_pos:unbox()
			local move_target = is_on_edge and exit_pos or blackboard.ledge_position:unbox()

			if is_on_edge then
				ai_base_extension:anim_event("move_fwd")

				blackboard.spawn_to_running = true

				locomotion_extension:teleport_to(move_target)
				navigation_extension:set_navbot_position(move_target)
				locomotion_extension:set_wanted_velocity(Vector3(0, 0, 0))
				LocomotionUtils.set_animation_driven_movement(unit, false)

				blackboard.climb_state = "done"
			else
				local jump_anim_thresholds = SmartObjectSettings.templates[blackboard.breed.smart_object_template].jump_down_anim_thresholds
				local climb_jump_height = move_target.z - blackboard.climb_exit_pos:unbox().z

				for i = 1, #jump_anim_thresholds do
					local jump_anim_threshold = jump_anim_thresholds[i]

					if climb_jump_height < jump_anim_threshold.height_threshold then
						local ai_extension = ScriptUnit.extension(unit, "ai_system")
						local ai_size_variation = ai_extension:size_variation()
						local animation_length = jump_anim_threshold.fence_horizontal_length
						local flat_distance_to_jump = Vector3.length(Vector3.flat(unit_position - exit_pos))

						flat_distance_to_jump = flat_distance_to_jump - jump_anim_threshold.fence_land_length

						local animation_translation_scale = flat_distance_to_jump / (animation_length * ai_size_variation)

						LocomotionUtils.set_animation_translation_scale(unit, Vector3(animation_translation_scale, animation_translation_scale, 1))

						local jump_anim_name = is_on_edge and jump_anim_threshold.animation_edge or jump_anim_threshold.animation_fence

						ai_base_extension:anim_event(randomize(jump_anim_name))

						break
					end
				end

				blackboard.climb_state = "waiting_to_reach_ground"
			end
		end
	end

	if blackboard.climb_state == "waiting_to_reach_ground" then
		local action_data = self._tree_node.action_data
		local move_target = blackboard.climb_exit_pos:unbox()
		local velocity = locomotion_extension:get_velocity()

		if unit_position.z + velocity.z * dt * 2 <= move_target.z then
			blackboard.climb_state = "waiting_for_finished_land_anim"

			LocomotionUtils.set_animation_driven_movement(unit, true)
			LocomotionUtils.set_animation_translation_scale(unit, Vector3(1, 1, 1))
			ai_base_extension:anim_event("jump_down_land")
		end
	elseif blackboard.climb_state == "waiting_for_finished_land_anim" then
		local move_target = blackboard.climb_exit_pos:unbox()
		local ground_target = Vector3(unit_position.x, unit_position.y, move_target.z)

		locomotion_extension:teleport_to(ground_target)

		if blackboard.jump_climb_finished then
			local move_target = blackboard.climb_exit_pos:unbox()

			LocomotionUtils.set_animation_driven_movement(unit, false)
			ai_base_extension:anim_event("move_fwd")

			blackboard.spawn_to_running = true

			local distance = Vector3.distance(unit_position, move_target)

			if distance < 0.01 then
				local altitude = GwNavQueries.triangle_from_position(blackboard.nav_world, move_target, 0.4, 0.4)

				if altitude then
					move_target.z = altitude
				end

				navigation_extension:set_navbot_position(move_target)
				locomotion_extension:teleport_to(move_target)
				locomotion_extension:set_wanted_velocity(Vector3.zero())

				blackboard.climb_state = "done"
			else
				local speed = blackboard.run_speed
				local time_to_travel = distance / speed

				blackboard.climb_align_end_time = t + time_to_travel
				blackboard.climb_state = "aligning_to_navmesh"
			end
		end
	end

	if blackboard.climb_state == "aligning_to_navmesh" then
		local move_target = blackboard.climb_exit_pos:unbox()

		if t > blackboard.climb_align_end_time then
			local altitude = GwNavQueries.triangle_from_position(blackboard.nav_world, move_target, 0.4, 0.4)

			if not altitude then
				altitude = GwNavQueries.triangle_from_position(blackboard.nav_world, move_target, 1.5, 1.5)

				if altitude then
					printf("WTF navmesh pos @ move_target %s, actual altitude=%f", tostring(move_target), altitude)
					QuickDrawerStay:sphere(move_target, 0.1, Color(255, 255, 255))
					QuickDrawerStay:sphere(move_target + Vector3.up(), 0.9, Color(255, 0, 0))
					QuickDrawerStay:sphere(move_target - Vector3.up(), 0.9, Color(255, 0, 0))
				end
			end

			navigation_extension:set_navbot_position(move_target)
			locomotion_extension:teleport_to(move_target)
			locomotion_extension:set_wanted_velocity(Vector3.zero())

			blackboard.climb_state = "done"
		else
			local speed = blackboard.run_speed
			local direction_to_target = Vector3.normalize(move_target - unit_position)
			local wanted_velocity = direction_to_target * speed

			locomotion_extension:set_wanted_velocity(wanted_velocity)
		end
	end

	if blackboard.climb_state == "done" then
		blackboard.climb_state = "done_for_reals"
	elseif blackboard.climb_state == "done_for_reals" then
		blackboard.climb_state = "done_for_reals2"
	elseif blackboard.climb_state == "done_for_reals2" then
		return "done"
	end

	return "running"
end
