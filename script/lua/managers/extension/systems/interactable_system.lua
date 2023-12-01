-- chunkname: @script/lua/managers/extension/systems/interactable_system.lua

require("script/lua/unit_extensions/simple_interactables")
require("script/lua/unit_extensions/extension_generic_weapon")
require("script/lua/unit_extensions/bow_extension")
require("script/lua/unit_extensions/handgun_extension")
require("script/lua/unit_extensions/interactable/interactable_lever_extension")
require("script/lua/unit_extensions/interactable/interactable_extension")
require("script/lua/unit_extensions/staff_extension")
require("script/lua/unit_extensions/rapier_extension")

local Unit = stingray.Unit
local World = stingray.World
local Vector3 = stingray.Vector3
local Matrix4x4 = stingray.Matrix4x4
local Actor = stingray.Actor
local PhysicsWorld = stingray.PhysicsWorld
local Quaternion = stingray.Quaternion
local LineObject = stingray.LineObject
local Color = stingray.Color

class("InteractableSystem", "ExtensionSystemBase")

InteractableSystem.extension_list = {
	"InteractableLeverExtension",
	"BowExtension",
	"ExtensionGenericWeapon",
	"HandgunExtension",
	"StaffExtension",
	"InteractableExtension",
	"RapierExtension"
}

InteractableSystem.init = function (self, entity_system_creation_context, system_name, extensions)
	InteractableSystem.super.init(self, entity_system_creation_context, system_name, extensions)

	self._level = entity_system_creation_context.level
	self._line_object = World.create_line_object(self._world)
	self._unit_extension_data = {}

	local network = Managers.lobby

	if network then
		local is_server = network.server

		self._network_mode = is_server and "server" or "client"
		self._extension_init_context.network_mode = self._network_mode
		self._interactables = {}
		self._interactables_lookup = {}
		self._num_interactables = 0

		if is_server then
			Managers.state.network:register_rpc_callbacks(self, "rpc_request_interaction", "rpc_interaction_ended", "rpc_server_request_fire", "rpc_update_bow_draw", "rpc_server_request_cancel_fire")
		else
			Managers.state.network:register_rpc_callbacks(self, "rpc_interactable_pose", "rpc_interaction_started", "rpc_interaction_denied", "rpc_interaction_ended", "rpc_client_fire", "rpc_update_bow_draw", "rpc_client_cancel_fire", "rpc_interactable_pose_initial")
		end

		self._requesting_interactors = {}
	end

	self._interactors = {}
	self._next_update = 0
end

local BITS = 6
local MAX_VAL = 2^BITS

InteractableSystem.on_add_extension = function (self, world, unit, extension_name, ...)
	local extension = InteractableSystem.super.on_add_extension(self, world, unit, extension_name)

	self._unit_extension_data[unit] = extension

	local network_mode = self._network_mode

	if network_mode then
		local new_index = self._num_interactables + 1
		local actor_index = 1
		local data = {
			sleeping = false,
			update_index = 1,
			level_index = Level.unit_index(self._level, unit),
			unit = unit,
			actor_index = actor_index,
			last_sleep_index = math.huge
		}

		self._interactables[new_index] = data
		self._interactables_lookup[unit] = new_index
		self._num_interactables = new_index

		Unit.set_data(unit, "unit_index", new_index)

		if network_mode == "client" then
			local actor = Unit.actor(unit, actor_index)

			Actor.set_kinematic(actor, true)

			local buffer = {}

			data.receive_buffer = buffer

			local pos = Actor.position(actor)
			local rot = Actor.rotation(actor)

			for i = 1, MAX_VAL do
				buffer[i] = {
					set = false,
					position = Vector3Box(pos),
					rotation = QuaternionBox(rot)
				}
			end

			data.last_position = Vector3Box(pos)
			data.last_rotation = QuaternionBox(rot)
			data.next_position = Vector3Box(pos)
			data.next_rotation = QuaternionBox(rot)
			data.start_time = 0
		end
	end

	return extension
end

