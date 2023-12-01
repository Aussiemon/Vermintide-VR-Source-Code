-- chunkname: @script/lua/managers/unlock/unlock_manager.lua

require("settings/unlock_settings")
class("UnlockManager")

UnlockManager.init = function (self)
	self:check_dlcs()
end

UnlockManager.check_dlcs = function (self)
	self._unlocked_dlcs = {}

	if rawget(_G, "Steam") then
		for name, data in pairs(DLCSettings) do
			if Steam.owns_app(data.app_id) then
				self._unlocked_dlcs[name] = true
			else
				self._unlocked_dlcs[name] = false
			end
		end
	end
end

UnlockManager.is_dlc_unlocked = function (self, dlc_name)
	if not rawget(_G, "Steam") then
		return true
	end

	return self._unlocked_dlcs[dlc_name]
end
