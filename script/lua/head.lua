-- chunkname: @script/lua/head.lua

local head_settings = {
	unit_name = "units/beings/player/empire_soldier/headpiece/es_helmet_05",
	pos_offset = {
		0,
		-0.06,
		0.025
	},
	rot_offset = {
		0,
		0,
		0
	}
}

HeadSettings = table.create_copy(HeadSettings, head_settings)

class("Head")

Head.init = function (self, world, gameplay_extensions)
	self._world = world

	local settings = HeadSettings

	self._settings = settings

	local head_unit_name = settings.unit_name
	local unit = World.spawn_unit(world, head_unit_name)

	self._wand_unit = unit

	Unit.set_data(unit, "extensions", 0, "HeadExtension")

	if gameplay_extensions then
		Unit.set_data(unit, "extensions", 1, "AggroExtension")
		Unit.set_data(unit, "extensions", 2, "PlayerHealthExtension")
		Unit.set_data(unit, "extensions", 3, "AIPlayerSlotExtension")
		Unit.set_data(unit, "extensions", 4, "PlayerHitReactionExtension")
		Unit.set_data(unit, "aggro_modifier_passive", 10)
		Unit.set_data(unit, "aggro_modifier_active", 20)
	end

	Managers.state.extension:register_unit(world, unit, {
		head_system = {
			settings = settings
		}
	})
end

Head.update = function (self, dt)
	return
end

Head.destroy = function (self)
	World.destroy_unit(self._world, self._wand_unit)
end
