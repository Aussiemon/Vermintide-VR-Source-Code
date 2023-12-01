-- chunkname: @script/lua/utils/ai_anim_utils.lua

AiAnimUtils = AiAnimUtils or {}

AiAnimUtils.get_start_move_animation = function (unit, blackboard, action)
	local animation_name
	local current_pos = Unit.local_position(unit, 1)
	local target_pos = Unit.local_position(blackboard.target_unit, 1)
	local target_vector_flat = Vector3.normalize(Vector3.flat(target_pos - current_pos))
	local rotation = Unit.local_rotation(unit, 1)
	local forward_vector_flat = Vector3.normalize(Vector3.flat(Quaternion.forward(rotation)))
	local dot_product = Vector3.dot(forward_vector_flat, target_vector_flat)
	local inv_sqrt_2 = 0.707

	if inv_sqrt_2 <= dot_product then
		animation_name = action.start_anims_name.fwd
	elseif dot_product > -inv_sqrt_2 then
		local is_to_the_left = Vector3.cross(forward_vector_flat, target_vector_flat).z > 0

		animation_name = is_to_the_left and action.start_anims_name.left or action.start_anims_name.right
	else
		animation_name = action.start_anims_name.bwd
	end

	return animation_name
end

AiAnimUtils.set_idle_animation_merge = function (unit, blackboard)
	local breed = blackboard.breed
	local animation_merge_options = breed.animation_merge_options
	local idle_animation_merge_options = animation_merge_options and animation_merge_options.idle_animation_merge_options

	if idle_animation_merge_options then
		Unit.set_animation_merge_options(unit, unpack(idle_animation_merge_options))

		if script_data.animation_merge_debug then
			AiAnimUtils._animation_merge_debug(unit, "idle")
		end
	end
end

AiAnimUtils.set_move_animation_merge = function (unit, blackboard)
	local breed = blackboard.breed
	local animation_merge_options = breed.animation_merge_options
	local move_animation_merge_options = animation_merge_options and animation_merge_options.move_animation_merge_options

	if move_animation_merge_options then
		Unit.set_animation_merge_options(unit, unpack(move_animation_merge_options))

		if script_data.animation_merge_debug then
			AiAnimUtils._animation_merge_debug(unit, "move")
		end
	end
end

AiAnimUtils.set_walk_animation_merge = function (unit, blackboard)
	local breed = blackboard.breed
	local animation_merge_options = breed.animation_merge_options
	local walk_animation_merge_options = animation_merge_options and animation_merge_options.walk_animation_merge_options

	if walk_animation_merge_options then
		Unit.set_animation_merge_options(unit, unpack(walk_animation_merge_options))

		if script_data.animation_merge_debug then
			AiAnimUtils._animation_merge_debug(unit, "walk")
		end
	end
end

AiAnimUtils.reset_animation_merge = function (unit)
	Unit.set_animation_merge_options(unit)

	if script_data.animation_merge_debug then
		AiAnimUtils._animation_merge_debug(unit, nil)
	end
end

AiAnimUtils._animation_merge_debug = function (unit, text)
	local category_name = "animation_merge"

	Managers.state.debug_text:clear_unit_text(unit, category_name)

	if text then
		local head_node = Unit.node(unit, "c_head")
		local viewport_name = "player_1"
		local color_vector = Vector3(25, 255, 25)
		local offset_vector = Vector3(0, 0, 1)
		local text_size = 0.5

		Managers.state.debug_text:output_unit_text(text, text_size, unit, head_node, offset_vector, nil, category_name, color_vector, viewport_name)
	end
end
