-- chunkname: @script/lua/managers/network/network_manager.lua

class("NetworkManager")

local NETWORK_STRICT = true

NetworkManager.init = function (self, create_session, world)
	self._lobby = Managers.lobby.lobby

	local is_server = Managers.lobby.server

	self._is_server = is_server
	self._rpc_receiver = self:_create_network_receiver()
	self._leave_timeout = math.huge
	self._in_receive = false

	if create_session then
		self._world = world
		self._session = Network.create_game_session()
		self._session_disconnected = false
		self._game_object_callbacks = {}
		self._game_object_id_lookup = {}

		if is_server then
			GameSession.make_game_session_host(self._session)
			Managers.lobby:set_game_server(Network.peer_id())

			self._state = "in_session"

			self:register_rpc_callbacks(self, "rpc_request_join_session", "game_object_sync_done", "game_object_created", "game_object_destroyed")

			self._object_synchronizing_clients = {}
			self._synchronized_peers = {}
		else
			self._state = "waiting_for_session"

			self:register_rpc_callbacks(self, "rpc_session_joined", "game_object_sync_done", "game_object_created", "game_object_destroyed", "game_session_disconnect")
		end

		Network.set_pong_timeout(GameSettingsDevelopment.network_timeout)
	end
end

NetworkManager._create_network_receiver = function (self)
	local function dummy_function()
		return
	end

	local receiver = {}
	local receiver_meta = {
		__index = function (t, k)
			printf("Ignoring RPC %q without registered callback", k)

			if NETWORK_STRICT then
				error(string.format("missing callback for %q", k))
			end

			return dummy_function
		end
	}

	setmetatable(receiver, receiver_meta)

	return receiver
end

NetworkManager.register_rpc_callbacks = function (self, object, ...)
	local receiver = self._rpc_receiver

	for i = 1, select("#", ...) do
		local rpc_name = select(i, ...)

		fassert(object[rpc_name], "Missing RPC %q in callback object", rpc_name)
		fassert(not rawget(receiver, rpc_name), "RPC callback for %q already registered.", rpc_name)

		receiver[rpc_name] = function (self, ...)
			object[rpc_name](object, ...)
		end
	end
end

NetworkManager.shutdown_session = function (self, timeout_time)
	fassert(self._is_server, "Trying to shut down session without being session host")
	fassert(self._state == "in_session", "Trying to shut down session without session in progress")

	self._state = "shutting_down"
	self._shutdown_timeout = timeout_time

	GameSession.shutdown_game_session_host(self._session)
end

NetworkManager.leave_session = function (self, timeout_time)
	fassert(not self._is_server, "Trying to leave sesssion while session host")

	local state = self._state

	if state == "in_session" then
		GameSession.leave(self._session)

		self._state = "leaving"
		self._leave_timeout = timeout_time
	elseif state == "requesting_session_join" then
		self._state = "queued_leave"
	elseif state then
		self._state = "left"

		self:_destroy_session()
	end
end

NetworkManager.state = function (self)
	return self._state
end

NetworkManager.in_session = function (self)
	return self._state == "in_session"
end

NetworkManager.session = function (self)
	return self._session
end

NetworkManager.update_receive = function (self, dt, t)
	Profiler.start("NetworkManager:update_receive()")

	self._in_receive = true

	Network.update_receive(dt, self._rpc_receiver)

	self._in_receive = false

	local lobby_manager = Managers.lobby
	local is_server = self._is_server
	local session = self._session

	if is_server and session then
		self:_update_server_session(dt, t, session)
	elseif session then
		self:_update_client_session(dt, t, session)
	end

	Profiler.stop("NetworkManager:update_receive()")
end

NetworkManager._update_server_session = function (self, dt, t, session, state)
	local state = self._state

	if state == "in_session" then
		local peer_id = GameSession.wants_to_leave(session) or GameSession.broken_connection(session)

		while peer_id do
			GameSession.remove_peer(session, peer_id, self._rpc_receiver)

			peer_id = GameSession.wants_to_leave(session) or GameSession.broken_connection(session)
		end

		self._synchronized_peers = GameSession.synchronized_peers(session)
	elseif state == "shutting_down" and t > self._shutdown_timeout then
		table.clear(self._synchronized_peers)

		self._state = "shut_down"

		self:_destroy_session()
	end
end

NetworkManager._update_client_session = function (self, dt, t, session, state)
	local state = self._state
	local host_peer_id = self._lobby:game_session_host()

	if state == "waiting_for_session" and host_peer_id then
		self:send_rpc_session_host("rpc_request_join_session")

		self._state = "requesting_session_join"
	elseif state == "requesting_session_join" or state == "in_session" or state == "queued_leave" then
		if GameSession.host_error(session) or self._session_disconnected or not Network.has_connection(host_peer_id) or Network.is_broken(host_peer_id) then
			GameSession.disconnect_from_host(session)

			self._state = "leaving"
			self._leave_timeout = math.huge
		end
	elseif state == "leaving" then
		if GameSession.in_session(session) then
			if t > self._leave_timeout then
				GameSession.disconnect_from_host(session)

				self._leave_timeout = math.huge
			end
		else
			self._state = "left"

			self:_destroy_session()
		end
	end
end

NetworkManager.update_transmit = function (self, dt, t)
	Profiler.start("NetworkManager:update_transmit()")
	Network.update_transmit()
	Profiler.stop("NetworkManager:update_transmit()")
end

NetworkManager.destroy = function (self)
	if self._session then
		self:_destroy_session()
	end
end

