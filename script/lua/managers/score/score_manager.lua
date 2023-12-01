-- chunkname: @script/lua/managers/score/score_manager.lua

class("ScoreManager")

local score_per_minute = 1
local score_per_kill = 1
local score_per_headshot = 1

local function debug_printf(...)
	if script_data.debug_scoring then
		printf(...)
	end
end

ScoreManager.init = function (self, world)
	self._world = world
	self._score_tables = {}

	local network = Managers.lobby

	if network then
		self._network_mode = network.server and "server" or "client"
		self.add_score = self.add_score_network

		if self._network_mode == "client" then
			Managers.state.network:register_rpc_callbacks(self, "rpc_server_sync_score")
		end
	else
		self.add_score = self.add_score_local
	end

	self:_setup_default_score()
end

local local_player_index = "local_player"

ScoreManager._setup_default_score = function (self)
	local network = Managers.lobby

	if network then
		local lobby_members = network:lobby_members()

		for i, peer_id in ipairs(lobby_members) do
			self:_create_score_table(peer_id)
		end
	else
		self:_create_score_table(local_player_index)
	end
end

ScoreManager.add_score_local = function (self, score_type)
	assert(ScoreTypeLookup[score_type])

	local peer_id = local_player_index

	self:_add_score(peer_id, score_type)
end

ScoreManager.add_score_network = function (self, score_type, peer_id)
	assert(ScoreTypeLookup[score_type])
	assert(self._network_mode == "server")
	assert(peer_id, "no peer_id in add_score_network")
	self:_add_score(peer_id, score_type)
	self:_sync_score()
end

ScoreManager._add_score = function (self, peer_id, score_type)
	assert(ScoreTypeLookup[score_type])

	if not self:_peer_have_score_table(peer_id) then
		self:_create_score_table(peer_id)
	end

	local score_tables = self._score_tables
	local score_table = score_tables[peer_id]

	score_table[score_type] = score_table[score_type] + 1

	debug_printf("add_score peer_id:%s score_type:%s new_score:%d", peer_id, score_type, score_table[score_type])
end

ScoreManager._sync_score = function (self)
	local score_tables = self._score_tables

	for peer_id, score_table in pairs(score_tables) do
		local kills = score_table.kills
		local headshots = score_table.headshots
		local minutes_played = score_table.minutes_played

		Managers.state.network:send_rpc_clients("rpc_server_sync_score", peer_id, kills, headshots, minutes_played)
		debug_printf("[server sent] rpc_server_sync_score peer_id: %s kills:%d headshots:%d minutes_played:%d", peer_id, kills, headshots, minutes_played)
	end
end

ScoreManager._create_score_table = function (self, peer_id)
	self._score_tables[peer_id] = {
		headshots = 0,
		kills = 0,
		minutes_played = 0
	}
end

ScoreManager._peer_have_score_table = function (self, peer_id)
	return self._score_tables[peer_id]
end

ScoreManager.rpc_server_sync_score = function (self, sender, peer_id, kills, headshots, minutes_played)
	if not self:_peer_have_score_table(peer_id) then
		self:_create_score_table(peer_id)
	end

	local score_tables = self._score_tables
	local score_table = score_tables[peer_id]

	score_table.kills = kills
	score_table.headshots = headshots
	score_table.minutes_played = minutes_played

	debug_printf("[client received] rpc_server_sync_score peer_id: %s kills:%d headshots:%d minutes_played:%d", peer_id, kills, headshots, minutes_played)
end

ScoreManager.hot_join_sync = function (self, peer_id)
	self:_create_score_table(peer_id)
	self:_sync_score()
end

ScoreManager.scores = function (self)
	return self._score_tables
end

ScoreManager.destroy = function (self)
	return
end

ScoreManager.update = function (self, dt, t)
	Profiler.start("ScoreManager")
	Profiler.stop("ScoreManager")
end
