-- chunkname: @script/lua/unit_extensions/staff_ragdoll_puller.lua

local DEBUG_PULL_SPHERE = false

class("StaffRagdollPuller")

StaffRagdollPuller.init = function (self, world, unit, skull_node, staff_wand_unit, staff_attach_node, staff_node, min_world_extent, max_world_extent)
	self._world = world
	self._unit = unit
	self._skull_node = skull_node
	self._staff_wand_unit = staff_wand_unit
	self._staff_attach_node = staff_attach_node
	self._staff_node = staff_node
	self._min_world_extent = min_world_extent
	self._max_world_extent = max_world_extent
	self._physics_world = World.physics_world(self._world)
	self._suffix = Unit.get_data(self._unit, "suffix")

	if DEBUG_PULL_SPHERE then
		self._line_object_pull_sphere = DebugDrawer:new(World.create_line_object(self._world), true)
	end

	self._max_lift_height = -1.5
	self._common_settings = {
		min = self._min_world_extent:unbox(),
		max = self._max_world_extent:unbox(),
		duration = math.huge
	}
	self._vector_fields = {}
	self._ragdoll_overlap_callback = callback(self, "ragdoll_overlap_callback")
	self._ragdoll_callback_context = {
		has_gotten_callback = false,
		num_hits = 0,
		overlap_units = {}
	}
	self._ragdoll_pull_time = 0
	self._magic_lifted_units = {}

	self:_add_common_vector_field()
	self:_add_ragdoll_pull_vector_field()
end

StaffRagdollPuller._settings = function (self)
	self._common_settings.min_pos = self._min_world_extent:unbox()
	self._common_settings.max_pos = self._max_world_extent:unbox()

	return self._common_settings
end

StaffRagdollPuller._add_common_vector_field = function (self)
	local skull_pos = Unit.world_position(self._unit, self._skull_node)

	self._vector_field = World.vector_field(self._world, "magic_ragdoll_link")

	local settings = self:_settings()
	local parameters = {
		center = skull_pos,
		radius = Vector4(1, 1, 1, 1),
		speed = Vector4(0, 0, 0, 0)
	}

	self._common_vf_id = VectorField.add(self._vector_field, "vector_fields/magic_pull_push", parameters, settings)
end

StaffRagdollPuller._add_ragdoll_pull_vector_field = function (self)
	self._ragdoll_pull_vf = World.vector_field(self._world, "magic_charge_pull")

	local position = Unit.world_position(self._unit, self._staff_node)
	local settings = self:_settings()

	settings.max.y = self._max_lift_height

	local parameters = {
		center = position,
		radius = Vector4(1, 1, 1, 1),
		inner_radius = Vector4(0.8, 0.8, 0.8, 0.8),
		speed = Vector4(0, 0, 0, 0)
	}

	self._ragdoll_pull_vf_id = VectorField.add(self._ragdoll_pull_vf, "vector_fields/staff_pull_ragdoll", parameters, settings)
end

StaffRagdollPuller._update_common_vector_field = function (self, radius)
	local skull_pos = Unit.world_position(self._unit, self._skull_node)
	local pull_speed = -StaffSettings.ragdoll_particle_link_pull.speed
	local parameters = {
		center = skull_pos,
		radius = Vector4(radius, radius, radius, radius),
		speed = Vector4(pull_speed, pull_speed, pull_speed, pull_speed)
	}
	local settings = self:_settings()

	VectorField.change(self._vector_field, self._common_vf_id, "vector_fields/magic_pull_push", parameters, settings)
end

StaffRagdollPuller.update = function (self, dt, t)
	if self._ragdoll_pull_time < StaffSettings.charge_time then
		self._ragdoll_pull_time = self._ragdoll_pull_time + dt
	end

	assert(StaffSettings.charge_pull_time > 0 and "StaffSettings.charge_pull_time must be above 0!")

	local percentage = self._ragdoll_pull_time / StaffSettings.charge_pull_time
	local rot = Unit.world_rotation(self._unit, self._staff_node)
	local up = Quaternion.up(rot)
	local charge_settings = StaffSettings.charge_pull_ragdolls
	local radius = charge_settings.min_radius + charge_settings.max_bonus_radius * percentage
	local inner_radius = charge_settings.min_inner_radius + charge_settings.max_bonus_inner_radius * percentage
	local speed = charge_settings.min_speed + charge_settings.max_bonus_speed * percentage
	local lift_speed = charge_settings.max_lift_speed
	local hand_pos = Unit.world_position(self._staff_wand_unit, self._staff_attach_node)
	local hand_rot = Unit.world_rotation(self._staff_wand_unit, self._staff_attach_node)
	local staff_up = Quaternion.up(hand_rot)
	local staff_pos = hand_pos + staff_up * (0.5 * radius)
	local center_pos = Vector3(staff_pos.x, staff_pos.y, staff_pos.z)

	if DEBUG_PULL_SPHERE then
		self._line_object_pull_sphere:update(self._world)
		self._line_object_pull_sphere:reset()
		self._line_object_pull_sphere:sphere(center_pos, radius, Color(255, 0, 255))
	end

	local parameters = {
		center = center_pos,
		radius = Vector4(radius, radius, radius, radius),
		inner_radius = Vector4(inner_radius, inner_radius, inner_radius, inner_radius),
		speed = Vector4(-speed, -speed, -lift_speed, speed)
	}
	local settings = self:_settings()

	VectorField.change(self._ragdoll_pull_vf, self._ragdoll_pull_vf_id, "vector_fields/staff_pull_ragdoll", parameters, settings)
	self:_update_common_vector_field(radius)
	self:_apply_ragdoll_pull_vector_field(dt, t)
	self:_find_ragdolls_and_apply_effects(center_pos, radius)
