-- chunkname: @gwnav/lua/runtime/navhelpers.lua

require("gwnav/lua/safe_require")

local NavHelpers = safe_require_guard()
local Color = stingray.Color
local Unit = stingray.Unit

NavHelpers.unit_script_data = function (unit, default, ...)
	if unit and Unit.alive(unit) and Unit.has_data(unit, ...) then
		return Unit.get_data(unit, ...)
	else
		return default
	end
end

NavHelpers.get_layer_and_smartobject = function (unit, script_object_name)
	local is_exclusive = NavHelpers.unit_script_data(unit, false, script_object_name, "is_exclusive")

	if is_exclusive then
		return is_exclusive, Color(255, 0, 0), -1, -1, -1
	end

	local layer_id = NavHelpers.unit_script_data(unit, -1, script_object_name, "layer_id")
	local smartobject_id = NavHelpers.unit_script_data(unit, -1, script_object_name, "smartobject_id")
	local user_data_id = NavHelpers.unit_script_data(unit, -1, script_object_name, "user_data_id")
	local nav_tag_color = Color(NavHelpers.unit_script_data(unit, 0, script_object_name, "color", "r"), NavHelpers.unit_script_data(unit, 255, script_object_name, "color", "g"), NavHelpers.unit_script_data(unit, 0, script_object_name, "color", "b"))

	return is_exclusive, nav_tag_color, layer_id, smartobject_id, user_data_id
end

NavHelpers.iconcat_inplace = function (table1, table2)
	for _, v in ipairs(table2) do
		table.insert(table1, v)
	end
end

NavHelpers.iconcat = function (table1, table2)
	newtable = {}

	NavHelpers.iconcat_inplace(newtable, table1)
	NavHelpers.iconcat_inplace(newtable, table2)

	return newtable
end

NavHelpers.bit_xor = function (a, b)
	local p, c = 1, 0

	while a > 0 and b > 0 do
		local ra, rb = a % 2, b % 2

		if ra ~= rb then
			c = c + p
		end

		a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
	end

	if a < b then
		a = b
	end

	while a > 0 do
		local ra = a % 2

		if ra > 0 then
			c = c + p
		end

		a, p = (a - ra) / 2, p * 2
	end

	return c
end

NavHelpers.bit_or = function (a, b)
	local p, c = 1, 0

	while a + b > 0 do
		local ra, rb = a % 2, b % 2

		if ra + rb > 0 then
			c = c + p
		end

		a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
	end

	return c
end

NavHelpers.bit_not = function (n)
	local p, c = 1, 0

	while n > 0 do
		local r = n % 2

		if r < 1 then
			c = c + p
		end

		n, p = (n - r) / 2, p * 2
	end

	return c
end

NavHelpers.bit_and = function (a, b)
	local p, c = 1, 0

	while a > 0 and b > 0 do
		local ra, rb = a % 2, b % 2

		if ra + rb > 1 then
			c = c + p
		end

		a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
	end

	return c
end

NavHelpers.bit_left_shift = function (x, by)
	return x * 2^by
end

NavHelpers.bit_right_shift = function (x, by)
	return math.floor(x / 2^by)
end

return NavHelpers
