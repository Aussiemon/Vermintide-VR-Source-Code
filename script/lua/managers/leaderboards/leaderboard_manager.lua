-- chunkname: @script/lua/managers/leaderboards/leaderboard_manager.lua

require("script/lua/managers/leaderboards/script_leaderboard_token")
require("script/lua/managers/leaderboards/script_fetch_leaderboard_token")
class("LeaderboardManager")

LeaderboardManager.init = function (self)
	if rawget(_G, "Steam") then
		self._score_template = {
			Leaderboard.INT(32),
			Leaderboard.INT(32),
			Leaderboard.INT(32)
		}
		self._current_leaderboard = "global"
		self._leaderboards_enabled = true

		local token = Leaderboard.init_leaderboards("drachenfels")
		local script_token = ScriptLeaderboardToken:new(token)

		Managers.token:register_token(script_token, callback(self, "cb_leaderboards_loaded"))
	else
		self._current_leaderboard = nil
		self._leaderboards_enabled = false

		Application.error("[LeaderboardManager] Leaderboards disabled")
	end
end

LeaderboardManager.set_current_leaderboard = function (self, current_leaderboard)
	self._current_leaderboard = current_leaderboard
end

LeaderboardManager.current_leaderboard = function (self)
	return self._current_leaderboard
end

LeaderboardManager.initialized = function (self)
	return self._leaderboards_initialized
end

LeaderboardManager.enabled = function (self)
	return self._leaderboards_enabled and Managers.lobby and Managers.lobby:using_steam()
end

LeaderboardManager.cb_leaderboards_loaded = function (self, info)
	Application.error("[LeaderboardManager] INFO: " .. info.result)

	self._leaderboards_initialized = true
end

LeaderboardManager.register_score = function (self, leaderboard_name, data)
	local score_data = {
		data.kills,
		data.headshots,
		data.time_in_seconds
	}
	local token = Leaderboard.register_score(leaderboard_name, data.score, Leaderboard.KEEP_BEST, self._score_template, score_data)
	local script_token = ScriptLeaderboardToken:new(token)

	Managers.token:register_token(script_token, callback(self, "cb_score_registered"))
end

LeaderboardManager.get_global_leaderboard = function (self, leaderboard_name, start_rank, num_ranks, in_callback)
	local token = Leaderboard.ranking_range(leaderboard_name, start_rank, num_ranks, self._score_template)
	local script_token = ScriptFetchLeaderboardToken:new(token, in_callback)

	Managers.token:register_token(script_token, callback(self, "cb_leaderboard_fetched"))
end

LeaderboardManager.get_friend_leaderboard = function (self, leaderboard_name, in_callback)
	local token = Leaderboard.ranking_for_friends(leaderboard_name, self._score_template)
	local script_token = ScriptFetchLeaderboardToken:new(token, in_callback)

	Managers.token:register_token(script_token, callback(self, "cb_leaderboard_fetched"))
end

LeaderboardManager.get_around_player_leaderboard = function (self, leaderboard_name, in_callback)
	local token = Leaderboard.ranking_around_self(leaderboard_name, 5, 15, self._score_template)
	local script_token = ScriptFetchLeaderboardToken:new(token, in_callback)

	Managers.token:register_token(script_token, callback(self, "cb_leaderboard_fetched"))
end

LeaderboardManager.cb_score_registered = function (self, info)
	Application.error("[LeaderboardManager] INFO: " .. info.result)
end

LeaderboardManager.cb_leaderboard_fetched = function (self, info)
	if info.callback then
		info.callback(info)
	end
end

LeaderboardManager.update = function (self, dt)
	return
end

LeaderboardManager.destroy = function (self)
	return
end