InteractableSystem.hot_join_sync = function (self, peer_id)
	local network_manager = Managers.state.network

	for wand_unit, data in pairs(self._interactors) do
		local i = self._interactables_lookup[data.unit]
		local wand_game_object_id = network_manager:game_object_id(wand_unit)
		local interaction_type_id = NetworkLookup.interaction_types[data.interaction_type]
		local attach_node = data.attach_node
		local wand_id = WandUnitLookup[data.wand_hand]
		local extension = self._unit_extension_data[data.unit]
		local picked_node = extension.picked_node and extension:picked_node(data.wand_hand) or EMPTY_PICKED_NODE

		RPC.rpc_interaction_started(peer_id, i, wand_game_object_id, wand_id, attach_node, interaction_type_id, picked_node)
	end

	self:_update_poses_server(0, 0, true, peer_id)
end

local UPDATE_RATE = 30
local TICK = 1 / UPDATE_RATE

InteractableSystem.update = function (self, dt, t)
	if self._network_mode == "client" then
		self:_update_poses_client(dt, t)
	end

	InteractableSystem.super.update(self, dt, t)
end

InteractableSystem.post_update = function (self, dt, t)
	if self._network_mode == "server" then
		self:_update_poses_server(dt, t)
	end
end

InteractableSystem._update_poses_server = function (self, dt, t, initial_sync, peer_id)
	local debug = script_data.debug_networked_physics
	local next_update = self._next_update
	local session = Managers.state.network:session()
	local run_once = initial_sync
	local rpc = RPC.rpc_interactable_pose
	local rpc_initial = RPC.rpc_interactable_pose_initial

	while run_once or next_update <= t and session do
		run_once = false
		next_update = next_update + TICK

		local interactables = self._interactables
		local other_peers = GameSession.synchronized_peers(session)
		local self_peer = Network.peer_id()

		for i = 1, self._num_interactables do
			local data = interactables[i]

			if not Unit.alive(data.unit) then
				table.dump(data, nil, 2)

				return
			end

			local actor = Unit.actor(data.unit, data.actor_index)

			if not actor then
				return
			end

			local is_sleeping = Actor.is_sleeping(actor)
			local new_index = data.update_index % MAX_VAL + 1
			local unit = data.unit
			local position = Vector3.clamp(Unit.world_position(unit, 1), -200, 200)
			local rotation = Unit.world_rotation(unit, 1)

			if is_sleeping and not initial_sync then
				data.last_sleeping_index = new_index
			else
				local wake_up

				if data.last_sleeping_index == math.huge then
					wake_up = false
				elseif data.last_sleeping_index == new_index then
					data.last_sleeping_index = math.huge
					wake_up = false
				else
					wake_up = true
				end

				if initial_sync then
					rpc_initial(peer_id, i, position, rotation, wake_up)
				else
					for _, peer in ipairs(other_peers) do
						rpc(peer, i, position, rotation, new_index, wake_up)

						if debug then
							QuickDrawer:sphere(position, 0.25, Color(7 * i % 255, 0, (255 - 7 * i) % 255))
						end
					end
				end
			end

			data.update_index = new_index
		end
	end

	self._next_update = next_update
end

local INTERPOLATE_FRAMES = 3
local DEBUG_INDEX = 0

InteractableSystem.rpc_interactable_pose = function (self, sender, i, position, rotation, index, wake_up)
	local data = self._interactables[i]
	local buffer_element = data.receive_buffer[index]

	buffer_element.position:store(position)
	buffer_element.rotation:store(rotation)

	buffer_element.set = true
	data.last_received_index = index

	if script_data.debug_networked_physics then
		QuickDrawer:sphere(position, 0.25, Color(7 * i, 0, 255 - 7 * i))
	end

	local start_time = data.start_time
	local t = Managers.time:time("game")
	local calculated_start_time = t - (index - INTERPOLATE_FRAMES) % MAX_VAL * TICK
	local max_time = MAX_VAL * TICK
	local calc = calculated_start_time % max_time
	local start = start_time % max_time
	local x1 = calc - start
	local x2 = max_time - start + calc
	local x3 = -start - (max_time - calc)
	local diff, str

	if math.abs(x1) < math.abs(x2) then
		if math.abs(x1) < math.abs(x3) then
			diff = x1
			str = "x1"
		else
			diff = x3
			str = "x3_1"
		end
	elseif math.abs(x2) < math.abs(x3) then
		diff = x2
		str = "x2"
	else
		diff = x3
		str = "x3_2"
	end

	if wake_up then
		data.start_time = data.start_time + diff
	else
		data.start_time = math.lerp(data.start_time, data.start_time + math.clamp(diff, -TICK, TICK), 0.1)
	end

	if i == DEBUG_INDEX then
		self._last_write = index
		self._last_diff = diff
		self._last_str = str
	end

	if script_data.debug_networked_physics then
		QuickDrawer:sphere(position, 0.25)
	end
