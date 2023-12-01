-- chunkname: @script/lua/managers/leaderboards/script_fetch_leaderboard_token.lua

class("ScriptFetchLeaderboardToken")

ScriptFetchLeaderboardToken.init = function (self, token, callback)
	self._token = token
	self._done = false
	self._callback = callback
	self._result = nil
end

ScriptFetchLeaderboardToken.update = function (self)
	local token = self._token
	local progress_data = Leaderboard.progress(token)

	if progress_data.transaction_status == "done" then
		self._done = true
		self._result = progress_data.work_status
		self._scores = progress_data.scores
		self._total_scores = progress_data.total_scores
		self._entry_count = progress_data.leaderboard_entry_count
	end
end

ScriptFetchLeaderboardToken.info = function (self)
	local info = {}

	info.result = self._result
	info.callback = self._callback
	info.scores = self._scores
	info.total_scores = self._total_scores
	info.entry_count = self._entry_count

	return info
end

ScriptFetchLeaderboardToken.done = function (self)
	return self._done
end

ScriptFetchLeaderboardToken.close = function (self)
	Leaderboard.close(self._token)
end
