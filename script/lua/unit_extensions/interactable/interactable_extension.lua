-- chunkname: @script/lua/unit_extensions/interactable/interactable_extension.lua

local Unit = stingray.Unit

class("InteractableExtension")

InteractableExtension.FIND_WITH_OVERLAP = true

InteractableExtension.init = function (self, extension_init_context, unit, extension_init_data)
	self._world = extension_init_context.world
	self._unit = unit
	self._wand_input = nil
	self._grip_anim = Unit.get_data(unit, "grip_info", "grip_anim") or "grip"
	self._network_mode = extension_init_context.network_mode
	self._is_interactable = true
	self._line_object = World.create_line_object(self._world)
end

InteractableExtension.update = function (self, dt)
	if self._draw_me then
		for ii = 1, Unit.num_scene_graph_items(self._unit) do
			local position = Unit.world_position(self._unit, ii)

			LineObject.add_sphere(self._line_object, Color(255, 0, 255), position, 0.1 + 0.01 * ii)
		end
	end

	local input = self._wand_input

	if input then
		if input:pressed("trigger") then
			Unit.flow_event(self._unit, "flow_pressed")
		end

		if input:released("trigger") then
			Unit.flow_event(self._unit, "flow_released")
		end
	end

	LineObject.dispatch(self._world, self._line_object)
	LineObject.reset(self._line_object)
end

InteractableExtension.can_interact = function (self, input)
	if not self._is_interactable then
		return false
	end

	return (input:pressed("grip") or input:pressed("trigger")) and not self._gripped
end

InteractableExtension.should_drop = function (self, input)
	return input:pressed("touch_down")
end

InteractableExtension.set_is_gripped = function (self, gripped)
	self._gripped = gripped
end

InteractableExtension.is_gripped = function (self)
	return self._gripped
end

InteractableExtension.picked_node = function (self, wand_hand)
	local unit = self._unit

	if Unit.has_node(unit, "a_grab") then
		return Unit.node(unit, "a_grab")
	else
		return 1
	end
end

InteractableExtension.interaction_started = function (self, wand_input, wand_unit, attach_node, wand_hand, _, __, ___, unit_node_in)
	local unit = self._unit
	local world = self._world
	local unit_node = unit_node_in or self:picked_node(wand_hand)

	Unit.animation_event(wand_unit, self._grip_anim)
	Unit.set_data(unit, "linked", true)
	Unit.set_data(unit, "wand_hand", wand_hand)

	local wand_transform = Matrix4x4.inverse(Unit.world_pose(wand_unit, 1))
	local unit_pos = Unit.world_position(unit, unit_node)
	local offset_pos = Matrix4x4.transform(wand_transform, unit_pos)
	local wand_rot = Quaternion.inverse(Unit.world_rotation(wand_unit, 1))
	local unit_rot = Unit.world_rotation(unit, unit_node)
	local offset_rot = Quaternion.multiply(wand_rot, unit_rot)
	local unit_scale = Unit.local_scale(unit, unit_node)
	local wand_node = 1

	if self._grip_anim then
		wand_node = attach_node
	end

	if Unit.get_data(unit, "disable_animation_on_pickup") then
		Unit.disable_animation_state_machine(unit)
	end

	if self._network_mode ~= "client" then
		local actor = Unit.get_data(unit, "picked_actor" .. wand_hand) or Unit.actor(unit, 1)

		if actor then
			Actor.set_kinematic(actor, true)
		end
	end

	World.link_unit(world, unit, 1, wand_unit, wand_node)

	if unit_node ~= 1 then
		local grab_pose_inverted = Unit.local_pose(unit, unit_node)
		local grab_pose = Matrix4x4.inverse(grab_pose_inverted)

		Unit.set_local_pose(unit, 1, grab_pose)
	end

	Unit.teleport_local_scale(unit, unit_node, unit_scale)
	self:set_is_gripped(true)

	self._wand_input = wand_input

	Unit.flow_event(unit, "pickup_sound")
	Unit.flow_event(unit, "lua_interaction_started")

	return unit_node
end

InteractableExtension.interaction_ended = function (self, wand_input, wand_unit)
	local world = self._world
	local unit = self._unit

	Unit.animation_event(wand_unit, "relax")
	self:set_is_gripped(false)

	self._wand_input = nil

	Unit.set_data(unit, "wand_hand", nil)
	World.unlink_unit(world, unit)

	if self._network_mode ~= "client" then
		for ii = 1, Unit.num_actors(unit) do
			local actor = Unit.actor(unit, ii)

			if actor and Actor.is_dynamic(actor) then
				Actor.set_kinematic(actor, false)
				Actor.wake_up(actor)
			end
		end
	end

	Unit.set_data(unit, "linked", false)
	Unit.flow_event(unit, "drop_sound")
	Unit.flow_event(unit, "lua_interaction_ended")
end

InteractableExtension.set_interactable = function (self, is_interactable)
	self._is_interactable = is_interactable
end

InteractableExtension.is_interactable = function (self)
	return self._is_interactable
end
