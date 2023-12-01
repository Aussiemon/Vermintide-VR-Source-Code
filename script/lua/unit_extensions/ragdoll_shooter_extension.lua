-- chunkname: @script/lua/unit_extensions/ragdoll_shooter_extension.lua

class("RagdollShooterExtension")

local DEBUG = false

RagdollShooterExtension.init = function (self, extension_init_context, unit, extension_init_data)
	local world = extension_init_context.world

	self._unit = unit
	self._world = world
	self._level = extension_init_context.level
	self._spawn_noise = Unit.get_data(unit, "spawn_timer_noise")
	self._direction_noise = Unit.get_data(unit, "direction_noise")
	self._force = Unit.get_data(unit, "force")

	if DEBUG and Unit.get_data(unit, "shotable") then
		self:set_active(true)
	else
		self:set_active(false)
	end
end

RagdollShooterExtension.set_active = function (self, active, spawn_timer, max_spawn)
	print("set active", active)

	if Managers.lobby and not Managers.lobby.server then
		return
	end

	fassert(active ~= nil, "Need to specify if RagdollShooterExtension is active")

	if active then
		self._spawn_timer = spawn_timer or Unit.get_data(self._unit, "spawn_timer")
		self._next_spawn_time = 0
		self._spawned_amount = 0
		self._max_spawn = max_spawn or math.huge
	else
		self._max_spawn = nil
		self._spawn_timer = nil
	end

	self._active = active
end

RagdollShooterExtension.spawn_burst = function (self)
	print("spawn burst")

	local max_spawn = Unit.get_data(self._unit, "burst_amount") or 10

	print(max_spawn)
	self:set_active(true, 0.1, max_spawn)
end

local function spawn_time_noise(base, noise)
	local timer = base + base * (Math.random() - 0.5) * noise

	timer = math.max(timer, base / 2)

	return timer
end

RagdollShooterExtension.update = function (self, unit, dt, t)
	if self._last_ragdoll then
		local ragdoll_unit = self._last_ragdoll
		local push_strength = Unit.get_data(ragdoll_unit, "push_strength")
		local push_seed = Unit.get_data(ragdoll_unit, "push_seed")
		local random_func = Math.random_from_seed(push_seed)

		if self:_push(ragdoll_unit, push_strength, random_func) then
			self._last_ragdoll = nil
		end
	elseif self._active and t >= self._next_spawn_time then
		local push_seed = Math.random()
		local position = Unit.world_position(unit, 1)

		self:spawn_ragdoll(position, self._force, push_seed)

		if self._spawned_amount < self._max_spawn then
			self._next_spawn_time = t + spawn_time_noise(self._spawn_timer, self._spawn_noise)
		else
			self:set_active(false)
		end
	end
end

RagdollShooterExtension._direction = function (self, random_func)
	local rotation = Unit.world_rotation(self._unit, 1)
	local forward = -Quaternion.right(rotation)
	local noise = self._direction_noise
	local noise_vec = Vector3((random_func() - 0.5) * noise, (random_func() - 0.5) * noise, (random_func() - 0.5) * noise)

	return Vector3.normalize(forward + noise_vec)
end

RagdollShooterExtension._push = function (self, ragdoll_unit, push_strength, random_func)
	local count = 0

	for ii = 1, Unit.num_actors(ragdoll_unit) do
		local actor = Unit.actor(ragdoll_unit, ii)

		if actor and not Actor.is_kinematic(actor) then
			count = count + 1
		end
	end

	if count == 0 then
		return false
	end

	local direction = self:_direction(random_func)

	for ii = 1, Unit.num_actors(ragdoll_unit) do
		local actor = Unit.actor(ragdoll_unit, ii)

		if actor and not Actor.is_kinematic(actor) then
			Actor.wake_up(actor)

			local push = direction * push_strength / count

			Actor.add_impulse(actor, push)
		end
	end

	return true
end

RagdollShooterExtension.spawn_ragdoll = function (self, position, push_strength, push_seed)
	local pose = Matrix4x4.identity()

	Matrix4x4.set_translation(pose, position)

	local world = self._world
	local ragdoll_unit = World.spawn_unit(world, "units/beings/enemies/skaven_clan_rat/chr_skaven_clan_rat_baked", pose)

	Unit.animation_event(ragdoll_unit, "ragdoll")

	self._last_ragdoll = ragdoll_unit

	Unit.set_data(ragdoll_unit, "push_seed", push_seed)
	Unit.set_data(ragdoll_unit, "push_strength", push_strength)
	Unit.flow_event(ragdoll_unit, "spawned_by_ragdoll_shooter")

	if Managers.lobby and Managers.lobby.server then
		local unit_id = Level.unit_index(self._level, self._unit)
		local rotation = Unit.world_rotation(ragdoll_unit, 1)
		local data = {
			from_ai = false,
			push_node_index = 0,
			ai_id = 0,
			push_strength = push_strength,
			push_direction = Vector3(0, 0, 0),
			position = position,
			rotation = rotation,
			push_seed = push_seed,
			level_unit_id = unit_id
		}

		self._spawned_amount = self._spawned_amount + 1

		Managers.state.event:trigger("event_ragdoll_spawn", ragdoll_unit, data, true)

		self._spawned_amount = self._spawned_amount + 1
	end

	if not Managers.state.network then
		self._spawned_amount = self._spawned_amount + 1

		Managers.state.event:trigger("event_ragdoll_spawn", ragdoll_unit)
	end

	return ragdoll_unit
end

function flow_callback_enable_ragdoll_shooter(params)
	local unit = params.unit
	local extension = ScriptUnit.extension(unit, "ragdoll_system")

	extension:set_active(true)
end

function flow_callback_disable_ragdoll_shooter(params)
	local unit = params.unit
	local extension = ScriptUnit.extension(unit, "ragdoll_system")

	extension:set_active(false)
end

function flow_callback_ragdoll_shooter_spawn_burst(params)
	local unit = params.unit
	local extension = ScriptUnit.extension(unit, "ragdoll_system")

	extension:spawn_burst()
end
