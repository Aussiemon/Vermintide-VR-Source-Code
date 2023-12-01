-- chunkname: @script/lua/managers/save/save_manager.lua

require("script/lua/managers/save/script_save_token")
require("script/lua/managers/save/save_data")
class("SaveManager")

SaveManager.init = function (self, disable_cloud_save)
	if not disable_cloud_save and rawget(_G, "Steam") and Cloud.enabled() then
		fassert(rawget(_G, "Steam"), "Steam is required for cloud saves")

		self._impl = Cloud
	else
		self._impl = SaveSystem
	end
end

SaveManager.auto_save = function (self, file_name, data, callback, force_local_save)
	local system = force_local_save and SaveSystem or self._impl
	local token = SaveSystem.auto_save(file_name, data)
	local save_token = ScriptSaveToken:new(system, token)

	Managers.token:register_token(save_token, callback)

	return save_token
end

SaveManager.auto_load = function (self, file_name, callback, force_local_save)
	local system = force_local_save and SaveSystem or self._impl
	local token = system.auto_load(file_name)
	local save_token = ScriptSaveToken:new(system, token)

	Managers.token:register_token(save_token, callback)

	return save_token
end