NetworkManager._destroy_session = function (self)
	Network.shutdown_game_session()

	self._session = nil
end

NetworkManager.send_rpc_session_clients_except = function (self, except, rpc_name, ...)
	fassert(self._is_server, "[GameNetworkManager:send_rpc_session_clients_except()] trying to send rpcs to clients while not host")

	local rpc = RPC[rpc_name]

	fassert(rpc, "[GameNetworkManager:send_rpc_session_clients_except()] rpc does not exist %q", rpc_name)

	local peers

	if self._in_receive then
		peers = GameSession.synchronized_peers(self._session)
	else
		peers = self._synchronized_peers
	end

	for _, peer in ipairs(self._synchronized_peers) do
		if peer ~= except then
			rpc(peer, ...)
		end
	end
end

NetworkManager.send_rpc_session_clients = function (self, rpc_name, ...)
	fassert(self._is_server, "[GameNetworkManager:send_rpc_session_clients()] trying to send rpcs to clients while not host")

	local rpc = RPC[rpc_name]

	fassert(rpc, "[GameNetworkManager:send_rpc_session_clients()] rpc does not exist %q", rpc_name)

	local peers

	if self._in_receive then
		peers = GameSession.synchronized_peers(self._session)
	else
		peers = self._synchronized_peers
	end

	for _, peer in ipairs(self._synchronized_peers) do
		rpc(peer, ...)
	end
end

NetworkManager.send_rpc_session_host = function (self, rpc_name, ...)
	local rpc = RPC[rpc_name]

	fassert(rpc, "[GameNetworkManager:send_rpc_session_host()] rpc does not exist %q", rpc_name)

	local host = self._lobby:game_session_host()

	fassert(host, "[NetworkManager:send_rpc_session_host())] trying to send rpc to session host without host")
	rpc(host, ...)
end

NetworkManager.send_rpc_clients = function (self, rpc_name, ...)
	fassert(self._is_server, "[NetworkManager] Trying to send rpc %q on client to clients which is wrong. Only servers should use this function.", rpc_name)

	local session = self._session

	if not session then
		return
	end

	local rpc = RPC[rpc_name]

	fassert(rpc, "[NetworkManager:send_rpc_clients()] rpc does not exist: %q", rpc_name)

	for _, peer_id in ipairs(GameSession.other_peers(session)) do
		rpc(peer_id, ...)
	end
end

NetworkManager.rpc_request_join_session = function (self, sender)
	if self._session then
		GameSession.add_peer(self._session, sender)

		self._object_synchronizing_clients[sender] = true
	end
end

NetworkManager.game_session_disconnect = function (self, peer_id)
	local state = self._state

	self._session_disconnected = true
end

NetworkManager.game_object_sync_done = function (self, peer_id)
	if self._is_server then
		self._object_synchronizing_clients[peer_id] = nil

		Managers.state.extension:hot_join_sync(peer_id)
		Managers.state.score:hot_join_sync(peer_id)
		RPC.rpc_session_joined(peer_id)
	end
end

NetworkManager.rpc_session_joined = function (self, sender)
	local state = self._state

	if state == "requesting_session_join" then
		self._state = "in_session"
	elseif state == "queued_leave" then
		GameSession.leave(self._session)

		self._state = "leaving"
		self._leave_timeout = Managers.time:time("game") + 1
	end
end

NetworkManager.set_game_object_unit = function (self, unit, game_object_id)
	local lookup = self._game_object_id_lookup

	lookup[unit] = game_object_id
	lookup[game_object_id] = unit
end

NetworkManager.unit = function (self, game_object_id)
	fassert(type(game_object_id) == "number", "Trying to fetch unit with non-number game object id.")

	return self._game_object_id_lookup[game_object_id]
end

NetworkManager.game_object_id = function (self, unit)
	fassert(type(unit) == "userdata", "Trying to fetch game object id with non-userdata unit.")

	return self._game_object_id_lookup[unit]
end

NetworkManager.create_game_object = function (self, type, data)
	return GameSession.create_game_object(self._session, type, data)
end

NetworkManager.destroy_game_object = function (self, object_id)
	GameSession.destroy_game_object(self._session, object_id)
end

NetworkManager.register_game_object_callback = function (self, callback_object, object_type, created_function_name, destroyed_function_name)
	local cbs = self._game_object_callbacks
	local old_cb = cbs[object_type]

	fassert(not old_cb, "%q already registered in class %q", object_type, old_cb and old_cb.__class_name)

	cbs[object_type] = {
		callback_object = callback_object,
		created = created_function_name,
		destroyed = destroyed_function_name
	}

	printf("registered callback to game object type %q to object of class %q", object_type, callback_object.__class_name)
end

NetworkManager._call_game_object_callback = function (self, object_id, owner, callback_type)
	local session = self._session

	for object_type, data in pairs(self._game_object_callbacks) do
		if GameSession.game_object_is_type(session, object_id, object_type) then
			local obj = data.callback_object

			obj[data[callback_type]](obj, object_type, session, object_id, owner)
			print("call_game_object_callback", object_id, owner, object_type)

			return
		end
	end

	fassert(false, "No callback registered for unknown type with id %i and owner %q.", object_id, owner)
end

NetworkManager.game_object_created = function (self, object_id, owner)
	print("game object created", object_id, owner)
	self:_call_game_object_callback(object_id, owner, "created")
end

NetworkManager.game_object_destroyed = function (self, object_id, owner)
	print("game object destroyed", object_id, owner)
	self:_call_game_object_callback(object_id, owner, "destroyed")
end
