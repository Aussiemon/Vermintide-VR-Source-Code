-- chunkname: @script/lua/unit_extensions/ai/ai_husk_base_extension.lua

class("AIHuskBaseExtension")

AIHuskBaseExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._unit = unit
	self._world = extension_init_context.world
	self._game_object_id = extension_init_data.game_object_id
	self.is_husk = true

	local breed = extension_init_data.breed
	local variation_setting = breed.variation_setting

	if variation_setting then
		AiUtils.set_unit_variation(unit, variation_setting)
	end

	self._breed = breed
end

AIHuskBaseExtension.update = function (self, unit, dt, t)
	return
end
