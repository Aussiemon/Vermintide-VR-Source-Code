-- chunkname: @script/lua/managers/save/save_data.lua

SaveFileNameUnlocks = "xx9b8isopt"
SaveDataUnlocks = SaveDataUnlocks or {
	version = 1,
	unlocks = {}
}

function populate_save_add_unlock(save_data, challenge_completed)
	if not rawget(_G, "Steam") then
		return
	end

	local steam_id = Steam.user_id()
	local stripped = string.gsub(steam_id, "^0*", "")
	local challenge_hash = Application.make_hash(challenge_completed .. "_" .. stripped)

	save_data.unlocks = save_data.unlocks or {}

	local new_unlock = not save_data.unlocks[challenge_hash]

	save_data.unlocks[challenge_hash] = true

	return new_unlock
end