end

StaffRagdollPuller._find_ragdolls_and_apply_effects = function (self, pos, radius)
	local callback_context = self._ragdoll_callback_context

	if not callback_context.has_gotten_callback then
		PhysicsWorld.overlap(self._physics_world, self._ragdoll_overlap_callback, "shape", "sphere", "position", pos, "size", radius, "types", "both", "collision_filter", "filter_staff_magic")
	elseif callback_context.has_gotten_callback then
		local num_actors = callback_context.num_hits
		local actors = callback_context.overlap_units
		local max_levitating_ragdolls = Managers.differentiation:max_levitating_ragdolls()
		local lifted_units = self._magic_lifted_units
		local suffix = tostring(self._suffix)

		for i = 1, num_actors do
			local hit_actor = actors[i]:unbox()
			local hit_unit = Actor.unit(hit_actor)

			if lifted_units[hit_unit] or max_levitating_ragdolls > table.size(self._magic_lifted_units) then
				if DEBUG_PULL_SPHERE then
					self._line_object_pull_sphere:sphere(Unit.world_position(hit_unit, 1), 0.75, Color(0, 255, 0))
				end

				Actor.set_collision_filter(hit_actor, "filter_ragdoll_liftable_" .. suffix)

				if not lifted_units[hit_unit] then
					self._magic_lifted_units[hit_unit] = {}

					Unit.flow_event(hit_unit, "magic_lift_particle_start")
				end

				local actors = self._magic_lifted_units[hit_unit]

				actors[#actors + 1] = ActorBox(hit_actor)
			end
		end

		callback_context.has_gotten_callback = false
		callback_context.num_hits = 0
		callback_context.overlap_units = {}
	end
end

StaffRagdollPuller._apply_ragdoll_pull_vector_field = function (self, dt, t)
	local suffix = tostring(self._suffix)

	PhysicsWorld.wake_actors(self._physics_world, "filter_staff_magic_vf_" .. suffix, self._min_world_extent:unbox(), self._max_world_extent:unbox())
	PhysicsWorld.apply_wind(self._physics_world, self._ragdoll_pull_vf, "filter_staff_magic_vf_" .. suffix)
end

StaffRagdollPuller._add_ragdoll = function (self, position, ragdoll_unit)
	return
end

StaffRagdollPuller._remove_ragdoll = function (self, ragdoll_unit)
	return
end

StaffRagdollPuller.ragdoll_overlap_callback = function (self, actors)
	local callback_context = self._ragdoll_callback_context

	callback_context.has_gotten_callback = true

	local overlap_units = callback_context.overlap_units

	for k, actor in pairs(actors) do
		callback_context.num_hits = callback_context.num_hits + 1

		if overlap_units[callback_context.num_hits] == nil then
			overlap_units[callback_context.num_hits] = ActorBox()
		end

		overlap_units[callback_context.num_hits]:store(actor)
	end
end

StaffRagdollPuller.destroy = function (self)
	self._ragdoll_pull_time = 0

	if DEBUG_PULL_SPHERE then
		self._line_object_pull_sphere:reset()
	end

	local position = Unit.world_position(self._unit, self._staff_node)
	local parameters = {
		center = position,
		radius = Vector4(1, 1, 1, 1),
		inner_radius = Vector4(0.4, 0.4, 0.4, 0.4),
		speed = Vector4(0, 0, 0, 0)
	}
	local settings = self:_settings()

	VectorField.change(self._ragdoll_pull_vf, self._ragdoll_pull_vf_id, "vector_fields/staff_pull_ragdoll", parameters, settings)
	self:_apply_ragdoll_pull_vector_field()

	for unit, actors in pairs(self._magic_lifted_units) do
		if unit and Unit.alive(unit) then
			Unit.flow_event(unit, "magic_lift_particle_end")

			for _, actor_box in ipairs(actors) do
				Actor.set_collision_filter(actor_box:unbox(), "filter_ragdoll")
			end
		end
	end

	table.clear(self._magic_lifted_units)
	VectorField.remove(self._vector_field, self._common_vf_id)
end
