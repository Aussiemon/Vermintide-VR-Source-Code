-- chunkname: @script/lua/unit_extensions/hit_reactions/player_hitreaction_extension.lua

require("settings/hitreaction_settings")
class("PlayerHitReactionExtension")

PlayerHitReactionExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._world = extension_init_context.world
	self._wwise_world = Wwise.wwise_world(self._world)
	self._unit = unit
	self._level = extension_init_context.level
end

PlayerHitReactionExtension.destroy = function (self)
	return
end

PlayerHitReactionExtension.extensions_ready = function (self, world, unit)
	return
end

PlayerHitReactionExtension.update = function (self, unit, dt, t)
	return
end

PlayerHitReactionExtension.add_hitreaction = function (self, params)
	local damage_type = params.damage_type
	local hit_reaction = HitReactionSettings[damage_type]
	local hit_sound = hit_reaction.hit_sound

	WwiseWorld.trigger_event(self._wwise_world, hit_sound)
end