end

InteractableSystem.rpc_interactable_pose_initial = function (self, sender, i, position, rotation, wake_up)
	local data = self._interactables[i]
	local buffer = data.receive_buffer

	for ii = 1, MAX_VAL do
		local sample = buffer[ii]

		sample.position:store(position)
		sample.rotation:store(rotation)

		sample.set = false
	end

	data.last_position:store(position)
	data.last_rotation:store(rotation)
	data.next_position:store(position)
	data.next_rotation:store(rotation)

	data.start_time = 0
end

InteractableSystem._update_poses_client = function (self, dt, t)
	local interactables = self._interactables

	for i = 1, self._num_interactables do
		local data = interactables[i]
		local t = t - data.start_time
		local frame_value = t * UPDATE_RATE
		local frames = math.floor(frame_value)
		local t_value = frame_value - frames
		local buffer_index = frames % MAX_VAL + 1
		local last_index = data.update_index

		data.update_index = buffer_index

		local new_buffer_element = last_index ~= buffer_index
		local next_index = last_index % MAX_VAL + 1
		local on_screen = false
		local do_print = false
		local do_debug = DEBUG_INDEX == i
		local print_func = not do_print and function ()
			return
		end or on_screen and Debug.text or function (str, ...)
			print(string.format(str, ...))
		end

		if last_index == buffer_index then
			print_func("do nothing %i %i %i", last_index, next_index, buffer_index)
		elseif next_index == buffer_index then
			local buffer_element = data.receive_buffer[buffer_index]

			if buffer_element.set then
				data.last_position:store(data.next_position:unbox())
				data.last_rotation:store(data.next_rotation:unbox())
				data.next_position:store(buffer_element.position:unbox())
				data.next_rotation:store(buffer_element.rotation:unbox())

				buffer_element.set = false

				print_func("go")

				if do_debug then
					self._last_cmd = "go"
				end
			else
				print_func("stop")

				if do_debug then
					self._last_cmd = "stop"
				end

				data.last_position:store(data.next_position:unbox())
				data.last_rotation:store(data.next_rotation:unbox())
			end
		else
			local last_pos = data.next_position:unbox()
			local last_rot = data.next_rotation:unbox()

			print_func("catchup %i %i %i", last_index, next_index, buffer_index)

			if do_debug then
				self._last_cmd = "catchup"
			end

			while next_index ~= buffer_index do
				local buffer_element = data.receive_buffer[next_index]

				if buffer_element.set then
					last_pos = buffer_element.position:unbox()
					last_rot = buffer_element.rotation:unbox()
					buffer_element.set = false
				end

				next_index = next_index % MAX_VAL + 1
			end

			data.last_position:store(last_pos)
			data.last_rotation:store(last_rot)

			local buffer_element = data.receive_buffer[next_index]

			if buffer_element.set then
				buffer_element.set = false

				data.next_position:store(buffer_element.position:unbox())
				data.next_rotation:store(buffer_element.rotation:unbox())
			else
				data.next_position:store(last_pos)
				data.next_rotation:store(last_rot)
			end
		end

		local last_pos = data.last_position:unbox()
		local last_rot = data.last_rotation:unbox()
		local next_pos = data.next_position:unbox()
		local next_rot = data.next_rotation:unbox()
		local pos = Vector3.lerp(last_pos, next_pos, t_value)
		local rot = Quaternion.lerp(last_rot, next_rot, t_value)
		local node = 1
		local unit = data.unit
		local interact_ext = ScriptUnit.extension(unit, "interactable_system")

		if not Unit.get_data(unit, "linked") then
			Unit.set_local_position(unit, node, pos)
			Unit.set_local_rotation(unit, node, rot)
		end

		if false then
			-- Nothing
		end

		if do_debug then
			self._last_read = buffer_index
		end
	end

	if DEBUG_INDEX > 0 then
		Debug.text("last type %q, last cmd %q diff %f ", self._last_str or "", self._last_cmd or "", self._last_diff or 0)

		local temp = {}

		for i = 1, 256 do
			local write = self._last_write or 0
			local read = self._last_read or 0

			for j = 1, 8 do
				temp[j * 2 - 1] = write >= i + (j - 1) * 32 and "*" or " "
				temp[j * 2] = read >= i + (j - 1) * 32 and "*" or " "
			end

			Debug.text("%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s", unpack(temp))
		end
	end
