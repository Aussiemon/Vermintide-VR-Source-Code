-- chunkname: @script/lua/unit_extensions/extension_generic_weapon.lua

local Unit = stingray.Unit
local Vector3 = stingray.Vector3
local ActorBox = stingray.ActorBox
local Actor = stingray.Actor
local World = stingray.World
local PhysicsWorld = stingray.PhysicsWorld
local Wwise = stingray.Wwise
local WwiseWorld = stingray.WwiseWorld
local HIT_COOLDOWN = 1

class("ExtensionGenericWeapon")

ExtensionGenericWeapon.init = function (self, extension_init_context, unit, extension_init_data)
	self._unit = unit
	self._world = extension_init_context.world
	self._physics_world = World.physics_world(self._world)
	self._wwise_world = Wwise.wwise_world(self._world)
	self._network_mode = extension_init_context.network_mode
end

ExtensionGenericWeapon.can_interact = function (self, wand_input)
	if not self._wand_input and (wand_input:pressed("grip") or wand_input:pressed("trigger") or wand_input:pressed("touch_down")) then
		local pos = Unit.world_position(self._unit, 1)

		if Vector3.length(wand_input:position() - pos) > 0.3 then
			return false
		end

		return true
	end

	return false
end

ExtensionGenericWeapon.should_drop = function (self, wand_input)
	return wand_input:pressed("touch_down")
end

ExtensionGenericWeapon.interaction_started = function (self, wand_input, wand_unit, attach_node, wand_hand)
	self._wand_input = wand_input
	self._wand_hand = wand_hand

	SimpleInteractables.link_interactable(self._world, self._unit, wand_input, wand_unit, wand_hand, attach_node, self._network_mode ~= "client")
end

ExtensionGenericWeapon.interaction_ended = function (self, wand_input, wand_unit)
	SimpleInteractables.unlink_interactable(self._world, self._unit, wand_unit, self._network_mode ~= "client")

	self._wand_input = nil
	self._wand_hand = nil
end

local callback_context = {
	has_gotten_callback = false,
	num_hits = 0,
	overlap_actors = {}
}

local function collision_callback(actors)
	callback_context.has_gotten_callback = true

	local overlap_actors = callback_context.overlap_actors

	for _, actor in pairs(actors) do
		callback_context.num_hits = callback_context.num_hits + 1

		if overlap_actors[callback_context.num_hits] == nil then
			overlap_actors[callback_context.num_hits] = ActorBox()
		end

		overlap_actors[callback_context.num_hits]:store(actor)
	end
end

ExtensionGenericWeapon._handle_collision = function (self, pose)
	PhysicsWorld.overlap(self._physics_world, collision_callback, "shape", "oobb", "pose", pose, "collision_filter", "filter_melee")

	if callback_context.has_gotten_callback then
		for _, actor_box in pairs(callback_context.overlap_actors) do
			local actor = actor_box:unbox()

			if actor then
				local hit_unit = Actor.unit(actor)

				if hit_unit then
					local is_enemy = Unit.get_data(hit_unit, "enemy")

					if is_enemy then
						local health_extension = ScriptUnit.extension(hit_unit, "health_system")

						health_extension:add_damage(1)
					end

					if false then
						-- Nothing
					end
				end
			end
		end

		callback_context.has_gotten_callback = false
		callback_context.num_hits = 0
		callback_context.overlap_actors = {}
	end
end

ExtensionGenericWeapon._update_recently_hit_actors = function (self)
	return
end

ExtensionGenericWeapon.update = function (self, unit, dt, t)
	if self._wand_input then
		if self._wand_input:pressed("trigger") then
			Unit.flow_event(self._unit, "flow_pressed")
		end

		if self._wand_input:released("trigger") then
			Unit.flow_event(self._unit, "flow_released")
		end

		if self:is_gripped() then
			self:_handle_collision(self._wand_input:pose())
		end
	end
end

ExtensionGenericWeapon.destroy = function (self)
	return
end

ExtensionGenericWeapon.set_is_gripped = function (self, gripped)
	self._gripped = gripped
end

ExtensionGenericWeapon.is_gripped = function (self)
	return self._gripped
end
