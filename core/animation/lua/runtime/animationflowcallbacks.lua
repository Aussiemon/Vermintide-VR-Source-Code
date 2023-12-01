-- chunkname: @core/animation/lua/runtime/animationflowcallbacks.lua

AnimationFlowCallbacks = AnimationFlowCallbacks or {}

local M = AnimationFlowCallbacks
local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local Vector3Box = stingray.Vector3Box
local Matrix4x4 = stingray.Matrix4x4
local Quaternion = stingray.Quaternion

M.get_animation_wanted_root_pose = function (t)
	local matrix_4_4 = Unit.animation_wanted_root_pose(t.unit)

	t.desired_position = Matrix4x4.translation(matrix_4_4)
	t.desired_rotation = Matrix4x4.rotation(matrix_4_4)
	t.delta_position = Matrix4x4.translation(matrix_4_4) - Unit.local_position(t.unit, 1)
	t.delta_rotation = Quaternion(Vector3.up(), Quaternion.angle(Matrix4x4.rotation(matrix_4_4)) - Quaternion.angle(Unit.local_rotation(t.unit, 1)))

	return t
end

M.get_animation_curve_value = function (t)
	local curve_found, float_value = Unit.animation_get_curve_value(t.unit, t.object, t.parameter, t.float_index)

	t.exists = curve_found
	t.float_value = float_value

	return t
end