end

InteractableSystem.on_remove_extension = function (self, unit, extension_name)
	InteractableSystem.super.on_remove_extension(self, unit, extension_name)

	self._unit_extension_data[unit] = nil
end

InteractableSystem.can_interact = function (self, unit, input)
	local can_interact = false
	local extension = self._unit_extension_data[unit]
	local can_interact, interaction_type = extension:can_interact(input)

	return can_interact, interaction_type or "n/a"
end

InteractableSystem.should_drop = function (self, unit, input)
	local should_drop = false
	local extension = self._unit_extension_data[unit]
	local should_drop = extension:should_drop(input)

	return should_drop
end

InteractableSystem.allowed_interact = function (self, unit, interaction_type)
	local extension = self._unit_extension_data[unit]
	local allow_func = extension.allowed_interact or function (extension, interaction_type)
		return not Unit.get_data(extension._unit, "linked")
	end

	return allow_func(extension, interaction_type)
end

EMPTY_PICKED_NODE = 16000

InteractableSystem.interaction_started = function (self, unit, wand_input, wand_unit, wand_hand, attach_node, interaction_type, result_cb)
	if self._network_mode == "client" then
		local extension = self._unit_extension_data[unit]
		local picked_node = extension.picked_node and extension:picked_node(wand_hand) or EMPTY_PICKED_NODE

		self._requesting_interactors[wand_unit] = {
			unit = unit,
			callback = result_cb,
			wand_input = wand_input
		}

		local network_manager = Managers.state.network

		network_manager:send_rpc_session_host("rpc_request_interaction", self._interactables_lookup[unit], network_manager:game_object_id(wand_unit), WandUnitLookup[wand_hand], attach_node, NetworkLookup.interaction_types[interaction_type], picked_node)
	elseif self:allowed_interact(unit, interaction_type) then
		local extension = self._unit_extension_data[unit]
		local peer_id = Managers.lobby and Network.peer_id() or nil
		local picked_node = extension:interaction_started(wand_input, wand_unit, attach_node, wand_hand, interaction_type, nil, peer_id) or EMPTY_PICKED_NODE

		self._interactors[wand_unit] = {
			unit = unit,
			attach_node = attach_node,
			interaction_type = interaction_type,
			wand_hand = wand_hand
		}

		if self._network_mode == "server" then
			local i = self._interactables_lookup[unit]
			local data = self._interactables[i]
			local network_manager = Managers.state.network
			local wand_game_object_id = network_manager:game_object_id(wand_unit)

			network_manager:send_rpc_session_clients("rpc_interaction_started", i, wand_game_object_id, WandUnitLookup[wand_hand], attach_node, NetworkLookup.interaction_types[interaction_type], picked_node)
		end

		local parry_extension = ScriptUnit.extension(unit, "parry_system")

		if parry_extension then
			parry_extension:interaction_started(wand_input, wand_unit, attach_node, wand_hand, interaction_type, nil, peer_id)
		end

		result_cb(true)
	else
		result_cb(false)
	end
end

