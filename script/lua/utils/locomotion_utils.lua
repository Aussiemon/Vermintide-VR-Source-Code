-- chunkname: @script/lua/utils/locomotion_utils.lua

LocomotionUtils = {}

local unit_local_position = Unit.local_position
local unit_set_local_rotation = Unit.set_local_rotation
local quaternion_look = Quaternion.look

LocomotionUtils.rotation_towards_unit_flat = function (unit, target_unit)
	local pos_unit = unit_local_position(unit, 1)
	local pos_target_unit = unit_local_position(target_unit, 1)
	local to_dir = pos_target_unit - pos_unit

	to_dir.z = 0

	local direction = Vector3.normalize(to_dir)
	local flat_rotation = Quaternion.look(direction)

	return flat_rotation
end

LocomotionUtils.constrain_on_clients = function (unit, constrain, min, max)
	local in_session = Managers.state.network and Managers.state.network:state() == "in_session"

	if in_session then
		local realmin = Vector3(math.min(min.x, max.x), math.min(min.y, max.y), math.min(min.z, max.z))
		local realmax = Vector3(math.max(min.x, max.x), math.max(min.y, max.y), math.max(min.z, max.z))
		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
		local game_object_id = ai_base_extension.game_object_id

		Managers.state.network:send_rpc_clients("rpc_constrain_ai", game_object_id, constrain, realmin, realmax)
	end
end

LocomotionUtils.set_animation_driven_movement = function (unit, animation_driven, is_affected_by_gravity, script_driven_rotation)
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	locomotion_extension:set_animation_driven(animation_driven, is_affected_by_gravity, script_driven_rotation)
end

LocomotionUtils.set_animation_translation_scale = function (unit, animation_translation_scale)
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	locomotion_extension:set_animation_translation_scale(animation_translation_scale)

	local in_session = Managers.state.network and Managers.state.network:state() == "in_session"

	if in_session then
		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
		local game_object_id = ai_base_extension.game_object_id

		Managers.state.network:send_rpc_clients("rpc_set_animation_translation_scale", game_object_id, animation_translation_scale)
	end
end

LocomotionUtils.set_animation_rotation_scale = function (unit, animation_rotation_scale)
	local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")

	locomotion_extension:set_animation_rotation_scale(animation_rotation_scale)

	local in_session = Managers.state.network and Managers.state.network:state() == "in_session"

	if in_session then
		local ai_base_extension = ScriptUnit.extension(unit, "ai_system")
		local game_object_id = ai_base_extension.game_object_id

		Managers.state.network:send_rpc_clients("rpc_set_animation_rotation_scale", game_object_id, animation_rotation_scale)
	end
end

LocomotionUtils.new_random_goal_uniformly_distributed_with_inside_from_outside_on_last = function (nav_world, blackboard, start_pos, min_dist, max_dist, max_tries, test_points, above, below, horizontal)
	local above = above or 30
	local below = below or 30
	local horizontal = horizontal or 3
	local distance_from_obstacle = 0
	local tries = 0

	while tries < max_tries do
		local min_dist_proportion = (min_dist / max_dist)^2
		local random_value = Math.random()
		local normalized_dist = min_dist_proportion + random_value * (1 - min_dist_proportion)
		local uniformly_scaled_dist = math.sqrt(normalized_dist)
		local dist = uniformly_scaled_dist * max_dist
		local add_vec = Vector3(dist, 0, 1.5)
		local pos = start_pos + Quaternion.rotate(Quaternion(Vector3.up(), Math.random() * math.pi * 2), add_vec)

		if test_points then
			test_points[#test_points + 1] = Vector3Box(pos)
		end

		if tries < max_tries - 1 then
			local altitude = GwNavQueries.triangle_from_position(nav_world, pos, above, below)

			if altitude then
				pos.z = altitude

				return pos
			end
		else
			local clamped_position = GwNavQueries.inside_position_from_outside_position(nav_world, pos, above, below, horizontal, distance_from_obstacle)

			if clamped_position then
				return clamped_position
			end
		end

		tries = tries + 1
	end
end
