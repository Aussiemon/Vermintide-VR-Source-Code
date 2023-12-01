-- chunkname: @script/lua/unit_extensions/ai/ai_level_unit_base_extension.lua

require("script/lua/unit_extensions/ai/ai_brain")
require("script/lua/utils/ai_utils")
require("settings/network_lookup")
class("AILevelUnitBaseExtension")

AILevelUnitBaseExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._unit = unit
	self._world = extension_init_context.world
	self._level = extension_init_context.level

	local breed = extension_init_data.breed

	Unit.set_data(unit, "breed", breed)

	self._breed = breed
	self._network_mode = extension_init_context.network_mode
	self._flow_anim_cb_damage = extension_init_data.flow_anim_cb_damage
	self.unit_level_id = extension_init_data.unit_level_id
	self.is_level_unit = true
end

AILevelUnitBaseExtension.destroy = function (self)
	return
end

AILevelUnitBaseExtension.update = function (self, unit, dt, t)
	local network_mode = self._network_mode

	if network_mode ~= "server" then
		return
	end

	if not self.game_object_id then
		self:_update_game_object(unit, dt, t)
	end
end

AILevelUnitBaseExtension._update_game_object = function (self, unit)
	local in_session = Managers.state.network and Managers.state.network:state() == "in_session"

	if in_session then
		local session = Managers.state.network:session()
		local breed = self._breed
		local breed_name = breed.name
		local breed_index = BreedReverseLookup[breed_name]
		local unit_level_id = self.unit_level_id

		self.game_object_id = Managers.state.network:create_game_object("ai_level_unit", {
			breed_index = breed_index,
			unit_level_id = unit_level_id
		})

		print("[SERVER] created gameobject ai_level unit with unit_level_id %d", unit_level_id)
	end
end

AILevelUnitBaseExtension.level_unit_anim_cb_damage = function (self)
	local target_unit = Unit.get_data(self._unit, "target_unit")
	local hit_flow_event = Unit.get_data(self._unit, "hit_flow_event")

	if target_unit and hit_flow_event then
		Unit.flow_event(target_unit, hit_flow_event)
	end
end