InteractableSystem.rpc_request_interaction = function (self, sender, i, wand_game_object_id, wand_id, attach_node, interaction_type_id, picked_node)
	if self._interactions_disabled then
		print("InteractableSystem:rpc_request_interaction() -> Interactions Disabled")

		return
	end

	local network_manager = Managers.state.network
	local interaction_type = NetworkLookup.interaction_types[interaction_type_id]
	local unit = self._interactables[i].unit
	local wand_hand = WandUnitLookup[wand_id]

	if self:allowed_interact(unit, interaction_type) then
		local wand_unit = network_manager:unit(wand_game_object_id)

		network_manager:send_rpc_session_clients("rpc_interaction_started", i, wand_game_object_id, wand_id, attach_node, interaction_type_id, EMPTY_PICKED_NODE)

		self._interactors[wand_unit] = {
			unit = unit,
			attach_node = attach_node,
			interaction_type = interaction_type,
			wand_hand = wand_hand
		}

		if picked_node == EMPTY_PICKED_NODE then
			picked_node = false
		end

		self:_set_husk_interaction_state(true, unit, wand_unit, attach_node, wand_hand, interaction_type, sender, picked_node)
	else
		RPC.rpc_interaction_denied(sender, i, wand_game_object_id)
	end
end

InteractableSystem._set_husk_interaction_state = function (self, state, unit, wand_unit, attach_node, wand_hand, interaction_type, owner_peer_id, picked_node)
	local wand_ext = ScriptUnit.extension(wand_unit, "wand_system")

	wand_ext:set_interaction_state(state, unit)

	local extension = self._unit_extension_data[unit]

	if state then
		if extension.husk_interaction_started then
			extension:husk_interaction_started(wand_unit, attach_node, wand_hand, interaction_type, nil, owner_peer_id)
		else
			extension:interaction_started(nil, wand_unit, attach_node, wand_hand, interaction_type, nil, owner_peer_id, picked_node)
		end
	elseif extension and extension.husk_interaction_ended then
		extension:husk_interaction_ended(wand_unit, owner_peer_id)
	else
		extension:interaction_ended(nil, wand_unit)
	end
end

InteractableSystem.rpc_interaction_started = function (self, sender, i, wand_game_object_id, wand_id, attach_node, interaction_type_id, picked_node)
	local wand_unit = Managers.state.network:unit(wand_game_object_id)
	local request = self._requesting_interactors[wand_unit]
	local data = self._interactables[i]
	local unit = data.unit
	local wand_hand = WandUnitLookup[wand_id]
	local interaction_type = NetworkLookup.interaction_types[interaction_type_id]

	self._interactors[wand_unit] = {
		unit = unit,
		attach_node = attach_node,
		interaction_type = interaction_type,
		wand_hand = wand_hand
	}

	if request then
		self._requesting_interactors[wand_unit] = nil

		local extension = self._unit_extension_data[request.unit]

		extension:interaction_started(request.wand_input, wand_unit, attach_node, wand_hand, interaction_type, nil, sender)
		request.callback(true)
	else
		if picked_node == EMPTY_PICKED_NODE then
			picked_node = false
		end

		self:_set_husk_interaction_state(true, unit, wand_unit, attach_node, wand_hand, interaction_type, sender, picked_node)
	end
end

InteractableSystem.rpc_interaction_denied = function (self, sender, i, wand_game_object_id)
	local wand_unit = Managers.state.network:unit(wand_game_object_id)
	local request = self._requesting_interactors[wand_unit]

	self._requesting_interactors[wand_unit] = nil

	request.callback(false)
end

InteractableSystem.interaction_ended = function (self, unit, wand_input, wand_unit, wand_hand)
	if self._interactions_disabled then
		print("InteractableSystem:interaction_ended() -> Interactions Disabled")

		return
	end

	local extension = self._unit_extension_data[unit]
	local enable_highlight = extension:interaction_ended(wand_input, wand_unit)
	local network_manager = Managers.state.network

	fassert(self._interactors[wand_unit].unit == unit, "Trying to stop interaction with unit %q that doesn't match current interactable %q", unit or "nil", self._interactors[wand_unit].unit or "nil")

	if self._network_mode == "client" then
		self._interactors[wand_unit] = nil

		network_manager:send_rpc_session_host("rpc_interaction_ended", self._interactables_lookup[unit], network_manager:game_object_id(wand_unit), WandUnitLookup[wand_hand])
	elseif self._network_mode == "server" then
		local i = self._interactables_lookup[unit]
		local data = self._interactables[i]

		self._interactors[wand_unit] = nil

		network_manager:send_rpc_session_clients("rpc_interaction_ended", self._interactables_lookup[unit], network_manager:game_object_id(wand_unit), WandUnitLookup[wand_hand])
	else
		self._interactors[wand_unit] = nil
	end

	return enable_highlight
