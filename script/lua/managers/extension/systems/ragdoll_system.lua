-- chunkname: @script/lua/managers/extension/systems/ragdoll_system.lua

require("script/lua/unit_extensions/ragdoll_shooter_extension")
class("RagdollSystem", "ExtensionSystemBase")

RagdollSystem.init = function (self, ...)
	self.super.init(self, ...)

	self._ragdolls = {}

	if Managers.state.network then
		Managers.state.network:register_game_object_callback(self, "ragdoll", "ragdoll_game_object_created", "ragdoll_game_object_destroyed")
	end

	self._synced_ragdolls = {}
	self._units_to_be_ragdolled = {}
end

RagdollSystem.update = function (self, dt, t)
	self.super.update(self, dt, t)

	if not self._registered then
		Managers.state.event:register(self, "event_ragdoll_spawn", "event_ragdoll_spawn")

		self._registered = true
	end

	local units_to_be_ragdolled = self._units_to_be_ragdolled

	for game_object_id, ragdoll_game_object_id in pairs(units_to_be_ragdolled) do
		local ai_system = Managers.state.extension:system("ai_system")
		local unit = ai_system:remote_unit(game_object_id)

		if unit then
			local session = Managers.state.network:session()
			local push_direction = GameSession.game_object_field(session, ragdoll_game_object_id, "push_direction")
			local push_strength = GameSession.game_object_field(session, ragdoll_game_object_id, "push_strength")
			local push_node_index = GameSession.game_object_field(session, ragdoll_game_object_id, "push_node_index")
			local extension = ScriptUnit.extension(unit, "health_system")
			local params = {
				hit_direction = push_direction,
				hit_force = push_strength,
				hit_node_index = push_node_index
			}

			extension:ragdoll(params)

			self._synced_ragdolls[ragdoll_game_object_id] = unit
			self._units_to_be_ragdolled[game_object_id] = nil
		end
	end

	local max_ragdolls = Managers.differentiation:current_mode().max_ragdolls

	if max_ragdolls < #self._ragdolls then
		local unit = table.remove(self._ragdolls, 1)

		Managers.state.spawn:mark_for_deletion(unit)

		if Managers.state.network and Managers.state.network:in_session() and Managers.lobby.server then
			local object_id = Unit.get_data(unit, "ragdoll_id")

			if object_id then
				Managers.state.network:destroy_game_object(object_id)
			end
		end
	end
end

RagdollSystem.event_ragdoll_spawn = function (self, unit, data)
	if Managers.state.network then
		if Managers.state.network:in_session() and Managers.lobby.server then
			self._ragdolls[#self._ragdolls + 1] = unit

			local obj_id = Managers.state.network:create_game_object("ragdoll", data)

			Unit.set_data(unit, "ragdoll_id", obj_id)
		end
	else
		self._ragdolls[#self._ragdolls + 1] = unit
	end
end

RagdollSystem.ragdoll_unit_and_add_to_pool = function (self, unit)
	self._ragdolls[#self._ragdolls + 1] = unit

	Unit.animation_event(unit, "ragdoll")
end

RagdollSystem.ragdoll_game_object_created = function (self, object_type, session, object_id, owner)
	local from_ai = GameSession.game_object_field(session, object_id, "from_ai")

	if from_ai then
		local push_direction = GameSession.game_object_field(session, object_id, "push_direction")
		local push_strength = GameSession.game_object_field(session, object_id, "push_strength")
		local push_node_index = GameSession.game_object_field(session, object_id, "push_node_index")
		local was_dismembered = GameSession.game_object_field(session, object_id, "dismember")
		local ai_id = GameSession.game_object_field(session, object_id, "ai_id")
		local ai_system = Managers.state.extension:system("ai_system")
		local unit = ai_system:remote_unit(ai_id)

		if unit then
			local extension = ScriptUnit.extension(unit, "health_system")
			local params = {
				hit_direction = push_direction,
				hit_force = push_strength,
				hit_node_index = push_node_index,
				was_dismembered = was_dismembered
			}

			extension:ragdoll(params)

			self._synced_ragdolls[object_id] = unit
		else
			self._units_to_be_ragdolled[ai_id] = object_id
		end
	else
		local level = self._level
		local unit_id = GameSession.game_object_field(session, object_id, "level_unit_id")
		local shooter_unit = Level.unit_by_index(self._level, unit_id)
		local extension = ScriptUnit.extension(shooter_unit, "ragdoll_system")
		local position = GameSession.game_object_field(session, object_id, "position")
		local push_strength = GameSession.game_object_field(session, object_id, "push_strength")
		local push_seed = GameSession.game_object_field(session, object_id, "push_seed")
		local unit = extension:spawn_ragdoll(position, push_strength, push_seed)

		self._synced_ragdolls[object_id] = unit
	end
end

RagdollSystem.ragdoll_game_object_destroyed = function (self, object_type, session, object_id, owner)
	local unit = self._synced_ragdolls[object_id]

	self._synced_ragdolls[object_id] = nil

	if Unit.alive(unit) then
		Managers.state.spawn:mark_for_deletion(unit)
	end
end
