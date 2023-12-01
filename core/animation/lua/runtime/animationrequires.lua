-- chunkname: @core/animation/lua/runtime/animationrequires.lua

if not ANIM_REQUIRES then
	require("core/animation/lua/runtime/animationflowcallbacks")

	ANIM_REQUIRES = true
end