end

InteractableSystem.rpc_interaction_ended = function (self, sender, i, wand_game_object_id, wand_id)
	if self._interactions_disabled then
		print("InteractableSystem:rpc_interaction_ended() -> Interactions Disabled")

		return
	end

	local network_manager = Managers.state.network
	local wand_hand = WandUnitLookup[wand_id]
	local data = self._interactables[i]
	local unit = data.unit
	local wand_unit = network_manager:unit(wand_game_object_id)
	local interactor_data = self._interactors[wand_unit]

	fassert(interactor_data and interactor_data.unit == unit, "Interactor missmatch, %q not currently interacting with %q", wand_unit or "nil", unit or "nil")

	self._interactors[wand_unit] = nil

	self:_set_husk_interaction_state(false, unit, wand_unit, nil, wand_hand)

	if self._network_mode == "server" then
		network_manager:send_rpc_session_clients_except(sender, "rpc_interaction_ended", i, wand_game_object_id, wand_id)
	end
end

InteractableSystem.rpc_server_request_fire = function (self, sender, unit_index, source_position, direction, look_target_pos)
	if self._interactions_disabled then
		print("InteractableSystem:rpc_server_request_fire() -> Interactions Disabled")

		return
	end

	local unit = self._interactables[unit_index].unit
	local extension = self._unit_extension_data[unit]

	if extension and extension.fire then
		extension:fire(source_position, direction, look_target_pos, true, sender)
		Managers.state.network:send_rpc_clients("rpc_client_fire", unit_index, source_position, direction, look_target_pos)
	end
end

InteractableSystem.rpc_client_fire = function (self, sender, unit_index, source_position, direction, look_target_pos)
	local unit = self._interactables[unit_index].unit
	local extension = self._unit_extension_data[unit]

	if extension and extension.fire then
		extension:fire(source_position, direction, look_target_pos)
	end
end

InteractableSystem.rpc_server_request_cancel_fire = function (self, sender, unit_index)
	if self._interactions_disabled then
		print("InteractableSystem:rpc_server_request_cancel_fire() -> Interactions Disabled")

		return
	end

	local unit = self._interactables[unit_index].unit
	local extension = self._unit_extension_data[unit]

	if extension and extension.cancel_fire then
		extension:cancel_fire()
		Managers.state.network:send_rpc_clients("rpc_client_cancel_fire", unit_index)
	end
end

InteractableSystem.rpc_client_cancel_fire = function (self, sender, unit_index)
	local unit = self._interactables[unit_index].unit
	local extension = self._unit_extension_data[unit]

	if extension and extension.cancel_fire then
		extension:cancel_fire()
	end
end

InteractableSystem.rpc_update_bow_draw = function (self, sender, unit_index, riser_position, string_position, draw_length)
	if self._interactions_disabled then
		print("InteractableSystem:rpc_update_bow_draw() -> Interactions Disabled")

		return
	end

	local unit = self._interactables[unit_index].unit
	local extension = self._unit_extension_data[unit]

	if extension and extension.update_bow_draw then
		if self._network_mode == "server" then
			extension:update_bow_draw(riser_position, string_position, draw_length)

			local network_manager = Managers.state.network

			network_manager:send_rpc_session_clients_except(sender, "rpc_update_bow_draw", unit_index, riser_position, string_position, draw_length)
		elseif self._network_mode == "client" then
			extension:update_bow_draw(riser_position, string_position, draw_length)
		end
	end
end

InteractableSystem.disable_all_interactions = function (self)
	print("Disable all interactions")

	for unit, extension in pairs(self._unit_extension_data) do
		if extension.set_interactable then
			if extension:is_gripped() then
				extension:interaction_ended(nil, nil, true)
			end

			extension:set_interactable(false)
		end
	end

	self._interactions_disabled = true
end

InteractableSystem.is_interactable = function (self, unit)
	local extension = self._unit_extension_data[unit]

	return extension:is_interactable()
end

InteractableSystem.destroy = function (self)
	self._unit_extension_data = nil
end

InteractableSystem.unit_extension_data = function (self)
	return self._unit_extension_data
end
