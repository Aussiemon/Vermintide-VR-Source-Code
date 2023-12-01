-- chunkname: @foundation/script/util/development_parameter.lua

Development = Development or {}
Development._param_exist_cache = Development._param_exist_cache or {}
Development._app_param_value_cache = Development._app_param_value_cache or {}
Development._dev_param_value_cache = Development._dev_param_value_cache or {}

local param_exist_cache = Development._param_exist_cache
local app_param_value_cache = Development._app_param_value_cache
local dev_param_value_cache = Development._dev_param_value_cache

Development.parameter = function (param)
	if Application.build() == "release" then
		return nil
	end

	local app_param_value_cache = app_param_value_cache
	local dev_param_value_cache = dev_param_value_cache

	if not param_exist_cache[param] then
		param_exist_cache[param] = true
		app_param_value_cache[param] = Development.application_parameter[param:gsub("_", "-")]
		dev_param_value_cache[param] = Development.setting(param)
	end

	local application_param = app_param_value_cache[param]

	if application_param ~= nil then
		return application_param
	end

	return dev_param_value_cache[param]
end

Development.set_parameter = function (param, value)
	if Application.build() == "release" then
		return nil
	end

	param_exist_cache[param] = true
	app_param_value_cache[param] = value
	dev_param_value_cache[param] = value
end

Development.clear_param_cache = function (param)
	param_exist_cache[param] = nil
end

Development.init_parameters = function ()
	return
end

Development.clear_param_cache_all = function ()
	for param, _ in pairs(param_exist_cache) do
		param_exist_cache[param] = nil
	end
end
