-- chunkname: @script/lua/unit_extensions/head/head_extension.lua

class("HeadExtension")

local DEBUG = false

HeadExtension.init = function (self, extension_init_context, unit, extension_init_data)
	local world = extension_init_context.world

	self._unit = unit

	Unit.set_unit_visibility(self._unit, false)

	self._world = world
	self._physics_world = World.physics_world(world)

	local settings = extension_init_data.settings

	self:_setup_unit(unit, settings)

	if self._network_mode ~= "client" then
		Unit.set_data(unit, "name", "player_1")
	end
end

HeadExtension._setup_unit = function (self, unit, head_settings)
	local head_unit_name = head_settings.unit_name
	local head_pos_offset = head_settings.pos_offset
	local head_rot_offset = head_settings.rot_offset
	local pos_offset = Vector3(head_pos_offset[1], head_pos_offset[2], head_pos_offset[3])

	self._head_pos_offset = Vector3Box(pos_offset)

	local rot_offset = Quaternion.from_euler_angles_xyz(head_rot_offset[1], head_rot_offset[2], head_rot_offset[3])

	self._head_rot_offset = QuaternionBox(rot_offset)

	local base_pose = Managers.vr:hmd_world_pose().head
	local head_pose = self:_calculate_head_pose(base_pose, rot_offset, pos_offset)

	Unit.set_local_pose(unit, 1, head_pose)
end

HeadExtension.update = function (self, unit, dt, t)
	self:_update_head_position()
end

HeadExtension._calculate_head_pose = function (self, base_pose, rotation_offset, position_offset)
	local head_pose = Matrix4x4.from_quaternion_position(Quaternion.multiply(Matrix4x4.rotation(base_pose), rotation_offset), Matrix4x4.transform(base_pose, position_offset))

	return head_pose
end

HeadExtension._update_head_position = function (self)
	local base_pose = Managers.vr:hmd_world_pose().head
	local head_pose = self:_calculate_head_pose(base_pose, self._head_rot_offset:unbox(), self._head_pos_offset:unbox())

	self:_update_game_object(head_pose)
	Unit.set_local_pose(self._unit, 1, head_pose)
end

HeadExtension._update_game_object = function (self, head_pose)
	local network_manager = Managers.state.network
	local in_session = network_manager and network_manager:state() == "in_session"

	if in_session and self.game_object_id then
		local session = network_manager:session()
		local position = Matrix4x4.translation(head_pose)
		local rotation = Matrix4x4.rotation(head_pose)
		local object_id = self.game_object_id

		GameSession.set_game_object_field(session, object_id, "position", position)
		GameSession.set_game_object_field(session, object_id, "rotation", rotation)
	elseif in_session then
		local session = network_manager:session()
		local position = Matrix4x4.translation(head_pose)
		local rotation = Matrix4x4.rotation(head_pose)
		local id = network_manager:create_game_object("head", {
			position = position,
			rotation = rotation
		}, self._unit)

		network_manager:set_game_object_unit(self._unit, id)

		self.game_object_id = id
	end
end
