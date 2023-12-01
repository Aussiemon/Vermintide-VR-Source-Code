-- chunkname: @script/lua/managers/hud/hud_manager.lua

require("script/lua/managers/hud/damage_hud")
class("HudManager")

HudManager.init = function (self, world, level)
	self.size = {
		4000,
		4000
	}
	self._world = world
	self._level = level
	self._gui = World.create_world_gui(self._world, Matrix4x4.identity(), self.size[1], self.size[2], "material", "gui/fonts/gw_fonts", "material", "gui/single_textures/gui", "immediate")

	print("HudManager -> World.create_world_gui")

	self._damage_hud = DamageHud:new(world, self._gui)
end

HudManager.update = function (self, dt, t)
	Profiler.start("HudManager:update()")
	self:_update_position(dt, t)
	self._damage_hud:update(dt, t)
	Profiler.stop("HudManager:update()")
end

HudManager.add_damage_indicator = function (self, damage, params)
	self._damage_hud:add_damage_indicator(damage, params)
end

HudManager.set_injury_level = function (self, injury_level)
	self._damage_hud:set_injury_level(injury_level)
end

HudManager._update_position = function (self, dt, t)
	local hmd_pose = Managers.vr:hmd_world_pose()

	if Matrix4x4.is_valid(hmd_pose.head) then
		local pose = hmd_pose.head
		local right = Matrix4x4.right(pose)
		local up = Matrix4x4.up(pose)

		Matrix4x4.set_translation(pose, Matrix4x4.translation(pose) + hmd_pose.forward * 0.4 + right * -0.5 + up * -0.5)

		if Matrix4x4.is_valid(hmd_pose.head) then
			Gui.move(self._gui, pose)
		end
	end
end
