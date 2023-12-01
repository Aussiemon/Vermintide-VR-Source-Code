-- chunkname: @script/lua/wand.lua

local wand_settings = {
	left = {
		unit_name = "units/beings/player/first_person/left_arm/left_arm",
		generic_wand_unit_name = "content/models/vr/vr_controller_vive_1_5",
		pos_offset = {
			0,
			0,
			0
		},
		rot_offset = {
			-90,
			0,
			180
		}
	},
	right = {
		unit_name = "units/beings/player/first_person/right_arm/right_arm",
		generic_wand_unit_name = "content/models/vr/vr_controller_vive_1_5",
		pos_offset = {
			0,
			0,
			0
		},
		rot_offset = {
			-90,
			0,
			180
		}
	}
}

for k, v in pairs(wand_settings) do
	v.hand = k
end

WandSettings = table.create_copy(WandSettings, wand_settings)
WandUnitLookup = {}

local i = 1

for key, data in pairs(WandSettings) do
	WandUnitLookup[key] = i
	WandUnitLookup[i] = key
	i = i + 1
end

class("Wand")

Wand.init = function (self, world, wand_input, wand_hand)
	self._world = world
	self._wand_input = wand_input
	self._wand_hand = wand_hand

	local settings = WandSettings[wand_hand]

	self._settings = settings

	local wand_unit_name = settings.unit_name
	local unit = World.spawn_unit(world, wand_unit_name)

	self._wand_unit = unit

	Unit.set_data(unit, "extensions", 0, "WandExtension")
	Managers.state.extension:register_unit(world, unit, {
		wand_system = {
			settings = settings,
			input = wand_input
		}
	})

	local generic_wand_unit_name = settings.generic_wand_unit_name
	local generic_unit = World.spawn_unit(world, generic_wand_unit_name)

	self._generic_wand_unit = generic_unit

	Unit.set_unit_visibility(self._generic_wand_unit, false)
end

Wand.update = function (self, dt)
	self._wand_input:update(dt)

	local pose = self._wand_input:pose()

	Unit.set_local_pose(self._generic_wand_unit, 1, pose)
end

Wand.input = function (self)
	return self._wand_input
end

Wand.wand_unit = function (self)
	return self._wand_unit
end

Wand.generic_wand_unit = function (self)
	return self._generic_wand_unit
end

Wand.set_visibility = function (self, visible)
	Unit.set_unit_visibility(self._wand_unit, visible)
end

Wand.enable_generic_wand = function (self, enable)
	Unit.set_unit_visibility(self._wand_unit, not enable)
	Unit.set_unit_visibility(self._generic_wand_unit, enable)
end

Wand.destroy = function (self)
	World.destroy_unit(self._world, self._wand_unit)
end
