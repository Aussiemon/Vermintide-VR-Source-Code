-- chunkname: @script/lua/unit_extensions/simple_interactables.lua

SimpleInteractables = SimpleInteractables or {}

local World = stingray.World
local Quaternion = stingray.Quaternion
local Unit = stingray.Unit
local Matrix4x4 = stingray.Matrix4x4
local Actor = stingray.Actor

SimpleInteractables.link_interactable = function (world, unit, wand_input, wand_unit, wand_hand, attach_node, husk)
	local actor = Unit.get_data(unit, "picked_actor" .. wand_hand) or Unit.actor(unit, 1)
	local unit_node = Actor.node(actor)

	if not husk then
		Actor.set_kinematic(actor, true)
	end

	Unit.set_data(unit, "linked", true)
	Unit.set_data(unit, "wand_hand", wand_hand)

	local wand_transform = Matrix4x4.inverse(Unit.world_pose(wand_unit, 1))
	local unit_pos = Unit.world_position(unit, unit_node)
	local offset_pos = Matrix4x4.transform(wand_transform, unit_pos)
	local wand_rot = Quaternion.inverse(Unit.world_rotation(wand_unit, 1))
	local unit_rot = Unit.world_rotation(unit, unit_node)
	local offset_rot = Quaternion.multiply(wand_rot, unit_rot)
	local unit_scale = Unit.local_scale(unit, unit_node)
	local grip_anim = Unit.get_data(unit, "grip_info", "grip_anim")
	local wand_node = 1

	if grip_anim then
		Unit.animation_event(wand_unit, grip_anim)

		wand_node = attach_node
	end

	if Unit.get_data(unit, "disable_animation_on_pickup") then
		Unit.disable_animation_state_machine(unit)
	end

	World.link_unit(world, unit, unit_node, wand_unit, wand_node)

	if wand_node == 1 then
		Unit.teleport_local_position(unit, unit_node, offset_pos)
		Unit.teleport_local_rotation(unit, unit_node, offset_rot)
	end

	Unit.teleport_local_scale(unit, unit_node, unit_scale)
end

SimpleInteractables.unlink_interactable = function (world, unit, wand_unit, husk)
	Unit.animation_event(wand_unit, "relax")
	Unit.set_data(unit, "linked", false)

	if not husk then
		World.unlink_unit(world, unit)

		if Unit.get_data(unit, "single_actor") then
			local actor = Unit.actor(unit, 1)

			Actor.set_kinematic(actor, false)
			Actor.wake_up(actor)
		else
			for ii = 1, Unit.num_actors(unit) do
				local actor = Unit.actor(unit, ii)

				if actor and Actor.is_dynamic(actor) then
					Actor.set_kinematic(actor, false)
					Actor.wake_up(actor)
				end
			end
		end
	end
end
