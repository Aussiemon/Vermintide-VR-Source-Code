-- chunkname: @script/lua/unit_extensions/hit_reactions/ai_hitreaction_extension.lua

require("settings/hitreaction_settings")
class("AIHitReactionExtension")

AIHitReactionExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._world = extension_init_context.world
	self._unit = unit
	self._level = extension_init_context.level
	self._breed_name = extension_init_data.breed_name
end

AIHitReactionExtension.destroy = function (self)
	return
end

AIHitReactionExtension.extensions_ready = function (self, world, unit)
	return
end

AIHitReactionExtension.update = function (self, unit, dt, t)
	return
end

AIHitReactionExtension.add_hitreaction = function (self, params)
	if self._breed_name then
		local unit = self._unit

		Unit.animation_event(unit, "hit_reaction")
		World.create_particles(self._world, "fx/impact_blood", Unit.world_position(unit, params.hit_node_index), Quaternion.look(Vector3.forward()))
	end
end
