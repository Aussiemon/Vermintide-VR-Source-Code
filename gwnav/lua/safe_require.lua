-- chunkname: @gwnav/lua/safe_require.lua

GWNAV_SAFE_REQUIRE = GWNAV_SAFE_REQUIRE or {
	error_level = 0,
	safely_required_modules = {}
}

function safe_require(file)
	if GWNAV_SAFE_REQUIRE.safely_required_modules[file] == nil then
		GWNAV_SAFE_REQUIRE.latest_safely_required_file = file

		local required_module = require(file)

		if GWNAV_SAFE_REQUIRE.latest_safely_required_file ~= nil then
			print_warning("`safe_require` called on unguarded file '" .. file .. "', falling back to `require` i.e. looping `require` calls will raise errors")

			GWNAV_SAFE_REQUIRE.latest_safely_required_file = nil

			return required_module
		end

		GWNAV_SAFE_REQUIRE.safely_required_modules[file] = required_module
	elseif GWNAV_SAFE_REQUIRE.error_level == 1 then
		require(file)
	end

	return GWNAV_SAFE_REQUIRE.safely_required_modules[file]
end

function safe_require_guard()
	local new_module = {}

	if GWNAV_SAFE_REQUIRE.latest_safely_required_file == nil then
		if GWNAV_SAFE_REQUIRE.error_level == 2 then
			print_warning("`safe_require` should be used for modules using `safe_require_guard`, otherwise looping `require` calls will raise errors")
		end

		return new_module
	end

	GWNAV_SAFE_REQUIRE.safely_required_modules[GWNAV_SAFE_REQUIRE.latest_safely_required_file] = new_module
	GWNAV_SAFE_REQUIRE.latest_safely_required_file = nil

	return new_module
end

function set_safe_require_error_level(new_error_level)
	GWNAV_SAFE_REQUIRE.error_level = new_error_level
end
